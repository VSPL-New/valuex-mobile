import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/realtime/realtime_event.dart';
import 'package:valuex_mobile/features/cart/data/cart_repository.dart';
import 'package:valuex_mobile/features/negotiation/domain/negotiation.dart';
import 'package:valuex_mobile/features/negotiation/presentation/negotiation_screen.dart';

import '../../helpers/fonts.dart';
import '../cart/cart_fixtures.dart';
import 'negotiation_fixtures.dart';

ApiError _refusal(String code) =>
    ApiError(type: ApiErrorType.business, message: 'x', code: code, statusCode: 409);

void main() {
  late MockNegotiationRepository repo;

  setUpAll(loadBrandFonts);

  setUp(() {
    repo = MockNegotiationRepository();
  });

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    double textScale = 1,
    Size size = const Size(390, 844),
    MockCartRepository? cart,
  }) async {
    await pumpNegotiationApp(
      tester,
      const NegotiationScreen(negotiationId: 'n1'),
      repo: repo,
      locale: locale,
      textScale: textScale,
      size: size,
      overrides: [if (cart != null) cartRepositoryProvider.overrideWithValue(cart)],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows a buyer waiting for the seller with the countdown, round and timeline',
      (tester) async {
    when(() => repo.get('n1')).thenAnswer((_) async => negotiation());

    await pump(tester);

    expect(find.text('Waiting for the seller'), findsOneWidget);
    expect(find.text('Round 1 of 5'), findsOneWidget);
    expect(find.text('Expires in 4h 20m'), findsOneWidget);
    expect(find.text('Apple Watch'), findsOneWidget);
    expect(find.text('Asking price: ₹14,500'), findsOneWidget);
    expect(find.text('Asha K'), findsOneWidget);
    expect(find.text('You · round 1'), findsOneWidget);
    expect(find.text('₹12,000'), findsOneWidget);
    expect(find.text('Cancel offer'), findsOneWidget);
    expect(find.textContaining('Accept'), findsNothing);
    expect(find.text('Counter'), findsNothing);
  });

  testWidgets('lets the buyer withdraw after confirming', (tester) async {
    when(() => repo.get('n1')).thenAnswer((_) async => negotiation());
    when(() => repo.cancel('n1')).thenAnswer(
      (_) async => negotiation(state: 'NEGOTIATION_CANCELLED', awaiting: 'NONE', actions: {}),
    );
    await pump(tester);

    await tester.tap(find.text('Cancel offer'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel your offer?'), findsOneWidget);
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();
    verifyNever(() => repo.cancel(any()));

    await tester.tap(find.text('Cancel offer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel offer').last);
    await tester.pumpAndSettle();

    verify(() => repo.cancel('n1')).called(1);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Cancel offer'), findsNothing);
  });

  testWidgets('gives the seller Accept, Counter and Decline on their turn', (tester) async {
    when(() => repo.get('n1')).thenAnswer((_) async => sellerTurn());

    await pump(tester);

    expect(find.text('Buyer offered ₹12,000'), findsOneWidget);
    expect(find.text('Accept ₹12,000'), findsOneWidget);
    expect(find.text('Counter'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.text('Cancel offer'), findsNothing);
    expect(find.text('Ravi'), findsOneWidget);
    expect(find.text('Buyer · round 1'), findsOneWidget);
  });

  testWidgets('accepts at the offered price and shows the locked price', (tester) async {
    when(() => repo.get('n1')).thenAnswer((_) async => sellerTurn());
    when(() => repo.accept('o1')).thenAnswer((_) async => negotiation(
          role: 'SELLER',
          state: 'OFFER_ACCEPTED',
          awaiting: 'NONE',
          agreedPrice: 12000,
          priceLockExpiresAt: '2026-11-18T10:00:00Z',
          expiresAt: null,
          offers: [offerJson('o1', 'BUYER', 12000, 1, status: 'ACCEPTED')],
          actions: {},
        ));
    await pump(tester);

    await tester.tap(find.text('Accept ₹12,000'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    verify(() => repo.accept('o1')).called(1);
    expect(find.text('Accepted at ₹12,000'), findsOneWidget);
    expect(find.text('Price locked at ₹12,000. Ends in 24h 0m'), findsOneWidget);
    expect(find.text('Accept ₹12,000'), findsNothing);
  });

  testWidgets('asks the seller to confirm an accept and does nothing when they keep waiting',
      (tester) async {
    when(() => repo.get('n1')).thenAnswer((_) async => sellerTurn());
    await pump(tester);

    await tester.tap(find.text('Accept ₹12,000'));
    await tester.pumpAndSettle();

    expect(find.text('Accept this offer?'), findsOneWidget);
    expect(
      find.text(
          'The price is locked for the buyer and the other offers on this item will be declined.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();

    verifyNever(() => repo.accept(any()));
  });

  testWidgets('tells a property seller that the other offers stay open', (tester) async {
    when(() => repo.get('n1')).thenAnswer((_) async => negotiation(
          role: 'SELLER',
          realEstate: true,
          actions: {'canAccept': true, 'canReject': true, 'canCounter': true, 'canCancel': false},
          counterRange: {'min': 12000.01, 'max': 14500},
        ));
    await pump(tester);

    await tester.tap(find.text('Accept ₹12,000'));
    await tester.pumpAndSettle();

    expect(
      find.text('You agree on this price with the buyer. Other offers on this property stay open.'),
      findsOneWidget,
    );
  });

  testWidgets('lets the buyer accept a counter offer without a confirmation', (tester) async {
    when(() => repo.get('n1')).thenAnswer((_) async => buyerTurn());
    when(() => repo.accept('o2')).thenAnswer((_) async => negotiation(
          state: 'OFFER_ACCEPTED',
          awaiting: 'NONE',
          agreedPrice: 13500,
          priceLockExpiresAt: '2026-11-18T10:00:00Z',
          expiresAt: null,
          actions: {},
        ));
    await pump(tester);

    await tester.tap(find.text('Accept ₹13,500'));
    await tester.pumpAndSettle();

    verify(() => repo.accept('o2')).called(1);
    expect(find.text('Accept this offer?'), findsNothing);
  });

  testWidgets('tells the seller the buyer can check out once the price is accepted for goods',
      (tester) async {
    when(() => repo.get('n1')).thenAnswer((_) async => negotiation(
          role: 'SELLER',
          state: 'OFFER_ACCEPTED',
          awaiting: 'NONE',
          agreedPrice: 12000,
          priceLockExpiresAt: '2026-11-18T10:00:00Z',
          expiresAt: null,
          actions: {},
        ));

    await pump(tester);

    expect(find.text('The buyer has been told and can now go to checkout.'), findsOneWidget);
  });

  testWidgets('does not say the buyer can check out to the buyer or for a property',
      (tester) async {
    when(() => repo.get('n1')).thenAnswer((_) async => negotiation(
          state: 'OFFER_ACCEPTED',
          awaiting: 'NONE',
          agreedPrice: 12000,
          priceLockExpiresAt: '2026-11-18T10:00:00Z',
          expiresAt: null,
          actions: {},
        ));

    await pump(tester);

    expect(find.text('The buyer has been told and can now go to checkout.'), findsNothing);
  });

  group('Add to cart from the accepted price (US-019)', () {
    Negotiation accepted({String role = 'BUYER', bool realEstate = false}) => negotiation(
          role: role,
          realEstate: realEstate,
          state: 'OFFER_ACCEPTED',
          awaiting: 'NONE',
          agreedPrice: 12000,
          priceLockExpiresAt: '2026-11-18T10:00:00Z',
          expiresAt: null,
          actions: {},
        );

    testWidgets('the buyer adds the item to the cart and is told so', (tester) async {
      final cart = MockCartRepository();
      when(() => repo.get('n1')).thenAnswer((_) async => accepted());
      when(() => cart.add('l1')).thenAnswer((_) async => addedLine());
      await pump(tester, cart: cart);

      await tester.tap(find.text('Add to cart'));
      await tester.pumpAndSettle();

      verify(() => cart.add('l1')).called(1);
      expect(find.text('Added to your cart'), findsOneWidget);
    });

    testWidgets('a refusal is shown and nothing else changes', (tester) async {
      final cart = MockCartRepository();
      when(() => repo.get('n1')).thenAnswer((_) async => accepted());
      when(() => cart.add('l1')).thenThrow(_refusal('ERROR_MAX_CART_ITEMS'));
      await pump(tester, cart: cart);

      await tester.tap(find.text('Add to cart'));
      await tester.pumpAndSettle();

      expect(find.text('Cart limit reached. Remove an item to add another'), findsOneWidget);
      expect(find.text('Add to cart'), findsOneWidget);
    });

    testWidgets('the seller, a property and an open negotiation have no such button',
        (tester) async {
      when(() => repo.get('n1')).thenAnswer((_) async => accepted(role: 'SELLER'));
      await pump(tester);
      expect(find.text('Add to cart'), findsNothing);

      when(() => repo.get('n1')).thenAnswer((_) async => accepted(realEstate: true));
      await pump(tester);
      expect(find.text('Add to cart'), findsNothing);

      when(() => repo.get('n1')).thenAnswer((_) async => negotiation());
      await pump(tester);
      expect(find.text('Add to cart'), findsNothing);
    });
  });
  testWidgets('says only Accept and Decline remain at the last round', (tester) async {
    when(() => repo.get('n1')).thenAnswer((_) async => negotiation(
          role: 'SELLER',
          round: 5,
          offers: [offerJson('o5', 'BUYER', 13000, 5)],
          actions: {'canAccept': true, 'canReject': true, 'canCounter': false, 'canCancel': false},
        ));

    await pump(tester);

    expect(find.text('This is the last round. You can only accept or decline.'), findsOneWidget);
    expect(find.text('Counter'), findsNothing);
    expect(find.text('Accept ₹13,000'), findsOneWidget);
  });

  testWidgets('does not show the last round note while counters are still possible',
      (tester) async {
    when(() => repo.get('n1')).thenAnswer((_) async => sellerTurn());

    await pump(tester);

    expect(find.text('This is the last round. You can only accept or decline.'), findsNothing);
  });

  testWidgets('shows the seller wording when an offer expired while they were reading it',
      (tester) async {
    var reads = 0;
    when(() => repo.get('n1')).thenAnswer((_) async {
      reads++;
      return reads == 1
          ? sellerTurn()
          : negotiation(
              role: 'SELLER',
              state: 'NEGOTIATION_EXPIRED',
              awaiting: 'NONE',
              actions: {},
              expiresAt: null);
    });
    when(() => repo.accept('o1')).thenThrow(_refusal('ERROR_OFFER_EXPIRED'));
    await pump(tester);

    await tester.tap(find.text('Accept ₹12,000'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(find.text('This offer has expired'), findsOneWidget);
    expect(find.text('Expired'), findsWidgets);
  });

  testWidgets('declines only after confirming, and the negotiation then shows as declined',
      (tester) async {
    when(() => repo.get('n1')).thenAnswer((_) async => sellerTurn());
    when(() => repo.reject('o1')).thenAnswer((_) async => negotiation(
          role: 'SELLER',
          state: 'OFFER_REJECTED',
          awaiting: 'NONE',
          actions: {},
          expiresAt: null,
        ));
    await pump(tester);

    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    expect(find.text('Decline this offer?'), findsOneWidget);
    await tester.tap(find.text('Decline').last);
    await tester.pumpAndSettle();

    verify(() => repo.reject('o1')).called(1);
    expect(find.text('Declined'), findsOneWidget);
  });

  testWidgets('counters with an amount from the sheet', (tester) async {
    when(() => repo.get('n1')).thenAnswer((_) async => sellerTurn());
    when(() => repo.counter('o1', amount: '13000', clientRequestId: any(named: 'clientRequestId')))
        .thenAnswer((_) async => negotiation(
              role: 'SELLER',
              state: 'BUYER_REVIEWING',
              awaiting: 'BUYER',
              round: 2,
              actions: {},
              offers: [
                offerJson('o1', 'BUYER', 12000, 1, status: 'SUPERSEDED'),
                offerJson('o2', 'SELLER', 13000, 2),
              ],
            ));
    await pump(tester);

    await tester.tap(find.text('Counter'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '13000');
    await tester.tap(find.text('Send counter offer'));
    await tester.pumpAndSettle();

    expect(find.text('Waiting for the buyer'), findsOneWidget);
    expect(find.text('Round 2 of 5'), findsOneWidget);
    expect(find.text('₹13,000'), findsOneWidget);
  });

  testWidgets('lets the buyer answer a seller counter', (tester) async {
    when(() => repo.get('n1')).thenAnswer((_) async => buyerTurn());

    await pump(tester);

    expect(find.text('Seller countered ₹13,500'), findsOneWidget);
    expect(find.text('Accept ₹13,500'), findsOneWidget);
    expect(find.text('Counter'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.text('Cancel offer'), findsOneWidget);
    expect(find.text('Seller · round 2'), findsOneWidget);
  });

  testWidgets('shows a refusal in words and the latest state after a stale answer', (tester) async {
    var reads = 0;
    when(() => repo.get('n1')).thenAnswer((_) async {
      reads++;
      return reads == 1
          ? sellerTurn()
          : negotiation(
              role: 'SELLER',
              state: 'OFFER_REJECTED',
              awaiting: 'NONE',
              actions: {},
              expiresAt: null);
    });
    when(() => repo.accept('o1')).thenThrow(_refusal('ERROR_OFFER_NOT_CURRENT'));
    await pump(tester);

    await tester.tap(find.text('Accept ₹12,000'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(find.text('This offer has changed. The latest is shown'), findsOneWidget);
    expect(find.text('Declined'), findsOneWidget);
  });

  testWidgets('shows the range in words when a counter is refused', (tester) async {
    when(() => repo.get('n1')).thenAnswer((_) async => sellerTurn());
    when(() => repo.counter('o1',
        amount: any(named: 'amount'),
        clientRequestId: any(named: 'clientRequestId'))).thenThrow(const ApiError(
      type: ApiErrorType.validation,
      message: 'x',
      code: 'ERROR_INVALID_COUNTER',
      statusCode: 422,
      details: {'min': '12000.01', 'max': '14500.00'},
    ));
    await pump(tester);

    await tester.tap(find.text('Counter'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '13000');
    await tester.tap(find.text('Send counter offer'));
    await tester.pumpAndSettle();

    expect(find.text('Counter offer must be between ₹12,000.01 and ₹14,500'), findsOneWidget);
  });

  testWidgets('shows the agreed price of a property without a lock', (tester) async {
    when(() => repo.get('n1')).thenAnswer((_) async => negotiation(
          state: 'OFFER_ACCEPTED',
          awaiting: 'NONE',
          agreedPrice: 12000,
          expiresAt: null,
          realEstate: true,
          offers: [offerJson('o1', 'BUYER', 12000, 1, status: 'ACCEPTED')],
        ));

    await pump(tester);

    expect(find.text('Price agreed: ₹12,000. The owner will close the deal.'), findsOneWidget);
    expect(find.textContaining('Ends in'), findsNothing);
  });

  testWidgets('says the item is gone and offers no answer when the listing is unavailable',
      (tester) async {
    when(() => repo.get('n1')).thenAnswer((_) async => negotiation(
          role: 'SELLER',
          available: false,
          actions: {
            'canAccept': false,
            'canReject': false,
            'canCounter': false,
            'canCancel': false
          },
        ));

    await pump(tester);

    expect(find.text('This item is no longer available'), findsOneWidget);
    expect(find.textContaining('Accept'), findsNothing);
  });

  testWidgets('shows an error with a Retry when the negotiation cannot be loaded', (tester) async {
    var fail = true;
    when(() => repo.get('n1')).thenAnswer((_) async {
      if (fail) throw _refusal('ERROR_NEGOTIATION_NOT_FOUND');
      return negotiation();
    });
    await pump(tester);

    expect(find.text('Retry'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Waiting for the seller'), findsOneWidget);
  });

  testWidgets('opens the listing and the chat from the screen', (tester) async {
    when(() => repo.get('n1')).thenAnswer((_) async => negotiation());
    await pump(tester);

    await tester.tap(find.text('Apple Watch'));
    await tester.pumpAndSettle();
    expect(find.text('listing l1'), findsOneWidget);
  });

  testWidgets('opens the chat thread from the app bar', (tester) async {
    when(() => repo.get('n1')).thenAnswer((_) async => negotiation());
    await pump(tester);

    await tester.tap(find.byTooltip('Chat with seller'));
    await tester.pumpAndSettle();

    expect(find.text('thread t1'), findsOneWidget);
  });

  testWidgets('hides the chat button when the negotiation has no thread', (tester) async {
    when(() => repo.get('n1')).thenAnswer((_) async => negotiation(threadId: null));

    await pump(tester);

    expect(find.byTooltip('Chat with seller'), findsNothing);
  });

  testWidgets('updates when the server says the negotiation changed', (tester) async {
    var reads = 0;
    when(() => repo.get('n1')).thenAnswer((_) async {
      reads++;
      return reads == 1 ? negotiation() : buyerTurn();
    });
    final realtime = await pumpNegotiationApp(
      tester,
      const NegotiationScreen(negotiationId: 'n1'),
      repo: repo,
    );
    await tester.pumpAndSettle();
    expect(find.text('Waiting for the seller'), findsOneWidget);

    realtime.emit(RealtimeTypes.negotiationUpdated, {'negotiationId': 'n1'});
    await tester.pumpAndSettle();

    expect(find.text('Seller countered ₹13,500'), findsOneWidget);
  });

  testWidgets('counts down from the server clock, not the phone clock', (tester) async {
    when(() => repo.get('n1'))
        .thenAnswer((_) async => negotiation(expiresAt: '2026-11-17T10:00:30Z'));

    await pump(tester);

    expect(find.text('Expires in under a minute'), findsOneWidget);
  });

  testWidgets('shows a deadline that already passed on the server as expired', (tester) async {
    when(() => repo.get('n1'))
        .thenAnswer((_) async => negotiation(expiresAt: '2026-11-17T09:59:00Z'));

    await pump(tester);

    expect(find.text('Expired'), findsOneWidget);
  });

  testWidgets('works in Hindi, at large text and on a narrow screen', (tester) async {
    when(() => repo.get('n1')).thenAnswer((_) async => buyerTurn());

    await pump(tester, locale: const Locale('hi'), textScale: 2, size: const Size(320, 640));

    expect(find.text('Seller countered ₹13,500'), findsNothing);
    expect(find.textContaining('₹13,500'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
