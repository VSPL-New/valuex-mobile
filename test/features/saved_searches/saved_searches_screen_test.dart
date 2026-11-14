import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/auth/data/models/auth_models.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/home/data/mock_home_repository.dart';
import 'package:valuex_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:valuex_mobile/features/listing/data/listing_repository.dart';
import 'package:valuex_mobile/features/listing/domain/category.dart';
import 'package:valuex_mobile/features/notifications/data/notifications_repository.dart';
import 'package:valuex_mobile/features/profile/data/profile_repository.dart';
import 'package:valuex_mobile/features/profile/domain/profile_menu_badges.dart';
import 'package:valuex_mobile/features/saved_searches/data/saved_searches_repository.dart';
import 'package:valuex_mobile/features/saved_searches/domain/saved_search.dart';
import 'package:valuex_mobile/features/saved_searches/presentation/providers/saved_searches_controller.dart';
import 'package:valuex_mobile/features/saved_searches/presentation/saved_search_results_screen.dart';
import 'package:valuex_mobile/features/saved_searches/presentation/saved_searches_screen.dart';
import 'package:valuex_mobile/features/saved_searches/presentation/widgets/save_search_button.dart';
import 'package:valuex_mobile/features/search/data/search_repository.dart';
import 'package:valuex_mobile/features/search/domain/search_criteria.dart';
import 'package:valuex_mobile/features/search/domain/search_page.dart';
import 'package:valuex_mobile/features/search/domain/transaction_intent.dart';
import 'package:valuex_mobile/features/search/presentation/search_screen.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/app_harness.dart';
import '../../helpers/fonts.dart';
import '../search/search_fixtures.dart';
import 'saved_search_fixtures.dart';

class _MockListingRepository extends Mock implements ListingRepository {}

class _MockNotifications extends Mock implements NotificationsRepository {}

class _MockProfileRepository extends Mock implements ProfileRepository {}

const _offline = ApiError(type: ApiErrorType.network, message: 'offline');

