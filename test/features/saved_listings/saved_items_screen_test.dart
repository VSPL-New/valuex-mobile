import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/core/widgets/square_back_button.dart';
import 'package:valuex_mobile/features/auth/data/models/auth_models.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/home/data/mock_home_repository.dart';
import 'package:valuex_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:valuex_mobile/features/listing/data/listing_repository.dart';
import 'package:valuex_mobile/features/listing/domain/category.dart';
import 'package:valuex_mobile/features/notifications/data/notifications_repository.dart';
import 'package:valuex_mobile/features/profile/data/profile_repository.dart';
import 'package:valuex_mobile/features/profile/domain/profile_menu_badges.dart';
import 'package:valuex_mobile/features/saved_listings/data/saved_listings_repository.dart';
import 'package:valuex_mobile/features/saved_listings/domain/saved_listing.dart';
import 'package:valuex_mobile/features/saved_listings/presentation/saved_items_screen.dart';
import 'package:valuex_mobile/features/search/data/search_repository.dart';
import 'package:valuex_mobile/features/search/domain/search_page.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/app_harness.dart';
import '../../helpers/fonts.dart';
import '../search/search_fixtures.dart';
import 'saved_listings_fixtures.dart';

class _MockListingRepository extends Mock implements ListingRepository {}

class _MockNotifications extends Mock implements NotificationsRepository {}

class _MockProfileRepository extends Mock implements ProfileRepository {}

const _offline = ApiError(type: ApiErrorType.network, message: 'offline');

