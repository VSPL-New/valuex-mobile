import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/realtime/realtime_providers.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/features/calls/data/call_permissions.dart';
import 'package:valuex_mobile/features/calls/data/call_platform.dart';
import 'package:valuex_mobile/features/calls/data/call_repository.dart';
import 'package:valuex_mobile/features/calls/data/rtc/fake_rtc_client.dart';
import 'package:valuex_mobile/features/calls/data/rtc/rtc_client.dart';
import 'package:valuex_mobile/features/calls/domain/call.dart';
import 'package:valuex_mobile/features/calls/presentation/call_screen.dart';
import 'package:valuex_mobile/features/calls/presentation/providers/call_controller.dart';
import 'package:valuex_mobile/features/communication_safety/data/communication_safety_repository.dart';
import 'package:valuex_mobile/features/communication_safety/domain/communication_safety.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../core/realtime/realtime_fakes.dart';
import '../../helpers/fonts.dart';
import '../communication_safety/communication_safety_fixtures.dart';
import 'call_fixtures.dart';

/// The phone's clock in these tests: five minutes after the call connected.
final _now = DateTime.utc(2026, 11, 22, 10, 5);
final _connected = DateTime.utc(2026, 11, 22, 10);

class _Env {
  final repo = MockCallRepository();
  final rtc = FakeRtcClient();
  final permissions = FakeCallPermissions();
  final platform = FakeCallPlatform();
  final safety = FakeCommunicationSafetyRepository();
  final realtime = FakeRealtimeClient();
}

class _PictureRtc extends FakeRtcClient {
  @override
  Widget remoteVideo() => const SizedBox.expand(key: Key('remote-picture'));

  @override
  Widget localVideo() => const SizedBox.expand(key: Key('local-picture'));
}

