import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/features/negotiation/domain/negotiation.dart';
import 'package:valuex_mobile/features/negotiation/presentation/negotiation_format.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';
import 'package:valuex_mobile/l10n/app_localizations_en.dart';

import 'negotiation_fixtures.dart';

void main() {
  group('Negotiation.fromJson', () {
    test('reads the buyer view of an offer waiting for the seller', () {
      final value = negotiation();

      expect(value.negotiationId, 'n1');
      expect(value.role, NegotiationRole.buyer);
      expect(value.state, NegotiationState.sellerReviewing);
      expect(value.awaiting, NegotiationRole.seller);
      expect(value.isMyTurn, isFalse);
      expect(value.counterpart.displayName, 'Asha K');
      expect(value.listing.title, 'Apple Watch');
      expect(value.listing.askingPrice, 14500);
      expect(value.listing.available, isTrue);
      expect(value.round, 1);
      expect(value.maxRounds, 5);
      expect(value.offers.single.amount, 12000);
      expect(value.pendingOffer?.offerId, 'o1');
      expect(value.actions.canCancel, isTrue);
      expect(value.actions.canAccept, isFalse);
      expect(value.counterRange, isNull);
      expect(value.threadId, 't1');
      expect(value.serverTime, serverNow);
      expect(value.expiresAt, DateTime.utc(2026, 11, 17, 14, 20));
    });

    test('reads the seller view with its turn and corridor', () {
      final value = sellerTurn();

      expect(value.role, NegotiationRole.seller);
      expect(value.isMyTurn, isTrue);
      expect(value.actions.canAccept, isTrue);
      expect(value.actions.canCancel, isFalse);
      expect(value.counterRange?.min, 12000.01);
    });

    test('says it is my turn when the awaited side is my own', () {
      expect(buyerTurn().isMyTurn, isTrue);
      expect(buyerTurn().counterRange?.min, 12000);
      expect(buyerTurn().counterRange?.max, 13499.99);
      expect(buyerTurn().pendingOffer?.offerId, 'o2');
      expect(buyerTurn().counterpart.displayName, 'Asha K');
    });

    test('has nobody awaited once accepted or closed, and keeps the agreed price and lock', () {
      final value = negotiation(
        state: 'OFFER_ACCEPTED',
        awaiting: 'NONE',
        agreedPrice: 12000,
        priceLockExpiresAt: '2026-11-18T10:00:00Z',
        offers: [offerJson('o1', 'BUYER', 12000, 1, status: 'ACCEPTED')],
      );

      expect(value.awaiting, isNull);
      expect(value.state, NegotiationState.offerAccepted);
      expect(value.agreedPrice, 12000);
      expect(value.priceLockExpiresAt, DateTime.utc(2026, 11, 18, 10));
      expect(value.pendingOffer, isNull);
    });

    test('maps every stored state and treats an unknown one as other', () {
      expect(NegotiationState.from('SELLER_REVIEWING'), NegotiationState.sellerReviewing);
      expect(NegotiationState.from('BUYER_REVIEWING'), NegotiationState.buyerReviewing);
      expect(NegotiationState.from('OFFER_ACCEPTED'), NegotiationState.offerAccepted);
      expect(NegotiationState.from('OFFER_REJECTED'), NegotiationState.offerRejected);
      expect(NegotiationState.from('NEGOTIATION_EXPIRED'), NegotiationState.expired);
      expect(NegotiationState.from('NEGOTIATION_CANCELLED'), NegotiationState.cancelled);
      expect(NegotiationState.from('NEGOTIATION_CONVERTED'), NegotiationState.converted);
      expect(NegotiationState.from('SOMETHING_NEW'), NegotiationState.other);
      expect(NegotiationState.from(null), NegotiationState.other);
      expect(NegotiationState.sellerReviewing.isAwaitingAnswer, isTrue);
      expect(NegotiationState.offerAccepted.isAwaitingAnswer, isFalse);
    });

    test('survives a response with missing parts', () {
      final value = Negotiation.fromJson({'negotiationId': 'n9'});

      expect(value.role, NegotiationRole.buyer);
      expect(value.state, NegotiationState.other);
      expect(value.offers, isEmpty);
      expect(value.actions.canAccept, isFalse);
      expect(value.listing.title, '');
      expect(value.buyer.displayName, '');
      expect(value.counterRange, isNull);
      expect(value.round, 0);
    });

    test('flips a role and reads a counter range only when both ends are numbers', () {
      expect(NegotiationRole.buyer.other, NegotiationRole.seller);
      expect(NegotiationRole.seller.other, NegotiationRole.buyer);
      expect(CounterRange.fromJson({'min': 1, 'max': 2})?.max, 2);
      expect(CounterRange.fromJson({'min': 1}), isNull);
      expect(CounterRange.fromJson('x'), isNull);
    });
  });

  group('parseOfferAmount and paise', () {
    test('accepts whole rupees and up to two decimals', () {
      expect(parseOfferAmount('850'), '850');
      expect(parseOfferAmount(' 850.5 '), '850.50');
      expect(parseOfferAmount('850.55'), '850.55');
      expect(parseOfferAmount('0.01'), '0.01');
    });

    test('refuses zero, text, too many decimals and signs', () {
      for (final bad in ['', '0', '0.00', 'abc', '8.555', '-5', '1e3', '12.', '.5', '1,000']) {
        expect(parseOfferAmount(bad), isNull, reason: bad);
      }
    });

    test('compares amounts in whole paise', () {
      expect(paise(14500), 1450000);
      expect(paise(13499.99), 1349999);
      expect(paise(0.1 + 0.2), 30);
    });
  });

  group('durationLabel and negotiationStatusText', () {
    final l10n = AppLocalizationsEn();

    test('shows hours and minutes, minutes, or under a minute', () {
      expect(durationLabel(l10n, const Duration(hours: 4, minutes: 20)), '4h 20m');
      expect(durationLabel(l10n, const Duration(minutes: 35)), '35m');
      expect(durationLabel(l10n, const Duration(seconds: 59)), 'under a minute');
      expect(durationLabel(l10n, Duration.zero), 'under a minute');
    });

    test('says whose answer is awaited from each side', () {
      expect(negotiationStatusText(l10n, negotiation()), 'Waiting for the seller');
      expect(negotiationStatusText(l10n, sellerTurn()), 'Buyer offered ₹12,000');
      expect(
        negotiationStatusText(
          l10n,
          negotiation(role: 'SELLER', awaiting: 'BUYER', state: 'BUYER_REVIEWING'),
        ),
        'Waiting for the buyer',
      );
      expect(negotiationStatusText(l10n, buyerTurn()), 'Seller countered ₹13,500');
      expect(
        negotiationStatusText(
          l10n,
          negotiation(
              role: 'SELLER', awaiting: 'SELLER', offers: [offerJson('o1', 'BUYER', 12000, 1)]),
        ),
        'Buyer offered ₹12,000',
      );
    });

    test('says what ended a negotiation and when the item is gone', () {
      expect(
        negotiationStatusText(
          l10n,
          negotiation(state: 'OFFER_ACCEPTED', awaiting: 'NONE', agreedPrice: 12000),
        ),
        'Accepted at ₹12,000',
      );
      expect(negotiationStatusText(l10n, negotiation(state: 'OFFER_REJECTED', awaiting: 'NONE')),
          'Declined');
      expect(
          negotiationStatusText(l10n, negotiation(state: 'NEGOTIATION_EXPIRED', awaiting: 'NONE')),
          'Expired');
      expect(
          negotiationStatusText(
              l10n, negotiation(state: 'NEGOTIATION_CANCELLED', awaiting: 'NONE')),
          'Cancelled');
      expect(
          negotiationStatusText(
              l10n, negotiation(state: 'NEGOTIATION_CONVERTED', awaiting: 'NONE')),
          'Order placed');
      expect(negotiationStatusText(l10n, negotiation(state: 'WHAT', awaiting: 'NONE')), '');
      expect(
        negotiationStatusText(l10n, negotiation(available: false)),
        'This item is no longer available',
      );
    });

    test('speaks the seller view of a buyer offer in plain words', () {
      final seller = Negotiation.fromJson({
        ...negotiationJson(role: 'SELLER'),
        'awaiting': 'SELLER',
      });
      // The seller's turn: the buyer's offer is awaiting an answer from the seller.
      expect(seller.isMyTurn, isTrue);
      expect(negotiationStatusText(l10n, seller), 'Buyer offered ₹12,000');
    });

    test('has Hindi text for the same lines', () async {
      final hindi = await AppLocalizations.delegate.load(const Locale('hi'));

      expect(negotiationStatusText(hindi, negotiation()), isNotEmpty);
      expect(negotiationStatusText(hindi, negotiation()), isNot('Waiting for the seller'));
    });
  });
}
