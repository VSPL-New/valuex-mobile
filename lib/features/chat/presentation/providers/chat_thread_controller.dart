import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/utils/provider_retry.dart';
import '../../../profile/data/profile_repository.dart';
import '../../data/chat_repository.dart';
import '../../domain/chat.dart';
import 'chat_polling.dart';
import 'chat_unread_provider.dart';

/// What happened to a message the user tried to send.
sealed class SendOutcome {
  const SendOutcome();
}

/// The server stored it.
class SendStored extends SendOutcome {
  const SendStored();
}

/// The phone could not reach the server. The message stays in the thread with a Retry, under the
/// same client id, so retrying never doubles it.
class SendQueued extends SendOutcome {
  const SendQueued();
}

/// The server blocked the text for restricted terms and stored nothing (decision D13). The user can
/// edit it, or choose Deliver message and agree.
class SendFlagged extends SendOutcome {
  final String clientMessageId;
  final String body;
  final List<RestrictedTerm> terms;

  const SendFlagged({required this.clientMessageId, required this.body, required this.terms});
}

/// The server refused it and stored nothing; [error] says why. The text belongs back in the composer.
class SendRefused extends SendOutcome {
  final Object error;

  const SendRefused(this.error);
}

/// An open conversation: the thread, its messages in order, and what is still being sent.
class ChatThreadState {
  final ChatThread thread;

  /// Stored messages in order of sequence, then the ones still being sent in the order written.
  final List<ChatMessage> messages;
  final bool hasMoreOlder;
  final bool loadingOlder;

  /// The first message from the other person that was unread when the thread opened; 0 for none.
  final int firstUnreadSeq;

  const ChatThreadState({
    required this.thread,
    required this.messages,
    required this.hasMoreOlder,
    this.loadingOlder = false,
    this.firstUnreadSeq = 0,
  });

  /// The highest sequence the server has given to a message the phone holds.
  int get lastSeq => messages.fold(0, (highest, message) => math.max(highest, message.seq));

  ChatThreadState copyWith({
    ChatThread? thread,
    List<ChatMessage>? messages,
    bool? hasMoreOlder,
    bool? loadingOlder,
  }) =>
      ChatThreadState(
        thread: thread ?? this.thread,
        messages: messages ?? this.messages,
        hasMoreOlder: hasMoreOlder ?? this.hasMoreOlder,
        loadingOlder: loadingOlder ?? this.loadingOlder,
        firstUnreadSeq: firstUnreadSeq,
      );
}

class _ImageDraft {
  final String fileName;
  final String contentType;
  final int width;
  final int height;

  const _ImageDraft(this.fileName, this.contentType, this.width, this.height);
}

/// One conversation (US-013). Messages are ordered by the sequence the server gives; a message the
/// user writes shows at once as sending and is replaced by the stored one. News arrives by polling
/// while the screen is open.
class ChatThreadController extends AsyncNotifier<ChatThreadState> {
  static const _uuid = Uuid();

  final String threadId;

  /// Media already uploaded for a picture that is being sent, so a retry only sends the message.
  final Map<String, String> _uploaded = {};
  final Map<String, _ImageDraft> _drafts = {};

  /// Ids of messages that failed for a reason a retry can fix; they are retried after a good poll.
  final Set<String> _retryable = {};

  ChatThreadController(this.threadId);

  @override
  Future<ChatThreadState> build() async {
    final repository = ref.watch(chatRepositoryProvider);
    final interval = ref.watch(chatPollIntervalProvider);
    if (interval != null) {
      final timer = Timer.periodic(interval, (_) => unawaited(_poll()));
      ref.onDispose(timer.cancel);
    }
    final (thread, page) = await (repository.thread(threadId), repository.messages(threadId)).wait;
    final firstUnread = page.messages
        .where((message) => !message.fromMe && message.seq > thread.myReadSeq)
        .map((message) => message.seq)
        .fold(0, (first, seq) => first == 0 ? seq : math.min(first, seq));
    final messages = _withStatuses(page.messages, thread);
    unawaited(_markSeen(messages.fold(0, (highest, m) => math.max(highest, m.seq)), thread));
    return ChatThreadState(
      thread: thread,
      messages: messages,
      hasMoreOlder: page.hasMore,
      firstUnreadSeq: firstUnread,
    );
  }

  /// Sends a text message. [clientMessageId] and [agreed] are used to deliver a message the server
  /// blocked after the user agreed (decision D13).
  Future<SendOutcome> sendText(String text, {String? clientMessageId, bool agreed = false}) {
    final body = text.trim();
    final id = clientMessageId ?? _uuid.v4();
    _add(_pending(id, ChatMessageType.text, body: body));
    return _deliver(id, () => _sendText(id, body, agreed));
  }

