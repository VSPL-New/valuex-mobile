import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/realtime/realtime_providers.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/features/buy_now/data/buy_now_repository.dart';
import 'package:valuex_mobile/features/buy_now/domain/buy_now_reservation.dart';
import 'package:valuex_mobile/features/listing_view/data/listing_view_repository.dart';
import 'package:valuex_mobile/features/listing_view/domain/public_listing.dart';
import 'package:valuex_mobile/features/listing_view/presentation/listing_view_screen.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../core/realtime/realtime_fakes.dart';
import '../../helpers/fonts.dart';
import '../buy_now/buy_now_test.dart' show MockBuyNowRepository, reservationJson;

class _MockListingViewRepository extends Mock implements ListingViewRepository {}

PublicListing _listing({bool buyNowAvailable = true, num? price = 14500}) =>
    PublicListing.fromJson({
      'listingId': 'l1',
      'title': 'Apple Watch',
      'description': 'Lightly used',
      'price': price,
      'negotiable': true,
      'seller': {'sellerId': 's1', 'displayName': 'Asha K'},
      'capabilities': {
        'chat': {'available': true},
        'call': {'available': false, 'reason': 'COMING_SOON'},
        'video': {'available': false, 'reason': 'COMING_SOON'},
        'offer': {'available': false, 'reason': 'COMING_SOON'},
        'cart': {'available': false, 'reason': 'COMING_SOON'},
        'buyNow': {
          'available': buyNowAvailable,
          'reason': buyNowAvailable ? null : 'DISABLED_BY_SELLER',
        },
      },
      'contact': {'threadId': null, 'negotiationId': null},
    });

ApiError _error(String code, {int status = 409}) => ApiError(
      type: ApiErrorType.business,
      message: 'server words',
      code: code,
      statusCode: status,
    );

void main() {
  setUpAll(loadBrandFonts);

  late _MockListingViewRepository listings;
  late MockBuyNowRepository buyNow;

  setUp(() {
    listings = _MockListingViewRepository();
    buyNow = MockBuyNowRepository();
  });

  Future<void> open(WidgetTester tester, PublicListing listing) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    when(() => listings.view('l1')).thenAnswer((_) async => listing);
    final router = GoRouter(
      initialLocation: '/listing/l1',
      routes: [
        GoRoute(
          path: RouteNames.listingViewPattern,
          builder: (context, state) =>
              ListingViewScreen(listingId: state.pathParameters['listingId']!),
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        listingViewRepositoryProvider.overrideWithValue(listings),
        buyNowRepositoryProvider.overrideWithValue(buyNow),
        realtimeClientProvider.overrideWithValue(FakeRealtimeClient()),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
  }

  When<Future<BuyNowReservation>> whenStarted() => when(() => buyNow.start(
        'l1',
        expectedPrice: any(named: 'expectedPrice'),
        clientRequestId: any(named: 'clientRequestId'),
      ));

  testWidgets(
      'tapping Buy Now sends the price the buyer saw, says it is reserved and reads the '
      'page again', (tester) async {
    whenStarted().thenAnswer((_) async => BuyNowReservation.fromJson(reservationJson()));
    await open(tester, _listing());

    await tester.tap(find.text('Buy Now'));
    await tester.pumpAndSettle();

    final sent = verify(() => buyNow.start(
          'l1',
          expectedPrice: captureAny(named: 'expectedPrice'),
          clientRequestId: captureAny(named: 'clientRequestId'),
        )).captured;
    expect(sent.first, '14500');
    expect(sent.last, isNotEmpty);
    expect(find.text('Reserved for you. Checkout is coming soon'), findsOneWidget);
    verify(() => listings.view('l1')).called(2);
  });

  testWidgets('a changed price is told and the page is read again to show the new price',
      (tester) async {
    whenStarted().thenAnswer((_) async => throw _error('ERROR_PRICE_CHANGED'));
    await open(tester, _listing());

    await tester.tap(find.text('Buy Now'));
    await tester.pumpAndSettle();

    expect(find.text('Price has changed. Please review'), findsOneWidget);
    verify(() => listings.view('l1')).called(2);
  });

  testWidgets('a sold item is told and the page is read again', (tester) async {
    whenStarted().thenAnswer((_) async => throw _error('ERROR_ITEM_SOLD'));
    await open(tester, _listing());

    await tester.tap(find.text('Buy Now'));
    await tester.pumpAndSettle();

    expect(find.text('This item is no longer available'), findsOneWidget);
    verify(() => listings.view('l1')).called(2);
  });

  testWidgets('a refusal that does not change what the buyer saw leaves the page alone',
      (tester) async {
    whenStarted().thenAnswer((_) async => throw _error('RATE_LIMIT_EXCEEDED', status: 429));
    await open(tester, _listing());

    await tester.tap(find.text('Buy Now'));
    await tester.pumpAndSettle();

    expect(find.text('Too many Buy Now attempts. Try again later'), findsOneWidget);
    verify(() => listings.view('l1')).called(1);
  });

  testWidgets('a double tap reaches the server once', (tester) async {
    final pending = Completer<BuyNowReservation>();
    whenStarted().thenAnswer((_) => pending.future);
    await open(tester, _listing());

    await tester.tap(find.text('Buy Now'));
    await tester.pump();
    await tester.tap(find.text('Buy Now'), warnIfMissed: false);
    await tester.pump();
    pending.complete(BuyNowReservation.fromJson(reservationJson()));
    await tester.pumpAndSettle();

    verify(() => buyNow.start(
          'l1',
          expectedPrice: any(named: 'expectedPrice'),
          clientRequestId: any(named: 'clientRequestId'),
        )).called(1);
  });

  testWidgets('without a price nothing is sent', (tester) async {
    await open(tester, _listing(price: null));

    await tester.tap(find.text('Buy Now'));
    await tester.pumpAndSettle();

    verifyNever(() => buyNow.start(
          any(),
          expectedPrice: any(named: 'expectedPrice'),
          clientRequestId: any(named: 'clientRequestId'),
        ));
  });

  testWidgets('a Buy Now the seller switched off cannot be tapped', (tester) async {
    await open(tester, _listing(buyNowAvailable: false));

    await tester.tap(find.text('Buy Now'), warnIfMissed: false);
    await tester.pumpAndSettle();

    verifyNever(() => buyNow.start(
          any(),
          expectedPrice: any(named: 'expectedPrice'),
          clientRequestId: any(named: 'clientRequestId'),
        ));
  });
}
