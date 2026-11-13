import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/sign_in_mobile_screen.dart';
import 'package:valuex_mobile/features/listing/data/listing_repository.dart';
import 'package:valuex_mobile/features/listing/domain/category.dart';
import 'package:valuex_mobile/features/notifications/data/notifications_repository.dart';
import 'package:valuex_mobile/features/search/data/search_repository.dart';
import 'package:valuex_mobile/features/search/domain/search_page.dart';
import 'package:valuex_mobile/features/search/domain/search_sort.dart';
import 'package:valuex_mobile/features/search/domain/transaction_intent.dart';
import 'package:valuex_mobile/features/search/presentation/category_browse_screen.dart';
import 'package:valuex_mobile/features/search/presentation/search_screen.dart';
import 'package:valuex_mobile/features/search/presentation/widgets/category_browser.dart';
import 'package:valuex_mobile/features/search/presentation/widgets/category_browser_tiles.dart';
import 'package:valuex_mobile/features/search/presentation/widgets/filter_sheet.dart';
import 'package:valuex_mobile/features/home/data/mock_home_repository.dart';
import 'package:valuex_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:valuex_mobile/features/search/presentation/widgets/intent_sheet.dart';
import 'package:valuex_mobile/features/search/presentation/widgets/search_skeleton.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/app_harness.dart';
import '../../helpers/fonts.dart';
import 'search_fixtures.dart';

class _MockListingRepository extends Mock implements ListingRepository {}

class _MockNotifications extends Mock implements NotificationsRepository {}

const _mobiles = CategoryNode(
  code: 'L1-M',
  name: 'Mobiles & Tablets',
  level: 1,
  hasChildren: true,
  popular: true,
);
const _books = CategoryNode(code: 'L1-B', name: 'Books', level: 1, hasChildren: true);
const _realEstate = CategoryNode(
  code: 'L1-R',
  name: 'Real Estate',
  level: 1,
  hasChildren: true,
  popular: true,
);
const _phones = CategoryNode(
  code: 'L2-P',
  name: 'Mobile Phones',
  level: 2,
  hasChildren: true,
  popular: true,
);
const _tablets = CategoryNode(code: 'L2-T', name: 'Tablets', level: 2, hasChildren: true);
const _homes = CategoryNode(code: 'L2-H', name: 'Homes', level: 2, hasChildren: true);
const _smartphones = CategoryNode(code: 'CAT-1', name: 'Smartphones', level: 3, hasChildren: false);

const _offline = ApiError(type: ApiErrorType.network, message: 'offline');