  /// Sends a picture: it is uploaded, cleaned by the server, then sent as a message.
  Future<SendOutcome> sendImage({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    required int width,
    required int height,
  }) {
    final id = _uuid.v4();
    _drafts[id] = _ImageDraft(fileName, contentType, width, height);
    _add(_pending(id, ChatMessageType.image, bytes: bytes));
    return _deliver(id, () => _sendImage(id));
  }

  /// Sends a failed message again with the same client id.
  Future<SendOutcome> retry(String clientMessageId) {
    final message = _find(clientMessageId);
    if (message == null || message.status != MessageStatus.failed) {
      return Future.value(const SendStored());
    }
    _replace(clientMessageId, message.copyWith(status: MessageStatus.sending));
    _retryable.remove(clientMessageId);
    return _deliver(
      clientMessageId,
      () => message.type == ChatMessageType.image
          ? _sendImage(clientMessageId)
          : _sendText(clientMessageId, message.body ?? '', false),
    );
  }

  /// Takes a message that is still pending out of the thread, for a Delete after a failure.
  void discard(String clientMessageId) {
    _retryable.remove(clientMessageId);
    _drafts.remove(clientMessageId);
    _remove(clientMessageId);
  }

  /// Loads the page of messages before the oldest one the phone holds.
  Future<bool> loadOlder() async {
    final current = state.value;
    if (current == null || !current.hasMoreOlder || current.loadingOlder) return true;
    final oldest = current.messages.where((m) => m.seq > 0).map((m) => m.seq).fold(0, _lowest);
    if (oldest == 0) return true;
    state = AsyncData(current.copyWith(loadingOlder: true));
    try {
      final page = await ref.read(chatRepositoryProvider).messages(threadId, beforeSeq: oldest);
      if (!ref.mounted) return true;
      final latest = state.value ?? current;
      state = AsyncData(latest.copyWith(
        messages: _normalize([...page.messages, ...latest.messages], latest.thread),
        hasMoreOlder: page.hasMore,
        loadingOlder: false,
      ));
      return true;
    } on Object {
      if (ref.mounted) state = AsyncData((state.value ?? current).copyWith(loadingOlder: false));
      return false;
    }
  }

  Future<ChatMessage> _sendText(String id, String body, bool agreed) => ref
      .read(chatRepositoryProvider)
      .sendText(threadId, clientMessageId: id, body: body, agreed: agreed);

  Future<ChatMessage> _sendImage(String id) async {
    final repository = ref.read(chatRepositoryProvider);
    var mediaId = _uploaded[id];
    if (mediaId == null) {
      final message = _find(id);
      final draft = _drafts[id];
      final bytes = message?.pendingImage;
      if (draft == null || bytes == null) {
        throw const ApiError(type: ApiErrorType.unknown, message: 'Picture is gone');
      }
      final owner = await ref.read(userProfileProvider.future);
      mediaId = await repository.uploadImage(
        ownerId: owner.userId,
        fileName: draft.fileName,
        contentType: draft.contentType,
        bytes: bytes,
        width: draft.width,
        height: draft.height,
      );
      _uploaded[id] = mediaId;
    }
    return repository.sendImage(threadId, clientMessageId: id, mediaId: mediaId);
  }

  Future<SendOutcome> _deliver(String id, Future<ChatMessage> Function() send) async {
    try {
      final stored = await send();
      if (!ref.mounted) return const SendStored();
      _confirm(id, stored);
      return const SendStored();
    } on ApiError catch (error) {
      if (!ref.mounted) return SendRefused(error);
      return _afterFailure(id, error);
    } on Object catch (error) {
      if (!ref.mounted) return SendRefused(error);
      return _afterFailure(id, ApiError(type: ApiErrorType.unknown, message: error.toString()));
    }
  }

  SendOutcome _afterFailure(String id, ApiError error) {
    final message = _find(id);
    switch (error.code) {
      case 'WARNING_CONTENT_FLAGGED':
        final body = message?.body ?? '';
        _remove(id);
        return SendFlagged(
          clientMessageId: id,
          body: body,
          terms: parseRestrictedTerms(error.details['terms'], body.length),
        );
      case 'ERROR_BLOCKED':
        _closeThread(ReadOnlyReason.blocked);
      case 'ERROR_THREAD_READ_ONLY':
        _closeThread(ReadOnlyReason.listingRemoved);
      case 'ERROR_SELLER_UNAVAILABLE':
        _closeThread(ReadOnlyReason.accountUnavailable);
    }
    if (error.isRetryable && error.code == null) {
      _replace(id,
          (message ?? _pending(id, ChatMessageType.text)).copyWith(status: MessageStatus.failed));
      _retryable.add(id);
      return const SendQueued();
    }
    _drafts.remove(id);
    _remove(id);
    return SendRefused(error);
  }

