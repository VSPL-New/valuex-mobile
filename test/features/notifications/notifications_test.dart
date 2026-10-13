import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/account_security/presentation/account_security_screen.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/notifications/data/notifications_repository.dart';
import 'package:valuex_mobile/features/notifications/domain/app_notification.dart';
import 'package:valuex_mobile/features/notifications/domain/notification_deep_links.dart';
import 'package:valuex_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:valuex_mobile/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:valuex_mobile/features/profile/presentation/profile_screen.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/app_harness.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_secure_storage.dart';
import '../../helpers/fonts.dart';

class _MockRepository extends Mock implements NotificationsRepository {}

const _offline = ApiError(type: ApiErrorType.network, message: 'offline');

final _config = AppConfig.parse(
  env: 'dev',
  apiBaseUrl: 'http://localhost:8080/api/v1',
  aadhaarFlow: 'sandbox',
);

AppNotification _n(
  String id, {
  String eventType = 'ACCOUNT_CREATED',
  String? title,
  String body = 'Your account has been created successfully.',
  String? deepLink = '/profile',
  bool read = false,
  Duration age = const Duration(hours: 2),
}) {
  return AppNotification(
    id: id,
    eventType: eventType,
    title: title ?? 'Title $id',
    body: body,
    deepLink: deepLink,
    priority: NotificationPriority.high,
    read: read,
    createdAt: DateTime.now().subtract(age),
  );
}

NotificationsPage _page(
  List<AppNotification> items, {
  int page = 0,
  bool hasMore = false,
  int? unread,
}) {
  return NotificationsPage(
    items: items,
    page: page,
    hasMore: hasMore,
    unread: unread ?? items.where((n) => !n.read).length,
  );
}