ApiError _coded(String code, {int status = 400, ApiErrorType? type}) => ApiError(
      type: type ?? ApiErrorType.business,
      message: 'x',
      code: code,
      statusCode: status,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(CategoryScope.all);
    loadBrandFonts();
  });

  late FakeSearchRepository search;
  late _MockListingRepository categories;
  late AppHarness harness;

  setUp(() {
    search = FakeSearchRepository(
      (criteria, page) async => SearchPage.fromJson(
        pageJson([
          listingJson('l1', title: 'Apple iPhone 14 128GB', badge: 'FEATURED', cardUrl: null),
          listingJson(
            'l2',
            title: 'Studio flat',
            price: 1299.5,
            qualifier: 'STARTING_FROM',
            condition: null,
            badge: 'BOOSTED',
            cardUrl: null,
          ),
          listingJson('l3', title: 'Old bike', price: 5000, cardUrl: null),
        ]),
      ),
    );
    categories = _MockListingRepository();
    when(
      () => categories.categoryChildren(
        parentCode: any(named: 'parentCode'),
        scope: any(named: 'scope'),
      ),
    ).thenAnswer((invocation) async {
      final parent = invocation.namedArguments[#parentCode] as String?;
      final scope = invocation.namedArguments[#scope] as CategoryScope?;
      return switch ((parent, scope)) {
        (null, CategoryScope.popular) => [_mobiles, _realEstate],
        (null, CategoryScope.others) => [_books],
        (null, CategoryScope.all) => [_mobiles, _realEstate, _books],
        ('L1-M', CategoryScope.all) => [_tablets, _phones],
        ('L1-R', CategoryScope.all) => [_homes],
        ('L2-P', CategoryScope.all) => [_smartphones],
        _ => <CategoryNode>[],
      };
    });
  });

  Future<AppHarness> openAt(
    WidgetTester tester,
    String location, {
    bool signedIn = true,
  }) async {
    final notifications = _MockNotifications();
    when(notifications.unreadCount).thenAnswer((_) async => 0);
    harness = AppHarness(
      tester,
      extraOverrides: [
        homeRepositoryProvider.overrideWithValue(const MockHomeRepository()),
        searchRepositoryProvider.overrideWithValue(search),
        listingRepositoryProvider.overrideWithValue(categories),
        notificationsRepositoryProvider.overrideWithValue(notifications),
      ],
    );
    if (signedIn) harness.signedInAs(AccountStatus.active);
    await harness.launch(location: location);
    return harness;
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(const Duration(milliseconds: 450));
    await harness.settle();
  }

  Finder inSheet(Finder finder) => find.descendant(of: find.byType(FilterSheet), matching: finder);

  Future<void> openFilters(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await harness.settle();
  }

  Future<void> apply(WidgetTester tester) async {
    await tester.tap(find.text('Apply'));
    await harness.settle();
  }

  group('start page', () {
    testWidgets('shows the title as a heading, the popular categories and a way to browse all',
        (tester) async {
      final handle = tester.ensureSemantics();
      await openAt(tester, '/search');

      expect(find.byType(SearchScreen), findsOneWidget);
      expect(tester.getSemantics(find.text('Search items').first), isSemantics(isHeader: true));
      expect(find.text('Popular categories'), findsOneWidget);
      expect(find.text('Mobiles & Tablets'), findsOneWidget);
      expect(find.text('Real Estate'), findsOneWidget);
      expect(find.text('Browse all categories'), findsOneWidget);
      expect(search.calls, isEmpty);
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('a failure to load the categories offers Retry', (tester) async {
      var fail = true;
      when(
        () => categories.categoryChildren(
          parentCode: any(named: 'parentCode'),
          scope: any(named: 'scope'),
        ),
      ).thenAnswer((_) async {
        if (fail) throw _offline;
        return [_mobiles];
      });
      await openAt(tester, '/search');

      expect(find.text('Unable to load categories. Try again'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Retry'));
      await harness.settle();

      expect(find.text('Mobiles & Tablets'), findsOneWidget);
      await harness.dispose();
    });
  });

  group('typing and results', () {
    testWidgets('results appear after the pause with price, badge and starting-from label',
        (tester) async {
      await openAt(tester, '/search');

      await type(tester, 'iphone');

      expect(search.calls, hasLength(1));
      expect(search.calls.single.criteria.query, 'iphone');
      expect(search.calls.single.nearCity, 'Mumbai');
      expect(search.calls.single.nearState, 'Maharashtra');
      expect(find.text('Apple iPhone 14 128GB'), findsOneWidget);
      expect(find.text('3 items found'), findsOneWidget);
      expect(find.text('\u20b942,000'), findsOneWidget);
      expect(find.text('\u20b91,299.50'), findsOneWidget);
      expect(find.text('Starting from'), findsOneWidget);
      expect(find.text('Featured'), findsOneWidget);
      expect(find.text('BOOSTED'), findsOneWidget);
      expect(find.text('Popular categories'), findsNothing);
      await harness.dispose();
    });

    testWidgets('a quick typist causes one search, for the final text', (tester) async {
      await openAt(tester, '/search');

      await tester.enterText(find.byType(TextField), 'l');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(find.byType(TextField), 'lap');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(find.byType(TextField), 'laptop');
      await tester.pump(const Duration(milliseconds: 450));
      await harness.settle();

      expect(search.calls, hasLength(1));
      expect(search.calls.single.criteria.query, 'laptop');
      await harness.dispose();
    });

    testWidgets('a slow answer for old text does not replace the newer results', (tester) async {
      final answers = <String, Completer<SearchPage>>{};
      search.handler =
          (criteria, page) => (answers[criteria.query] = Completer<SearchPage>()).future;
      await openAt(tester, '/search');

      await tester.enterText(find.byType(TextField), 'lap');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.enterText(find.byType(TextField), 'laptop');
      await tester.pump(const Duration(milliseconds: 450));
      answers['laptop']!.complete(
        SearchPage.fromJson(pageJson([listingJson('n1', title: 'Laptop deal')])),
      );
      await harness.settle();
      answers['lap']!.complete(
        SearchPage.fromJson(pageJson([listingJson('o1', title: 'Lap desk')])),
      );
      await harness.settle();

      expect(find.text('Laptop deal'), findsOneWidget);
      expect(find.text('Lap desk'), findsNothing);
      await harness.dispose();
    });

    testWidgets('the field holds 200 characters without showing a counter', (tester) async {
      await openAt(tester, '/search');

      expect(find.textContaining('characters'), findsNothing);
      await tester.enterText(find.byType(TextField), 'a' * 250);
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text.length, 200);
      expect(find.textContaining('characters'), findsNothing);
      await tester.pump(const Duration(milliseconds: 450));
      await harness.settle();
      expect(search.calls.single.criteria.query.length, 200);
      await harness.dispose();
    });

    testWidgets('clearing the text returns to the popular categories', (tester) async {
      await openAt(tester, '/search');
      await type(tester, 'iphone');

      await tester.tap(find.byTooltip('Clear search text'));
      await harness.settle();

      expect(find.byType(TextField), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
      expect(find.text('Popular categories'), findsOneWidget);
      expect(find.byTooltip('Clear search text'), findsNothing);
      await harness.dispose();
    });

    testWidgets('pressing search on the keyboard searches without waiting', (tester) async {
      await openAt(tester, '/search');

      await tester.enterText(find.byType(TextField), 'iphone');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      await harness.settle();

      expect(search.calls, hasLength(1));
      await harness.dispose();
    });

    testWidgets('skeletons show while the first page loads', (tester) async {
      final gate = Completer<SearchPage>();
      search.handler = (criteria, page) => gate.future;
      await openAt(tester, '/search?q=iphone');

      expect(find.byType(SearchSkeleton), findsOneWidget);

      gate.complete(SearchPage.fromJson(pageJson([listingJson('l1')])));
      await harness.settle();
      expect(find.byType(SearchSkeleton), findsNothing);
      expect(find.text('Apple iPhone 14 128GB'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('skeletons do not animate when the system asks to reduce motion', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final gate = Completer<SearchPage>();
      search.handler = (criteria, page) => gate.future;
      await openAt(tester, '/search?q=iphone');

      expect(find.byType(SearchSkeleton), findsOneWidget);
      gate.complete(SearchPage.fromJson(pageJson([])));
      await harness.settle();
      await harness.dispose();
    });

    testWidgets('a listing card is announced as one button with its facts', (tester) async {
      final handle = tester.ensureSemantics();
      await openAt(tester, '/search?q=flat');

      expect(
        find.bySemanticsLabel('Studio flat, Starting from \u20b91,299.50, Pune, BOOSTED'),
        findsOneWidget,
      );
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('tapping a card says details are coming soon', (tester) async {
      await openAt(tester, '/search?q=flat');

      await tester.tap(find.text('Old bike'));
      await tester.pump();

      expect(find.text('This is coming soon'), findsOneWidget);
      await harness.dispose();
    });
  });

  group('infinite scroll and refresh', () {
    setUp(() {
      search.handler = (criteria, page) async => listingsPage(page * 20, 20, total: 55);
    });

    testWidgets('scrolling to the end loads the next page, and so on until there is no more',
        (tester) async {
      search.handler = (criteria, page) async => listingsPage(
            page * 20,
            page == 2 ? 15 : 20,
            total: 55,
            hasNext: page < 2,
            page: page,
          );
      await openAt(tester, '/search?q=item');
      expect(search.calls.map((c) => c.page), [0]);

      for (var i = 0; i < 12 && search.calls.length < 3; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
        await harness.settle();
      }

      expect(search.calls.map((c) => c.page), [0, 1, 2]);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -5000));
      await harness.settle();
      expect(search.calls, hasLength(3));
      expect(find.text('Item 54'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a page that fails to load can be tried again from the end of the list',
        (tester) async {
      var fail = true;
      search.handler = (criteria, page) async {
        if (page == 1 && fail) throw _offline;
        return listingsPage(page * 20, 20, total: 40, hasNext: page == 0, page: page);
      };
      await openAt(tester, '/search?q=item');

      for (var i = 0; i < 5; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
        await harness.settle();
      }
      expect(find.text('Unable to load more items. Tap to try again'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('Unable to load more items. Tap to try again'));
      await harness.settle();
      for (var i = 0; i < 5; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
        await harness.settle();
      }

      expect(find.text('Item 39'), findsOneWidget);
      expect(find.text('Unable to load more items. Tap to try again'), findsNothing);
      await harness.dispose();
    });

    testWidgets('pulling down refreshes the first page', (tester) async {
      await openAt(tester, '/search?q=item');
      expect(search.calls, hasLength(1));

      await tester.fling(find.byType(CustomScrollView), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await harness.settle();

      expect(search.calls, hasLength(2));
      expect(search.calls.last.page, 0);
      expect(find.text('Item 0'), findsOneWidget);
      await harness.dispose();
    });
  });

  group('empty and error states', () {
    testWidgets('no results says so, with no clear-filters button when nothing is filtered',
        (tester) async {
      search.handler =
          (criteria, page) async => SearchPage.fromJson(pageJson([], advisory: 'NO_RESULTS_FOUND'));
      await openAt(tester, '/search?q=zzzz');

      expect(find.text('No items found. Try different keywords'), findsOneWidget);
      expect(find.text('Clear filters'), findsNothing);
      await harness.dispose();
    });

    testWidgets('no results with filters offers Clear filters, which searches again without them',
        (tester) async {
      search.handler = (criteria, page) async => criteria.hasFilters
          ? SearchPage.fromJson(pageJson([], advisory: 'NO_RESULTS_FOUND'))
          : SearchPage.fromJson(pageJson([listingJson('l1', title: 'Back again')]));
      await openAt(tester, '/search?q=phone');
      await openFilters(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Maximum price'), '10');
      await apply(tester);

      expect(find.text('No items match your filters. Try fewer filters'), findsOneWidget);
      await tester.tap(find.text('Clear filters'));
      await harness.settle();

      expect(search.calls.last.criteria.hasFilters, isFalse);
      expect(search.calls.last.criteria.query, 'phone');
      expect(find.text('Back again'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('an error shows its message and Retry loads the page again', (tester) async {
      var fail = true;
      search.handler = (criteria, page) async {
        if (fail) {
          throw _coded('ERROR_SEARCH_UNAVAILABLE', status: 503, type: ApiErrorType.server);
        }
        return SearchPage.fromJson(pageJson([listingJson('l1', title: 'Recovered')]));
      };
      await openAt(tester, '/search?q=phone');

      expect(find.text('Search is not available right now. Try again'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Retry'));
      await harness.settle();

      expect(find.text('Recovered'), findsOneWidget);
      expect(find.text('Search is not available right now. Try again'), findsNothing);
      await harness.dispose();
    });

    testWidgets('the rate limit is explained', (tester) async {
      search.handler = (criteria, page) async => throw _coded('RATE_LIMITED', status: 429);
      await openAt(tester, '/search?q=phone');

      expect(find.text('Too many searches. Wait a moment and try again'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a network failure uses the general connection message', (tester) async {
      search.handler = (criteria, page) async => throw _offline;
      await openAt(tester, '/search?q=phone');

      expect(find.text('Unable to connect — Retry'), findsOneWidget);
      await harness.dispose();
    });
  });

  group('filter sheet', () {
    testWidgets('a minimum price above the maximum is shown inline and blocks Apply',
        (tester) async {
      await openAt(tester, '/search?q=phone');
      await openFilters(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Minimum price'), '500');
      await tester.enterText(find.widgetWithText(TextFormField, 'Maximum price'), '100');
      await tester.pump();

      expect(find.text('Minimum price cannot be above maximum price'), findsOneWidget);
      final apply = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Apply'));
      expect(apply.onPressed, isNull);

      await tester.enterText(find.widgetWithText(TextFormField, 'Maximum price'), '900');
      await tester.pump();
      expect(find.text('Minimum price cannot be above maximum price'), findsNothing);
      expect(
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Apply')).onPressed,
        isNotNull,
      );
      await harness.dispose();
    });

    testWidgets('price takes at most two decimals', (tester) async {
      await openAt(tester, '/search?q=phone');
      await openFilters(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Minimum price'), '12.345');
      await tester.pump();

      expect(find.text('12.34'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('applying sends the price, conditions, place and sort and shows the count',
        (tester) async {
      await openAt(tester, '/search?q=phone');
      await openFilters(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Minimum price'), '100.50');
      await tester.enterText(find.widgetWithText(TextFormField, 'Maximum price'), '900');
      await tester.tap(inSheet(find.text('Good')));
      await tester.tap(inSheet(find.text('Like New')));
      await tester.tap(inSheet(find.text('Like New')));
      await tester.tap(inSheet(find.text('Fair')));
      await tester.tap(inSheet(find.text('Newest first')));
      await tester.ensureVisible(find.widgetWithText(TextFormField, 'City'));
      await tester.enterText(find.widgetWithText(TextFormField, 'City'), ' Pune ');
      await tester.pump();
      await apply(tester);

      final criteria = search.calls.last.criteria;
      expect(criteria.priceMin, 100.5);
      expect(criteria.priceMax, 900);
      expect(criteria.conditions, {'GOOD', 'FAIR'});
      expect(criteria.city, 'Pune');
      expect(criteria.sort, SearchSort.newest);
      expect(find.byTooltip('Filters, 3 applied'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('the sheet opens with the current filters and Reset clears them', (tester) async {
      await openAt(tester, '/search?q=phone');
      await openFilters(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Maximum price'), '900');
      await tester.tap(inSheet(find.text('Good')));
      await apply(tester);

      await openFilters(tester);
      expect(find.text('900'), findsOneWidget);
      await tester.tap(find.text('Reset'));
      await tester.pump();
      expect(find.text('900'), findsNothing);
      await apply(tester);

      expect(search.calls.last.criteria.hasFilters, isFalse);
      expect(find.byTooltip('Filters'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('closing the sheet changes nothing', (tester) async {
      await openAt(tester, '/search?q=phone');
      await openFilters(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Maximum price'), '900');

      await tester.tap(find.byTooltip('Close filters'));
      await harness.settle();

      expect(search.calls, hasLength(1));
      expect(find.byType(FilterSheet), findsNothing);
      await harness.dispose();
    });

    testWidgets('the state is chosen from the list and can be cleared', (tester) async {
      await openAt(tester, '/search?q=phone');
      await openFilters(tester);

      await tester.tap(find.text('Select your state'));
      await harness.settle();
      await tester.tap(find.text('Goa'));
      await harness.settle();
      expect(find.byTooltip('Clear state'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear state'));
      await tester.pump();
      expect(find.byTooltip('Clear state'), findsNothing);
      await tester.tap(find.text('Select your state'));
      await harness.settle();
      await tester.tap(find.text('Goa'));
      await harness.settle();
      await apply(tester);

      expect(search.calls.last.criteria.state, 'Goa');
      await harness.dispose();
    });

    testWidgets('the category filters come from the response facets', (tester) async {
      search.handler = (criteria, page) async => SearchPage.fromJson(
            pageJson([listingJson('l1')], facets: List.of(facetsJson)),
          );
      await openAt(tester, '/search?category=CAT-1&categoryName=Smartphones&level=3');
      expect(find.text('Smartphones'), findsWidgets);
      await openFilters(tester);

      expect(find.text('Brand'), findsOneWidget);
      expect(find.text('Apple (41)'), findsOneWidget);
      expect(find.text('Storage'), findsOneWidget);
      expect(find.text('Available: 16 to 512'), findsOneWidget);
      expect(find.text('Dual SIM'), findsOneWidget);

      await tester.ensureVisible(find.text('Apple (41)'));
      await tester.tap(find.text('Apple (41)'));
      await tester.enterText(find.widgetWithText(TextFormField, 'Storage, minimum'), '64');
      await tester.enterText(find.widgetWithText(TextFormField, 'Storage, maximum'), '256');
      await tester.ensureVisible(find.text('Dual SIM'));
      await tester.tap(find.text('Dual SIM'));
      await tester.pump();
      await apply(tester);

      final criteria = search.calls.last.criteria;
      expect(criteria.facets, {'brand': 'apple', 'storage_gb': '64..256', 'dual_sim': 'true'});
      expect(search.calls.last.page, 0);
      expect(find.byTooltip('Filters, 3 applied'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a facet value is picked once and a second tap removes it', (tester) async {
      search.handler = (criteria, page) async => SearchPage.fromJson(
            pageJson([listingJson('l1')], facets: List.of(facetsJson)),
          );
      await openAt(tester, '/search?category=CAT-1&categoryName=Smartphones&level=3');
      await openFilters(tester);

      await tester.ensureVisible(find.text('Apple (41)'));
      await tester.tap(find.text('Apple (41)'));
      await tester.tap(find.text('Samsung (12)'));
      await tester.pump();
      await tester.tap(find.text('Samsung (12)'));
      await tester.pump();
      await tester.tap(find.text('Apple (41)'));
      await tester.ensureVisible(find.text('Dual SIM'));
      await tester.tap(find.text('Dual SIM'));
      await tester.pump();
      await tester.tap(find.text('Dual SIM'));
      await tester.pump();
      await apply(tester);

      expect(search.calls.last.criteria.facets, {'brand': 'apple'});
      await harness.dispose();
    });

    testWidgets('a facet range with the minimum above the maximum is shown inline', (tester) async {
      search.handler = (criteria, page) async => SearchPage.fromJson(
            pageJson([listingJson('l1')], facets: List.of(facetsJson)),
          );
      await openAt(tester, '/search?category=CAT-1&categoryName=Smartphones&level=3');
      await openFilters(tester);

      await tester.ensureVisible(find.widgetWithText(TextFormField, 'Storage, minimum'));
      await tester.enterText(find.widgetWithText(TextFormField, 'Storage, minimum'), '300');
      await tester.enterText(find.widgetWithText(TextFormField, 'Storage, maximum'), '100');
      await tester.pump();

      expect(find.text('Minimum cannot be above maximum'), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Apply')).onPressed,
        isNull,
      );

      await tester.enterText(find.widgetWithText(TextFormField, 'Storage, minimum'), '');
      await tester.enterText(find.widgetWithText(TextFormField, 'Storage, maximum'), '');
      await tester.pump();
      await apply(tester);
      expect(search.calls.last.criteria.facets, isEmpty);
      await harness.dispose();
    });

    testWidgets('the filters of a category are shown with their previous values', (tester) async {
      search.handler = (criteria, page) async => SearchPage.fromJson(
            pageJson([listingJson('l1')], facets: List.of(facetsJson)),
          );
      await openAt(tester, '/search?category=CAT-1&categoryName=Smartphones&level=3');
      await openFilters(tester);
      await tester.ensureVisible(find.widgetWithText(TextFormField, 'Storage, minimum'));
      await tester.enterText(find.widgetWithText(TextFormField, 'Storage, minimum'), '64');
      await apply(tester);

      await openFilters(tester);
      await tester.ensureVisible(find.widgetWithText(TextFormField, 'Storage, minimum'));

      expect(find.text('64'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('an option facet with no buckets is left out', (tester) async {
      search.handler = (criteria, page) async => SearchPage.fromJson(
            pageJson(
              [listingJson('l1')],
              facets: [
                {'key': 'brand', 'label': 'Brand', 'type': 'OPTION', 'buckets': <dynamic>[]},
              ],
            ),
          );
      await openAt(tester, '/search?category=CAT-1&categoryName=Smartphones&level=3');
      await openFilters(tester);

      expect(find.text('Brand'), findsNothing);
      await harness.dispose();
    });
  });

  group('Real Estate', () {
    const realEstateLocation =
        '/search?category=L1-R&categoryName=Real+Estate&level=1&realEstate=true';

    testWidgets('opening a Real Estate category asks Buy, Rent or Lease before any search',
        (tester) async {
      await openAt(tester, realEstateLocation);

      expect(find.byType(IntentSheet), findsOneWidget);
      expect(find.text('Choose Buy, Rent or Lease'), findsOneWidget);
      expect(find.text('Buy'), findsOneWidget);
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Lease'), findsOneWidget);
      expect(search.calls, isEmpty);
      await harness.dispose();
    });

    testWidgets('choosing Rent searches with that intent and shows how to change it',
        (tester) async {
      await openAt(tester, realEstateLocation);

      await tester.tap(find.text('Rent'));
      await harness.settle();

      expect(search.calls.single.criteria.intent, TransactionIntent.rent);
      expect(search.calls.single.criteria.categoryCode, 'L1-R');
      expect(find.byType(IntentSheet), findsNothing);
      expect(find.text('Rent. Change'), findsOneWidget);

      await tester.tap(find.text('Rent. Change'));
      await harness.settle();
      await tester.tap(find.text('Lease'));
      await harness.settle();

      expect(search.calls.last.criteria.intent, TransactionIntent.lease);
      expect(find.text('Lease. Change'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('closing the chooser leaves a prompt that opens it again', (tester) async {
      await openAt(tester, realEstateLocation);

      await tester.tapAt(const Offset(10, 10));
      await harness.settle();

      expect(find.byType(IntentSheet), findsNothing);
      expect(find.text('Choose Buy, Rent or Lease to see properties'), findsOneWidget);
      expect(search.calls, isEmpty);

      await tester.tap(find.text('Choose'));
      await harness.settle();
      expect(find.byType(IntentSheet), findsOneWidget);
      await tester.tap(find.text('Buy'));
      await harness.settle();

      expect(search.calls.single.criteria.intent, TransactionIntent.sale);
      await harness.dispose();
    });

    testWidgets('the server answering ERROR_INTENT_REQUIRED opens the chooser', (tester) async {
      search.handler = (criteria, page) async => criteria.intent == null
          ? throw _coded('ERROR_INTENT_REQUIRED')
          : SearchPage.fromJson(pageJson([listingJson('l1', title: 'Flat for sale')]));
      await openAt(tester, '/search?category=L2-X&categoryName=Flats&level=2');

      expect(find.byType(IntentSheet), findsOneWidget);
      await tester.tap(find.text('Buy'));
      await harness.settle();

      expect(search.calls, hasLength(2));
      expect(search.calls.last.criteria.intent, TransactionIntent.sale);
      expect(find.text('Flat for sale'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('the condition filter is not offered for properties', (tester) async {
      await openAt(
          tester,
          '/search?category=L1-R&categoryName=Real+Estate&level=1&realEstate=true'
          '&intent=SALE');
      await openFilters(tester);

      expect(find.text('Condition'), findsNothing);
      expect(find.text('Price (\u20b9)'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('the chooser is accessible', (tester) async {
      final handle = tester.ensureSemantics();
      await openAt(tester, realEstateLocation);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrast));
      handle.dispose();
      await harness.dispose();
    });
  });

  group('category browsing', () {
    testWidgets('the top level shows popular cards and expands the others inline', (tester) async {
      final handle = tester.ensureSemantics();
      await openAt(tester, '/search/categories');

      expect(find.byType(CategoryBrowseScreen), findsOneWidget);
      expect(tester.getSemantics(find.text('Browse categories')), isSemantics(isHeader: true));
      expect(find.text('Popular categories'), findsOneWidget);
      expect(find.text('Books'), findsNothing);
      await tester.tap(find.text('More categories'));
      await harness.settle();
      final popular = tester.getTopLeft(find.text('Mobiles & Tablets')).dy;
      final others = tester.getTopLeft(find.text('More categories')).dy;
      final book = tester.getTopLeft(find.text('Books')).dy;
      expect(popular, lessThan(others));
      expect(others, lessThan(book));
      await tester.tap(find.text('More categories'));
      await harness.settle();
      expect(find.text('Books'), findsNothing);
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('L1 opens L2, L2 opens L3 and an L3 opens its listings with facets asked for',
        (tester) async {
      await openAt(tester, '/search/categories');

      await tester.tap(find.text('Mobiles & Tablets'));
      await harness.settle();
      expect(find.text('View all in Mobiles & Tablets'), findsOneWidget);
      expect(find.text('Mobile Phones'), findsOneWidget);
      expect(find.text('Tablets'), findsOneWidget);
      expect(find.text('Other groups'), findsNothing);
      expect(tester.getTopLeft(find.text('Mobile Phones')).dy,
          lessThan(tester.getTopLeft(find.text('Tablets')).dy));
      verifyNever(
          () => categories.categoryChildren(parentCode: 'L1-M', scope: CategoryScope.popular));
      verifyNever(
          () => categories.categoryChildren(parentCode: 'L1-M', scope: CategoryScope.others));
      expect(find.byType(CategoryBrowseScreen), findsOneWidget);

      await tester.tap(find.text('Mobile Phones'));
      await harness.settle();
      expect(find.text('Smartphones'), findsOneWidget);
      expect(find.text('Mobiles & Tablets'), findsOneWidget);
      expect(find.text('Mobile Phones'), findsOneWidget);
      expect(search.calls, isEmpty);

      await tester.ensureVisible(find.text('Smartphones'));
      await tester.tap(find.text('Smartphones'));
      await harness.settle();
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(search.calls.single.criteria.categoryCode, 'CAT-1');
      expect(search.calls.single.criteria.categoryLevel, 3);
      expect(find.text('Apple iPhone 14 128GB'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Back'));
      await harness.settle();
      expect(find.text('Smartphones'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('View all opens the listings of a whole L1 category', (tester) async {
      await openAt(tester, '/search/categories');
      await tester.tap(find.text('Mobiles & Tablets'));
      await harness.settle();

      await tester.tap(find.text('View all in Mobiles & Tablets'));
      await harness.settle();

      expect(search.calls.single.criteria.categoryCode, 'L1-M');
      expect(search.calls.single.criteria.categoryLevel, 1);
      expect(search.calls.single.criteria.realEstate, isFalse);
      await harness.dispose();
    });

    testWidgets('Real Estate shows the Buy, Rent or Lease chooser when its listings open',
        (tester) async {
      await openAt(tester, '/search/categories');
      await tester.tap(find.text('Real Estate'));
      await harness.settle();
      expect(find.byType(IntentSheet), findsNothing);

      await tester.tap(find.text('View all in Real Estate'));
      await harness.settle();

      expect(find.byType(IntentSheet), findsOneWidget);
      expect(search.calls, isEmpty);
      await tester.tap(find.text('Lease'));
      await harness.settle();
      expect(search.calls.single.criteria.intent, TransactionIntent.lease);
      expect(search.calls.single.criteria.realEstate, isTrue);
      await harness.dispose();
    });

    testWidgets('a leaf of a Real Estate path asks the intent too', (tester) async {
      when(
        () => categories.categoryChildren(parentCode: 'L2-H', scope: CategoryScope.all),
      ).thenAnswer(
        (_) async => [
          const CategoryNode(code: 'CAT-9', name: 'Villas', level: 3, hasChildren: false),
        ],
      );
      await openAt(tester, '/search/categories');
      await tester.tap(find.text('Real Estate'));
      await harness.settle();
      await tester.tap(find.text('Homes'));
      await harness.settle();

      await tester.ensureVisible(find.text('Villas'));
      await tester.tap(find.text('Villas'));
      await harness.settle();

      expect(find.byType(IntentSheet), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a failure to load a list offers Retry', (tester) async {
      var fail = true;
      when(
        () => categories.categoryChildren(
          parentCode: any(named: 'parentCode'),
          scope: CategoryScope.others,
        ),
      ).thenAnswer((_) async {
        if (fail) throw _offline;
        return [_books];
      });
      await openAt(tester, '/search/categories');
      await tester.tap(find.text('More categories'));
      await harness.settle();

      expect(find.text('Unable to load categories. Try again'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Retry'));
      await harness.settle();

      expect(find.text('Books'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a failure to load the popular categories offers Retry', (tester) async {
      var fail = true;
      when(
        () => categories.categoryChildren(
          parentCode: any(named: 'parentCode'),
          scope: CategoryScope.popular,
        ),
      ).thenAnswer((_) async {
        if (fail) throw _offline;
        return [_mobiles];
      });
      await openAt(tester, '/search/categories');

      fail = false;
      await tester.tap(find.text('Retry'));
      await harness.settle();

      expect(find.text('Mobiles & Tablets'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('Browse all categories reveals remaining roots without navigating', (tester) async {
      await openAt(tester, '/search');

      await tester.tap(find.text('Browse all categories'));
      await harness.settle();

      expect(find.byType(CategoryBrowseScreen), findsNothing);
      expect(find.text('Books'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a popular category on the start page opens its sub-categories', (tester) async {
      await openAt(tester, '/search');

      await tester.tap(find.text('Mobiles & Tablets'));
      await harness.settle();

      expect(find.byType(CategoryBrowseScreen), findsNothing);
      expect(find.text('Mobile Phones'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('only one L1 and L2 stay expanded; groups toggle inline', (tester) async {
      await openAt(tester, '/search');
      await tester.tap(find.text('Mobiles & Tablets'));
      await harness.settle();
      await tester.tap(find.text('Mobile Phones'));
      await harness.settle();
      await tester.ensureVisible(find.text('Tablets'));
      await tester.tap(find.text('Tablets'));
      await harness.settle();
      expect(find.text('Smartphones'), findsNothing);
      expect(find.text('View all'), findsOneWidget);
      expect(find.text('No more categories'), findsOneWidget);
      await tester.ensureVisible(find.text('Real Estate'));
      await tester.tap(find.text('Real Estate'));
      await harness.settle();
      expect(find.text('Mobile Phones'), findsNothing);
      expect(find.text('Homes'), findsOneWidget);
      await tester.tap(find.text('Real Estate'));
      await harness.settle();
      expect(find.text('Homes'), findsNothing);
      await harness.dispose();
    });

    testWidgets('L2 View all keeps the correct result scope', (tester) async {
      await openAt(tester, '/search');
      await tester.tap(find.text('Mobiles & Tablets'));
      await harness.settle();
      await tester.tap(find.text('Mobile Phones'));
      await harness.settle();
      await tester.ensureVisible(find.text('View all'));
      await tester.tap(find.text('View all'));
      await harness.settle();
      expect(search.calls.single.criteria.categoryCode, 'L2-P');
      expect(search.calls.single.criteria.categoryLevel, 2);
      await harness.dispose();
    });

    testWidgets('all L2 groups are available even beyond the popular API limit', (tester) async {
      when(() => categories.categoryChildren(parentCode: 'L1-M', scope: CategoryScope.all))
          .thenAnswer((_) async => [
                for (var index = 0; index < 24; index++)
                  CategoryNode(
                    code: 'GROUP-$index',
                    name: 'Group $index',
                    level: 2,
                    hasChildren: true,
                    popular: index < 12,
                  ),
              ]);
      await openAt(tester, '/search');
      await tester.tap(find.text('Mobiles & Tablets'));
      await harness.settle();
      for (var index = 0; index < 24; index++) {
        expect(find.text('Group $index'), findsOneWidget);
      }
      expect(find.text('Other groups'), findsNothing);
      await tester.ensureVisible(find.text('Group 23'));
      await tester.tap(find.text('Group 23'));
      await harness.settle();
      verify(() => categories.categoryChildren(parentCode: 'GROUP-23', scope: CategoryScope.all))
          .called(1);
      await harness.dispose();
    });

    testWidgets('all leaves appear on expansion and survive search and result navigation',
        (tester) async {
      when(() => categories.categoryChildren(parentCode: 'L2-P', scope: CategoryScope.all))
          .thenAnswer((_) async => [
                _smartphones,
                const CategoryNode(
                    code: 'CAT-2', name: 'Feature Phones', level: 3, hasChildren: false),
                const CategoryNode(
                    code: 'CAT-3', name: 'Foldable Phones', level: 3, hasChildren: false),
                const CategoryNode(
                    code: 'CAT-4', name: 'Rugged Phones', level: 3, hasChildren: false),
              ]);
      await openAt(tester, '/search');
      await tester.tap(find.text('Mobiles & Tablets'));
      await harness.settle();
      await tester.tap(find.text('Mobile Phones'));
      await harness.settle();
      expect(find.text('Rugged Phones'), findsOneWidget);
      expect(find.text('Show more Mobile Phones'), findsNothing);
      expect(find.text('Show less'), findsNothing);
      final firstTile = tester.getTopLeft(find.text('Smartphones'));
      final secondTile = tester.getTopLeft(find.text('Feature Phones'));
      final thirdTile = tester.getTopLeft(find.text('Foldable Phones'));
      expect(secondTile.dy, firstTile.dy);
      expect(thirdTile.dy, firstTile.dy);
      expect(secondTile.dx, greaterThan(firstTile.dx));
      expect(thirdTile.dx, greaterThan(secondTile.dx));
      final target = tester.getSize(
        find.ancestor(of: find.text('Smartphones'), matching: find.byType(InkWell)).first,
      );
      expect(target.width, greaterThanOrEqualTo(48));
      expect(target.height, greaterThanOrEqualTo(48));
      final scroller = find.descendant(
        of: find.byType(CategoryBrowser),
        matching: find.byType(SingleChildScrollView),
      );
      await tester.ensureVisible(find.text('Rugged Phones'));
      final offset = tester.widget<SingleChildScrollView>(scroller).controller!.offset;
      await tester.tap(find.text('Rugged Phones'));
      await harness.settle();
      expect(search.calls.last.criteria.categoryCode, 'CAT-4');
      await tester.tap(find.bySemanticsLabel('Back'));
      await harness.settle();
      expect(find.text('Rugged Phones'), findsOneWidget);
      expect(tester.widget<SingleChildScrollView>(scroller).controller!.offset, offset);
      await type(tester, 'iphone');
      expect(find.text('Rugged Phones'), findsNothing);
      await tester.tap(find.byTooltip('Clear search text'));
      await harness.settle();
      expect(find.text('Rugged Phones'), findsOneWidget);
      await tester.ensureVisible(find.text('Mobile Phones'));
      await tester.tap(find.text('Mobile Phones'));
      await harness.settle();
      expect(find.text('Rugged Phones'), findsNothing);
      await harness.dispose();
    });

    testWidgets('parent deep links expand inline and Browse all restores the full tree',
        (tester) async {
      await openAt(tester, '/search/categories?parent=L2-P&name=Mobile+Phones&level=2');
      expect(find.text('Mobile Phones'), findsOneWidget);
      expect(find.text('Smartphones'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      await tester.tap(find.text('Browse all categories'));
      await harness.settle();
      expect(find.text('Mobiles & Tablets'), findsOneWidget);
      expect(find.text('Mobile Phones'), findsNothing);
      expect(find.text('Books'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('child loading and failure leave the parent usable with Retry', (tester) async {
      final pending = Completer<List<CategoryNode>>();
      when(() => categories.categoryChildren(parentCode: 'L1-M', scope: CategoryScope.all))
          .thenAnswer((_) => pending.future);
      await openAt(tester, '/search');
      await tester.tap(find.text('Mobiles & Tablets'));
      await harness.settle();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.completeError(_offline);
      await harness.settle();
      expect(find.text('View all in Mobiles & Tablets'), findsOneWidget);
      expect(find.text('Unable to load categories. Try again'), findsOneWidget);
      when(() => categories.categoryChildren(parentCode: 'L1-M', scope: CategoryScope.all))
          .thenAnswer((_) async => [_phones]);
      await tester.ensureVisible(find.text('Retry'));
      await tester.tap(find.text('Retry'));
      await harness.settle();
      expect(find.text('Mobile Phones'), findsOneWidget);
      await harness.dispose();
    });
  });

  group('Home wiring', () {
    testWidgets('the Home search bar opens search and Back returns to Home', (tester) async {
      await openAt(tester, '/home');

      await tester.tap(find.text('Search here ...'));
      await harness.settle();

      expect(find.byType(SearchScreen), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back'));
      await harness.settle();
      expect(find.text('Featured Deals Near You'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('the Search item of the bottom navigation opens search, and Home returns',
        (tester) async {
      await openAt(tester, '/home');

      await tester.tap(find.text('Search'));
      await harness.settle();
      expect(find.byType(SearchScreen), findsOneWidget);

      await tester.tap(find.text('Home'));
      await harness.settle();
      expect(find.text('Featured Deals Near You'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a Home category tile opens its taxonomy branch without a keyword search',
        (tester) async {
      await openAt(tester, '/home');

      await tester.tap(find.text('Mobiles & Tablets'));
      await harness.settle();

      expect(find.byType(SearchScreen), findsOneWidget);
      expect(tester.widget<SearchScreen>(find.byType(SearchScreen)).browseParent?.code, 'L1-M');
      expect(find.text('Mobile Phones'), findsOneWidget);
      expect(search.calls, isEmpty);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
      await harness.dispose();
    });

    testWidgets('See All browses everything, ranked for the same place', (tester) async {
      await openAt(tester, '/home');

      await tester.tap(find.text('See All'));
      await harness.settle();

      expect(find.byType(SearchScreen), findsOneWidget);
      expect(search.calls.single.criteria.browseAll, isTrue);
      expect(search.calls.single.nearCity, 'Mumbai');
      await harness.dispose();
    });

    testWidgets('More lists all taxonomy roots and opens their branch', (tester) async {
      await openAt(tester, '/home');

      await tester.tap(find.text('More'));
      await harness.settle();
      await tester.tap(find.text('Books'));
      await harness.settle();

      expect(find.byType(SearchScreen), findsOneWidget);
      expect(tester.widget<SearchScreen>(find.byType(SearchScreen)).browseParent?.code, 'L1-B');
      expect(search.calls, isEmpty);
      verify(() => categories.categoryChildren(parentCode: 'L1-B', scope: CategoryScope.all))
          .called(1);
      await harness.dispose();
    });

    testWidgets('a signed-out visitor is sent to sign in', (tester) async {
      await openAt(tester, '/home', signedIn: false);

      await tester.tap(find.text('Search here ...'));
      await harness.settle();

      expect(find.byType(SearchScreen), findsNothing);
      expect(find.byType(SignInMobileScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('Home cards without a condition or price still show', (tester) async {
      await openAt(tester, '/search?q=flat');

      expect(find.text('Studio flat'), findsOneWidget);
      expect(find.text('Good'), findsNWidgets(2));
      await harness.dispose();
    });
  });

  group('languages and text size', () {
    for (final language in const ['en', 'hi']) {
      testWidgets('expanded categories reflow without overflow at 200% text in $language',
          (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        tester.platformDispatcher.localesTestValue = [Locale(language)];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        when(() => categories.categoryChildren(parentCode: 'L2-P', scope: CategoryScope.all))
            .thenAnswer((_) async => [
                  _smartphones,
                  const CategoryNode(
                    code: 'CAT-2',
                    name: 'Feature Phones',
                    level: 3,
                    hasChildren: false,
                  ),
                ]);
        await openAt(tester, '/search/categories?parent=L1-M&name=Mobiles+%26+Tablets&level=1');
        tester.view.physicalSize = const Size(640, 1280);
        tester.view.devicePixelRatio = 2;
        await harness.settle();
        await tester.ensureVisible(find.text('Mobile Phones'));
        await tester.tap(find.text('Mobile Phones'));
        await harness.settle();
        await tester.ensureVisible(find.text('Smartphones'));
        expect(find.byType(CategoryLeafGrid), findsOneWidget);
        final firstTile = tester.getTopLeft(
          find.ancestor(of: find.text('Smartphones'), matching: find.byType(InkWell)).first,
        );
        final secondTile = tester.getTopLeft(
          find.ancestor(of: find.text('Feature Phones'), matching: find.byType(InkWell)).first,
        );
        expect(secondTile.dy, greaterThan(firstTile.dy));
        expect(secondTile.dx, firstTile.dx);
        expect(tester.takeException(), isNull);
        await harness.dispose();
      });

      testWidgets('search, filters and results fit a small screen at 200% text in $language',
          (tester) async {
        final locale = Locale(language);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        tester.platformDispatcher.localesTestValue = [locale];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        search.handler = (criteria, page) async => SearchPage.fromJson(
              pageJson(
                [listingJson('l1', qualifier: 'STARTING_FROM', badge: 'FEATURED', cardUrl: null)],
                facets: List.of(facetsJson),
              ),
            );
        await openAt(tester, '/search?category=CAT-1&categoryName=Smartphones&level=3');
        tester.view.physicalSize = const Size(640, 1280);
        tester.view.devicePixelRatio = 2;
        await harness.settle();

        expect(tester.takeException(), isNull);
        await tester.tap(find.byIcon(Icons.tune_rounded));
        await harness.settle();
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -2000));
        await harness.settle();
        expect(tester.takeException(), isNull);
        await harness.dispose();
      });
    }

    testWidgets('the screen is in Hindi when the language is Hindi', (tester) async {
      tester.platformDispatcher.localesTestValue = [const Locale('hi')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await openAt(tester, '/search');

      expect(find.text('वस्तुएँ खोजें'), findsWidgets);
      expect(find.text('लोकप्रिय श्रेणियाँ'), findsOneWidget);
      expect(find.text('Popular categories'), findsNothing);
      await harness.dispose();
    });
  });

  group('accessibility', () {
    final guidelines = <String, AccessibilityGuideline>{
      'android tap target (48 dp)': androidTapTargetGuideline,
      'ios tap target (44 pt)': iOSTapTargetGuideline,
      'labelled tap targets': labeledTapTargetGuideline,
      'text contrast (4.5:1)': textContrast,
    };

    for (final entry in guidelines.entries) {
      testWidgets('results, no-results, error and the filter sheet pass ${entry.key}',
          (tester) async {
        final handle = tester.ensureSemantics();
        search.handler = (criteria, page) async => SearchPage.fromJson(
              pageJson(
                [listingJson('l1', qualifier: 'STARTING_FROM', badge: 'FEATURED', cardUrl: null)],
                facets: List.of(facetsJson),
              ),
            );
        await openAt(tester, '/search?category=CAT-1&categoryName=Smartphones&level=3');
        await expectLater(tester, meetsGuideline(entry.value));

        await openFilters(tester);
        await expectLater(tester, meetsGuideline(entry.value));
        await tester.tap(find.byTooltip('Close filters'));
        await harness.settle();

        search.handler = (criteria, page) async =>
            SearchPage.fromJson(pageJson([], advisory: 'NO_RESULTS_FOUND'));
        await type(tester, 'zzz');
        await expectLater(tester, meetsGuideline(entry.value));

        search.handler = (criteria, page) async => throw _offline;
        await type(tester, 'zzzz');
        await expectLater(tester, meetsGuideline(entry.value));
        handle.dispose();
        await harness.dispose();
      });
    }

    testWidgets('the category browser passes the tap target and label guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await openAt(tester, '/search/categories?parent=L1-M&name=Mobiles+%26+Tablets&level=1');

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrast));
      await tester.tap(find.text('Mobile Phones'));
      await harness.settle();
      await tester.ensureVisible(find.text('Smartphones'));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
      await harness.dispose();
    });
  });
}
