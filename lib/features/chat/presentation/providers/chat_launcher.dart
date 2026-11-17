import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/chat_repository.dart';

/// What opening a chat gave: the thread to show, or the reason it could not be opened.
class OpenChatResult {
  final String? threadId;
  final Object? error;

  const OpenChatResult.opened(String this.threadId) : error = null;
  const OpenChatResult.failed(Object this.error) : threadId = null;

  /// A second tap while a request is running.
  const OpenChatResult.ignored()
      : threadId = null,
        error = null;
}

/// Starts a chat from a listing's Chat button (US-069). While a request runs the state is true, so
/// a second tap does nothing and the server never sees two requests.
class ChatLauncher extends Notifier<bool> {
  @override
  bool build() => false;

  /// Opens the chat about [listingId]; a thread the listing page already knows is used directly.
  Future<OpenChatResult> open(String listingId, {String? knownThreadId}) async {
    if (knownThreadId != null) return OpenChatResult.opened(knownThreadId);
    if (state) return const OpenChatResult.ignored();
    state = true;
    try {
      final opened = await ref.read(chatRepositoryProvider).open(listingId);
      return OpenChatResult.opened(opened.thread.threadId);
    } on Object catch (error) {
      return OpenChatResult.failed(error);
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

final chatLauncherProvider = NotifierProvider.autoDispose<ChatLauncher, bool>(ChatLauncher.new);