void main() {
  setUpAll(() {
    registerFallbackValue(CategoryScope.all);
    loadBrandFonts();
  });

  late FakeSavedListingsRepository saved;
  late FakeSearchRepository search;
  late AppHarness harness;

  setUp(() {
    saved = FakeSavedListingsRepository();
    saved.onList = (page) async => savedPage([
          savedListingJson('l1', title: 'Apple iPhone 14'),
          savedListingJson('l2', title: 'Old sofa', available: false, reason: 'SOLD'),
          savedListingJson('l3', title: 'Dining table', available: false, reason: 'UNDER_REVIEW'),
        ]);
    search = FakeSearchRepository(
      (criteria, page) async => SearchPage.fromJson(
        pageJson([
          listingJson('l1', title: 'Apple iPhone 14', cardUrl: null),
          listingJson('l9', title: 'Wooden chair', cardUrl: null),
        ]),
      ),
    );
  });

  Future<AppHarness> openAt(WidgetTester tester, String location) async {
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
        savedListingsRepositoryProvider.overrideWithValue(saved),
        listingRepositoryProvider.overrideWithValue(categories),
        notificationsRepositoryProvider.overrideWithValue(notifications),
        profileRepositoryProvider.overrideWithValue(profile),
      ],
    );
    harness.signedInAs(AccountStatus.active);
    await harness.launch(location: location);
    return harness;
  }

  group('Saved Items list', () {
    testWidgets('shows available, sold and under-review items differently (AC2, AC3)',
        (tester) async {
      final handle = tester.ensureSemantics();
      await openAt(tester, RouteNames.savedItems);

      expect(find.byType(SavedItemsScreen), findsOneWidget);
      expect(tester.getSemantics(find.text('Saved items').first), isSemantics(isHeader: true));
      expect(find.text('Apple iPhone 14'), findsOneWidget);
      expect(find.text('Old sofa'), findsOneWidget);
      expect(find.text('Dining table'), findsOneWidget);
      expect(find.text('No longer available'), findsOneWidget);
      expect(find.text('Under review'), findsOneWidget);
      expect(find.text('Remove from saved'), findsNWidgets(3));
      // Add to cart is disabled until Sprint 5, and only offered for an available item.
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed, isNull);
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('shows the price and condition of an available item', (tester) async {
      await openAt(tester, RouteNames.savedItems);

      expect(find.textContaining('42,000'), findsWidgets);
      expect(find.text('Like New'), findsWidgets);
      await harness.dispose();
    });

    testWidgets('an empty list explains how to save an item', (tester) async {
      saved.onList = (page) async => savedPage(const []);
      await openAt(tester, RouteNames.savedItems);

      expect(find.text('No saved items yet'), findsOneWidget);
      expect(find.textContaining('Tap the heart'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a failed load shows an error with Retry', (tester) async {
      var fail = true;
      saved.onList = (page) async {
        if (fail) throw _offline;
        return savedPage([savedListingJson('l1')]);
      };
      await openAt(tester, RouteNames.savedItems);

      expect(find.text('Unable to load your saved items. Try again'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Retry'));
      await harness.settle();

      expect(find.text('Apple iPhone 14'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('waits with a spinner while the list loads', (tester) async {
      final gate = Completer<SavedListingsPage>();
      saved.onList = (page) => gate.future;
      await openAt(tester, RouteNames.savedItems);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      gate.complete(savedPage([savedListingJson('l1')]));
      await harness.settle();
      expect(find.text('Apple iPhone 14'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('pull to refresh loads the list again', (tester) async {
      await openAt(tester, RouteNames.savedItems);
      expect(saved.listed, [0]);

      await tester.fling(find.text('Apple iPhone 14'), const Offset(0, 400), 1000);
      await harness.settle();
      await tester.pump(const Duration(seconds: 1));

      expect(saved.listed.length, 2);
      await harness.dispose();
    });

    testWidgets('loads the next page when the buyer scrolls to the end', (tester) async {
      saved.onList = (page) async => page == 0
          ? savedPage(
              [for (var i = 0; i < 20; i++) savedListingJson('a$i', title: 'Item $i')],
              hasNext: true,
              total: 21,
            )
          : savedPage([savedListingJson('z1', title: 'Last item')], page: 1, total: 21);
      await openAt(tester, RouteNames.savedItems);

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -20000));
      await harness.settle();

      expect(saved.listed, [0, 1]);
      await harness.dispose();
    });

    testWidgets('a page that fails to load says so', (tester) async {
      saved.onList = (page) async => page == 0
          ? savedPage(
              [for (var i = 0; i < 20; i++) savedListingJson('a$i', title: 'Item $i')],
              hasNext: true,
              total: 21,
            )
          : throw _offline;
      await openAt(tester, RouteNames.savedItems);

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -20000));
      await harness.settle();

      expect(find.text('Unable to load more items. Try again'), findsOneWidget);
      await harness.dispose();
    });
  });

  group('removing', () {
    testWidgets('Remove takes the item off the list and tells the server (AC2)', (tester) async {
      await openAt(tester, RouteNames.savedItems);

      await tester.tap(find.text('Remove from saved').first);
      await harness.settle();

      expect(find.text('Apple iPhone 14'), findsNothing);
      expect(find.text('Old sofa'), findsOneWidget);
      expect(saved.removed, ['l1']);
      await harness.dispose();
    });

    testWidgets('an unavailable item can be removed too', (tester) async {
      await openAt(tester, RouteNames.savedItems);

      await tester.tap(find.text('Remove from saved').at(1));
      await harness.settle();

      expect(find.text('Old sofa'), findsNothing);
      expect(saved.removed, ['l2']);
      await harness.dispose();
    });

    testWidgets('a removal the server refuses puts the item back and says so', (tester) async {
      saved.onRemove = (id) async => throw _offline;
      await openAt(tester, RouteNames.savedItems);

      await tester.tap(find.text('Remove from saved').first);
      await harness.settle();

      expect(find.text('Apple iPhone 14'), findsOneWidget);
      expect(find.text('Unable to remove this item. Try again'), findsOneWidget);
      await harness.dispose();
    });
  });

  group('navigation', () {
    testWidgets('Profile has a Saved items row that opens the list', (tester) async {
      await openAt(tester, RouteNames.profile);

      await tester.tap(find.text('Saved Items'));
      await harness.settle();

      expect(find.byType(SavedItemsScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('the back button returns to Profile when there is nothing to pop', (tester) async {
      await openAt(tester, RouteNames.savedItems);

      await tester.tap(find.byType(SquareBackButton));
      await harness.settle();

      expect(find.byType(SavedItemsScreen), findsNothing);
      await harness.dispose();
    });
  });

  group('accessibility and language', () {
    testWidgets('passes the tap target, label and contrast guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await openAt(tester, RouteNames.savedItems);

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
        saved.onList = (page) async => savedPage([
              savedListingJson('l1', title: 'A very long saved listing title for a phone in Pune'),
              savedListingJson('l2', available: false, reason: 'EXPIRED'),
            ]);
        await openAt(tester, RouteNames.savedItems);
        tester.view.physicalSize = const Size(640, 1280);
        tester.view.devicePixelRatio = 2;
        await harness.settle();

        expect(find.byType(SavedItemsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await harness.dispose();
      });
    }

    testWidgets('shows Hindi text when the language is Hindi', (tester) async {
      tester.platformDispatcher.localesTestValue = [const Locale('hi')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await openAt(tester, RouteNames.savedItems);

      expect(find.text('सहेजे हुए आइटम'), findsOneWidget);
      expect(find.text('अब उपलब्ध नहीं है'), findsOneWidget);
      expect(find.text('समीक्षा में है'), findsOneWidget);
      await harness.dispose();
    });
  });

  group('the heart on search results (AC1)', () {
    testWidgets('saves a listing at once and shows the heart filled', (tester) async {
      final handle = tester.ensureSemantics();
      await openAt(tester, '/search?q=chair');

      await tester.tap(find.bySemanticsLabel('Save listing').first);
      await harness.settle();

      expect(saved.saved, ['l1']);
      expect(find.bySemanticsLabel('Remove from saved'), findsOneWidget);
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('removes a saved listing when the filled heart is tapped', (tester) async {
      final handle = tester.ensureSemantics();
      await openAt(tester, '/search?q=chair');
      await tester.tap(find.bySemanticsLabel('Save listing').first);
      await harness.settle();

      await tester.tap(find.bySemanticsLabel('Remove from saved'));
      await harness.settle();

      expect(saved.removed, ['l1']);
      expect(find.bySemanticsLabel('Save listing'), findsNWidgets(2));
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('puts the heart back and says so when saving fails', (tester) async {
      saved.onSave = (id) async => throw _offline;
      await openAt(tester, '/search?q=chair');

      await tester.tap(find.bySemanticsLabel('Save listing').first);
      await harness.settle();

      expect(find.text('Unable to update your saved items. Try again'), findsOneWidget);
      expect(find.bySemanticsLabel('Remove from saved'), findsNothing);
      await harness.dispose();
    });

    testWidgets('says how many items can be saved when the limit is reached', (tester) async {
      saved.onSave = (id) async => throw const SavedListingLimitReached(200);
      await openAt(tester, '/search?q=chair');

      await tester.tap(find.bySemanticsLabel('Save listing').first);
      await harness.settle();

      expect(
        find.text('Maximum 200 saved items reached. Remove some to add more'),
        findsOneWidget,
      );
      await harness.dispose();
    });

    testWidgets('says the listing is gone when the server says it is unavailable', (tester) async {
      saved.onSave = (id) async => throw const SavedListingUnavailable();
      await openAt(tester, '/search?q=chair');

      await tester.tap(find.bySemanticsLabel('Save listing').first);
      await harness.settle();

      expect(find.text('This listing is no longer available'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('starts filled for a listing the server says is saved', (tester) async {
      final handle = tester.ensureSemantics();
      search.handler = (criteria, page) async => SearchPage.fromJson(
            pageJson([
              {...listingJson('l1', cardUrl: null), 'saved': true},
              listingJson('l9', cardUrl: null),
            ]),
          );
      await openAt(tester, '/search?q=chair');

      expect(find.bySemanticsLabel('Remove from saved'), findsOneWidget);
      expect(find.bySemanticsLabel('Save listing'), findsOneWidget);
      handle.dispose();
      await harness.dispose();
    });
  });
}
