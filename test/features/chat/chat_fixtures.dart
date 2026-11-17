import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/features/chat/data/chat_repository.dart';
import 'package:valuex_mobile/features/chat/domain/chat.dart';

class MockChatRepository extends Mock implements ChatRepository {}

Map<String, dynamic> threadJson({
  String id = 't1',
  String role = 'BUYER',
  String listingId = 'l1',
  String listingTitle = 'iPhone 15 Pro Max',
  String counterpart = 'Rajesh Kumar',
  Map<String, dynamic>? lastMessage,
  int unread = 0,
  bool canSend = true,
  String? readOnlyReason,
  int? lastSeq,
  int myReadSeq = 0,
  int otherReadSeq = 0,
  int otherDeliveredSeq = 0,
  bool available = true,
}) =>
    {
      'threadId': id,
      'role': role,
      'listing': {
        'listingId': listingId,
        'title': listingTitle,
        'price': 52000,
        'thumbnailUrl': null,
        'available': available,
      },
      'counterpart': {'userId': 'u-$counterpart', 'displayName': counterpart},
      'lastMessage': lastMessage,
      'unreadCount': unread,
      'canSend': canSend,
      'readOnlyReason': readOnlyReason,
      if (lastSeq != null) ...{
        'lastSeq': lastSeq,
        'myReadSeq': myReadSeq,
        'otherReadSeq': otherReadSeq,
        'otherDeliveredSeq': otherDeliveredSeq,
      },
    };

ChatThread thread({
  String id = 't1',
  String role = 'BUYER',
  String counterpart = 'Rajesh Kumar',
  String listingTitle = 'iPhone 15 Pro Max',
  Map<String, dynamic>? lastMessage,
  int unread = 0,
  bool canSend = true,
  String? readOnlyReason,
  int lastSeq = 1,
  int myReadSeq = 0,
  int otherReadSeq = 0,
  int otherDeliveredSeq = 0,
}) =>
    ChatThread.fromJson(threadJson(
      id: id,
      role: role,
      counterpart: counterpart,
      listingTitle: listingTitle,
      lastMessage: lastMessage,
      unread: unread,
      canSend: canSend,
      readOnlyReason: readOnlyReason,
      lastSeq: lastSeq,
      myReadSeq: myReadSeq,
      otherReadSeq: otherReadSeq,
      otherDeliveredSeq: otherDeliveredSeq,
    ));

Map<String, dynamic> messageJson({
  required int seq,
  String type = 'TEXT',
  bool fromMe = false,
  String? body,
  String? status,
  Map<String, dynamic>? image,
  Map<String, dynamic>? payload,
  List<String> flags = const [],
  String at = '2026-11-17T10:00:00Z',
}) =>
    {
      'id': 'm$seq',
      'seq': seq,
      'type': type,
      'fromMe': fromMe,
      'body': body,
      'image': image,
      'payload': payload,
      'flags': flags,
      'status': status,
      'createdAt': at,
    };

ChatMessage message({
  required int seq,
  bool fromMe = false,
  String? body,
  String type = 'TEXT',
  String? status,
  String at = '2026-11-17T10:00:00Z',
}) =>
    ChatMessage.fromJson(messageJson(
        seq: seq, fromMe: fromMe, body: body ?? 'm$seq', type: type, status: status, at: at));

ChatMessage listingCard({int seq = 1, String title = 'iPhone 15 Pro Max'}) =>
    ChatMessage.fromJson(messageJson(
      seq: seq,
      type: 'LISTING_CONTEXT',
      payload: {'listingId': 'l1', 'title': title, 'price': 52000},
    ));

ChatMessagePage page(List<ChatMessage> messages, {bool hasMore = false}) =>
    ChatMessagePage(messages: messages, hasMore: hasMore);

ChatThreadPage threadPage(List<ChatThread> items, {int page = 0, bool hasNext = false}) =>
    ChatThreadPage(items: items, page: page, hasNext: hasNext);
