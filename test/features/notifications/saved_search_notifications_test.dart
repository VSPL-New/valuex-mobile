import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/home/data/mock_home_repository.dart';
import 'package:valuex_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:valuex_mobile/features/notifications/data/notifications_repository.dart';
import 'package:valuex_mobile/features/notifications/domain/app_notification.dart';
import 'package:valuex_mobile/features/notifications/domain/notification_deep_links.dart';
import 'package:valuex_mobile/features/notifications/presentation/notification_presentation.dart';
import 'package:valuex_mobile/features/notifications/presentation/notification_text.dart';
import 'package:valuex_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:valuex_mobile/features/saved_searches/data/saved_searches_repository.dart';
import 'package:valuex_mobile/features/saved_searches/domain/saved_search.dart';
import 'package:valuex_mobile/features/search/data/search_repository.dart';
import 'package:valuex_mobile/features/search/domain/search_page.dart';
import 'package:valuex_mobile/features/search/presentation/search_screen.dart';
import 'package:valuex_mobile/l10n/app_localizations_en.dart';
import 'package:valuex_mobile/l10n/app_localizations_hi.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fonts.dart';
import '../search/search_fixtures.dart';
import '../saved_searches/saved_search_fixtures.dart';

class _MockNotifications extends Mock implements NotificationsRepository {}

final _en = AppLocalizationsEn();
final _hi = AppLocalizationsHi();

AppNotification _digest({
  Map<String, dynamic>? params,
  String deepLink = '/search/saved?id=s1',
  String title = 'Server title',
  String body = 'Server body',
}) =>
    AppNotification(
      id: 'n1',
      eventType: 'SAVED_SEARCH_MATCHES',
      title: title,
      body: body,
      deepLink: deepLink,
      params: params ??
          {
            'searchId': 's1',
            'count': 5,
            'name': 'Phones in Pune',
            'titles': ['iPhone 14', 'iPhone 13'],
          },
      priority: NotificationPriority.medium,
      read: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    );

void main() {
  setUpAll(loadBrandFonts);

  group('saved search alert text', () {
    test('shows the count, the name and the sample titles in English and Hindi', () {
      expect(notificationTitle(_en, _digest()), 'New matches for your saved search');
      expect(notificationTitle(_hi, _digest()), isNot('Server title'));
      expect(
        notificationBody(_en, _digest()),
        '5 new items match "Phones in Pune": iPhone 14; iPhone 13 and more.',
      );
      final hindi = notificationBody(_hi, _digest());
      expect(hindi, contains('Phones in Pune'));
      expect(hindi, contains('5'));
      expect(hindi, contains('iPhone 14; iPhone 13'));
      expect(hindi, contains('और भी'));
    });

    test('says one item in the singular and leaves out "and more" when all titles are shown', () {
      final one = _digest(
        params: {
          'count': 1,
          'name': 'Chairs',
          'titles': ['Oak chair'],
        },
      );
      expect(notificationBody(_en, one), '1 new item matches "Chairs": Oak chair.');
      expect(
        notificationBody(
          _en,
          _digest(params: {'count': 3, 'name': 'Chairs', 'titles': <String>[]}),
        ),
        '3 new items match "Chairs".',
      );
    });

    test('falls back to the server text when the count or name is missing', () {
      for (final params in <Map<String, dynamic>>[
        {'name': 'Chairs'},
        {'count': 2},
        {'count': 0, 'name': 'Chairs'},
        {'count': 'x', 'name': 'Chairs'},
        <String, dynamic>{},
      ]) {
        expect(notificationBody(_en, _digest(params: params)), 'Server body', reason: '$params');
      }
    });

    test('has its own icon and is listed under Others', () {
      expect(notificationIcon(_digest()), Icons.notifications_active_outlined);
      expect(_digest().category, NotificationCategory.others);
    });
  });

  group('saved search alert link', () {
    test('opens that saved search above the list', () {
      final target = notificationTargetFor('/search/saved?id=s1')!;

      expect(target.route, '/search/saved?id=s1');
      expect(target.isTab, isFalse);
      expect(target.needsListing, isFalse);
      expect(target.route, RouteNames.savedSearch('s1'));
    });

    test('a link without an id has no target', () {
      expect(notificationTargetFor('/search/saved'), isNull);
      expect(notificationTargetFor('/search/saved?id='), isNull);
    });
  });

  group('tapping the alert', () {
    late FakeSearchRepository search;
    late FakeSavedSearchesRepository saved;
    late AppHarness harness;

    Future<void> open(WidgetTester tester, AppNotification notification) async {
      final notifications = _MockNotifications();
      when(() => notifications.page(0)).thenAnswer(
        (_) async => NotificationsPage(
          items: [notification],
          page: 0,
          hasMore: false,
          unread: 1,
        ),
      );
      when(notifications.unreadCount).thenAnswer((_) async => 1);
      when(() => notifications.markRead(any())).thenAnswer((_) async {});
      search = FakeSearchRepository(
        (criteria, page) async =>
            SearchPage.fromJson(pageJson([listingJson('l1', title: 'iPhone 14', cardUrl: null)])),
      );
      saved = FakeSavedSearchesRepository()
        ..onList = () async => [SavedSearch.fromJson(savedSearchJson('s1'))];
      harness = AppHarness(
        tester,
        extraOverrides: [
          homeRepositoryProvider.overrideWithValue(const MockHomeRepository()),
          notificationsRepositoryProvider.overrideWithValue(notifications),
          searchRepositoryProvider.overrideWithValue(search),
          savedSearchesRepositoryProvider.overrideWithValue(saved),
        ],
      )..signedInAs(AccountStatus.active, aadhaarVerified: true);
      await harness.launch(location: RouteNames.notifications);
    }

    testWidgets('shows the app text and opens the results of that saved search', (tester) async {
      await open(tester, _digest());

      expect(find.text('New matches for your saved search'), findsOneWidget);
      expect(
        find.text('5 new items match "Phones in Pune": iPhone 14; iPhone 13 and more.'),
        findsOneWidget,
      );
      await tester.tap(find.text('New matches for your saved search'));
      await harness.settle();

      expect(find.byType(SearchScreen), findsOneWidget);
      expect(search.calls.first.criteria.query, 'iphone');
      expect(search.calls.first.criteria.facets, {'brand': 'apple', 'storage_gb': '32..128'});
      await harness.dispose();
    });

    testWidgets('a link the app does not know still says coming soon', (tester) async {
      await open(tester, _digest(deepLink: '/support'));

      await tester.tap(find.text('New matches for your saved search'));
      await harness.settle();

      expect(find.text('This is coming soon'), findsOneWidget);
      expect(find.byType(NotificationsScreen), findsOneWidget);
      await harness.dispose();
    });
  });
}
