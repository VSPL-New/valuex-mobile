import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/route_guard.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/core/theme/colors.dart';
import 'package:valuex_mobile/core/widgets/square_back_button.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_state.dart';
import 'package:valuex_mobile/features/listing_view/data/listing_view_repository.dart';
import 'package:valuex_mobile/features/listing_view/domain/public_listing.dart';
import 'package:valuex_mobile/features/listing_view/presentation/listing_view_screen.dart';
import 'package:valuex_mobile/features/listing_view/presentation/seller_profile_screen.dart';
import 'package:valuex_mobile/features/listing_view/presentation/widgets/listing_gallery.dart';
import 'package:valuex_mobile/features/search/domain/search_page.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../helpers/fonts.dart';

class _MockRepository extends Mock implements ListingViewRepository {}

const _capabilities = {
  'chat': {'available': false, 'reason': 'COMING_SOON'},
  'call': {'available': false, 'reason': 'COMING_SOON'},
  'video': {'available': false, 'reason': 'COMING_SOON'},
  'cart': {'available': false, 'reason': 'COMING_SOON'},
  'buyNow': {'available': false, 'reason': 'COMING_SOON'},
};

final _realEstateCapabilities = {
  ..._capabilities,
  'cart': {'available': false, 'reason': 'NOT_APPLICABLE'},
  'buyNow': {'available': false, 'reason': 'NOT_APPLICABLE'},
};

Map<String, dynamic> photo(int n, {String? expiresAt}) => {
      'mediaId': 'm$n',
      'sortOrder': n,
      'thumbnailUrl': 'https://media.example/t$n.jpg',
      'detailUrl': 'https://media.example/d$n.jpg',
      'zoomUrl': 'https://media.example/z$n.jpg',
      if (expiresAt != null) 'expiresAt': expiresAt,
    };

Map<String, dynamic> listingJson({
  String publishedAt = '2026-11-09T10:00:00Z',
  String serverTime = '2026-11-12T10:00:00Z',
  Object? condition = const {'code': 'LIKE_NEW', 'label': 'Like New'},
  num? price = 14500,
  String? priceQualifier,
  String? transactionIntent,
  Map<String, dynamic> capabilities = _capabilities,
  List<Map<String, dynamic>>? photos,
  List<Map<String, dynamic>>? attributes,
  bool ownListing = false,
  double? rating,
  String description = 'Lightly used, with the original box.',
  String title = 'Apple Watch',
  String? area,
}) =>
    {
      'listingId': 'l1',
      'title': title,
      'description': description,
      'condition': condition,
      'conditionNotes': 'No scratches',
      'price': price,
      'priceQualifier': priceQualifier,
      'currency': 'INR',
      'negotiable': true,
      'transactionIntent': transactionIntent,
      'category': [
        {'code': 'L1', 'name': 'Electronics', 'level': 1},
        {'code': 'L2', 'name': 'Wearables', 'level': 2},
        {'code': 'L3', 'name': 'Smart watches', 'level': 3},
      ],
      'attributes': attributes ??
          [
            {'key': 'storage', 'label': 'Storage', 'value': '128 GB'},
            {'key': 'battery', 'label': 'Battery health', 'value': 91, 'unit': '%'},
            {'key': 'has_box', 'label': 'Original box', 'value': true},
            {
              'key': 'accessories',
              'label': 'Accessories',
              'value': ['Charger', 'Box']
            },
          ],
      'photos': photos ?? [photo(1), photo(2), photo(3)],
      'seller': {
        'sellerId': 's1',
        'displayName': 'Asha K',
        'rating': rating,
        'ratingCount': rating == null ? 0 : 12,
        'city': 'Bengaluru',
        'area': area,
        'joinedAt': '2025-03-04T00:00:00Z',
        'otherListingsCount': 2,
      },
      'publishedAt': publishedAt,
      'serverTime': serverTime,
      'capabilities': capabilities,
      'saved': false,
      'ownListing': ownListing,
    };

Map<String, dynamic> cardJson(String id, {String title = 'Seller item'}) => {
      'listingId': id,
      'title': title,
      'price': 500,
      'city': 'Bengaluru',
      'condition': 'GOOD',
    };

Map<String, dynamic> pageJson(List<Map<String, dynamic>> items,
        {int page = 0, bool hasNext = false}) =>
    {
      'items': items,
      'page': page,
      'size': 20,
      'totalItems': items.length,
      'hasNext': hasNext,
    };

SearchPage searchPage(List<Map<String, dynamic>> items, {int page = 0, bool hasNext = false}) =>
    SearchPage.fromJson(pageJson(items, page: page, hasNext: hasNext));