SavedSearch _search(
  String id, {
  String name = 'Phones in Pune',
  bool alerts = true,
  bool valid = true,
  Map<String, dynamic>? criteria,
}) =>
    SavedSearch.fromJson(
      savedSearchJson(id, name: name, alerts: alerts, valid: valid, criteria: criteria),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(CategoryScope.all);
    loadBrandFonts();
  });

  late FakeSavedSearchesRepository saved;
  late FakeSearchRepository search;
  late AppHarness harness;

  setUp(() {
    saved = FakeSavedSearchesRepository();
    saved.onList = () async => [
          _search('s1'),
          _search('s2', name: 'Cheap chairs', alerts: false, criteria: {'query': 'chair'}),
        ];
    search = FakeSearchRepository(
      (criteria, page) async => SearchPage.fromJson(
          pageJson([listingJson('l1', title: 'Apple iPhone 14', cardUrl: null)])),
    );
  });

  Future<AppHarness> openAt(WidgetTester tester, String location, {bool signedIn = true}) async {
    final notifications = _MockNotifications();
    when(notifications.unreadCount).thenAnswer((_) async => 0);
    final categories = _MockListingRepository();
    when(
      () => categories.categoryChildren(
        parentCode: any(named: 'parentCode'),
        scope: any(named: 'scope'),
      ),
    ).thenAnswer((_) async => <CategoryNode>[]);
    final profile = _MockProfileRepository();
    when(() => profile.fetch()).thenAnswer(
      (_) async => UserProfileModel.fromJson(const {
        'userId': 'user-1',
        'status': 'ACTIVE',
        'aadhaarVerified': true,
        'displayName': 'Abhay Kumar',
        'mobile': '90XXXX0010',
        'email': 'a***@gmail.com',
        'avatarId': 'avatar-02',
        'memberSince': '2026-08-07T12:00:00Z',
        'gender': 'MALE',
      }).toEntity(),
    );
    when(profile.menuBadges).thenAnswer((_) async => const ProfileMenuBadges());
    harness = AppHarness(
      tester,
      extraOverrides: [
        homeRepositoryProvider.overrideWithValue(const MockHomeRepository()),
        searchRepositoryProvider.overrideWithValue(search),
        savedSearchesRepositoryProvider.overrideWithValue(saved),
        listingRepositoryProvider.overrideWithValue(categories),
        notificationsRepositoryProvider.overrideWithValue(notifications),
        profileRepositoryProvider.overrideWithValue(profile),
      ],
    );
    if (signedIn) harness.signedInAs(AccountStatus.active);
    await harness.launch(location: location);
    return harness;
  }

  group('list', () {
    testWidgets('shows every search with a readable summary and the alert switch (AC3)',
        (tester) async {
      final handle = tester.ensureSemantics();
      await openAt(tester, RouteNames.savedSearches);

      expect(find.byType(SavedSearchesScreen), findsOneWidget);
      expect(tester.getSemantics(find.text('Saved searches').first), isSemantics(isHeader: true));
      expect(find.text('Phones in Pune'), findsOneWidget);
      expect(
        find.text(
          'iphone · Smartphones · ₹100 – ₹900.50 · Good · New · Pune · Maharashtra · 2 filters',
        ),
        findsOneWidget,
      );
      expect(find.text('Cheap chairs'), findsOneWidget);
      expect(find.text('chair · Smartphones'), findsOneWidget);
      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches.map((s) => s.value), [true, false]);
      expect(
        tester.getSemantics(find.byType(Switch).first).label,
        contains('Alerts for Phones in Pune'),
      );
      expect(find.byTooltip('Delete saved search Cheap chairs'), findsOneWidget);
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('an empty account explains how to save a search', (tester) async {
      saved.onList = () async => const [];
      await openAt(tester, RouteNames.savedSearches);

      expect(find.text('No saved searches yet'), findsOneWidget);
      expect(find.textContaining('tap Save search'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a failed load shows an error with Retry', (tester) async {
      var fail = true;
      saved.onList = () async {
        if (fail) throw _offline;
        return [_search('s1')];
      };
      await openAt(tester, RouteNames.savedSearches);

      expect(find.text('Unable to load your saved searches. Try again'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Retry'));
      await harness.settle();

      expect(find.text('Phones in Pune'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('pull to refresh loads the list again', (tester) async {
      await openAt(tester, RouteNames.savedSearches);
      expect(saved.listCalls, 1);

      await tester.fling(find.text('Phones in Pune'), const Offset(0, 400), 1000);
      await harness.settle();
      await tester.pump(const Duration(seconds: 1));

      expect(saved.listCalls, 2);
      await harness.dispose();
    });

    testWidgets('the switch changes alerts and puts itself back when the server refuses (AC4)',
        (tester) async {
      saved.onSetAlerts = (id, enabled) async => _search(id, alerts: enabled);
      await openAt(tester, RouteNames.savedSearches);

      await tester.tap(find.byType(Switch).first);
      await harness.settle();
      expect(saved.alertCalls, [('s1', false)]);
      expect(tester.widgetList<Switch>(find.byType(Switch)).first.value, isFalse);

      saved.onSetAlerts = (id, enabled) async => throw _offline;
      await tester.tap(find.byType(Switch).first);
      await harness.settle();
      expect(find.text('Unable to change alerts. Try again'), findsOneWidget);
      expect(tester.widgetList<Switch>(find.byType(Switch)).first.value, isFalse);
      await harness.dispose();
    });

    testWidgets('delete hides the search, offers Undo and sends the request after the window (AC4)',
        (tester) async {
      await openAt(tester, RouteNames.savedSearches);

      await tester.tap(find.byTooltip('Delete saved search Cheap chairs'));
      await harness.settle();

      expect(find.text('Cheap chairs'), findsNothing);
      expect(find.text('Saved search deleted'), findsOneWidget);
      expect(saved.deleted, isEmpty);
      await tester.pump(SavedSearchesController.undoWindow + const Duration(seconds: 1));
      expect(saved.deleted, ['s2']);
      await harness.dispose();
    });

    testWidgets('Undo brings the search back and nothing is deleted', (tester) async {
      await openAt(tester, RouteNames.savedSearches);

      await tester.tap(find.byTooltip('Delete saved search Cheap chairs'));
      await harness.settle();
      await tester.tap(find.text('Undo'));
      await harness.settle();
      await tester.pump(SavedSearchesController.undoWindow + const Duration(seconds: 1));

      expect(find.text('Cheap chairs'), findsOneWidget);
      expect(saved.deleted, isEmpty);
      await harness.dispose();
    });

    testWidgets('a delete the server refuses puts the search back and says so', (tester) async {
      saved.onDelete = (id) async => throw _offline;
      await openAt(tester, RouteNames.savedSearches);

      await tester.tap(find.byTooltip('Delete saved search Cheap chairs'));
      await harness.settle();
      await tester.pump(SavedSearchesController.undoWindow + const Duration(seconds: 1));
      await harness.settle();

      expect(find.text('Cheap chairs'), findsOneWidget);
      expect(find.text('Unable to delete the saved search. It was put back'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('an invalid search shows the error and can only be deleted', (tester) async {
      saved.onList = () async => [_search('s1', valid: false), _search('s2', name: 'Fine')];
      await openAt(tester, RouteNames.savedSearches);

      expect(find.text('Search criteria no longer valid'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.byTooltip('Delete saved search Phones in Pune'), findsOneWidget);
      await tester.tap(find.text('Phones in Pune'));
      await harness.settle();
      expect(find.byType(SavedSearchesScreen), findsOneWidget);
      expect(search.calls, isEmpty);
      await harness.dispose();
    });

    testWidgets('tapping a search opens its results with every saved filter', (tester) async {
      await openAt(tester, RouteNames.savedSearches);

      await tester.tap(find.text('Phones in Pune'));
      await harness.settle();

      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.text('Apple iPhone 14'), findsOneWidget);
      final criteria = search.calls.first.criteria;
      expect(criteria.query, 'iphone');
      expect(criteria.categoryCode, 'CAT-1');
      expect(criteria.facets, {'brand': 'apple', 'storage_gb': '32..128'});
      expect(criteria.priceMin, 100);
      expect(criteria.priceMax, 900.5);
      expect(criteria.conditions, {'GOOD', 'NEW'});
      expect(criteria.city, 'Pune');
      expect(criteria.state, 'Maharashtra');
      await harness.dispose();
    });

    testWidgets('Profile has a Saved searches row that opens the list', (tester) async {
      await openAt(tester, RouteNames.profile);

      await tester.tap(find.text('Saved searches'));
      await harness.settle();

      expect(find.byType(SavedSearchesScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('passes the tap target, label and contrast guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      saved.onList = () async => [_search('s1'), _search('s2', valid: false, name: 'Broken')];
      await openAt(tester, RouteNames.savedSearches);

      for (final guideline in [
        androidTapTargetGuideline,
        iOSTapTargetGuideline,
        labeledTapTargetGuideline,
        textContrast,
      ]) {
        await expectLater(tester, meetsGuideline(guideline));
      }
      handle.dispose();
      await harness.dispose();
    });

    for (final language in const ['en', 'hi']) {
      testWidgets('reflows without overflow at 200% text in $language', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        tester.platformDispatcher.localesTestValue = [Locale(language)];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        saved.onList = () async => [
              _search('s1', name: 'A very long saved search name for phones in Pune'),
              _search('s2', valid: false, name: 'Broken'),
            ];
        await openAt(tester, RouteNames.savedSearches);
        tester.view.physicalSize = const Size(640, 1280);
        tester.view.devicePixelRatio = 2;
        await harness.settle();

        expect(find.byType(SavedSearchesScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await harness.dispose();
      });
    }

    testWidgets('shows Hindi text when the language is Hindi', (tester) async {
      tester.platformDispatcher.localesTestValue = [const Locale('hi')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await openAt(tester, RouteNames.savedSearches);

      expect(find.text('सहेजी गई खोजें'), findsOneWidget);
      expect(find.text('सूचनाएँ'), findsNWidgets(2));
      expect(find.textContaining('₹100 – ₹900.50'), findsOneWidget);
      expect(find.textContaining('2 फ़िल्टर'), findsOneWidget);
      await harness.dispose();
    });
  });

  group('results of one saved search', () {
    testWidgets('open it by id from a link or an alert', (tester) async {
      await openAt(tester, '${RouteNames.savedSearches}?id=s2');

      expect(find.byType(SavedSearchResultsScreen), findsOneWidget);
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(search.calls.first.criteria.query, 'chair');
      await harness.dispose();
    });

    testWidgets('a deleted search says so and leads to the list', (tester) async {
      await openAt(tester, '${RouteNames.savedSearches}?id=gone');

      expect(find.text('This saved search no longer exists'), findsOneWidget);
      expect(search.calls, isEmpty);
      await tester.tap(find.text('View saved searches'));
      await harness.settle();
      expect(find.byType(SavedSearchesScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a search that is no longer valid shows the message, not results', (tester) async {
      saved.onList = () async => [_search('s1', valid: false)];
      await openAt(tester, '${RouteNames.savedSearches}?id=s1');

      expect(find.text('Search criteria no longer valid'), findsOneWidget);
      expect(find.byType(SearchScreen), findsNothing);
      await harness.dispose();
    });

    testWidgets('a failed load can be retried', (tester) async {
      var fail = true;
      saved.onList = () async {
        if (fail) throw _offline;
        return [_search('s1')];
      };
      await openAt(tester, '${RouteNames.savedSearches}?id=s1');

      expect(find.text('Unable to load your saved searches. Try again'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Retry'));
      await harness.settle();

      expect(find.byType(SearchScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('waits with a spinner while the list loads', (tester) async {
      final gate = Completer<List<SavedSearch>>();
      saved.onList = () => gate.future;
      await openAt(tester, '${RouteNames.savedSearches}?id=s1');

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      gate.complete([_search('s1')]);
      await harness.settle();
      expect(find.byType(SearchScreen), findsOneWidget);
      await harness.dispose();
    });
  });

  group('Save search button on the Search screen (AC1)', () {
    testWidgets('saves the criteria on screen and says so', (tester) async {
      saved.onCreate = (c) async => SaveResult(_search('n'), alreadySaved: false);
      await openAt(tester, '/search?q=chair&category=CAT-1&categoryName=Smartphones&level=3');

      await tester.tap(find.text('Save search'));
      await harness.settle();

      expect(saved.created.single.query, 'chair');
      expect(saved.created.single.categoryCode, 'CAT-1');
      expect(
        find.text('Search saved. You will get a daily alert about new items'),
        findsOneWidget,
      );
      await harness.dispose();
    });

    testWidgets('says Already saved when the server returns the existing search', (tester) async {
      saved.onCreate = (c) async => SaveResult(_search('n'), alreadySaved: true);
      await openAt(tester, '/search?q=chair');

      await tester.tap(find.text('Save search'));
      await harness.settle();

      expect(find.text('Already saved'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('shows the limit message with the allowed number', (tester) async {
      saved.onCreate = (c) async => throw const SavedSearchLimitReached(10);
      await openAt(tester, '/search?q=chair');

      await tester.tap(find.text('Save search'));
      await harness.settle();

      expect(find.text('Maximum 10 saved searches allowed'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('says when the search could not be saved', (tester) async {
      saved.onCreate = (c) async => throw _offline;
      await openAt(tester, '/search?q=chair');

      await tester.tap(find.text('Save search'));
      await harness.settle();

      expect(find.text('Unable to save this search. Try again'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('the Saved searches link opens the list', (tester) async {
      await openAt(tester, '/search?q=chair');

      await tester.tap(find.text('Saved searches'));
      await harness.settle();

      expect(find.byType(SavedSearchesScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a signed out visitor sees no save button', (tester) async {
      await openAt(tester, '/search', signedIn: false);

      expect(find.text('Save search'), findsNothing);
      await harness.dispose();
    });

    testWidgets('is disabled with nothing to save and for Real Estate without Buy, Rent or Lease',
        (tester) async {
      Future<void> pumpButton(SearchCriteria criteria) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [savedSearchesRepositoryProvider.overrideWithValue(saved)],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SaveSearchButton(criteria: criteria)),
            ),
          ),
        );
      }

      bool enabled() => tester.widget<TextButton>(find.byType(TextButton)).onPressed != null;

      await pumpButton(const SearchCriteria());
      expect(enabled(), isFalse);
      await pumpButton(const SearchCriteria(query: 'chair'));
      expect(enabled(), isTrue);
      await pumpButton(const SearchCriteria(categoryCode: 'L1-R', realEstate: true));
      expect(enabled(), isFalse);
      saved.onCreate = (c) async => SaveResult(_search('n'), alreadySaved: false);
      await pumpButton(
        const SearchCriteria(
          categoryCode: 'L1-R',
          realEstate: true,
          intent: TransactionIntent.rent,
          priceMax: 900,
        ),
      );
      expect(enabled(), isTrue);
      await tester.tap(find.byType(TextButton));
      await tester.pump();
      expect(saved.created.single.intent, TransactionIntent.rent);
      expect(saved.created.single.priceMax, 900);
    });

    testWidgets('is disabled while a save is running', (tester) async {
      final gate = Completer<SaveResult>();
      saved.onCreate = (c) => gate.future;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [savedSearchesRepositoryProvider.overrideWithValue(saved)],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: SaveSearchButton(criteria: SearchCriteria(query: 'chair'))),
          ),
        ),
      );

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(tester.widget<TextButton>(find.byType(TextButton)).onPressed, isNull);
      gate.complete(SaveResult(_search('n'), alreadySaved: false));
      await tester.pump();
      expect(tester.widget<TextButton>(find.byType(TextButton)).onPressed, isNotNull);
      expect(saved.created, hasLength(1));
    });
  });
}