  Future<void> _poll() async {
    final current = state.value;
    if (current == null) return;
    final repository = ref.read(chatRepositoryProvider);
    try {
      final (thread, page) = await (
        repository.thread(threadId),
        repository.messages(threadId, afterSeq: current.lastSeq)
      ).wait;
      if (!ref.mounted) return;
      final latest = state.value ?? current;
      final merged = _normalize([...latest.messages, ...page.messages], thread);
      state = AsyncData(latest.copyWith(thread: thread, messages: merged));
      if (page.messages.any((message) => !message.fromMe)) {
        unawaited(_markSeen(merged.fold(0, (highest, m) => math.max(highest, m.seq)), thread));
      }
      for (final id in _retryable.toList()) {
        unawaited(retry(id));
      }
    } on Object {
      // Offline or a server hiccup: the next poll tries again.
    }
  }

  /// Tells the server the caller has received and read everything up to [upTo].
  Future<void> _markSeen(int upTo, ChatThread thread) async {
    if (upTo <= 0 || upTo <= thread.myReadSeq) return;
    final repository = ref.read(chatRepositoryProvider);
    try {
      await repository.markDelivered(threadId, upTo);
      await repository.markRead(threadId, upTo);
      if (ref.mounted) ref.invalidate(chatUnreadCountProvider);
    } on Object {
      // The cursor moves with the next successful poll.
    }
  }

  void _closeThread(ReadOnlyReason reason) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(thread: current.thread.readOnly(reason)));
  }

  ChatMessage _pending(String id, ChatMessageType type, {String? body, Uint8List? bytes}) =>
      ChatMessage(
        seq: 0,
        clientMessageId: id,
        type: type,
        fromMe: true,
        createdAt: DateTime.now(),
        body: body,
        pendingImage: bytes,
        status: MessageStatus.sending,
      );

  ChatMessage? _find(String clientMessageId) {
    final current = state.value;
    if (current == null) return null;
    for (final message in current.messages) {
      if (message.seq == 0 && message.clientMessageId == clientMessageId) return message;
    }
    return null;
  }

  void _add(ChatMessage message) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(messages: [...current.messages, message]));
  }

  void _replace(String clientMessageId, ChatMessage replacement) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(messages: [
      for (final message in current.messages)
        if (message.seq == 0 && message.clientMessageId == clientMessageId)
          replacement
        else
          message,
    ]));
  }

  void _remove(String clientMessageId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(messages: [
      for (final message in current.messages)
        if (!(message.seq == 0 && message.clientMessageId == clientMessageId)) message,
    ]));
  }

  /// The stored message takes the place of the pending one.
  void _confirm(String clientMessageId, ChatMessage stored) {
    final current = state.value;
    if (current == null) return;
    _drafts.remove(clientMessageId);
    _uploaded.remove(clientMessageId);
    _retryable.remove(clientMessageId);
    final others = [
      for (final message in current.messages)
        if (!(message.seq == 0 && message.clientMessageId == clientMessageId)) message,
    ];
    state = AsyncData(current.copyWith(messages: _normalize([...others, stored], current.thread)));
  }

  static int _lowest(int lowest, int seq) => lowest == 0 ? seq : math.min(lowest, seq);

  /// Stored messages once each, in order of sequence, then the ones still pending as written.
  List<ChatMessage> _normalize(List<ChatMessage> all, ChatThread thread) {
    final stored = <int, ChatMessage>{};
    final pending = <ChatMessage>[];
    for (final message in all) {
      if (message.seq == 0) {
        pending.add(message);
      } else {
        stored[message.seq] = message;
      }
    }
    final ordered = stored.keys.toList()..sort();
    return [
      ..._withStatuses([for (final seq in ordered) stored[seq]!], thread),
      ...pending
    ];
  }

  /// Sent, Delivered or Read for the caller's own messages, from the other person's cursors.
  List<ChatMessage> _withStatuses(List<ChatMessage> messages, ChatThread thread) => [
        for (final message in messages)
          if (message.fromMe && message.seq > 0)
            message.copyWith(
              status: message.seq <= thread.otherReadSeq
                  ? MessageStatus.read
                  : message.seq <= thread.otherDeliveredSeq
                      ? MessageStatus.delivered
                      : (message.status == MessageStatus.delivered ||
                              message.status == MessageStatus.read)
                          ? message.status
                          : MessageStatus.sent,
            )
          else
            message,
      ];
}

final chatThreadControllerProvider =
    AsyncNotifierProvider.autoDispose.family<ChatThreadController, ChatThreadState, String>(
  ChatThreadController.new,
  retry: noAutoRetry,
);
