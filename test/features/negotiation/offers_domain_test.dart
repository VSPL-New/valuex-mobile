import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/features/negotiation/domain/negotiation.dart';
import 'package:valuex_mobile/features/negotiation/domain/offers.dart';

import 'negotiation_fixtures.dart';
import 'offers_fixtures.dart';

void main() {
  group('OffersFilter', () {
    test('names the server lists', () {
      expect(OffersFilter.pending.apiName, 'PENDING');
      expect(OffersFilter.accepted.apiName, 'ACCEPTED');
      expect(OffersFilter.closed.apiName, 'CLOSED');
    });
  });

  group('a received offer', () {
    test('carries the buyer, the item, the prices and the clocks', () {
      final page = receivedPage([
        receivedJson(rating: 4.5, ratingCount: 12, thumbnailUrl: 'https://cdn/t.jpg'),
      ]);

      final card = page.items.single;

      expect(card.negotiationId, 'n1');
      expect(card.counterpartName, 'Ravi K');
      expect(card.counterpartRating, 4.5);
      expect(card.counterpartRatingCount, 12);
      expect(card.listingTitle, 'Apple Watch');
      expect(card.thumbnailUrl, 'https://cdn/t.jpg');
      expect(card.offeredPrice, 12000);
      expect(card.askingPrice, 14500);
      expect(card.offeredAt, DateTime.utc(2026, 11, 17, 8));
      expect(card.expiresAt, DateTime.utc(2026, 11, 17, 14, 20));
      expect(card.serverTime, DateTime.utc(2026, 11, 17, 10));
      expect(card.state, NegotiationState.sellerReviewing);
    });

    test('needs the seller\'s answer only while the seller is reviewing', () {
      final reviewing = receivedPage([receivedJson()]).items.single;
      final countered = receivedPage([receivedJson(state: 'BUYER_REVIEWING')]).items.single;
      final accepted = receivedPage([receivedJson(state: 'OFFER_ACCEPTED')]).items.single;

      expect(reviewing.needsMyAnswer, isTrue);
      expect(countered.needsMyAnswer, isFalse);
      expect(accepted.needsMyAnswer, isFalse);
    });

    test('has no rating and no time when the server sends none', () {
      final card = receivedPage([receivedJson(expiresAt: null)]).items.single;

      expect(card.counterpartRating, isNull);
      expect(card.counterpartRatingCount, 0);
      expect(card.expiresAt, isNull);
      expect(card.isPastExpiry, isFalse);
    });

    test('is past its expiry once the server time reached it while an answer is awaited', () {
      final late = receivedPage([receivedJson(expiresAt: '2026-11-17T09:59:00Z')]).items.single;
      final closed = receivedPage([
        receivedJson(state: 'OFFER_REJECTED', expiresAt: '2026-11-17T09:59:00Z'),
      ]).items.single;

      expect(late.isPastExpiry, isTrue);
      expect(closed.isPastExpiry, isFalse);
    });

    test('reads a page with its paging and survives missing fields', () {
      final page = OffersPage.received({
        'items': [
          {'negotiationId': 'x', 'state': 'SELLER_REVIEWING'},
        ],
      });

      expect(page.items.single.counterpartName, '');
      expect(page.items.single.listingTitle, '');
      expect(page.items.single.offeredPrice, 0);
      expect(page.page, 0);
      expect(page.hasNext, isFalse);
      expect(receivedPage([], page: 2, hasNext: true).hasNext, isTrue);
    });
  });

  group('a sent offer', () {
    test('is built from the buyer\'s negotiation with the seller as the other person', () {
      final card = sentPage([sentJson()]).items.single;

      expect(card.counterpartName, 'Asha K');
      expect(card.listingTitle, 'Apple Watch');
      expect(card.askingPrice, 14500);
      expect(card.offeredPrice, 12000);
      expect(card.offeredAt, DateTime.utc(2026, 11, 17, 9));
      expect(card.needsMyAnswer, isFalse);
    });

    test('needs the buyer\'s answer when the seller countered', () {
      final card = sentPage([
        sentJson(
          state: 'BUYER_REVIEWING',
          awaiting: 'BUYER',
          offers: [
            offerJson('o1', 'BUYER', 12000, 1, status: 'SUPERSEDED'),
            offerJson('o2', 'SELLER', 13500, 2),
          ],
        ),
      ]).items.single;

      expect(card.needsMyAnswer, isTrue);
      expect(card.offeredPrice, 13500);
    });

    test('shows the agreed price once accepted', () {
      final card = sentPage([
        sentJson(
          state: 'OFFER_ACCEPTED',
          awaiting: 'NONE',
          agreedPrice: 13000,
          priceLockExpiresAt: '2026-11-18T10:00:00Z',
          expiresAt: null,
        ),
      ], filter: OffersFilter.accepted)
          .items
          .single;

      expect(card.offeredPrice, 13000);
      expect(card.priceLockExpiresAt, DateTime.utc(2026, 11, 18, 10));
    });

    test('has no price or time for a negotiation without offers', () {
      final card = sentPage([sentJson(offers: [])]).items.single;

      expect(card.offeredPrice, 0);
      expect(card.offeredAt, isNull);
    });

    test('splits the open negotiations into pending and accepted and keeps all closed ones', () {
      final open = [
        sentJson(id: 'a'),
        sentJson(id: 'b', state: 'OFFER_ACCEPTED', awaiting: 'NONE', expiresAt: null),
      ];
      final closed = [sentJson(id: 'c', state: 'OFFER_REJECTED', awaiting: 'NONE')];

      expect(sentPage(open).items.map((c) => c.negotiationId), ['a']);
      expect(
          sentPage(open, filter: OffersFilter.accepted).items.map((c) => c.negotiationId), ['b']);
      expect(
          sentPage(closed, filter: OffersFilter.closed).items.map((c) => c.negotiationId), ['c']);
    });

    test('puts the soonest expiry first among the pending ones and the ones without a time last',
        () {
      final cards = sentPage([
        sentJson(id: 'late', expiresAt: '2026-11-17T20:00:00Z'),
        sentJson(id: 'none', expiresAt: null),
        sentJson(id: 'soon', expiresAt: '2026-11-17T11:00:00Z'),
        sentJson(id: 'none2', expiresAt: null),
      ]).items;

      expect(cards.map((c) => c.negotiationId), ['soon', 'late', 'none', 'none2']);
    });
  });

  group('the summary', () {
    test('reads the three counts and defaults to zero', () {
      final summary = OffersSummary.fromJson({'pending': 5, 'accepted': 2, 'expiringSoon': 1});

      expect(summary.pending, 5);
      expect(summary.accepted, 2);
      expect(summary.expiringSoon, 1);
      expect(OffersSummary.fromJson(const {}).pending, 0);
      expect(const OffersSummary().expiringSoon, 0);
    });
  });
}