void main() {
  setUpAll(loadBrandFonts);

  late _Env env;

  CallSession active({String type = 'VOICE', int maxMinutes = 30, bool outgoing = true}) =>
      CallSession.fromJson(
        callJson(
          type: type,
          state: 'ACTIVE',
          outgoing: outgoing,
          connectedAt: _connected,
          maxMinutes: maxMinutes,
        ),
        receivedAt: DateTime.utc(2026, 11, 22, 10),
      );

  /// What the server answers to joining the room and confirming it; a voice call unless told.
  void stubJoin({String media = 'AUDIO', bool withVideo = false, CallSession? connected}) {
    when(() => env.repo.join('c1')).thenAnswer(
      (_) async => CallCredentials.fromJson(credentialsJson(media: media, withVideo: withVideo)),
    );
    when(() => env.repo.connected('c1')).thenAnswer((_) async => connected ?? active());
    when(() => env.repo.heartbeat('c1')).thenAnswer((_) async {});
  }

  setUp(() {
    env = _Env();
    stubJoin();
  });

  Future<void> pumpCall(
    WidgetTester tester,
    CallSession? session, {
    Object? readError,
    DateTime? now,
    Locale locale = const Locale('en'),
    double textScale = 1,
    Size size = const Size(390, 844),
    FakeRtcClient? rtc,
  }) async {
    if (session != null && session.type.hasVideo) {
      stubJoin(media: 'VIDEO', withVideo: true, connected: active(type: 'VIDEO'));
    }
    if (readError != null) {
      when(() => env.repo.get('c1')).thenThrow(readError);
    } else {
      when(() => env.repo.get('c1')).thenAnswer((_) async => session!);
    }
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final router = GoRouter(
      initialLocation: '/call/c1',
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const Scaffold(body: Text('home tab'))),
        GoRoute(path: '/call/:callId', builder: (context, state) => const CallScreen(callId: 'c1')),
      ],
    );
    final fixedNow = now ?? _now;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          callRepositoryProvider.overrideWithValue(env.repo),
          callRtcClientProvider.overrideWith((ref, callId) => rtc ?? env.rtc),
          callPermissionsProvider.overrideWithValue(env.permissions),
          callPlatformProvider.overrideWithValue(env.platform),
          realtimeClientProvider.overrideWithValue(env.realtime),
          communicationSafetyRepositoryProvider.overrideWithValue(env.safety),
          callTickProvider.overrideWith((ref) => Stream<DateTime>.value(fixedNow)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
    });
    await tester.pumpAndSettle();
  }

  group('ringing', () {
    testWidgets('the caller sees who is being called and can cancel', (tester) async {
      await pumpCall(tester, call());
      when(() => env.repo.cancel('c1')).thenAnswer(
        (_) async => call(state: 'ENDED', endReason: 'CANCELLED'),
      );

      expect(find.text('Asha Verma'), findsOneWidget);
      expect(find.text('Calling…'), findsOneWidget);
      expect(find.text('About iPhone 15 Pro Max'), findsOneWidget);
      expect(find.text('This call is not recorded'), findsOneWidget);
      expect(find.text('Accept'), findsNothing);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verify(() => env.repo.cancel('c1')).called(1);
      expect(find.text('home tab'), findsOneWidget);
    });

    testWidgets('the person called can accept or decline an incoming voice call', (tester) async {
      await pumpCall(tester, call(outgoing: false));

      expect(find.text('Incoming voice call'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('an incoming video call says so', (tester) async {
      await pumpCall(tester, call(type: 'VIDEO', outgoing: false));

      expect(find.text('Incoming video call'), findsOneWidget);
    });

    testWidgets('declining ends the call and closes the screen', (tester) async {
      await pumpCall(tester, call(outgoing: false));
      when(() => env.repo.decline('c1')).thenAnswer(
        (_) async => call(state: 'ENDED', endReason: 'DECLINED', outgoing: false),
      );

      await tester.tap(find.text('Decline'));
      await tester.pumpAndSettle();

      verify(() => env.repo.decline('c1')).called(1);
      expect(find.text('home tab'), findsOneWidget);
    });

    testWidgets('accepting asks for the permissions and joins the room', (tester) async {
      await pumpCall(tester, call(outgoing: false));
      stubJoin();
      when(() => env.repo.accept('c1')).thenAnswer(
        (_) async => call(state: 'ACCEPTED', outgoing: false),
      );

      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      expect(env.permissions.requests, [false]);
      expect(env.rtc.calls, contains('join video=false'));
      expect(find.text('Connecting…'), findsOneWidget);
      expect(find.text('Mute'), findsOneWidget);
    });

    testWidgets('a refused microphone says so and offers the settings', (tester) async {
      await pumpCall(tester, call(outgoing: false));
      env.permissions.result = CallPermissionResult.microphoneDenied;

      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      expect(find.text('Microphone access is required for calls'), findsOneWidget);
      verifyNever(() => env.repo.accept(any()));
      await tester.tap(find.text('Open settings'));
      expect(env.permissions.settingsOpened, 1);
    });

    testWidgets('a refused camera on a video call names the camera', (tester) async {
      await pumpCall(tester, call(type: 'VIDEO', outgoing: false));
      env.permissions.result = CallPermissionResult.cameraDenied;

      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      expect(
          find.text('Camera and microphone access are required for video calls'), findsOneWidget);
    });
  });

  group('a voice call in progress', () {
    testWidgets('shows the timer from the server time and the controls', (tester) async {
      await pumpCall(tester, active());
      stubJoin();
      env.rtc.emit(const RtcConnected());
      await tester.pumpAndSettle();

      expect(find.text('Asha Verma'), findsOneWidget);
      expect(find.text('5:00'), findsOneWidget);
      expect(find.text('This call is not recorded'), findsOneWidget);
      for (final label in ['Mute', 'Earpiece', 'Report', 'End call']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('Mute and Speaker toggle and tell the media layer', (tester) async {
      await pumpCall(tester, active());
      stubJoin();
      env.rtc.emit(const RtcConnected());
      await tester.pumpAndSettle();
      env.rtc.calls.clear();

      await tester.tap(find.text('Mute'));
      await tester.pumpAndSettle();
      expect(find.text('Unmute'), findsOneWidget);
      await tester.tap(find.text('Earpiece'));
      await tester.pumpAndSettle();

      expect(env.rtc.calls, ['mic false', 'speaker true']);
      expect(find.text('Speaker'), findsOneWidget);
    });

    testWidgets('End call hangs up and shows how long it lasted', (tester) async {
      await pumpCall(tester, active());
      stubJoin();
      env.rtc.emit(const RtcConnected());
      await tester.pumpAndSettle();
      when(() => env.repo.end('c1')).thenAnswer(
        (_) async => call(state: 'ENDED', endReason: 'COMPLETED', durationSeconds: 300),
      );

      await tester.tap(find.text('End call'));
      await tester.pumpAndSettle();

      expect(find.text('Call ended'), findsOneWidget);
      expect(find.text('5:00'), findsOneWidget);
      expect(env.rtc.left, isTrue);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('home tab'), findsOneWidget);
    });

    testWidgets('warns two minutes before the longest call time', (tester) async {
      await pumpCall(tester, active(), now: _connected.add(const Duration(minutes: 28)));
      stubJoin();
      env.rtc.emit(const RtcConnected());
      await tester.pumpAndSettle();

      expect(find.text('This call ends in 2:00'), findsOneWidget);
    });

    testWidgets('says when the other person has not joined and when the line is lost',
        (tester) async {
      await pumpCall(tester, active());
      stubJoin();
      env.rtc.emit(const RtcConnected());
      await tester.pumpAndSettle();
      expect(find.text('Waiting for Asha Verma to join…'), findsOneWidget);

      env.rtc.emit(const RtcReconnecting());
      await tester.pumpAndSettle();
      expect(find.text('Reconnecting…'), findsOneWidget);

      env.rtc.emit(const RtcReconnected());
      env.rtc.emit(const RtcQualityChanged(RtcQuality.good));
      await tester.pumpAndSettle();
      expect(find.text('Good connection'), findsOneWidget);

      env.rtc.emit(const RtcDisconnected(RtcDisconnectCause.failed));
      await tester.pumpAndSettle();
      expect(find.text('The connection was lost. End the call and try again.'), findsOneWidget);
    });

    testWidgets('Report opens the report sheet for this call', (tester) async {
      await pumpCall(tester, active());
      stubJoin();
      env.rtc.emit(const RtcConnected());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spam'));
      await tester.pump();
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();

      expect(env.safety.reports.single.target, ReportTarget.call);
      expect(env.safety.reports.single.targetId, 'c1');
      expect(find.text("Thanks. We've received your report"), findsOneWidget);
    });
  });

  group('a video call in progress', () {
    testWidgets('shows the other person full screen and this phone small, with the controls',
        (tester) async {
      final rtc = _PictureRtc();
      await pumpCall(tester, active(type: 'VIDEO'), rtc: rtc);
      stubJoin(media: 'VIDEO', withVideo: true, connected: active(type: 'VIDEO'));
      rtc.emit(const RtcConnected());
      rtc.emit(const RtcRemoteChanged(present: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('remote-picture')), findsOneWidget);
      expect(find.byKey(const Key('local-picture')), findsOneWidget);
      for (final label in [
        'Mute',
        'Turn camera off',
        'Flip camera',
        'Speaker',
        'Report',
        'End call'
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('5:00'), findsOneWidget);
    });

    testWidgets('the small picture can be dragged', (tester) async {
      final rtc = _PictureRtc();
      await pumpCall(tester, active(type: 'VIDEO'), rtc: rtc);
      stubJoin(media: 'VIDEO', withVideo: true, connected: active(type: 'VIDEO'));
      rtc.emit(const RtcConnected());
      await tester.pumpAndSettle();
      final before = tester.getTopLeft(find.byKey(const Key('local-picture')));

      await tester.drag(find.byKey(const Key('local-picture')), const Offset(-120, 200));
      await tester.pumpAndSettle();

      final after = tester.getTopLeft(find.byKey(const Key('local-picture')));
      expect(after.dx, lessThan(before.dx));
      expect(after.dy, greaterThan(before.dy));
    });

    testWidgets('turning the camera off removes the small picture and offers to turn it on',
        (tester) async {
      final rtc = _PictureRtc();
      await pumpCall(tester, active(type: 'VIDEO'), rtc: rtc);
      stubJoin(media: 'VIDEO', withVideo: true, connected: active(type: 'VIDEO'));
      rtc.emit(const RtcConnected());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Turn camera off'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('local-picture')), findsNothing);
      expect(find.text('Turn camera on'), findsOneWidget);
      expect(find.text('Flip camera'), findsNothing);
    });

    testWidgets('a weak line offers Turn off video, which keeps the sound', (tester) async {
      final rtc = _PictureRtc();
      await pumpCall(tester, active(type: 'VIDEO'), rtc: rtc);
      stubJoin(media: 'VIDEO', withVideo: true, connected: active(type: 'VIDEO'));
      rtc.emit(const RtcConnected());
      rtc.emit(const RtcQualityChanged(RtcQuality.poor));
      await tester.pumpAndSettle();
      expect(find.text('Your connection is weak.'), findsOneWidget);

      await tester.tap(find.text('Turn off video'));
      await tester.pumpAndSettle();

      expect(rtc.calls, contains('camera false'));
      expect(find.text('Your connection is weak.'), findsNothing);
    });

    testWidgets('while the other person is not in the room their name and status show',
        (tester) async {
      final rtc = _PictureRtc();
      await pumpCall(tester, active(type: 'VIDEO'), rtc: rtc);
      stubJoin(media: 'VIDEO', withVideo: true, connected: active(type: 'VIDEO'));
      rtc.emit(const RtcConnected());
      await tester.pumpAndSettle();

      expect(find.text('Waiting for Asha Verma to join…'), findsOneWidget);
    });
  });

  group('an ended call', () {
    Future<void> endedWith(WidgetTester tester, String reason, {bool outgoing = true}) =>
        pumpCall(tester, call(state: 'ENDED', endReason: reason, outgoing: outgoing));

    testWidgets('says how it ended for each reason, from the side of the person looking',
        (tester) async {
      final cases = <(String, bool, String)>[
        ('NO_ANSWER', true, 'Asha Verma did not answer'),
        ('NO_ANSWER', false, 'Missed call from Asha Verma'),
        ('CANCELLED', false, 'Missed call from Asha Verma'),
        ('DECLINED', true, 'Asha Verma declined the call'),
        ('DROPPED', true, 'The call ended because the connection was lost'),
        ('MAX_DURATION', true, 'The call reached its time limit'),
        ('BLOCKED', true, 'This call could not continue'),
        ('JOIN_FAILED', true, 'The call could not be connected'),
        ('SYSTEM_ERROR', false, 'The call could not be connected'),
      ];
      for (final (reason, outgoing, text) in cases) {
        await endedWith(tester, reason, outgoing: outgoing);
        expect(find.text(text), findsOneWidget, reason: '$reason outgoing=$outgoing');
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('a call the person ended themselves closes the screen without a summary',
        (tester) async {
      await endedWith(tester, 'CANCELLED');
      expect(find.text('home tab'), findsOneWidget);
    });

    testWidgets('an ended call can be reported and closed', (tester) async {
      await endedWith(tester, 'NO_ANSWER');

      expect(find.text('Report'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('home tab'), findsOneWidget);
    });
  });

  group('problems', () {
    testWidgets('a call that cannot be opened says so and closes', (tester) async {
      await pumpCall(
        tester,
        null,
        readError: const ApiError(type: ApiErrorType.network, message: 'offline'),
      );

      expect(find.text('We could not open this call. Please try again.'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('home tab'), findsOneWidget);
    });

    testWidgets('a room that cannot be joined says so and ends the call', (tester) async {
      env.rtc.joinError = StateError('no route');
      await pumpCall(tester, call(state: 'ACCEPTED'));
      stubJoin();
      when(() => env.repo.end('c1'))
          .thenAnswer((_) async => call(state: 'ENDED', endReason: 'CANCELLED'));
      await tester.pumpAndSettle();

      expect(find.text('We could not connect the call. Please try again.'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('home tab'), findsOneWidget);
    });
  });

  group('layout', () {
    testWidgets('holds at 320 dp wide and 200 percent text in every state', (tester) async {
      final sessions = <CallSession>[
        call(),
        call(outgoing: false, type: 'VIDEO'),
        active(),
        call(state: 'ENDED', endReason: 'NO_ANSWER'),
      ];
      for (final session in sessions) {
        stubJoin();
        await pumpCall(tester, session, textScale: 2, size: const Size(320, 568));
        env.rtc.emit(const RtcConnected());
        await tester.pumpAndSettle();

        final problem = tester.takeException();
        expect(
          problem,
          isNull,
          reason:
              '${session.state} ${session.type}: ${problem is FlutterError ? problem.toStringDeep() : problem}',
        );
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('the video call holds at 320 dp wide and 200 percent text', (tester) async {
      final rtc = _PictureRtc();
      stubJoin(media: 'VIDEO', withVideo: true, connected: active(type: 'VIDEO'));
      await pumpCall(
        tester,
        active(type: 'VIDEO'),
        rtc: rtc,
        textScale: 2,
        size: const Size(320, 568),
      );
      rtc.emit(const RtcConnected());
      rtc.emit(const RtcQualityChanged(RtcQuality.poor));
      await tester.pumpAndSettle();

      final problem = tester.takeException();
      expect(problem, isNull, reason: '$problem');
    });

    testWidgets('speaks Hindi', (tester) async {
      await pumpCall(tester, call(outgoing: false), locale: const Locale('hi'));

      expect(find.text('स्वीकार करें'), findsOneWidget);
      expect(find.text('अस्वीकार करें'), findsOneWidget);
      expect(find.text('आने वाली वॉइस कॉल'), findsOneWidget);
    });

    testWidgets('announces the controls by name', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCall(tester, call(outgoing: false));

      expect(find.bySemanticsLabel('Accept'), findsOneWidget);
      expect(find.bySemanticsLabel('Decline'), findsOneWidget);
      handle.dispose();
    });
  });
}
