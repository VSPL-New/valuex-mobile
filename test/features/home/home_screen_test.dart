import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valuex_mobile/core/constants/storage_keys.dart';
import 'package:valuex_mobile/core/routing/app_router.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/core/widgets/category_icon.dart';
import 'package:valuex_mobile/features/address/domain/saved_address.dart';
import 'package:valuex_mobile/features/address/presentation/providers/address_providers.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/sign_in_mobile_screen.dart';
import 'package:valuex_mobile/features/home/data/mock_home_repository.dart';
import 'package:valuex_mobile/features/home/domain/entities/home_badges.dart';
import 'package:valuex_mobile/features/home/domain/entities/home_location.dart';
import 'package:valuex_mobile/features/home/domain/entities/listing.dart';
import 'package:valuex_mobile/features/home/domain/entities/promo.dart';
import 'package:valuex_mobile/features/home/domain/repositories/home_repository.dart';
import 'package:valuex_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:valuex_mobile/features/listing/presentation/create_listing_screen.dart';
import 'package:valuex_mobile/features/listing/data/listing_repository.dart';
import 'package:valuex_mobile/features/listing/domain/category.dart';
import 'package:valuex_mobile/features/listing_view/data/listing_view_repository.dart';
import 'package:valuex_mobile/features/listing_view/domain/public_listing.dart';
import 'package:valuex_mobile/features/listing_view/presentation/listing_view_screen.dart';
import 'package:valuex_mobile/features/search/data/search_repository.dart';
import 'package:valuex_mobile/features/search/presentation/search_screen.dart';
import 'package:valuex_mobile/features/home/domain/services/location_service.dart';
import 'package:valuex_mobile/features/notifications/data/notifications_repository.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fonts.dart';
import '../search/search_fixtures.dart';

class _MockNotifications extends Mock implements NotificationsRepository {}

class _MockCategories extends Mock implements ListingRepository {}

class _MockListingView extends Mock implements ListingViewRepository {}

/// Home content whose answers a test decides; whatever it is not given comes from the sample
/// repository, so a test changes only the part it is about.
class _ScriptedHome implements HomeRepository {
  static const HomeRepository _sample = MockHomeRepository();

  Future<List<Promo>> Function()? onPromos;
  Future<List<Listing>> Function(HomeLocation location)? onFeatured;
  int promoCalls = 0;
  int featuredCalls = 0;

  @override
  Future<List<Promo>> promos() {
    promoCalls++;
    return (onPromos ?? _sample.promos)();
  }

  @override
  Future<List<Listing>> featuredListings(HomeLocation location) {
    featuredCalls++;
    return (onFeatured ?? _sample.featuredListings)(location);
  }

  @override
  Future<HomeBadges> badges() => _sample.badges();
}

const _carsPromo = Promo(
  id: 'promo-cars',
  badge: 'This week',
  title: 'Used cars sale',
  body: 'Find your next car',
  ctaLabel: 'Shop cars',
  image: '',
  target: PromoTarget(type: PromoTargetType.category, value: 'L1-CARS'),
);

final _roots = [
  for (final (code, name) in const [
    ('L1-MOBILES_TABLETS', 'Mobiles & Tablets'),
    ('L1-COMPUTERS_IT', 'Computers & IT'),
    ('L1-CAMERAS_PHOTOGRAPHY', 'Cameras & Photography'),
    ('L1-FURNITURE', 'Furniture'),
    ('L1-CARS', 'Cars'),
    ('L1-REAL_ESTATE', 'Real Estate'),
    ('L1-BOOKS_STATIONERY_EDUCATION', 'Books, Stationery & Education'),
  ])
    CategoryNode(code: code, name: name, level: 1, hasChildren: true),
];

const _home = SavedAddress(
  id: 'a-1',
  label: 'Home',
  address: '12 FC Road, Shivajinagar',
  landmark: 'Flat 4',
  city: 'Pune',
  state: 'Maharashtra',
  pincode: '411014',
  isDefault: true,
);

const _office = SavedAddress(
  id: 'a-2',
  label: 'Office',
  address: 'Cyber Park, Hinjewadi',
  city: 'Pune',
  state: 'Maharashtra',
  pincode: '411057',
);

