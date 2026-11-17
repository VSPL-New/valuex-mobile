import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// The version of the "Deliver message" agreement text the app shows. The server refuses another
/// version, so a change here and on the server go together (decision D13).
const String policyAgreementVersion = 'policy-override-v1';

/// The longest text message the server accepts (`CHAT_MESSAGE_MAX_CHARS`, Admin-managed); the
/// counter uses this and the server still has the last word.
const int chatMessageMaxChars = 2000;

/// What a message is. Only [text] and [image] are written by a person; the others are cards.
enum ChatMessageType {
  text,
  image,
  listingContext,
  offerEvent,
  callSummary,
  unknown;

  static ChatMessageType from(String? value) => switch (value) {
        'TEXT' => text,
        'IMAGE' => image,
        'LISTING_CONTEXT' => listingContext,
        'OFFER_EVENT' => offerEvent,
        'CALL_SUMMARY' => callSummary,
        _ => unknown,
      };

  bool get isCard => this != text && this != image;
}

/// Where one of the caller's own messages is on its way. [sending] and [failed] exist only on the
/// phone; the server knows [sent], [delivered] and [read].
enum MessageStatus {
  sending,
  failed,
  sent,
  delivered,
  read;

  static MessageStatus? from(String? value) => switch (value) {
        'SENT' => sent,
        'DELIVERED' => delivered,
        'READ' => read,
        _ => null,
      };
}

/// Why nobody can write in a thread any more; the history stays readable.
enum ReadOnlyReason {
  blocked,
  accountUnavailable,
  listingRemoved;

  static ReadOnlyReason? from(String? value) => switch (value) {
        'BLOCKED' => blocked,
        'ACCOUNT_UNAVAILABLE' => accountUnavailable,
        'LISTING_REMOVED' => listingRemoved,
        _ => null,
      };
}

/// Which side of the conversations the list shows.
enum ChatRole {
  all('ALL'),
  buying('BUYING'),
  selling('SELLING');

  /// The value the API expects.
  final String apiName;

  const ChatRole(this.apiName);
}

/// The listing a conversation is about, as it was when the chat started.
@immutable
class ChatListingRef {
  final String listingId;
  final String title;
  final num? price;
  final String? thumbnailUrl;
  final bool available;

  const ChatListingRef({
    required this.listingId,
    required this.title,
    this.price,
    this.thumbnailUrl,
    this.available = true,
  });

  factory ChatListingRef.fromJson(Map<String, dynamic> json) => ChatListingRef(
        listingId: json['listingId'] as String,
        title: json['title'] as String? ?? '',
        price: json['price'] as num?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        available: json['available'] as bool? ?? true,
      );
}

/// The other person in a conversation.
@immutable
class ChatCounterpart {
  final String userId;
  final String displayName;

  const ChatCounterpart({required this.userId, required this.displayName});

  factory ChatCounterpart.fromJson(Map<String, dynamic> json) => ChatCounterpart(
        userId: json['userId'] as String,
        displayName: json['displayName'] as String? ?? '',
      );

  /// The first letter of the name, shown in the avatar.
  String get initial {
    final name = displayName.trim();
    return name.isEmpty ? '?' : String.fromCharCode(name.runes.first).toUpperCase();
  }
}

/// A short preview of a conversation's last message; never the full text.
@immutable
class ChatLastMessage {
  final ChatMessageType type;
  final String? preview;
  final DateTime? at;
  final bool fromMe;

  const ChatLastMessage({required this.type, this.preview, this.at, this.fromMe = false});

  factory ChatLastMessage.fromJson(Map<String, dynamic> json) => ChatLastMessage(
        type: ChatMessageType.from(json['type'] as String?),
        preview: json['preview'] as String?,
        at: DateTime.tryParse(json['at'] as String? ?? '')?.toLocal(),
        fromMe: json['fromMe'] as bool? ?? false,
      );
}

