import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/realtime/realtime_providers.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/features/cart/data/cart_repository.dart';
import 'package:valuex_mobile/features/listing_view/data/listing_view_repository.dart';
import 'package:valuex_mobile/features/listing_view/domain/public_listing.dart';
import 'package:valuex_mobile/features/listing_view/presentation/listing_view_screen.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../core/realtime/realtime_fakes.dart';
import '../../helpers/fonts.dart';
import '../cart/cart_fixtures.dart';

class _MockListingViewRepository extends Mock implements ListingViewRepository {}

PublicListing _listing({required Map<String, dynamic> cart}) => PublicListing.fromJson({
      'listingId': 'l1',
      'title': 'Apple Watch',
      'description': 'Lightly used',
      'price': 14500,
      'negotiable': true,
      'seller': {'sellerId': 's1', 'displayName': 'Asha K'},
      'capabilities': {
        'chat': {'available': true},
        'call': {'available': false, 'reason': 'COMING_SOON'},
        'video': {'available': false, 'reason': 'COMING_SOON'},
        'offer': {'available': true},
        'cart': cart,
        'buyNow': {'available': true},
      },
      'contact': {'threadId': null, 'negotiationId': null},
    });

const _ready = {'available': true};
const _needsOffer = {'available': false, 'reason': 'NEGOTIATION_REQUIRED'};

ApiError _refusal(String code) => ApiError(
      type: ApiErrorType.business,
      message: 'server words',
      code: code,
      statusCode: 409,
    );

void main() {
  setUpAll(loadBrandFonts);

  late _MockListingViewRepository listings;
  late MockCartRepository cart;

  setUp(() {
    listings = _MockListingViewRepository();
    cart = MockCartRepository();
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
        GoRoute(
          path: RouteNames.cart,
          builder: (context, state) => const Scaffold(body: Text('cart screen')),
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        listingViewRepositoryProvider.overrideWithValue(listings),
        cartRepositoryProvider.overrideWithValue(cart),
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

  testWidgets('Add to Cart adds the listing, says so and View cart opens the cart', (tester) async {
    when(() => cart.add('l1')).thenAnswer((_) async => addedLine());
    await open(tester, _listing(cart: _ready));

    await tester.tap(find.text('Add to Cart'));
    await tester.pumpAndSettle();

    verify(() => cart.add('l1')).called(1);
    expect(find.text('Added to your cart'), findsOneWidget);
    await tester.tap(find.text('View cart'));
    await tester.pumpAndSettle();
    expect(find.text('cart screen'), findsOneWidget);
  });

  testWidgets('a refusal says why and reads the page again when what the buyer saw is stale',
      (tester) async {
    when(() => cart.add('l1')).thenThrow(_refusal('ERROR_PRICE_NOT_ACCEPTED'));
    await open(tester, _listing(cart: _ready));

    await tester.tap(find.text('Add to Cart'));
    await tester.pumpAndSettle();

    expect(find.textContaining("hasn't been accepted yet"), findsOneWidget);
    verify(() => listings.view('l1')).called(2);
  });

  testWidgets('a full cart says so and leaves the page as it is', (tester) async {
    when(() => cart.add('l1')).thenThrow(_refusal('ERROR_MAX_CART_ITEMS'));
    await open(tester, _listing(cart: _ready));

    await tester.tap(find.text('Add to Cart'));
    await tester.pumpAndSettle();

    expect(find.text('Cart limit reached. Remove an item to add another'), findsOneWidget);
    verify(() => listings.view('l1')).called(1);
  });

  testWidgets('before a price is accepted the button explains and sends nothing', (tester) async {
    await open(tester, _listing(cart: _needsOffer));

    await tester.tap(find.text('Add to Cart'));
    await tester.pumpAndSettle();

    expect(find.text('Make an offer or Buy Now first'), findsOneWidget);
    verifyNever(() => cart.add(any()));
  });
}