void main() {
  setUpAll(() async {
    registerFallbackValue(CategoryScope.all);
    await loadBrandFonts();
  });

  late _MockCategories taxonomy;
  late _MockListingView listingView;
  late FakeSearchRepository search;
  late HomeRepository content;
  setUp(() {
    content = const MockHomeRepository();
    taxonomy = _MockCategories();
    listingView = _MockListingView();
    when(() => listingView.view(any())).thenAnswer(
      (call) async => PublicListing.fromJson({
        'listingId': call.positionalArguments.single,
        'title': 'Opened listing',
        'seller': {'sellerId': 's1', 'displayName': 'Asha K'},
      }),
    );
    search = FakeSearchRepository((criteria, page) async => listingsPage(0, 0, hasNext: false));
    when(() => taxonomy.categoryChildren(
          parentCode: any(named: 'parentCode'),
          scope: any(named: 'scope'),
        )).thenAnswer((call) async {
      final parent = call.namedArguments[#parentCode] as String?;
      final scope = call.namedArguments[#scope] as CategoryScope?;
      return switch ((parent, scope)) {
        (null, CategoryScope.popular) => _roots.take(5).toList(),
        (null, CategoryScope.others) => _roots.skip(5).toList(),
        (null, CategoryScope.all) => _roots,
        ('L1-MOBILES_TABLETS', CategoryScope.all) => [
            const CategoryNode(
                code: 'L2-MOBILES_TABLETS-PHONES',
                name: 'Mobile Phones',
                level: 2,
                hasChildren: true),
          ],
        ('L1-REAL_ESTATE', CategoryScope.all) => [
            const CategoryNode(
                code: 'L2-REAL_ESTATE-HOMES', name: 'Homes', level: 2, hasChildren: true),
          ],
        _ => <CategoryNode>[],
      };
    });
  });

  Finder inDialog(String text) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text).first;
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
  }

  /// Tapping a button lower on the page scrolls the header out of the list, where it is not built.
  Future<void> showHeaderThenListing(WidgetTester tester, AppHarness harness) async {
    final page = find.byType(Scrollable).first;
    tester.state<ScrollableState>(page).position.jumpTo(0);
    await harness.settle();
  }

  Future<void> scrollToListing(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Sony A7 IV Camera'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }

  Future<AppHarness> openHome(
    WidgetTester tester, {
    bool aadhaarVerified = true,
    LocationAccess access = LocationAccess.granted,
    LocationAccess afterRequest = LocationAccess.granted,
    List<SavedAddress> saved = const [],
    Future<List<SavedAddress>> Function()? savedLoader,
    bool signedIn = true,
  }) async {
    final notifications = _MockNotifications();
    when(notifications.unreadCount).thenAnswer((_) async => 3);
    final harness = AppHarness(
      tester,
      extraOverrides: [
        homeRepositoryProvider.overrideWithValue(content),
        listingRepositoryProvider.overrideWithValue(taxonomy),
        listingViewRepositoryProvider.overrideWithValue(listingView),
        searchRepositoryProvider.overrideWithValue(search),
        notificationsRepositoryProvider.overrideWithValue(notifications),
        savedAddressesProvider.overrideWith((ref) => (savedLoader ?? () async => saved)()),
      ],
    );
    if (signedIn) harness.signedInAs(AccountStatus.active, aadhaarVerified: aadhaarVerified);
    harness.locationService
      ..state = access
      ..afterRequest = afterRequest;
    await harness.launch(location: RouteNames.home);
    return harness;
  }

  testWidgets('shows the header, promo, categories and featured deals', (tester) async {
    final harness = await openHome(tester);

    expect(find.text('Andheri (East)'), findsOneWidget);
    expect(find.text('Mumbai, Maharashtra'), findsOneWidget);
    expect(find.text('Search here ...'), findsOneWidget);
    expect(find.text('Unlock AI Photo Search'), findsOneWidget);
    expect(find.text('Claim Voucher'), findsOneWidget);
    expect(find.text('Browse'), findsOneWidget);
    expect(find.text('Mobiles & Tablets'), findsOneWidget);
    expect(find.text('Electronic'), findsNothing);
    expect(find.text('More'), findsOneWidget);
    expect(find.text('Featured Deals Near You'), findsOneWidget);
    expect(find.text('Sony A7 IV Camera'), findsOneWidget);
    expect(find.text('\u20b91,85,000'), findsOneWidget);
    expect(find.text('BOOSTED'), findsWidgets);
    expect(tester.takeException(), isNull);
    await harness.dispose();
  });

  testWidgets('the cart and the bell tell a screen reader their counts', (tester) async {
    final handle = tester.ensureSemantics();
    final harness = await openHome(tester);

    expect(find.bySemanticsLabel('Cart, 2 items'), findsOneWidget);
    expect(find.bySemanticsLabel('Notifications, 3 unread'), findsOneWidget);
    handle.dispose();
    await harness.dispose();
  });

  testWidgets('Home and its category list share the category icon component', (tester) async {
    final harness = await openHome(tester);
    expect(find.byType(CategoryIcon), findsNWidgets(5));
    final first = tester.widget<CategoryIcon>(find.byType(CategoryIcon).first);
    expect(first.code, 'L1-MOBILES_TABLETS');
    await tapText(tester, 'More');
    await harness.settle();
    expect(find.byType(CategoryIcon), findsWidgets);
    expect(
      tester.widgetList<CategoryIcon>(find.byType(CategoryIcon)).map((icon) => icon.code),
      containsAll(['L1-MOBILES_TABLETS', 'L1-COMPUTERS_IT', 'L1-CAMERAS_PHOTOGRAPHY']),
    );
    await harness.dispose();
  });

  testWidgets('a listing card is announced as one button with its facts', (tester) async {
    final handle = tester.ensureSemantics();
    final harness = await openHome(tester);

    expect(
      find.bySemanticsLabel(
        'Sony A7 IV Camera, \u20b91,85,000, Delhi, Rated 4.7 out of 5, Good, BOOSTED',
      ),
      findsOneWidget,
    );
    handle.dispose();
    await harness.dispose();
  });

  testWidgets('every featured card has a heart that starts unsaved (US-073)', (tester) async {
    final handle = tester.ensureSemantics();
    final harness = await openHome(tester);

    expect(find.bySemanticsLabel('Save listing'), findsWidgets);
    expect(find.bySemanticsLabel('Remove from saved'), findsNothing);
    handle.dispose();
    await harness.dispose();
  });

  testWidgets('tapping a featured listing card opens that listing, not a coming soon message', (
    tester,
  ) async {
    final harness = await openHome(tester);

    await tapText(tester, 'Sony A7 IV Camera');
    await harness.settle();

    expect(find.byType(ListingViewScreen), findsOneWidget);
    expect(find.text('Opened listing'), findsOneWidget);
    verify(() => listingView.view('sony-a7-iv')).called(1);
    expect(find.text('This is coming soon'), findsNothing);
    await harness.dispose();
  });

  testWidgets('going back from a listing returns to Home', (tester) async {
    final harness = await openHome(tester);

    await tapText(tester, 'Sony A7 IV Camera');
    await harness.settle();
    harness.container.read(appRouterProvider).pop();
    await harness.settle();

    expect(find.byType(ListingViewScreen), findsNothing);
    expect(find.text('Sony A7 IV Camera'), findsOneWidget);
    await harness.dispose();
  });

  group('location', () {
    testWidgets('without permission Home explains and offers the current or a saved location', (
      tester,
    ) async {
      final harness = await openHome(tester, access: LocationAccess.denied);

      expect(find.text('See items near you'), findsOneWidget);
      expect(find.text('Use my current location'), findsOneWidget);
      expect(find.text('Use my saved location'), findsOneWidget);
      expect(find.text('Enter address'), findsNothing);
      expect(find.text('Set your location'), findsOneWidget);
      expect(find.text('Sony A7 IV Camera'), findsNothing);
      await harness.dispose();
    });

    testWidgets('allowing location shows the place and the listings', (tester) async {
      final harness = await openHome(tester, access: LocationAccess.denied);

      await tapText(tester, 'Use my current location');
      await harness.settle();

      expect(harness.locationService.requests, 1);
      await showHeaderThenListing(tester, harness);
      expect(find.text('Andheri (East)'), findsOneWidget);
      await scrollToListing(tester);
      expect(find.text('Sony A7 IV Camera'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('refusing the request says why and keeps the saved location option', (
      tester,
    ) async {
      final harness = await openHome(
        tester,
        access: LocationAccess.denied,
        afterRequest: LocationAccess.denied,
      );

      await tapText(tester, 'Use my current location');
      await harness.settle();

      expect(
        find.text('Location access is off. Use a saved location to see items near you'),
        findsOneWidget,
      );
      expect(find.text('Use my saved location'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a permanent refusal sends the user to the settings', (tester) async {
      final harness = await openHome(tester, access: LocationAccess.deniedForever);

      await tapText(tester, 'Open settings');
      await tester.pump();

      expect(harness.locationService.settingsOpened, 1);
      await harness.dispose();
    });

    testWidgets('a saved location is chosen from a pop-up that shows the name and full address', (
      tester,
    ) async {
      final harness = await openHome(
        tester,
        access: LocationAccess.denied,
        saved: [_home, _office],
      );

      await tapText(tester, 'Use my saved location');
      await harness.settle();

      expect(find.text('Choose a saved location'), findsOneWidget);
      expect(inDialog('Home'), findsOneWidget);
      expect(
          find.text('Flat 4, 12 FC Road, Shivajinagar, Pune, Maharashtra 411014'), findsOneWidget);
      expect(find.text('Office'), findsOneWidget);
      expect(find.text('Cyber Park, Hinjewadi, Pune, Maharashtra 411057'), findsOneWidget);
      expect(find.byType(Radio<String>), findsNWidgets(2));

      await tester.tap(find.text('Office'));
      await harness.settle();
      expect(find.text('Choose a saved location'), findsOneWidget, reason: 'picking only selects');
      await tester.tap(find.text('Use this address'));
      await harness.settle();

      expect(find.text('Choose a saved location'), findsNothing);
      await showHeaderThenListing(tester, harness);
      expect(find.text('Pune, Maharashtra'), findsOneWidget);
      await scrollToListing(tester);
      expect(find.text('Sony A7 IV Camera'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      final kept = HomeLocation.tryParse(prefs.getString(StorageKeys.homeLocation));
      expect(kept?.city, 'Pune');
      expect(kept?.pincode, '411057');
      await harness.dispose();
    });

    testWidgets('the header opens a sheet with only the two choices and no address entry', (
      tester,
    ) async {
      final harness = await openHome(tester, saved: [_home]);

      await tester.tap(find.text('Andheri (East)'));
      await harness.settle();

      expect(find.text('Choose your location'), findsOneWidget);
      expect(find.text('Use my current location'), findsOneWidget);
      expect(find.text('Use my saved location'), findsOneWidget);
      expect(find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)),
          findsNothing);

      await tester.tap(find.text('Use my saved location'));
      await harness.settle();
      expect(find.text('Choose a saved location'), findsOneWidget);
      await tester.tap(inDialog('Home'));
      await harness.settle();
      await tester.tap(find.text('Use this address'));
      await harness.settle();

      expect(find.text('Pune, Maharashtra'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('with no saved address the pop-up says one is saved when the user buys or sells', (
      tester,
    ) async {
      final harness = await openHome(tester, access: LocationAccess.denied);

      await tapText(tester, 'Use my saved location');
      await harness.settle();

      expect(
        find.text(
            'You have no saved locations yet. An address is saved when you buy or sell an item.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await harness.settle();
      expect(find.text('Choose a saved location'), findsNothing);
      await harness.dispose();
    });

    testWidgets('a failed load of the saved addresses can be retried', (tester) async {
      var calls = 0;
      final harness = await openHome(
        tester,
        access: LocationAccess.denied,
        savedLoader: () async {
          calls++;
          if (calls == 1) throw Exception('offline');
          return [_home];
        },
      );

      await tapText(tester, 'Use my saved location');
      await harness.settle();
      expect(find.text('Unable to load your saved locations. Try again'), findsOneWidget);

      await tester.tap(inDialog('Retry'));
      await harness.settle();

      expect(inDialog('Home'), findsOneWidget);
      await harness.dispose();
    });
  });

  group('navigation', () {
    testWidgets('guests browse categories but must sign in before opening listings',
        (tester) async {
      final harness = await openHome(tester, signedIn: false);
      await tapText(tester, 'Mobiles & Tablets');
      await harness.settle();
      expect(find.text('Mobile Phones'), findsOneWidget);
      expect(search.calls, isEmpty);
      expect(search.suggestCalls, isEmpty);
      await tapText(tester, 'View all in Mobiles & Tablets');
      await harness.settle();
      expect(find.byType(SignInMobileScreen), findsOneWidget);
      expect(search.calls, isEmpty);
      await harness.dispose();
    });

    testWidgets('guest category browser search field requests sign-in without calling search',
        (tester) async {
      final harness = await openHome(tester, signedIn: false);
      await tapText(tester, 'Mobiles & Tablets');
      await harness.settle();
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
      await tester.tap(find.byType(TextField));
      await harness.settle();
      expect(find.byType(SignInMobileScreen), findsOneWidget);
      expect(search.calls, isEmpty);
      expect(search.suggestCalls, isEmpty);
      await harness.dispose();
    });

    testWidgets('a Home shortcut opens the same root expanded, without a keyword search',
        (tester) async {
      final harness = await openHome(tester);
      await tapText(tester, 'Mobiles & Tablets');
      await harness.settle();

      final screen = tester.widget<SearchScreen>(find.byType(SearchScreen));
      expect(screen.browseParent?.code, 'L1-MOBILES_TABLETS');
      expect(screen.browseParent?.name, 'Mobiles & Tablets');
      expect(screen.browseParent?.level, 1);
      expect(find.text('Mobile Phones'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
      expect(search.calls, isEmpty);
      verify(() =>
              taxonomy.categoryChildren(parentCode: 'L1-MOBILES_TABLETS', scope: CategoryScope.all))
          .called(1);
      expect(screen.initial.query, isEmpty);
      await harness.dispose();
    });

    testWidgets('Home and Search reuse the popular taxonomy request', (tester) async {
      final harness = await openHome(tester);
      await tapText(tester, 'Search here ...');
      await harness.settle();

      expect(find.text('Mobiles & Tablets'), findsOneWidget);
      verify(() => taxonomy.categoryChildren(parentCode: null, scope: CategoryScope.popular))
          .called(1);
      await harness.dispose();
    });

    testWidgets('More shows all 39 server roots, including non-popular categories', (tester) async {
      final all = [
        ..._roots,
        for (var i = 7; i < 39; i++)
          CategoryNode(code: 'L1-EXTRA_$i', name: 'Extra root $i', level: 1, hasChildren: true),
      ];
      when(() => taxonomy.categoryChildren(parentCode: null, scope: CategoryScope.all))
          .thenAnswer((_) async => all);
      final harness = await openHome(tester);
      expect(find.text('Real Estate'), findsNothing);
      await tapText(tester, 'More');
      await harness.settle();
      await tester.scrollUntilVisible(find.text('Extra root 38'), 400);
      expect(find.text('Extra root 38'), findsOneWidget);
      verify(() => taxonomy.categoryChildren(parentCode: null, scope: CategoryScope.all)).called(1);
      await harness.dispose();
    });

    testWidgets('More opens Real Estate expanded and preserves the intent requirement',
        (tester) async {
      final harness = await openHome(tester);
      await tapText(tester, 'More');
      await harness.settle();
      await tapText(tester, 'Real Estate');
      await harness.settle();

      final screen = tester.widget<SearchScreen>(find.byType(SearchScreen));
      expect(screen.browseParent?.code, 'L1-REAL_ESTATE');
      expect(screen.browseRealEstate, isTrue);
      expect(find.text('Homes'), findsOneWidget);
      expect(search.calls, isEmpty);
      await tapText(tester, 'View all in Real Estate');
      await harness.settle();
      expect(find.text('Buy'), findsWidgets);
      expect(find.text('Rent'), findsWidgets);
      expect(find.text('Lease'), findsWidgets);
      expect(search.calls, isEmpty);
      await harness.dispose();
    });

    testWidgets('More opens every category and Back returns to Home', (tester) async {
      final harness = await openHome(tester);

      await tester.tap(find.text('More'));
      await harness.settle();
      expect(find.text('All categories'), findsOneWidget);
      expect(find.text('Furniture'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Back'));
      await harness.settle();
      expect(find.text('Featured Deals Near You'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('Sell is not blocked for a user who skipped Aadhaar', (tester) async {
      final harness = await openHome(tester, aadhaarVerified: false);

      await tester.tap(find.text('Sell'));
      await harness.settle();

      expect(find.text('Please complete Aadhaar verification to proceed'), findsNothing);
      expect(find.byType(CreateListingScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a screen that is not built yet says it is coming soon', (tester) async {
      final harness = await openHome(tester);

      await tester.tap(find.text('Chats'));
      await tester.pump();

      expect(find.text('This is coming soon'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a signed-out visitor who taps Sell is sent to create an account', (tester) async {
      final harness = AppHarness(
        tester,
        extraOverrides: [homeRepositoryProvider.overrideWithValue(content)],
      );
      await harness.launch(location: RouteNames.home);

      await tester.tap(find.text('Sell'));
      await harness.settle();

      expect(find.text('Create an Account'), findsWidgets);
      await harness.dispose();
    });
  });

  group('taxonomy states', () {
    testWidgets('Home loads without showing sample categories', (tester) async {
      final pending = Completer<List<CategoryNode>>();
      when(() => taxonomy.categoryChildren(parentCode: null, scope: CategoryScope.popular))
          .thenAnswer((_) => pending.future);
      final harness = await openHome(tester);
      expect(find.byType(CategoryIcon), findsNothing);
      expect(find.text('Electronic'), findsNothing);
      pending.complete(_roots.take(5).toList());
      await harness.settle();
      expect(find.text('Mobiles & Tablets'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('Home exposes failure and retries the shared taxonomy', (tester) async {
      var calls = 0;
      when(() => taxonomy.categoryChildren(parentCode: null, scope: CategoryScope.popular))
          .thenAnswer((_) async {
        if (++calls == 1) throw Exception('offline');
        return _roots.take(5).toList();
      });
      final harness = await openHome(tester);
      expect(find.byType(CategoryIcon), findsNothing);
      await tapText(tester, 'Retry');
      await harness.settle();
      expect(calls, 2);
      expect(find.text('Mobiles & Tablets'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('empty popular categories retain More and never use mock roots', (tester) async {
      when(() => taxonomy.categoryChildren(parentCode: null, scope: CategoryScope.popular))
          .thenAnswer((_) async => []);
      final harness = await openHome(tester);
      expect(find.byType(CategoryIcon), findsNothing);
      await tapText(tester, 'More');
      await harness.settle();
      expect(find.text('Real Estate'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('More has loading, retry and empty states', (tester) async {
      final pending = Completer<List<CategoryNode>>();
      var calls = 0;
      when(() => taxonomy.categoryChildren(parentCode: null, scope: CategoryScope.all))
          .thenAnswer((_) {
        calls++;
        return calls == 1 ? pending.future : Future.value([]);
      });
      final harness = await openHome(tester);
      await tapText(tester, 'More');
      await harness.settle();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.completeError(Exception('offline'));
      await harness.settle();
      await tapText(tester, 'Retry');
      await harness.settle();
      expect(calls, 2);
      expect(find.byType(ListTile), findsNothing);
      expect(find.text('Electronic'), findsNothing);
      expect(tester.takeException(), isNull);
      await harness.dispose();
    });

    testWidgets('pull to refresh reloads the popular taxonomy', (tester) async {
      final harness = await openHome(tester);
      clearInteractions(taxonomy);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 500));
      await tester.pump(const Duration(seconds: 1));
      await harness.settle();
      verify(() => taxonomy.categoryChildren(parentCode: null, scope: CategoryScope.popular))
          .called(1);
      await harness.dispose();
    });
  });

  group('content from the server', () {
    late _ScriptedHome home;
    setUp(() {
      home = _ScriptedHome();
      content = home;
    });

    testWidgets('a failed promo call hides only the promo card', (tester) async {
      home.onPromos = () async => throw Exception('offline');
      final harness = await openHome(tester);

      expect(find.text('Unlock AI Photo Search'), findsNothing);
      expect(find.text('Mobiles & Tablets'), findsOneWidget);
      expect(find.text('Sony A7 IV Camera'), findsOneWidget);
      expect(find.text('Unable to load Home. Pull down or tap Retry'), findsNothing);
      await harness.dispose();
    });

    testWidgets('a failed featured call shows the error with Retry and Retry loads again',
        (tester) async {
      const sample = MockHomeRepository();
      var offline = true;
      home.onFeatured = (location) async {
        if (offline) throw Exception('offline');
        return sample.featuredListings(location);
      };
      final harness = await openHome(tester);
      const message = 'Unable to load Home. Pull down or tap Retry';

      // The other sections are not affected by the failed featured call.
      expect(find.text('Unlock AI Photo Search'), findsOneWidget);
      expect(find.text('Mobiles & Tablets'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(message),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(message), findsOneWidget);
      expect(find.text('Sony A7 IV Camera'), findsNothing);

      offline = false;
      final callsBeforeRetry = home.featuredCalls;
      await tapText(tester, 'Retry');
      await harness.settle();

      expect(home.featuredCalls, greaterThan(callsBeforeRetry));
      expect(find.text(message), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Sony A7 IV Camera'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Sony A7 IV Camera'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('no listings near the place says so', (tester) async {
      home.onFeatured = (_) async => const [];
      final harness = await openHome(tester);

      expect(find.text('No items near you yet. Try another location'), findsOneWidget);
      expect(find.text('Sony A7 IV Camera'), findsNothing);
      await harness.dispose();
    });

    testWidgets('no active promo shows no promo section', (tester) async {
      home.onPromos = () async => const [];
      final harness = await openHome(tester);

      expect(find.text('Unlock AI Photo Search'), findsNothing);
      expect(find.text('Claim Voucher'), findsNothing);
      expect(find.text('Featured Deals Near You'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a promo for a category opens the listings of that category', (tester) async {
      home.onPromos = () async => const [_carsPromo];
      final harness = await openHome(tester);

      await tapText(tester, 'Shop cars');
      await harness.settle();

      expect(find.byType(SearchScreen), findsOneWidget);
      expect(search.calls.last.criteria.categoryCode, 'L1-CARS');
      await harness.dispose();
    });

    testWidgets('a promo for a search text opens search for that text', (tester) async {
      home.onPromos = () async => const [
            Promo(
              id: 'promo-chairs',
              badge: 'Deal',
              title: 'Chairs for less',
              body: 'Sit well',
              ctaLabel: 'Shop chairs',
              image: '',
              target: PromoTarget(type: PromoTargetType.search, value: 'office chair'),
            ),
          ];
      final harness = await openHome(tester);

      await tapText(tester, 'Shop chairs');
      await harness.settle();

      expect(find.byType(SearchScreen), findsOneWidget);
      expect(search.calls.last.criteria.query, 'office chair');
      await harness.dispose();
    });

    testWidgets('a promo for a listing opens that listing', (tester) async {
      home.onPromos = () async => const [
            Promo(
              id: 'promo-listing',
              badge: 'Pick',
              title: 'Editor pick',
              body: 'A good one',
              ctaLabel: 'See it',
              image: '',
              target: PromoTarget(type: PromoTargetType.listing, value: 'listing-1'),
            ),
          ];
      final harness = await openHome(tester);

      await tapText(tester, 'See it');
      await harness.settle();

      expect(find.byType(ListingViewScreen), findsOneWidget);
      expect(find.text('Opened listing'), findsOneWidget);
      verify(() => listingView.view('listing-1')).called(1);
      expect(find.text('This is coming soon'), findsNothing);
      await harness.dispose();
    });

    testWidgets('a sample promo with no target says it is coming soon', (tester) async {
      final harness = await openHome(tester);

      await tapText(tester, 'Claim Voucher');
      await tester.pump();

      expect(find.text('This is coming soon'), findsOneWidget);
      await harness.dispose();
    });
  });
}