/// One conversation of a buyer and a seller about a listing. The cursor fields are only filled by
/// the single-thread call.
@immutable
class ChatThread {
  final String threadId;
  final bool isBuyer;
  final ChatListingRef listing;
  final ChatCounterpart counterpart;
  final ChatLastMessage? lastMessage;
  final int unreadCount;
  final bool canSend;
  final ReadOnlyReason? readOnlyReason;
  final int lastSeq;
  final int myReadSeq;
  final int otherReadSeq;
  final int otherDeliveredSeq;

  const ChatThread({
    required this.threadId,
    required this.isBuyer,
    required this.listing,
    required this.counterpart,
    this.lastMessage,
    this.unreadCount = 0,
    this.canSend = true,
    this.readOnlyReason,
    this.lastSeq = 0,
    this.myReadSeq = 0,
    this.otherReadSeq = 0,
    this.otherDeliveredSeq = 0,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    final last = json['lastMessage'];
    return ChatThread(
      threadId: json['threadId'] as String,
      isBuyer: json['role'] != 'SELLER',
      listing: ChatListingRef.fromJson(json['listing'] as Map<String, dynamic>),
      counterpart: ChatCounterpart.fromJson(json['counterpart'] as Map<String, dynamic>),
      lastMessage: last is Map<String, dynamic> ? ChatLastMessage.fromJson(last) : null,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      canSend: json['canSend'] as bool? ?? true,
      readOnlyReason: ReadOnlyReason.from(json['readOnlyReason'] as String?),
      lastSeq: (json['lastSeq'] as num?)?.toInt() ?? 0,
      myReadSeq: (json['myReadSeq'] as num?)?.toInt() ?? 0,
      otherReadSeq: (json['otherReadSeq'] as num?)?.toInt() ?? 0,
      otherDeliveredSeq: (json['otherDeliveredSeq'] as num?)?.toInt() ?? 0,
    );
  }

  /// The thread made read-only, as the server reports a block or a closed listing on a send.
  ChatThread readOnly(ReadOnlyReason reason) => withAccess(canSend: false, reason: reason);

  /// The thread with what the server says about the other person's cursors or the last sequence.
  /// A cursor or sequence never moves backwards.
  ChatThread advanced({int? lastSeq, int? otherReadSeq, int? otherDeliveredSeq}) => ChatThread(
        threadId: threadId,
        isBuyer: isBuyer,
        listing: listing,
        counterpart: counterpart,
        lastMessage: lastMessage,
        unreadCount: unreadCount,
        canSend: canSend,
        readOnlyReason: readOnlyReason,
        lastSeq: math.max(this.lastSeq, lastSeq ?? 0),
        myReadSeq: myReadSeq,
        otherReadSeq: math.max(this.otherReadSeq, otherReadSeq ?? 0),
        otherDeliveredSeq: math.max(this.otherDeliveredSeq, otherDeliveredSeq ?? 0),
      );

  /// The thread with whether anyone can write in it, and why not.
  ChatThread withAccess({required bool canSend, ReadOnlyReason? reason}) => ChatThread(
        threadId: threadId,
        isBuyer: isBuyer,
        listing: listing,
        counterpart: counterpart,
        lastMessage: lastMessage,
        unreadCount: unreadCount,
        canSend: canSend,
        readOnlyReason: canSend ? null : reason,
        lastSeq: lastSeq,
        myReadSeq: myReadSeq,
        otherReadSeq: otherReadSeq,
        otherDeliveredSeq: otherDeliveredSeq,
      );
}

/// One page of conversations, most recently active first.
@immutable
class ChatThreadPage {
  final List<ChatThread> items;
  final int page;
  final bool hasNext;

  const ChatThreadPage({required this.items, required this.page, required this.hasNext});