ApiError businessError(String code) =>
    ApiError(type: ApiErrorType.business, message: code, code: code, statusCode: 404);

void main() {
  setUpAll(loadBrandFonts);

  late _MockRepository repository;
  late GoRouter router;

  Future<void> open(
    WidgetTester tester, {
    String location = '/listing/l1',
    Locale locale = const Locale('en'),
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(path: '/start', builder: (context, state) => const Text('start')),
        GoRoute(
          path: RouteNames.listingViewPattern,
          builder: (context, state) =>
              ListingViewScreen(listingId: state.pathParameters['listingId']!),
        ),
        GoRoute(
          path: RouteNames.sellerProfilePattern,
          builder: (context, state) =>
              SellerProfileScreen(sellerId: state.pathParameters['sellerId']!),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [listingViewRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump();
    unawaited(router.push(location));
    await tester.pumpAndSettle();
  }

  void stubListing(Map<String, dynamic> json) =>
      when(() => repository.view('l1')).thenAnswer((_) async => PublicListing.fromJson(json));

  setUp(() {
    repository = _MockRepository();
    stubListing(listingJson());
    when(() => repository.sellerListings('s1', page: any(named: 'page')))
        .thenAnswer((_) async => searchPage([cardJson('a'), cardJson('b', title: 'Second')]));
    when(() => repository.sellerReviews('s1'))
        .thenAnswer((_) async => const SellerReviews(available: false, count: 0));
  });

  group('details', () {
    testWidgets('shows the photos, title, condition, price, seller, location and age',
        (tester) async {
      await open(tester);

      expect(find.text('Listing details'), findsOneWidget);
      expect(find.textContaining('Electronics'), findsNothing);
      expect(find.textContaining('Wearables'), findsNothing);
      expect(find.textContaining('Smart watches'), findsNothing);
      expect(find.text('Apple Watch'), findsOneWidget);
      expect(find.text('Like New'), findsOneWidget);
      expect(find.text('₹14,500'), findsOneWidget);
      expect(find.text('Negotiable'), findsOneWidget);
      expect(find.text('Posted 3 days ago'), findsOneWidget);
      expect(find.text('Bengaluru'), findsWidgets);
      expect(find.text('Lightly used, with the original box.'), findsOneWidget);
      expect(find.text('Asha K'), findsOneWidget);
      expect(find.text('No ratings yet'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('View Profile'), findsOneWidget);
      expect(find.text('Joined Mar 2025'), findsNothing);
      expect(find.text('2 other listings'), findsNothing);
      expect(find.text('1 / 3'), findsOneWidget);
      verify(() => repository.view('l1')).called(1);
    });

    testWidgets('shows a heart that starts from the saved flag (US-073)', (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester);
      expect(find.bySemanticsLabel('Save listing'), findsOneWidget);
      expect(find.bySemanticsLabel('Remove from saved'), findsNothing);
      expect(PublicListing.fromJson(listingJson()).saved, isFalse);

      stubListing({...listingJson(), 'saved': true});
      await open(tester);

      expect(find.bySemanticsLabel('Remove from saved'), findsOneWidget);
      expect(PublicListing.fromJson({...listingJson(), 'saved': true}).saved, isTrue);
      handle.dispose();
    });

    testWidgets('shows area and city and groups the content into brand cards', (tester) async {
      stubListing(listingJson(area: 'Whitefield'));
      await open(tester);

      expect(find.text('Whitefield, Bengaluru'), findsOneWidget);
      for (final title in ['DESCRIPTION', 'ITEM DETAILS', 'SELLER']) {
        final container = tester.widget<Container>(
          find.ancestor(of: find.text(title), matching: find.byType(Container)).first,
        );
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.color, AppColors.brandSurface);
        expect(decoration.boxShadow, isNotEmpty);
        expect(decoration.borderRadius, BorderRadius.circular(16));
      }
    });

    testWidgets('lists the schema attributes with units and Yes/No', (tester) async {
      await open(tester);
      await tester.scrollUntilVisible(find.text('Accessories'), 200,
          scrollable: find.byType(Scrollable).first);

      expect(find.text('Storage'), findsOneWidget);
      expect(find.text('128 GB'), findsOneWidget);
      expect(find.text('91 %'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('Charger, Box'), findsOneWidget);
    });

    testWidgets('shows the seller rating when there is one', (tester) async {
      stubListing(listingJson(rating: 4.5));
      await open(tester);

      expect(find.text('4.5'), findsOneWidget);
      expect(find.bySemanticsLabel('Rated 4.5 out of 5, 12 reviews'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.text('No ratings yet'), findsNothing);
    });

    testWidgets('listing age comes from the server clock, not the device', (tester) async {
      stubListing(listingJson(publishedAt: '2026-11-12T08:00:00Z'));
      await open(tester);
      expect(find.text('Posted today'), findsOneWidget);
    });

    testWidgets('a listing posted a day ago says so', (tester) async {
      stubListing(listingJson(publishedAt: '2026-11-11T09:00:00Z'));
      await open(tester);
      expect(find.text('Posted 1 day ago'), findsOneWidget);
    });

    testWidgets('has no save or heart control before saved items exist', (tester) async {
      await open(tester);
      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    });

    testWidgets('a Real Estate listing shows its intent and Starting from price', (tester) async {
      stubListing(listingJson(
        condition: null,
        price: 8500000,
        priceQualifier: 'STARTING_FROM',
        transactionIntent: 'SALE',
        capabilities: _realEstateCapabilities,
      ));
      await open(tester);

      expect(find.text('Starting from ₹85,00,000'), findsOneWidget);
      expect(find.text('For sale'), findsOneWidget);
      expect(find.text('Like New'), findsNothing);
      expect(find.text('Add to Cart'), findsNothing);
      expect(find.text('Buy Now'), findsNothing);
      expect(find.text('Chat'), findsOneWidget);
    });

    testWidgets('a rent listing is labelled for rent', (tester) async {
      stubListing(listingJson(transactionIntent: 'RENT'));
      await open(tester);
      expect(find.text('For rent'), findsOneWidget);
    });

    testWidgets('a lease listing is labelled for lease', (tester) async {
      stubListing(listingJson(transactionIntent: 'LEASE'));
      await open(tester);
      expect(find.text('For lease'), findsOneWidget);
    });

    testWidgets('a listing with no photos says so', (tester) async {
      stubListing(listingJson(photos: const []));
      await open(tester);
      expect(find.text('No photo'), findsOneWidget);
      expect(find.text('1 / 3'), findsNothing);
      expect(find.byTooltip('Refresh photos'), findsNothing);
    });

    testWidgets('empty sections stay hidden', (tester) async {
      stubListing(listingJson(description: '', attributes: const []));
      await open(tester);
      expect(find.text('DESCRIPTION'), findsNothing);
      expect(find.text('ITEM DETAILS'), findsNothing);
      expect(find.text('SELLER'), findsOneWidget);
    });

    testWidgets('does not break at 320px wide with 200% text', (tester) async {
      await open(tester, size: const Size(320, 640), textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.text('Apple Watch'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Buy Now'), 300,
          scrollable: find.byType(Scrollable).first);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reads in Hindi', (tester) async {
      await open(tester, locale: const Locale('hi'));
      expect(find.text('लिस्टिंग विवरण'), findsOneWidget);
      expect(find.text('3 दिन पहले पोस्ट किया गया'), findsOneWidget);
    });

    testWidgets('long seller and location wrap in Hindi at 200% text', (tester) async {
      final json = listingJson(area: 'Whitefield Extension Bengaluru East', rating: 4.6);
      (json['seller'] as Map<String, dynamic>)['displayName'] = 'Asha Krishnamurthy Radhakrishnan';
      stubListing(json);
      await open(tester, locale: const Locale('hi'), size: const Size(320, 640), textScale: 2);
      await tester.scrollUntilVisible(find.text('प्रोफ़ाइल देखें'), 250,
          scrollable: find.byType(Scrollable).first);
      expect(tester.takeException(), isNull);
      expect(find.text('4.6'), findsOneWidget);
    });

    testWidgets('the back button returns to where the buyer came from', (tester) async {
      await open(tester);
      await tester.tap(find.byType(SquareBackButton));
      await tester.pumpAndSettle();
      expect(find.text('start'), findsOneWidget);
    });
  });

  group('actions', () {
    testWidgets('Chat, Call and Video are disabled, show no text under them and start nothing',
        (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester);

      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Call'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
      expect(find.text('Coming soon'), findsNothing);
      expect(find.bySemanticsLabel('Chat, Coming soon'), findsOneWidget);
      await tester.tap(find.text('Chat'));
      await tester.pump();
      expect(find.byType(SnackBar), findsNothing);
      handle.dispose();
    });

    testWidgets('a general listing offers Add to Cart and Buy Now, also disabled', (tester) async {
      await open(tester);
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.text('Buy Now'), findsOneWidget);
      await tester.tap(find.text('Buy Now'));
      await tester.pump();
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('your own listing says so instead of Coming soon', (tester) async {
      stubListing(listingJson(
        ownListing: true,
        capabilities: {
          for (final key in ['chat', 'call', 'video', 'cart', 'buyNow'])
            key: {'available': false, 'reason': 'OWN_LISTING'},
        },
      ));
      await open(tester);
      expect(find.text('Your listing'), findsNWidgets(5));
      expect(find.text('Coming soon'), findsNothing);
    });

    testWidgets('an action the server offers only reports that it is not built yet',
        (tester) async {
      stubListing(listingJson(capabilities: {
        ..._capabilities,
        'chat': {'available': true},
      }));
      await open(tester);

      await tester.tap(find.text('Chat'));
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('with every action not applicable the action area is gone', (tester) async {
      stubListing(listingJson(capabilities: {
        for (final key in ['chat', 'call', 'video', 'cart', 'buyNow'])
          key: {'available': false, 'reason': 'NOT_APPLICABLE'},
      }));
      await open(tester);
      expect(find.text('Chat'), findsNothing);
      expect(find.text('Coming soon'), findsNothing);
    });
  });

  group('gallery', () {
    testWidgets('swipes between photos and shows the position', (tester) async {
      await open(tester);

      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('a thumbnail jumps to its photo', (tester) async {
      await open(tester);

      await tester.tap(find.bySemanticsLabel('Show photo 3'));
      await tester.pumpAndSettle();
      expect(find.text('3 / 3'), findsOneWidget);
    });

    testWidgets('tapping a photo opens the full-resolution one', (tester) async {
      await open(tester);

      await tester.tap(find.byType(PageView));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsNothing);
    });

    testWidgets('Refresh is not offered for permanent photo links', (tester) async {
      await open(tester);
      expect(find.text('Photos not loading? Refresh'), findsNothing);
      expect(find.byTooltip('Refresh photos'), findsNothing);
    });

    testWidgets('Refresh appears for expiring links and loads the listing again', (tester) async {
      stubListing(listingJson(photos: [photo(1, expiresAt: '2026-11-12T10:05:00Z')]));
      await open(tester);
      expect(find.text('Photos not loading? Refresh'), findsNothing);
      final refresh = find.byTooltip('Refresh photos');
      expect(refresh, findsOneWidget);
      expect(tester.getRect(find.byType(PageView)).contains(tester.getCenter(refresh)), isTrue);
      expect(tester.getSize(refresh).shortestSide, greaterThanOrEqualTo(48));

      await tester.tap(refresh);
      await tester.pumpAndSettle();
      verify(() => repository.view('l1')).called(2);
    });

    testWidgets('refresh failure shows an error and retry recovers', (tester) async {
      stubListing(listingJson(photos: [photo(1, expiresAt: '2026-11-12T10:05:00Z')]));
      await open(tester);
      when(() => repository.view('l1')).thenThrow(
        const ApiError(type: ApiErrorType.network, message: 'offline'),
      );
      await tester.tap(find.byTooltip('Refresh photos'));
      await tester.pumpAndSettle();
      expect(find.byType(ListingGallery), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
      stubListing(listingJson());
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Apple Watch'), findsOneWidget);
    });
  });

  group('errors', () {
    testWidgets('a listing that is gone says so, without Retry', (tester) async {
      when(() => repository.view('l1'))
          .thenAnswer((_) async => throw businessError('ERROR_LISTING_NOT_AVAILABLE'));
      await open(tester);

      expect(find.text('This listing is no longer available'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      expect(find.text('Chat'), findsNothing);
    });

    testWidgets('a suspended seller says so, without Retry', (tester) async {
      when(() => repository.view('l1'))
          .thenAnswer((_) async => throw businessError('ERROR_SELLER_SUSPENDED'));
      await open(tester);

      expect(find.text("This seller's listings are not available right now"), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('a connection failure offers Retry, which loads the listing again', (tester) async {
      var calls = 0;
      when(() => repository.view('l1')).thenAnswer((_) async {
        calls++;
        if (calls == 1) {
          throw const ApiError(type: ApiErrorType.network, message: 'No connection');
        }
        return PublicListing.fromJson(listingJson());
      });
      await open(tester);

      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Apple Watch'), findsOneWidget);
      expect(calls, 2);
    });
  });

  group('seller profile', () {
    testWidgets('opens from the seller card and lists the seller\'s listings', (tester) async {
      await open(tester);
      await tester.scrollUntilVisible(find.text('View Profile'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('View Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Seller profile'), findsOneWidget);
      expect(find.text('Seller item'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      verify(() => repository.sellerListings('s1', page: 0)).called(1);
    });

    testWidgets('a listing card opens that listing', (tester) async {
      when(() => repository.view('a')).thenAnswer(
        (_) async => PublicListing.fromJson({...listingJson(), 'listingId': 'a', 'title': 'Other'}),
      );
      await open(tester, location: '/seller/s1');

      await tester.tap(find.text('Seller item'));
      await tester.pumpAndSettle();
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('a seller with no other listings says so', (tester) async {
      when(() => repository.sellerListings('s1', page: any(named: 'page')))
          .thenAnswer((_) async => searchPage(const []));
      await open(tester, location: '/seller/s1');
      expect(find.text('This seller has no other listings'), findsOneWidget);
    });

    testWidgets('loads the next page on request and appends it', (tester) async {
      when(() => repository.sellerListings('s1', page: 0)).thenAnswer(
        (_) async => searchPage([cardJson('a')], hasNext: true),
      );
      when(() => repository.sellerListings('s1', page: 1)).thenAnswer(
        (_) async => searchPage([cardJson('b', title: 'Page two')], page: 1),
      );
      await open(tester, location: '/seller/s1');

      expect(find.text('Page two'), findsNothing);
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();
      expect(find.text('Seller item'), findsOneWidget);
      expect(find.text('Page two'), findsOneWidget);
      expect(find.text('Load more'), findsNothing);
    });

    testWidgets('a failed load can be retried', (tester) async {
      var calls = 0;
      when(() => repository.sellerListings('s1', page: any(named: 'page'))).thenAnswer((_) async {
        calls++;
        if (calls == 1) {
          throw const ApiError(type: ApiErrorType.network, message: 'No connection');
        }
        return searchPage([cardJson('a')]);
      });
      await open(tester, location: '/seller/s1');

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Seller item'), findsOneWidget);
    });

    testWidgets('a failure on a later page keeps the loaded ones and offers another try',
        (tester) async {
      var second = 0;
      when(() => repository.sellerListings('s1', page: 0)).thenAnswer(
        (_) async => searchPage([cardJson('a')], hasNext: true),
      );
      when(() => repository.sellerListings('s1', page: 1)).thenAnswer((_) async {
        second++;
        if (second == 1) {
          throw const ApiError(type: ApiErrorType.network, message: 'No connection');
        }
        return searchPage([cardJson('b', title: 'Page two')], page: 1);
      });
      await open(tester, location: '/seller/s1');

      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();
      expect(find.text('Seller item'), findsOneWidget);
      await tester.tap(find.text('Unable to load more items. Tap to try again'));
      await tester.pumpAndSettle();
      expect(find.text('Page two'), findsOneWidget);
    });

    testWidgets('an unknown seller says so without Retry', (tester) async {
      when(() => repository.sellerListings('s1', page: any(named: 'page')))
          .thenAnswer((_) async => throw businessError('SELLER_NOT_FOUND'));
      await open(tester, location: '/seller/s1');

      expect(find.text('This seller could not be found'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('reviews are coming soon until the rating module exists', (tester) async {
      await open(tester, location: '/seller/s1');
      await tester.tap(find.text('Reviews'));
      await tester.pumpAndSettle();
      expect(find.text('Seller reviews are coming soon'), findsOneWidget);
    });

    testWidgets('available but empty reviews say there are none', (tester) async {
      when(() => repository.sellerReviews('s1'))
          .thenAnswer((_) async => const SellerReviews(available: true, count: 0));
      await open(tester, location: '/seller/s1');
      await tester.tap(find.text('Reviews'));
      await tester.pumpAndSettle();
      expect(find.text('No reviews yet'), findsOneWidget);
    });

    testWidgets('a reviews failure offers Retry', (tester) async {
      var calls = 0;
      when(() => repository.sellerReviews('s1')).thenAnswer((_) async {
        calls++;
        if (calls == 1) {
          throw const ApiError(type: ApiErrorType.network, message: 'No connection');
        }
        return const SellerReviews(available: false, count: 0);
      });
      await open(tester, location: '/seller/s1');
      await tester.tap(find.text('Reviews'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Seller reviews are coming soon'), findsOneWidget);
    });
  });

  group('route guard', () {
    test('a signed-out user is sent to sign in, an active one may stay', () {
      for (final path in [RouteNames.listingView('l1'), RouteNames.sellerProfile('s1')]) {
        expect(redirectFor(session: const AsyncData(Unauthenticated()), location: path),
            RouteNames.signIn,
            reason: path);
        expect(
          redirectFor(
            session:
                const AsyncData(Authenticated(status: AccountStatus.active, aadhaarVerified: true)),
            location: path,
          ),
          isNull,
          reason: path,
        );
      }
      expect(RouteNames.listingView('l1'), '/listing/l1');
      expect(RouteNames.sellerProfile('s1'), '/seller/s1');
    });
  });
}