void main() {
  setUpAll(loadBrandFonts);

  group('categories', () {
    test('account events and Aadhaar belong to Account', () {
      for (final type in [
        'ACCOUNT_CREATED',
        'AADHAAR_VERIFIED',
        'ACCOUNT_UNDER_REVIEW',
        'ACCOUNT_SUSPENDED',
        'ACCOUNT_BANNED',
      ]) {
        expect(notificationCategoryOf(type), NotificationCategory.account, reason: type);
      }
    });

    test('order, payment, shipping and refund events belong to Orders', () {
      for (final type in ['ORDER_PLACED', 'PAYMENT_SUCCESS', 'SHIPMENT_LOST', 'REFUND_PROCESSED']) {
        expect(notificationCategoryOf(type), NotificationCategory.orders, reason: type);
      }
    });

    test('chat and offers belong to Messages, listing events to Listings', () {
      expect(notificationCategoryOf('MESSAGE_RECEIVED'), NotificationCategory.messages);
      expect(notificationCategoryOf('OFFER_ACCEPTED'), NotificationCategory.messages);
      expect(notificationCategoryOf('LISTING_BOOSTED'), NotificationCategory.listings);
    });

    test('anything else, in any letter case, is Others', () {
      expect(notificationCategoryOf('PRICE_DROP'), NotificationCategory.others);
      expect(notificationCategoryOf(''), NotificationCategory.others);
      expect(notificationCategoryOf('order_placed'), NotificationCategory.orders);
    });

    test('only the three account-state events are alerts', () {
      expect(_n('1', eventType: 'ACCOUNT_SUSPENDED').isAlert, isTrue);
      expect(_n('2', eventType: 'ACCOUNT_BANNED').isAlert, isTrue);
      expect(_n('3', eventType: 'ACCOUNT_UNDER_REVIEW').isAlert, isTrue);
      expect(_n('4', eventType: 'ACCOUNT_CREATED').isAlert, isFalse);
    });
  });

  group('deep links', () {
    test('the profile link switches to the Profile tab', () {
      final target = notificationTargetFor('/profile')!;
      expect(target.route, RouteNames.profile);
      expect(target.isTab, isTrue);
    });

    test('the account-security link opens Account Security on top', () {
      final target = notificationTargetFor('/profile/account-security')!;
      expect(target.route, RouteNames.accountSecurity);
      expect(target.isTab, isFalse);
    });

    test('a query string and a trailing slash are ignored', () {
      expect(notificationTargetFor('/profile/account-security?from=push')?.route,
          RouteNames.accountSecurity);
      expect(notificationTargetFor('/profile/')?.route, RouteNames.profile);
    });

    test('screens that are not built yet and missing links have no target', () {
      expect(notificationTargetFor('/support'), isNull);
      expect(notificationTargetFor(null), isNull);
    });
  });

  group('repository', () {
    late FakeHttpAdapter adapter;
    late NotificationsRepository repository;
    var unreadHeader = '4';

    setUp(() {
      unreadHeader = '4';
      adapter = FakeHttpAdapter((options) async {
        if (options.path == '/notifications' && options.method == 'GET') {
          return ResponseBody.fromString(
            '{"success":true,"data":[${[
              '{"id":"a","eventType":"ACCOUNT_SUSPENDED","title":"Account Suspended","body":"b",'
                  '"deepLink":"/support","priority":"HIGH","read":false,"createdAt":"2026-10-13T09:00:00Z"}',
              '{"id":"b","eventType":"X","title":"t","body":"b","deepLink":"https://evil.example","priority":"WEIRD","read":true,"createdAt":"bad"}',
            ].join(',')}],'
            '"metadata":{"page":${options.queryParameters['page']},"size":${options.queryParameters['size']},"totalPages":3}}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
              if (unreadHeader.isNotEmpty) 'X-Unread-Notifications': [unreadHeader],
            },
          );
        }
        return FakeHttpAdapter.ok(null);
      });
      repository = NotificationsRepository(ApiClient(
        FakeSecureStorage(accessToken: 'access-1', refreshToken: 'refresh-1'),
        _config,
        adapter: adapter,
      ));
    });

    test('reads a page with its items, position and the unread header', () async {
      final page = await repository.page(1);

      expect(page.page, 1);
      expect(page.hasMore, isTrue);
      expect(page.unread, 4);
      expect(page.items.map((n) => n.id), ['a', 'b']);
      final first = page.items.first;
      expect(first.eventType, 'ACCOUNT_SUSPENDED');
      expect(first.deepLink, '/support');
      expect(first.priority, NotificationPriority.high);
      expect(first.read, isFalse);
      expect(first.createdAt, DateTime.utc(2026, 10, 13, 9).toLocal());
      final request = adapter.requests.single;
      expect(request.queryParameters, {'page': 1, 'size': 20});
      expect(request.headers['Authorization'], 'Bearer access-1');
    });

    test('a link that is not an app path, an unknown priority and a bad date are tolerated',
        () async {
      final second = (await repository.page(0)).items.last;

      expect(second.deepLink, isNull);
      expect(second.priority, NotificationPriority.medium);
      expect(second.read, isTrue);
      expect(second.createdAt.difference(DateTime.now()).inMinutes.abs(), lessThan(2));
    });

    test('the last page has no more', () async {
      expect((await repository.page(2)).hasMore, isFalse);
    });

    test('without the header the unread count is taken from the loaded items', () async {
      unreadHeader = '';

      expect((await repository.page(0)).unread, 1);
      expect(await repository.unreadCount(), 0);
    });

    test('the unread count asks for a single item', () async {
      expect(await repository.unreadCount(), 4);

      expect(adapter.requests.single.queryParameters, {'page': 0, 'size': 1});
    });

    test('marking one read patches that notification', () async {
      await repository.markRead('abc');

      final request = adapter.requests.single;
      expect(request.method, 'PATCH');
      expect(request.path, '/notifications/abc/read');
    });

    test('marking all read patches the bulk endpoint', () async {
      await repository.markAllRead();

      final request = adapter.requests.single;
      expect(request.method, 'PATCH');
      expect(request.path, '/notifications/read-all');
    });

    test('a response that is not a list is an error', () async {
      final broken = NotificationsRepository(ApiClient(
        FakeSecureStorage(accessToken: 'a', refreshToken: 'r'),
        _config,
        adapter: FakeHttpAdapter((_) async => FakeHttpAdapter.ok({'not': 'a list'})),
      ));

      await expectLater(broken.page(0), throwsA(isA<ApiError>()));
    });
  });

  group('NotificationsController', () {
    late _MockRepository repository;
    late ProviderContainer container;

    NotificationsController controller() =>
        container.read(notificationsControllerProvider.notifier);
    NotificationsState state() => container.read(notificationsControllerProvider).requireValue;
    int? unread() => container.read(unreadNotificationsProvider).value;

    Future<void> load(NotificationsPage first) async {
      when(() => repository.page(0)).thenAnswer((_) async => first);
      when(repository.unreadCount).thenAnswer((_) async => first.unread);
      container.listen(unreadNotificationsProvider, (_, __) {});
      container.listen(notificationsControllerProvider, (_, __) {});
      await container.read(notificationsControllerProvider.future);
      await Future<void>.delayed(Duration.zero);
    }

    setUp(() {
      repository = _MockRepository();
      container = ProviderContainer(
        overrides: [notificationsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
    });

    test('loads the first page and publishes the unread count', () async {
      await load(_page([_n('1'), _n('2', read: true)], unread: 7));

      expect(state().items.map((n) => n.id), ['1', '2']);
      expect(state().hasMore, isFalse);
      expect(unread(), 7);
    });

    test('a failed first load is an error the page can retry', () async {
      when(() => repository.page(0)).thenThrow(_offline);
      container.listen(notificationsControllerProvider, (_, __) {});

      await expectLater(container.read(notificationsControllerProvider.future), throwsA(_offline));

      expect(container.read(notificationsControllerProvider).hasError, isTrue);
    });

    test('loadMore appends the next page and skips ones already shown', () async {
      await load(_page([_n('1'), _n('2')], hasMore: true));
      when(() => repository.page(1))
          .thenAnswer((_) async => _page([_n('2'), _n('3')], page: 1, unread: 3));

      await controller().loadMore();
      await Future<void>.delayed(Duration.zero);

      expect(state().items.map((n) => n.id), ['1', '2', '3']);
      expect(state().hasMore, isFalse);
      expect(state().loadingMore, isFalse);
      expect(unread(), 3);
    });

    test('loadMore does nothing when there is no more or one is already loading', () async {
      await load(_page([_n('1')], hasMore: true));
      final pending = Completer<NotificationsPage>();
      when(() => repository.page(1)).thenAnswer((_) => pending.future);

      final first = controller().loadMore();
      await controller().loadMore();
      pending.complete(_page([_n('2')], page: 1));
      await first;

      verify(() => repository.page(1)).called(1);
      await controller().loadMore();
      verifyNever(() => repository.page(2));
    });

    test('a failed loadMore is remembered and retried on the same page', () async {
      await load(_page([_n('1')], hasMore: true));
      when(() => repository.page(1)).thenThrow(_offline);

      await controller().loadMore();

      expect(state().loadMoreFailed, isTrue);
      expect(state().items, hasLength(1));
      when(() => repository.page(1)).thenAnswer((_) async => _page([_n('2')], page: 1));

      await controller().loadMore();

      expect(state().loadMoreFailed, isFalse);
      expect(state().items.map((n) => n.id), ['1', '2']);
    });

    test('markRead marks at once and lowers the unread count', () async {
      await load(_page([_n('1'), _n('2')]));
      when(() => repository.markRead('1')).thenAnswer((_) async {});

      await controller().markRead('1');

      expect(state().items.first.read, isTrue);
      expect(state().items.last.read, isFalse);
      expect(unread(), 1);
      verify(() => repository.markRead('1')).called(1);
    });

    test('markRead on a read or unknown notification sends nothing', () async {
      await load(_page([_n('1', read: true)]));

      await controller().markRead('1');
      await controller().markRead('missing');

      verifyNever(() => repository.markRead(any()));
      expect(unread(), 0);
    });

    test('markRead is undone when the server refuses', () async {
      await load(_page([_n('1')]));
      when(() => repository.markRead('1')).thenThrow(_offline);

      await controller().markRead('1');

      expect(state().items.single.read, isFalse);
      expect(unread(), 1);
    });

    test('markAllRead marks every notification and clears the count', () async {
      await load(_page([_n('1'), _n('2'), _n('3', read: true)]));
      when(repository.markAllRead).thenAnswer((_) async {});

      await controller().markAllRead();

      expect(state().items.every((n) => n.read), isTrue);
      expect(state().markingAll, isFalse);
      expect(unread(), 0);
      verify(repository.markAllRead).called(1);
    });

    test('markAllRead puts everything back and rethrows when the server refuses', () async {
      await load(_page([_n('1'), _n('2', read: true)], unread: 5));
      when(repository.markAllRead).thenThrow(_offline);

      await expectLater(controller().markAllRead(), throwsA(_offline));

      expect(state().items.map((n) => n.read), [false, true]);
      expect(state().markingAll, isFalse);
      expect(unread(), 5);
    });

    test('refresh loads the first page again', () async {
      await load(_page([_n('1')]));
      when(() => repository.page(0)).thenAnswer((_) async => _page([_n('9'), _n('1')]));

      await controller().refresh();

      expect(state().items.map((n) => n.id), ['9', '1']);
    });
  });

  group('screens', () {
    late AppHarness harness;
    late _MockRepository repository;

    Future<void> launch(
      WidgetTester tester, {
      List<AppNotification>? items,
      NotificationsPage? first,
      NotificationsPage? next,
      int unreadCount = 2,
      String location = RouteNames.notifications,
      bool? error,
    }) async {
      repository = _MockRepository();
      final loaded = first ?? _page(items ?? _sample, unread: unreadCount);
      if (error == true) {
        when(() => repository.page(any())).thenThrow(_offline);
      } else {
        when(() => repository.page(0)).thenAnswer((_) async => loaded);
      }
      if (next != null) when(() => repository.page(1)).thenAnswer((_) async => next);
      when(repository.unreadCount).thenAnswer((_) async => loaded.unread);
      when(() => repository.markRead(any())).thenAnswer((_) async {});
      when(repository.markAllRead).thenAnswer((_) async {});
      harness = AppHarness(
        tester,
        extraOverrides: [notificationsRepositoryProvider.overrideWithValue(repository)],
      )..signedInAs(AccountStatus.active, aadhaarVerified: true);
      await harness.launch(location: location);
    }

    testWidgets('lists notifications newest first with their text and time', (tester) async {
      await launch(tester);

      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('2 unread'), findsOneWidget);
      expect(find.text('Welcome to JustQlic'), findsOneWidget);
      expect(find.text('Account Suspended'), findsOneWidget);
      expect(find.text('Order Delivered'), findsOneWidget);
      expect(find.text('2 hours ago'), findsOneWidget);
      expect(find.text('5 minutes ago'), findsOneWidget);
      expect(find.text('3 days ago'), findsOneWidget);
      expect(find.text('Mark all read'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('an unread notification is announced as unread, a read one is not', (tester) async {
      final handle = tester.ensureSemantics();
      await launch(tester);

      expect(
        find.bySemanticsLabel(
          'Unread. Welcome to JustQlic. Your account has been created successfully.. 2 hours ago',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp(r'^Order Delivered\. Your order has been delivered\.\. 3 days ago$'),
        ),
        findsOneWidget,
      );
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('a notification older than a week shows its date', (tester) async {
      await launch(tester, items: [_n('1', age: const Duration(days: 30))]);

      final date = DateTime.now().subtract(const Duration(days: 30));
      expect(find.textContaining('${date.year}'), findsOneWidget);
      expect(find.text('30 days ago'), findsNothing);
      await harness.dispose();
    });

    testWidgets('tabs list All and only the categories that have notifications', (tester) async {
      await launch(tester);

      for (final label in ['All', 'Account', 'Orders']) {
        expect(find.widgetWithText(GestureDetector, label), findsOneWidget, reason: label);
      }
      for (final label in ['Messages', 'Listings', 'Others']) {
        expect(find.text(label), findsNothing, reason: label);
      }
      await harness.dispose();
    });

    testWidgets('choosing a tab shows only that category and All shows everything again',
        (tester) async {
      await launch(tester);

      await tester.tap(find.text('Orders'));
      await tester.pump();
      expect(find.text('Order Delivered'), findsOneWidget);
      expect(find.text('Welcome to JustQlic'), findsNothing);

      await tester.tap(find.text('Account'));
      await tester.pump();
      expect(find.text('Order Delivered'), findsNothing);
      expect(find.text('Welcome to JustQlic'), findsOneWidget);

      await tester.tap(find.text('All'));
      await tester.pump();
      expect(find.text('Order Delivered'), findsOneWidget);
      expect(find.text('Welcome to JustQlic'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('an unknown event type appears under Others', (tester) async {
      await launch(tester, items: [_n('1'), _n('2', eventType: 'PRICE_DROP', title: 'Price drop')]);

      await tester.tap(find.text('Others'));
      await tester.pump();

      expect(find.text('Price drop'), findsOneWidget);
      expect(find.text('Title 1'), findsNothing);
      await harness.dispose();
    });

    testWidgets('with a single category there is no tab row', (tester) async {
      await launch(tester, items: [_n('1'), _n('2')]);

      expect(find.text('All'), findsNothing);
      expect(find.text('Account'), findsNothing);
      await harness.dispose();
    });

    testWidgets('tapping a notification marks it read and opens its screen', (tester) async {
      await launch(tester);

      await tester.tap(find.text('Welcome to JustQlic'));
      await harness.settle();

      verify(() => repository.markRead('1')).called(1);
      expect(find.byType(ProfileScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('an account-security link opens Account Security above the list', (tester) async {
      await launch(tester, items: [
        _n('1',
            eventType: 'AADHAAR_VERIFIED',
            title: 'Aadhaar verified',
            deepLink: '/profile/account-security'),
      ]);

      await tester.tap(find.text('Aadhaar verified'));
      await harness.settle();

      expect(find.byType(AccountSecurityScreen), findsOneWidget);
      verify(() => repository.markRead('1')).called(1);
      await harness.dispose();
    });

    testWidgets('a link to a screen that is not built yet says it is coming soon', (tester) async {
      await launch(tester);

      await tester.tap(find.text('Account Suspended'));
      await harness.settle();

      expect(find.text('This is coming soon'), findsOneWidget);
      expect(find.byType(NotificationsScreen), findsOneWidget);
      verify(() => repository.markRead('2')).called(1);
      await harness.dispose();
    });

    testWidgets('a notification without a link is only marked read', (tester) async {
      await launch(tester, items: [_n('1', deepLink: null)]);

      await tester.tap(find.text('Title 1'));
      await harness.settle();

      verify(() => repository.markRead('1')).called(1);
      expect(find.text('This is coming soon'), findsNothing);
      expect(find.byType(NotificationsScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('Mark all read clears the unread state', (tester) async {
      await launch(tester);

      await tester.tap(find.text('Mark all read'));
      await harness.settle();

      verify(repository.markAllRead).called(1);
      expect(find.text("You're all caught up"), findsOneWidget);
      expect(find.text('Mark all read'), findsNothing);
      await harness.dispose();
    });

    testWidgets('a failed Mark all read tells the user and keeps the list unread', (tester) async {
      await launch(tester);
      when(repository.markAllRead).thenThrow(_offline);

      await tester.tap(find.text('Mark all read'));
      await harness.settle();

      expect(find.text('Unable to mark all as read. Try again'), findsOneWidget);
      expect(find.text('2 unread'), findsOneWidget);
      expect(find.text('Mark all read'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('no unread notifications means no Mark all read button', (tester) async {
      await launch(tester, items: [_n('1', read: true)], unreadCount: 0);

      expect(find.text("You're all caught up"), findsOneWidget);
      expect(find.text('Mark all read'), findsNothing);
      await harness.dispose();
    });

    testWidgets('an empty history says so', (tester) async {
      await launch(tester, items: const [], unreadCount: 0);

      expect(find.text('No notifications yet'), findsOneWidget);
      expect(find.text('Updates about your account will appear here'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a failed load shows an error with Retry that loads again', (tester) async {
      await launch(tester, error: true);

      expect(find.text('Retry'), findsOneWidget);
      when(() => repository.page(0)).thenAnswer((_) async => _page(_sample));

      await tester.tap(find.text('Retry'));
      await harness.settle();

      expect(find.text('Welcome to JustQlic'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('pulling down reloads the list', (tester) async {
      await launch(tester);
      when(() => repository.page(0))
          .thenAnswer((_) async => _page([_n('9', title: 'Brand new'), ..._sample]));

      await tester.fling(find.text('Welcome to JustQlic'), const Offset(0, 400), 1000);
      await harness.settle();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Brand new'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('scrolling to the end loads the next page, and a failure can be retried',
        (tester) async {
      final firstPage = [for (var i = 0; i < 20; i++) _n('a$i', title: 'First $i', read: true)];
      await launch(tester, first: _page(firstPage, hasMore: true, unread: 0));
      when(() => repository.page(1)).thenThrow(_offline);

      await tester.drag(find.byType(ListView).last, const Offset(0, -6000));
      await harness.settle();

      expect(find.text('Unable to load more notifications'), findsOneWidget);
      when(() => repository.page(1)).thenAnswer(
        (_) async => _page([_n('b0', title: 'Second 0', read: true)], page: 1, unread: 0),
      );

      await tester.ensureVisible(find.text('Retry'));
      await tester.tap(find.text('Retry'));
      await harness.settle();

      expect(find.text('Unable to load more notifications'), findsNothing);
      await tester.drag(find.byType(ListView).last, const Offset(0, -6000));
      await harness.settle();
      expect(find.text('Second 0'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a short first page that has more loads the next one on its own', (tester) async {
      await launch(
        tester,
        first: _page([_n('a', read: true)], hasMore: true, unread: 0),
        next: _page([_n('b', title: 'Loaded next', read: true)], page: 1, unread: 0),
      );
      await harness.settle();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Loaded next'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('the title is marked as a heading', (tester) async {
      final handle = tester.ensureSemantics();
      await launch(tester);

      expect(tester.getSemantics(find.text('Notifications').first), isSemantics(isHeader: true));
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('the back button returns to Home', (tester) async {
      await launch(tester);

      await tester.tap(find.bySemanticsLabel('Back'));
      await harness.settle();

      expect(find.byType(NotificationsScreen), findsNothing);
      expect(find.text('Featured Deals Near You'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('the Home bell opens the list and shows the count', (tester) async {
      final handle = tester.ensureSemantics();
      await launch(tester, location: RouteNames.home);

      expect(find.bySemanticsLabel('Notifications, 2 unread'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Notifications, 2 unread'));
      await harness.settle();

      expect(find.byType(NotificationsScreen), findsOneWidget);
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('reading everything updates the Home bell without another request', (tester) async {
      final handle = tester.ensureSemantics();
      await launch(tester, location: RouteNames.home);
      await tester.tap(find.bySemanticsLabel('Notifications, 2 unread'));
      await harness.settle();

      await tester.tap(find.text('Mark all read'));
      await harness.settle();
      await tester.tap(find.bySemanticsLabel('Back'));
      await harness.settle();

      expect(find.bySemanticsLabel('Notifications'), findsOneWidget);
      verify(repository.unreadCount).called(1);
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('the Profile row shows the unread count and opens the list', (tester) async {
      final handle = tester.ensureSemantics();
      await launch(tester, location: RouteNames.profile);

      expect(find.bySemanticsLabel('Notifications, 2 new'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Notifications'), 200);
      await tester.tap(find.text('Notifications'));
      await harness.settle();

      expect(find.byType(NotificationsScreen), findsOneWidget);
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('a signed-out visitor is sent to Sign In', (tester) async {
      repository = _MockRepository();
      harness = AppHarness(
        tester,
        extraOverrides: [notificationsRepositoryProvider.overrideWithValue(repository)],
      );
      await harness.launch(location: RouteNames.notifications);

      expect(find.byType(NotificationsScreen), findsNothing);
      await harness.dispose();
    });

    testWidgets('the list passes the tap target, label and contrast guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await launch(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrast));
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('large text does not overflow', (tester) async {
      await launch(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await harness.settle();

      expect(tester.takeException(), isNull);
      await harness.dispose();
    });
  });
}

final _sample = [
  _n('1', title: 'Welcome to JustQlic'),
  _n(
    '2',
    eventType: 'ACCOUNT_SUSPENDED',
    title: 'Account Suspended',
    body: 'Your account has been suspended.',
    deepLink: '/support',
    age: const Duration(minutes: 5),
  ),
  _n(
    '3',
    eventType: 'ORDER_DELIVERED',
    title: 'Order Delivered',
    body: 'Your order has been delivered.',
    deepLink: null,
    read: true,
    age: const Duration(days: 3),
  ),
];