  factory ChatThreadPage.fromJson(Map<String, dynamic> json) => ChatThreadPage(
        items: [
          for (final item in json['items'] as List<dynamic>? ?? const [])
            ChatThread.fromJson(item as Map<String, dynamic>),
        ],
        page: (json['page'] as num?)?.toInt() ?? 0,
        hasNext: json['hasNext'] as bool? ?? false,
      );
}

/// One message. A message the phone has not sent yet has a [clientMessageId] of its own and no
/// [seq]; once the server stores it the stored message replaces it.
@immutable
class ChatMessage {
  /// Sequence given by the server, the only order that counts; 0 until it is sent.
  final int seq;
  final String? id;
  final String clientMessageId;
  final ChatMessageType type;
  final bool fromMe;
  final String? body;
  final String? imageUrl;
  final Map<String, dynamic> payload;
  final List<String> flags;
  final MessageStatus? status;
  final DateTime createdAt;

  /// Bytes of a picture that is still being sent, so the bubble can show it.
  final Uint8List? pendingImage;

  const ChatMessage({
    required this.seq,
    required this.clientMessageId,
    required this.type,
    required this.fromMe,
    required this.createdAt,
    this.id,
    this.body,
    this.imageUrl,
    this.payload = const {},
    this.flags = const [],
    this.status,
    this.pendingImage,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final image = json['image'];
    final payload = json['payload'];
    return ChatMessage(
      id: json['id'] as String?,
      seq: (json['seq'] as num?)?.toInt() ?? 0,
      clientMessageId: json['id'] as String? ?? '',
      type: ChatMessageType.from(json['type'] as String?),
      fromMe: json['fromMe'] as bool? ?? false,
      body: json['body'] as String?,
      imageUrl: image is Map<String, dynamic> ? image['url'] as String? : null,
      payload: payload is Map<String, dynamic> ? payload : const {},
      flags: [for (final flag in json['flags'] as List<dynamic>? ?? const []) flag as String],
      status: MessageStatus.from(json['status'] as String?),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

  bool get isPending => status == MessageStatus.sending || status == MessageStatus.failed;

  ChatMessage copyWith({MessageStatus? status}) => ChatMessage(
        seq: seq,
        id: id,
        clientMessageId: clientMessageId,
        type: type,
        fromMe: fromMe,
        createdAt: createdAt,
        body: body,
        imageUrl: imageUrl,
        payload: payload,
        flags: flags,
        status: status ?? this.status,
        pendingImage: pendingImage,
      );
}

/// A page of history in ascending order of sequence.
@immutable
class ChatMessagePage {
  final List<ChatMessage> messages;
  final bool hasMore;

  const ChatMessagePage({required this.messages, required this.hasMore});

  factory ChatMessagePage.fromJson(Map<String, dynamic> json) => ChatMessagePage(
        messages: [
          for (final item in json['messages'] as List<dynamic>? ?? const [])
            ChatMessage.fromJson(item as Map<String, dynamic>),
        ],
        hasMore: json['hasMore'] as bool? ?? false,
      );
}

/// A stretch of a message the server found restricted: [start] inclusive, [end] exclusive.
@immutable
class RestrictedTerm {
  final int start;
  final int end;

  const RestrictedTerm(this.start, this.end);
}

/// Reads the `terms` detail of `WARNING_CONTENT_FLAGGED`: ranges such as `4-8,12-17`. A malformed
/// or out-of-range piece is dropped, so the highlight can never break the text.
List<RestrictedTerm> parseRestrictedTerms(String? raw, int textLength) {
  if (raw == null || raw.isEmpty) return const [];
  final terms = <RestrictedTerm>[];
  for (final piece in raw.split(',')) {
    final parts = piece.split('-');
    if (parts.length != 2) continue;
    final start = int.tryParse(parts[0]);
    final end = int.tryParse(parts[1]);
    if (start == null || end == null || start < 0 || end <= start || end > textLength) continue;
    terms.add(RestrictedTerm(start, end));
  }
  return terms;
}
