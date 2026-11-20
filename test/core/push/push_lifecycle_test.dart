import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/push/push_lifecycle.dart';
import 'package:valuex_mobile/core/push/push_providers.dart';
import 'package:valuex_mobile/core/push/push_service.dart';
import 'package:valuex_mobile/core/push/push_token_repository.dart';
import 'package:valuex_mobile/core/routing/app_router.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_controller.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_state.dart';
import 'package:valuex_mobile/features/notifications/domain/notification_deep_links.dart';
import 'package:valuex_mobile/features/settings/presentation/providers/locale_controller.dart';

import 'push_fakes.dart';

class _FakeSession extends SessionController {
  SessionState initial;

  _FakeSession(this.initial);

  @override
  Future<SessionState> build() async => initial;

  void become(SessionState next) => state = AsyncData(next);
}

class _MockRepository extends Mock implements PushTokenRepository {}

const _active = Authenticated(status: AccountStatus.active, aadhaarVerified: true);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePushService service;
  late _MockRepository repository;
  late _FakeSession session;

  var registered = 0;

  setUp(() {
    registered = 0;
    service = FakePushService()..token_ = 'fcm-1';
    repository = _MockRepository();
    when(() => repository.register(
          deviceId: any(named: 'deviceId'),
          platform: any(named: 'platform'),
          token: any(named: 'token'),
          locale: any(named: 'locale'),
          appVersion: any(named: 'appVersion'),
          permissionGranted: any(named: 'permissionGranted'),
        )).thenAnswer((_) async => registered++);
  });

  int registrations() => registered;

  ProviderContainer make(SessionState initial, {List<Override> extra = const []}) {
    session = _FakeSession(initial);
    final container = ProviderContainer(overrides: [
      sessionControllerProvider.overrideWith(() => session),
      pushServiceProvider.overrideWithValue(service),
      pushTokenRepositoryProvider.overrideWithValue(repository),
      installIdProvider.overrideWith((ref) async => 'install-1'),
      ...extra,
    ]);
    addTearDown(container.dispose);
    return container;
  }

  Future<ProviderContainer> start(SessionState initial) async {
    final container = make(initial);
    container.listen(pushLifecycleProvider, (_, __) {});
    await container.read(sessionControllerProvider.future);
    await _settle();
    return container;
  }

  group('registration', () {
    test('registers once the account is active', () async {
      await start(_active);

      expect(registrations(), 1);
    });

    test('registers nothing while signed out, and does not delete a token at start', () async {
      await start(const Unauthenticated());

      expect(registrations(), 0);
      expect(service.deleted, 0);
    });

    test('registers when the account becomes active after sign-in', () async {
      await start(const Unauthenticated());

      session.become(_active);
      await _settle();

      expect(registrations(), 1);
    });

    test('registers again when the token changes', () async {
      await start(_active);

      service.tokens.add('fcm-2');
      await _settle();

      expect(registrations(), 2);
    });

    test('ignores a token change while the account is not active', () async {
      await start(const Unauthenticated());

      service.tokens.add('fcm-2');
      await _settle();

      expect(registrations(), 0);
    });

    test('registers again when the app language changes', () async {
      final container = await start(_active);

      await container.read(localeControllerProvider.notifier).select(const Locale('hi'));
      await _settle();

      expect(registrations(), 2);
    });

    test('does not register on a language change while signed out', () async {
      final container = await start(const Unauthenticated());

      await container.read(localeControllerProvider.notifier).select(const Locale('hi'));
      await _settle();

      expect(registrations(), 0);
    });

    test('drops the token on the phone when the person signs out', () async {
      await start(_active);

      session.become(const Unauthenticated());
      await _settle();

      expect(service.deleted, 1);
    });

    test('drops the token when the account stops being active', () async {
      await start(_active);

      session.become(const Authenticated(status: AccountStatus.suspended, aadhaarVerified: true));
      await _settle();

      expect(service.deleted, 1);
    });
  });

  group('taps', () {
    GoRouter makeRouter() => GoRouter(routes: [
          GoRoute(path: '/', builder: (context, state) => const SizedBox()),
          GoRoute(path: '/chats/:id', builder: (context, state) => const SizedBox()),
          GoRoute(path: '/profile', builder: (context, state) => const SizedBox()),
        ]);

    String location(GoRouter router) =>
        router.routerDelegate.currentConfiguration.last.matchedLocation;

    Future<ProviderContainer> startWithRouter(
      WidgetTester tester,
      GoRouter router,
      SessionState initial,
    ) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final container = make(initial, extra: [appRouterProvider.overrideWithValue(router)]);
      container.listen(pushLifecycleProvider, (_, __) {});
      await container.read(sessionControllerProvider.future);
      return container;
    }

    testWidgets('a notification that opened the app is opened once the account is active',
        (tester) async {
      final router = makeRouter();
      service.initial = const PushTap(deepLink: '/chats/abc', eventId: 'e1');
      await startWithRouter(tester, router, const Unauthenticated());
      expect(location(router), '/');

      session.become(_active);
      await tester.pumpAndSettle();

      expect(location(router), '/chats/abc');
    });

    testWidgets('a tap on a notification while the app is in the background opens its screen',
        (tester) async {
      final router = makeRouter();
      await startWithRouter(tester, router, _active);

      service.tapEvents.add(const PushTap(deepLink: '/chats/xyz', eventId: 'e9'));
      await tester.pumpAndSettle();

      expect(location(router), '/chats/xyz');
    });

    testWidgets('a link to a main tab switches to the tab', (tester) async {
      final router = makeRouter();
      await startWithRouter(tester, router, _active);

      service.tapEvents.add(const PushTap(deepLink: '/profile', eventId: 'e10'));
      await tester.pumpAndSettle();

      expect(location(router), '/profile');
    });

    test('opens the conversation of a chat push', () {
      final opened = <NotificationTarget>[];

      PushTapHandler(opened.add).handle(const PushTap(deepLink: '/chats/abc', eventId: 'e1'));

      expect(opened.single.route, '/chats/abc');
      expect(opened.single.isTab, isFalse);
    });

    test('opens the negotiation of an offer push', () {
      final opened = <NotificationTarget>[];

      PushTapHandler(opened.add)
          .handle(const PushTap(deepLink: '/negotiations/n-1', eventId: 'e2'));

      expect(opened.single.route, '/negotiations/n-1');
    });

    test('ignores a second tap on the same event', () {
      final opened = <NotificationTarget>[];
      final handler = PushTapHandler(opened.add);

      handler.handle(const PushTap(deepLink: '/chats/abc', eventId: 'e1'));
      handler.handle(const PushTap(deepLink: '/chats/abc', eventId: 'e1'));

      expect(opened, hasLength(1));
    });

    test('handles a tap without an event id every time', () {
      final opened = <NotificationTarget>[];
      final handler = PushTapHandler(opened.add);

      handler.handle(const PushTap(deepLink: '/chats/abc'));
      handler.handle(const PushTap(deepLink: '/chats/abc'));

      expect(opened, hasLength(2));
    });

    test('forgets old event ids so memory stays bounded', () {
      final opened = <NotificationTarget>[];
      final handler = PushTapHandler(opened.add);

      for (var i = 0; i < 25; i++) {
        handler.handle(PushTap(deepLink: '/chats/abc', eventId: 'e$i'));
      }
      handler.handle(const PushTap(deepLink: '/chats/abc', eventId: 'e0'));

      expect(opened, hasLength(26));
    });

    test('does nothing for a link the app cannot open, or one that needs a listing loaded', () {
      final opened = <NotificationTarget>[];
      final handler = PushTapHandler(opened.add);

      handler.handle(const PushTap(deepLink: '/support', eventId: 'a'));
      handler.handle(const PushTap(deepLink: null, eventId: 'b'));
      handler.handle(const PushTap(deepLink: '/sell/details?listingId=1', eventId: 'c'));

      expect(opened, isEmpty);
    });
  });
}
