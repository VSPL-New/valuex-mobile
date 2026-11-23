import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/realtime/realtime_event.dart';
import 'package:valuex_mobile/core/realtime/realtime_providers.dart';
import 'package:valuex_mobile/core/routing/app_router.dart';
import 'package:valuex_mobile/features/calls/data/call_permissions.dart';
import 'package:valuex_mobile/features/calls/data/call_repository.dart';
import 'package:valuex_mobile/features/calls/domain/call.dart';
import 'package:valuex_mobile/features/calls/presentation/call_starter.dart';
import 'package:valuex_mobile/features/calls/presentation/providers/call_launcher.dart';
import 'package:valuex_mobile/features/calls/presentation/providers/incoming_call_listener.dart';
import 'package:valuex_mobile/features/notifications/domain/notification_deep_links.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';

import '../../core/realtime/realtime_fakes.dart';
import 'call_fixtures.dart';

ApiError _error(String code, {int status = 409}) =>
    ApiError(type: ApiErrorType.business, message: code, code: code, statusCode: status);

void main() {
  late MockCallRepository repo;
  late FakeCallPermissions permissions;

  setUpAll(() => registerFallbackValue(CallType.voice));

  setUp(() {
    repo = MockCallRepository();
    permissions = FakeCallPermissions();
  });

  ProviderContainer containerOf([FakeRealtimeClient? realtime]) {
    final container = ProviderContainer(
      overrides: [
        callRepositoryProvider.overrideWithValue(repo),
        callPermissionsProvider.overrideWithValue(permissions),
        if (realtime != null) realtimeClientProvider.overrideWithValue(realtime),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('CallLauncher', () {
    test('asks for the permissions first and then starts the call', () async {
      when(() => repo.start('l1', type: CallType.voice)).thenAnswer((_) async => call());
      final container = containerOf();
      container.listen(callLauncherProvider, (previous, next) {});

      final result = await container.read(callLauncherProvider.notifier).start(
            'l1',
            type: CallType.voice,
          );

      expect(result.callId, 'c1');
      expect(permissions.requests, [false]);
    });

    test('a video call also asks for the camera', () async {
      when(() => repo.start('l1', type: CallType.video))
          .thenAnswer((_) async => call(type: 'VIDEO'));
      final container = containerOf();
      container.listen(callLauncherProvider, (previous, next) {});

      await container.read(callLauncherProvider.notifier).start('l1', type: CallType.video);

      expect(permissions.requests, [true]);
    });

    test('a refusal creates no call', () async {
      permissions.result = CallPermissionResult.permanentlyDenied;
      final container = containerOf();
      container.listen(callLauncherProvider, (previous, next) {});

      final result = await container.read(callLauncherProvider.notifier).start(
            'l1',
            type: CallType.voice,
          );

      expect(result.callId, isNull);
      expect(result.permission, CallPermissionResult.permanentlyDenied);
      verifyNever(() => repo.start(any(), type: any(named: 'type')));
    });

    test('a refusal by the server is handed back as the error', () async {
      when(() => repo.start('l1', type: CallType.voice)).thenThrow(_error('ERROR_USER_BUSY'));
      final container = containerOf();
      container.listen(callLauncherProvider, (previous, next) {});

      final result = await container.read(callLauncherProvider.notifier).start(
            'l1',
            type: CallType.voice,
          );

      expect((result.error! as ApiError).code, 'ERROR_USER_BUSY');
    });

    test('a second tap while a call is being started is ignored', () async {
      final starting = Completer<CallSession>();
      when(() => repo.start('l1', type: CallType.voice)).thenAnswer((_) => starting.future);
      final container = containerOf();
      container.listen(callLauncherProvider, (previous, next) {});
      final launcher = container.read(callLauncherProvider.notifier);

      final first = launcher.start('l1', type: CallType.voice);
      await Future<void>.delayed(Duration.zero);
      final second = await launcher.start('l1', type: CallType.voice);
      expect(container.read(callLauncherProvider), isTrue);
      starting.complete(call());
      await first;

      expect(second.callId, isNull);
      expect(second.error, isNull);
      expect(second.permission, isNull);
      expect(container.read(callLauncherProvider), isFalse);
      verify(() => repo.start('l1', type: CallType.voice)).called(1);
    });
  });

  group('startCall', () {
    Future<(WidgetRef, BuildContext)> pump(WidgetTester tester) async {
      late WidgetRef capturedRef;
      late BuildContext capturedContext;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                capturedContext = context;
                return const Scaffold(body: Text('listing'));
              },
            ),
          ),
          GoRoute(
            path: '/call/:callId',
            builder: (context, state) =>
                Scaffold(body: Text('call ${state.pathParameters['callId']}')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            callRepositoryProvider.overrideWithValue(repo),
            callPermissionsProvider.overrideWithValue(permissions),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (capturedRef, capturedContext);
    }

    testWidgets('opens the call screen once the server rings the seller', (tester) async {
      when(() => repo.start('l1', type: CallType.voice)).thenAnswer((_) async => call());
      final (ref, context) = await pump(tester);

      unawaited(startCall(context, ref, listingId: 'l1', type: CallType.voice));
      await tester.pumpAndSettle();

      expect(find.text('call c1'), findsOneWidget);
    });

    testWidgets('a refused permission shows its text and a way to the settings', (tester) async {
      permissions.result = CallPermissionResult.microphoneDenied;
      final (ref, context) = await pump(tester);

      unawaited(startCall(context, ref, listingId: 'l1', type: CallType.voice));
      await tester.pumpAndSettle();

      expect(find.text('Microphone access is required for calls'), findsOneWidget);
      await tester.tap(find.text('Open settings'));
      expect(permissions.settingsOpened, 1);
      expect(find.text('listing'), findsOneWidget);
    });

    testWidgets('each refusal of the server has its own text', (tester) async {
      final cases = {
        'ERROR_CALLS_UNAVAILABLE': 'Calls are not available right now. Please try again later.',
        'ERROR_CALL_IN_PROGRESS': 'You are already on a call',
        'ERROR_USER_BUSY': 'The seller is on another call. Please try again in a moment.',
        'ERROR_CALL_FAILED': 'We could not connect the call. Please try again.',
        'ERROR_BLOCKED': 'You cannot contact this seller',
        'ERROR_SELLER_UNAVAILABLE': 'Seller is currently unavailable',
      };
      for (final entry in cases.entries) {
        when(() => repo.start('l1', type: CallType.video)).thenThrow(_error(entry.key));
        final (ref, context) = await pump(tester);

        unawaited(startCall(context, ref, listingId: 'l1', type: CallType.video));
        await tester.pumpAndSettle();

        expect(find.textContaining(entry.value.split('.').first), findsOneWidget,
            reason: entry.key);
        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  group('incoming call listener', () {
    testWidgets('opens the call screen when the server rings this phone, once per call',
        (tester) async {
      final realtime = FakeRealtimeClient();
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Text('home'))),
          GoRoute(
            path: '/call/:callId',
            builder: (context, state) =>
                Scaffold(body: Text('ringing ${state.pathParameters['callId']}')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appRouterProvider.overrideWithValue(router),
            realtimeClientProvider.overrideWithValue(realtime),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              ref.watch(incomingCallProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      realtime.emit(RealtimeTypes.callUpdated, {'callId': 'c8'});
      realtime.emit(RealtimeTypes.callIncoming, {'type': 'VOICE'});
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);

      realtime.emit(RealtimeTypes.callIncoming, {'callId': 'c7', 'type': 'VOICE'});
      await tester.pumpAndSettle();
      expect(find.text('ringing c7'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      realtime.emit(RealtimeTypes.callIncoming, {'callId': 'c7', 'type': 'VOICE'}, id: 'again');
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('notification deep links', () {
    test('a push for a ringing call opens its screen', () {
      final target = notificationTargetFor('/call/abc');

      expect(target!.route, '/call/abc');
      expect(target.isTab, isFalse);
    });

    test('a bare call path opens nothing', () {
      expect(notificationTargetFor('/call'), isNull);
      expect(notificationTargetFor('/call/'), isNull);
    });
  });
}
