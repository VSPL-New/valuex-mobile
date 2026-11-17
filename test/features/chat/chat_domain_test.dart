import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/features/chat/domain/chat.dart';
import 'package:valuex_mobile/features/listing_view/domain/public_listing.dart';

import 'chat_fixtures.dart';

void main() {
  group('ChatThread', () {
    test('reads the list item and the detail cursors', () {
      final parsed = ChatThread.fromJson(threadJson(
        role: 'SELLER',
        unread: 3,
        lastSeq: 9,
        myReadSeq: 6,
        otherReadSeq: 4,
        otherDeliveredSeq: 8,
        lastMessage: {
          'type': 'IMAGE',
          'preview': 'Photo',
          'at': '2026-11-17T10:00:00Z',
          'fromMe': true
        },
      ));

      expect(parsed.isBuyer, isFalse);
      expect(parsed.unreadCount, 3);
      expect(parsed.lastSeq, 9);
      expect(parsed.myReadSeq, 6);
      expect(parsed.otherReadSeq, 4);
      expect(parsed.otherDeliveredSeq, 8);
      expect(parsed.lastMessage!.type, ChatMessageType.image);
      expect(parsed.lastMessage!.fromMe, isTrue);
      expect(parsed.listing.title, 'iPhone 15 Pro Max');
      expect(parsed.listing.available, isTrue);
      expect(parsed.canSend, isTrue);
    });

    test('a thread with no last message and no cursors uses the defaults', () {
      final parsed = ChatThread.fromJson(threadJson());

      expect(parsed.lastMessage, isNull);
      expect(parsed.lastSeq, 0);
      expect(parsed.isBuyer, isTrue);
    });

    test('maps the read-only reasons and ignores an unknown one', () {
      expect(ReadOnlyReason.from('BLOCKED'), ReadOnlyReason.blocked);
      expect(ReadOnlyReason.from('ACCOUNT_UNAVAILABLE'), ReadOnlyReason.accountUnavailable);
      expect(ReadOnlyReason.from('LISTING_REMOVED'), ReadOnlyReason.listingRemoved);
      expect(ReadOnlyReason.from('NOPE'), isNull);
      expect(ReadOnlyReason.from(null), isNull);
    });

    test('readOnly keeps everything else and closes the thread', () {
      final closed = thread(unread: 2, lastSeq: 5).readOnly(ReadOnlyReason.blocked);

      expect(closed.canSend, isFalse);
      expect(closed.readOnlyReason, ReadOnlyReason.blocked);
      expect(closed.unreadCount, 2);
      expect(closed.lastSeq, 5);
    });

    test('the counterpart initial is the first letter, upper case, or a question mark', () {
      expect(const ChatCounterpart(userId: 'u', displayName: 'rajesh').initial, 'R');
      expect(const ChatCounterpart(userId: 'u', displayName: '  आशा').initial, 'आ');
      expect(const ChatCounterpart(userId: 'u', displayName: ' ').initial, '?');
    });

    test('a page reads its items and whether more follow', () {
      final parsed = ChatThreadPage.fromJson({
        'items': [threadJson(), threadJson(id: 't2')],
        'page': 1,
        'hasNext': true,
      });

      expect(parsed.items.map((t) => t.threadId), ['t1', 't2']);
      expect(parsed.page, 1);
      expect(parsed.hasNext, isTrue);
      expect(ChatThreadPage.fromJson(const {}).items, isEmpty);
    });
  });

  group('ChatMessage', () {
    test('reads a text message, its flags and its status', () {
      final parsed = ChatMessage.fromJson(messageJson(
          seq: 4, fromMe: true, body: 'Hi', status: 'DELIVERED', flags: ['CONTACT_INFO']));

      expect(parsed.seq, 4);
      expect(parsed.type, ChatMessageType.text);
      expect(parsed.fromMe, isTrue);
      expect(parsed.status, MessageStatus.delivered);
      expect(parsed.flags, ['CONTACT_INFO']);
      expect(parsed.isPending, isFalse);
      expect(parsed.createdAt.toUtc(), DateTime.utc(2026, 11, 17, 10));
    });

    test('reads a picture link and a card payload', () {
      final picture = ChatMessage.fromJson(messageJson(
          seq: 2, type: 'IMAGE', image: {'url': 'https://x/y.jpg', 'width': 10, 'height': 5}));
      final card = listingCard();

      expect(picture.imageUrl, 'https://x/y.jpg');
      expect(card.type, ChatMessageType.listingContext);
      expect(card.type.isCard, isTrue);
      expect(card.payload['title'], 'iPhone 15 Pro Max');
      expect(picture.type.isCard, isFalse);
    });

    test('an unknown type is kept as unknown and counts as a card', () {
      expect(ChatMessageType.from('FUTURE'), ChatMessageType.unknown);
      expect(ChatMessageType.unknown.isCard, isTrue);
      expect(ChatMessageType.from('OFFER_EVENT'), ChatMessageType.offerEvent);
      expect(ChatMessageType.from('CALL_SUMMARY'), ChatMessageType.callSummary);
    });

    test('only the phone knows sending and failed; a server status maps to its state', () {
      expect(MessageStatus.from('SENT'), MessageStatus.sent);
      expect(MessageStatus.from('READ'), MessageStatus.read);
      expect(MessageStatus.from('SENDING'), isNull);
      final pending = message(seq: 0).copyWith(status: MessageStatus.failed);
      expect(pending.isPending, isTrue);
      expect(pending.copyWith(status: MessageStatus.sent).isPending, isFalse);
    });

    test('a page reads its messages in order', () {
      final parsed = ChatMessagePage.fromJson({
        'messages': [messageJson(seq: 1, body: 'a'), messageJson(seq: 2, body: 'b')],
        'hasMore': true,
      });

      expect(parsed.messages.map((m) => m.body), ['a', 'b']);
      expect(parsed.hasMore, isTrue);
    });
  });

  group('restricted terms', () {
    test('reads ranges and drops anything malformed or outside the text', () {
      final terms = parseRestrictedTerms('4-8,12-17,5-3,x-2,9,30-40,-1-2', 20);

      expect(terms.map((t) => (t.start, t.end)), [(4, 8), (12, 17)]);
    });

    test('nothing to read gives no terms', () {
      expect(parseRestrictedTerms(null, 10), isEmpty);
      expect(parseRestrictedTerms('', 10), isEmpty);
    });
  });

  group('capabilities of the listing page', () {
    test('reads the new reasons and the offer option', () {
      final parsed = Capabilities.fromJson({
        'chat': {'available': true, 'reason': null},
        'call': {'available': false, 'reason': 'COMING_SOON'},
        'video': {'available': false, 'reason': 'UNAVAILABLE'},
        'offer': {'available': false, 'reason': 'NOT_NEGOTIABLE'},
        'cart': {'available': false, 'reason': 'IDENTITY_REQUIRED'},
        'buyNow': {'available': false, 'reason': 'SOMETHING_NEW'},
      });

      expect(parsed.chat.available, isTrue);
      expect(parsed.video.reason, CapabilityReason.unavailable);
      expect(parsed.offer.reason, CapabilityReason.notNegotiable);
      expect(parsed.cart.reason, CapabilityReason.identityRequired);
      expect(parsed.buyNow.reason, CapabilityReason.other);
    });

    test('an older server without offer leaves it hidden', () {
      final parsed = Capabilities.fromJson({
        'chat': {'available': true},
      });

      expect(parsed.offer.hidden, isTrue);
    });

    test('the listing carries the caller\'s existing chat id', () {
      final listing = PublicListing.fromJson({
        'listingId': 'l1',
        'contact': {'threadId': 't9', 'negotiationId': null},
        'seller': {'sellerId': 's1', 'displayName': 'Asha'},
      });
      final without = PublicListing.fromJson({
        'listingId': 'l1',
        'seller': {'sellerId': 's1', 'displayName': 'Asha'},
      });

      expect(listing.chatThreadId, 't9');
      expect(without.chatThreadId, isNull);
    });
  });
}
