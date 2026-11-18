import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/realtime/realtime_event.dart';
import 'package:valuex_mobile/features/negotiation/domain/offers.dart';
import 'package:valuex_mobile/features/negotiation/presentation/offers_screen.dart';

import '../../helpers/fonts.dart';
import 'negotiation_fixtures.dart';
import 'offers_fixtures.dart';

void main() {
  late MockNegotiationRepository repo;

  setUpAll(() async {
    registerFallbackValue(OffersFilter.pending);
    await loadBrandFonts();
  });

  setUp(() {
    repo = MockNegotiationRepository();
    when(() => repo.receivedOffers(any(), page: any(named: 'page')))
        .thenAnswer((_) async => receivedPage([]));
    when(() => repo.sentOffers(any(), page: any(named: 'page')))
        .thenAnswer((_) async => sentPage([]));
    when(() => repo.offersSummary()).thenAnswer((_) async => const OffersSummary());
  });

  Future<dynamic> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    double textScale = 1,
    Size size = const Size(390, 844),
    Duration? pollInterval,
  }) async {
    final realtime = await pumpNegotiationApp(
      tester,
      const OffersScreen(),
      repo: repo,
      locale: locale,
      textScale: textScale,
      size: size,
      pollInterval: pollInterval,
    );
    await tester.pumpAndSettle();
    return realtime;
  }

  void received(List<Map<String, dynamic>> items, {OffersFilter filter = OffersFilter.pending}) {
    when(() => repo.receivedOffers(filter, page: any(named: 'page')))
        .thenAnswer((_) async => receivedPage(items));
  }

  testWidgets('lists the received offers with the buyer, rating, item, prices and expiry',
      (tester) async {
    received([
      receivedJson(rating: 4.5, ratingCount: 12),
      receivedJson(id: 'n2', buyer: 'Meera S', title: 'Bicycle', offered: 3000, asking: 5000),
    ]);

    await pump(tester);

    expect(find.text('Ravi K'), findsOneWidget);
    expect(find.text('4.5 ★ (12)'), findsOneWidget);
    expect(find.text('No ratings yet'), findsOneWidget);
    expect(find.text('Apple Watch'), findsOneWidget);
    expect(find.text('Offered ₹12,000 of ₹14,500'), findsOneWidget);
    expect(find.text('Offered ₹3,000 of ₹5,000'), findsOneWidget);
    expect(find.text('Expires in 4h 20m'), findsNWidgets(2));
    expect(find.text('Needs your answer'), findsNWidgets(2));
    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets('keeps the order the server gives, soonest expiry first', (tester) async {
    received([
      receivedJson(id: 'soon', buyer: 'First', expiresAt: '2026-11-17T11:00:00Z'),
      receivedJson(id: 'late', buyer: 'Second', expiresAt: '2026-11-17T20:00:00Z'),
    ]);

    await pump(tester);

    expect(tester.getTopLeft(find.text('First')).dy,
        lessThan(tester.getTopLeft(find.text('Second')).dy));
  });

  testWidgets('shows an offer past its time as expired', (tester) async {
    received([receivedJson(expiresAt: '2026-11-17T09:00:00Z')]);

    await pump(tester);

    expect(find.text('Expired'), findsWidgets);
    expect(find.text('Needs your answer'), findsNothing);
  });

  testWidgets('says the buyer is to answer after a counter offer', (tester) async {
    received([receivedJson(state: 'BUYER_REVIEWING')]);

    await pump(tester);

    expect(find.text('Waiting for the buyer'), findsOneWidget);
  });

  testWidgets('shows the counts on the chips and the offers about to expire', (tester) async {
    when(() => repo.offersSummary()).thenAnswer(
      (_) async => const OffersSummary(pending: 3, accepted: 2, expiringSoon: 1),
    );

    await pump(tester);

    expect(find.text('Pending (3)'), findsOneWidget);
    expect(find.text('Accepted (2)'), findsOneWidget);
    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('1 expiring soon'), findsOneWidget);
  });

  testWidgets('shows an empty state with a hint for each side', (tester) async {
    await pump(tester);
    expect(find.text('No offers here'), findsOneWidget);
    expect(find.text('When buyers make offers on your items, they show up here.'), findsOneWidget);

    await tester.tap(find.text('Sent'));
    await tester.pumpAndSettle();

    expect(find.text('Offers you make on items show up here.'), findsOneWidget);
  });

  testWidgets('switches the list with the chips and keeps the choice on the other tab',
      (tester) async {
    received([receivedJson()]);
    received([
      receivedJson(
          id: 'a1', state: 'OFFER_ACCEPTED', buyer: 'Asif', lockEndsAt: '2026-11-18T10:00:00Z')
    ], filter: OffersFilter.accepted);
    await pump(tester);

    await tester.tap(find.text('Accepted'));
    await tester.pumpAndSettle();

    expect(find.text('Asif'), findsOneWidget);
    expect(find.text('Price locked, 24h 0m left'), findsOneWidget);
    expect(find.text('Accepted at ₹12,000'), findsOneWidget);
    expect(find.text('Ravi K'), findsNothing);
    await tester.tap(find.text('Sent'));
    await tester.pumpAndSettle();
    verify(() => repo.sentOffers(OffersFilter.accepted, page: 0)).called(1);
  });

  testWidgets('shows the offers the person sent, with the seller as the other person',
      (tester) async {
    when(() => repo.sentOffers(OffersFilter.pending, page: any(named: 'page')))
        .thenAnswer((_) async => sentPage([sentJson()]));
    await pump(tester);

    await tester.tap(find.text('Sent'));
    await tester.pumpAndSettle();

    expect(find.text('Asha K'), findsOneWidget);
    expect(find.text('Waiting for the seller'), findsOneWidget);
    expect(find.text('No ratings yet'), findsNothing);
  });

  testWidgets('shows a failure with Retry and then the offers', (tester) async {
    when(() => repo.receivedOffers(any(), page: any(named: 'page')))
        .thenThrow(const ApiError(type: ApiErrorType.network, message: 'offline'));
    await pump(tester);

    expect(find.text('Could not load offers. Pull down to try again.'), findsOneWidget);

    received([receivedJson()]);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Ravi K'), findsOneWidget);
  });

  testWidgets('loads more offers on request and says when that fails', (tester) async {
    when(() => repo.receivedOffers(OffersFilter.pending, page: 0))
        .thenAnswer((_) async => receivedPage([receivedJson()], hasNext: true));
    when(() => repo.receivedOffers(OffersFilter.pending, page: 1))
        .thenThrow(const ApiError(type: ApiErrorType.network, message: 'offline'));
    await pump(tester);

    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load more offers'), findsOneWidget);

    when(() => repo.receivedOffers(OffersFilter.pending, page: 1))
        .thenAnswer((_) async => receivedPage([receivedJson(id: 'n2', buyer: 'Meera S')], page: 1));
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    expect(find.text('Meera S'), findsOneWidget);
    expect(find.text('Load more'), findsNothing);
  });

  testWidgets('opens the negotiation of a card and reads the list again when coming back',
      (tester) async {
    received([receivedJson()]);
    await pump(tester);

    await tester.tap(find.text('Ravi K'));
    await tester.pumpAndSettle();
    expect(find.text('negotiation n1'), findsOneWidget);

    received([receivedJson(buyer: 'Changed')]);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.text('Changed'), findsOneWidget);
  });

  testWidgets('reads the list again when the server says a negotiation changed', (tester) async {
    received([receivedJson()]);
    final realtime = await pump(tester);
    received([receivedJson(), receivedJson(id: 'n2', buyer: 'Meera S')]);

    realtime.emit(RealtimeTypes.negotiationUpdated, {'negotiationId': 'n2'});
    await tester.pumpAndSettle();

    expect(find.text('Meera S'), findsOneWidget);
  });

  testWidgets('pulls to refresh', (tester) async {
    received([receivedJson()]);
    await pump(tester);
    received([receivedJson(buyer: 'Refreshed')]);

    await tester.fling(find.text('Ravi K'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Refreshed'), findsOneWidget);
  });

  testWidgets('tells the person when a pull to refresh fails', (tester) async {
    received([receivedJson()]);
    await pump(tester);
    when(() => repo.receivedOffers(any(), page: any(named: 'page')))
        .thenThrow(const ApiError(type: ApiErrorType.network, message: 'offline'));

    await tester.fling(find.text('Ravi K'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Could not load offers. Pull down to try again.'), findsOneWidget);
    expect(find.text('Ravi K'), findsOneWidget);
  });

  testWidgets('polls while the live connection is down', (tester) async {
    received([receivedJson()]);
    await pump(tester, pollInterval: const Duration(seconds: 15));
    received([receivedJson(buyer: 'Polled')]);

    await tester.pump(const Duration(seconds: 16));
    await tester.pumpAndSettle();

    expect(find.text('Polled'), findsOneWidget);
  });

  testWidgets('works in Hindi at large text on a narrow screen', (tester) async {
    received([receivedJson(rating: 4.2, ratingCount: 3)]);

    await pump(tester, locale: const Locale('hi'), textScale: 2, size: const Size(320, 640));

    expect(find.text('ऑफ़र'), findsWidgets);
    expect(find.text('प्राप्त'), findsOneWidget);
    expect(find.textContaining('4.2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('speaks a card as one sentence', (tester) async {
    final semantics = tester.ensureSemantics();
    received([receivedJson()]);

    await pump(tester);

    expect(
      find.bySemanticsLabel(RegExp(r'Ravi K, Apple Watch\. Offered ₹12,000 of ₹14,500')),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
