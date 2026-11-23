import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/realtime/realtime_event.dart';
import 'package:valuex_mobile/core/realtime/realtime_providers.dart';
import 'package:valuex_mobile/features/calls/data/call_permissions.dart';
import 'package:valuex_mobile/features/calls/data/call_platform.dart';
import 'package:valuex_mobile/features/calls/data/call_repository.dart';
import 'package:valuex_mobile/features/calls/data/rtc/fake_rtc_client.dart';
import 'package:valuex_mobile/features/calls/data/rtc/rtc_client.dart';
import 'package:valuex_mobile/features/calls/domain/call.dart';
import 'package:valuex_mobile/features/calls/presentation/providers/call_controller.dart';

import '../../core/realtime/realtime_fakes.dart';
import 'call_fixtures.dart';

ApiError _error(String code, int status) =>
    ApiError(type: ApiErrorType.business, message: code, code: code, statusCode: status);

class _Harness {
  final repo = MockCallRepository();
  final rtc = FakeRtcClient();
  final permissions = FakeCallPermissions();
  final platform = FakeCallPlatform();
  final realtime = FakeRealtimeClient();
  late final ProviderContainer container;

  _Harness() {
    container = ProviderContainer(
      overrides: [
        callRepositoryProvider.overrideWithValue(repo),
        callRtcClientProvider.overrideWith((ref, callId) => rtc),
        callPermissionsProvider.overrideWithValue(permissions),
        callPlatformProvider.overrideWithValue(platform),
        realtimeClientProvider.overrideWithValue(realtime),
      ],
    );
    container.listen(callControllerProvider('c1'), (previous, next) {});
  }

  CallController get controller => container.read(callControllerProvider('c1').notifier);

  CallUiState get state => container.read(callControllerProvider('c1'));

  /// The server answers [session] to every read of the call, until a test changes it.
  void serverShows(CallSession session) =>
      when(() => repo.get('c1')).thenAnswer((_) async => session);

  void dispose() => container.dispose();
}

final _connected = DateTime.utc(2026, 11, 22, 10);

CallSession _active({String type = 'VOICE', bool outgoing = true}) =>
    call(type: type, state: 'ACTIVE', outgoing: outgoing, connectedAt: _connected);

void main() {
  setUpAll(() => registerFallbackValue(CallType.voice));

  void withHarness(
    String name,
    void Function(_Harness h, FakeAsync async) body,
  ) {
    test(name, () {
      fakeAsync((async) {
        final h = _Harness();
        try {
          body(h, async);
        } finally {
          h.dispose();
        }
      });
    });
  }

  void stubJoin(_Harness h, {String media = 'AUDIO', bool withVideo = false}) {
    when(() => h.repo.join('c1')).thenAnswer(
      (_) async => CallCredentials.fromJson(credentialsJson(media: media, withVideo: withVideo)),
    );
    when(() => h.repo.connected('c1')).thenAnswer((_) async => call(state: 'ACCEPTED'));
  }

  withHarness('a call being made rings until the seller answers', (h, async) {
    h.serverShows(call());

    async.flushMicrotasks();

    expect(h.state.phase, CallPhase.ringingOut);
    expect(h.state.call!.counterpartName, 'Asha Verma');
  });

  withHarness('the phone rings for an incoming call and the caller hears the ringback', (h, async) {
    h.serverShows(call(outgoing: false));
    async.flushMicrotasks();
    expect(h.platform.calls, ['ring incoming=true']);
  });

  withHarness('the caller hears a ringback tone while waiting, and it stops on cancel', (h, async) {
    h.serverShows(call());
    when(() => h.repo.cancel('c1'))
        .thenAnswer((_) async => call(state: 'ENDED', endReason: 'CANCELLED'));
    async.flushMicrotasks();
    async.elapse(const Duration(seconds: 7));
    expect(h.platform.calls, ['ring incoming=false']);

    unawaited(h.controller.cancel());
    async.flushMicrotasks();

    expect(h.platform.calls, ['ring incoming=false', 'stop ring', 'end']);
  });

  withHarness('the ringing stops when the other person answers or the server ends the call',
      (h, async) {
    h.serverShows(call());
    stubJoin(h);
    async.flushMicrotasks();
    h.serverShows(call(state: 'ACCEPTED'));

    async.elapse(const Duration(seconds: 3));

    expect(h.platform.calls.take(2), ['ring incoming=false', 'stop ring']);
  });

  withHarness('a call that rings out stops ringing when it ends unanswered', (h, async) {
    h.serverShows(call(outgoing: false));
    async.flushMicrotasks();
    h.serverShows(call(state: 'ENDED', endReason: 'NO_ANSWER', outgoing: false));

    async.elapse(const Duration(seconds: 3));

    expect(h.platform.calls, ['ring incoming=true', 'stop ring', 'end']);
  });

  withHarness('closing the screen while it rings silences the phone', (h, async) {
    h.serverShows(call(outgoing: false));
    async.flushMicrotasks();

    h.dispose();

    expect(h.platform.calls, ['ring incoming=true', 'stop ring']);
  });

  withHarness('a call being received waits for the person to decide', (h, async) {
    h.serverShows(call(outgoing: false));

    async.flushMicrotasks();

    expect(h.state.phase, CallPhase.ringingIn);
  });

  withHarness('a call that cannot be read is a problem with a reason', (h, async) {
    when(() => h.repo.get('c1')).thenThrow(_error('ERROR_CALL_NOT_FOUND', 404));

    async.flushMicrotasks();

    expect(h.state.phase, CallPhase.failed);
    expect(h.state.problem, CallProblem.loadFailed);
  });

  withHarness('accepting asks for the permissions first and then joins the room', (h, async) {
    h.serverShows(call(outgoing: false));
    stubJoin(h);
    when(() => h.repo.accept('c1'))
        .thenAnswer((_) async => call(state: 'ACCEPTED', outgoing: false));
    async.flushMicrotasks();

    CallPermissionResult? answer;
    h.controller.accept().then((value) => answer = value);
    async.flushMicrotasks();

    expect(answer, CallPermissionResult.granted);
    expect(h.permissions.requests, [false]);
    expect(h.rtc.calls, contains('join video=false'));
    expect(h.state.phase, CallPhase.joining);
    expect(h.platform.calls, ['ring incoming=true', 'stop ring', 'begin video=false']);
  });

  withHarness('a refused permission accepts nothing and says what was refused', (h, async) {
    h.serverShows(call(outgoing: false, type: 'VIDEO'));
    h.permissions.result = CallPermissionResult.cameraDenied;
    async.flushMicrotasks();

    CallPermissionResult? answer;
    h.controller.accept().then((value) => answer = value);
    async.flushMicrotasks();

    expect(answer, CallPermissionResult.cameraDenied);
    expect(h.permissions.requests, [true]);
    verifyNever(() => h.repo.accept(any()));
    expect(h.state.phase, CallPhase.ringingIn);
  });

  withHarness('a second tap on Accept while it is running is ignored', (h, async) {
    h.serverShows(call(outgoing: false));
    stubJoin(h);
    final accepting = Completer<CallSession>();
    when(() => h.repo.accept('c1')).thenAnswer((_) => accepting.future);
    async.flushMicrotasks();

    unawaited(h.controller.accept());
    async.flushMicrotasks();
    unawaited(h.controller.accept());
    async.flushMicrotasks();

    expect(h.permissions.requests, hasLength(1));
    verify(() => h.repo.accept('c1')).called(1);
  });

  withHarness('the caller joins as soon as the server shows the call as accepted', (h, async) {
    h.serverShows(call());
    stubJoin(h);
    async.flushMicrotasks();
    h.serverShows(call(state: 'ACCEPTED'));

    async.elapse(const Duration(seconds: 3));

    expect(h.rtc.calls, contains('join video=false'));
    expect(h.state.phase, CallPhase.joining);
  });

  withHarness('a video call joins with the camera, the limits and the speaker on', (h, async) {
    h.serverShows(call(type: 'VIDEO', state: 'ACCEPTED'));
    stubJoin(h, media: 'VIDEO', withVideo: true);

    async.flushMicrotasks();

    expect(h.rtc.calls, containsAll(['join video=true', 'speaker true']));
    expect(h.rtc.lastCamera!.maxHeight, 720);
    expect(h.state.cameraOn, isTrue);
    expect(h.state.speakerOn, isTrue);
    expect(h.platform.calls, ['begin video=true']);
  });

  withHarness('being in the room is confirmed to the server and the call is on when both are in',
      (h, async) {
    h.serverShows(call(state: 'ACCEPTED'));
    stubJoin(h);
    async.flushMicrotasks();
    when(() => h.repo.connected('c1')).thenAnswer((_) async => _active());

    h.rtc.emit(const RtcConnected());
    async.flushMicrotasks();

    verify(() => h.repo.connected('c1')).called(1);
    expect(h.state.phase, CallPhase.active);
  });

  withHarness('the phone alone in the room keeps waiting for the other person', (h, async) {
    h.serverShows(call(state: 'ACCEPTED'));
    stubJoin(h);
    async.flushMicrotasks();

    h.rtc.emit(const RtcConnected());
    async.flushMicrotasks();

    expect(h.state.phase, CallPhase.joining);
  });

  withHarness('a heartbeat goes to the server every 15 seconds while the call is on', (h, async) {
    h.serverShows(_active());
    stubJoin(h);
    when(() => h.repo.connected('c1')).thenAnswer((_) async => _active());
    when(() => h.repo.heartbeat('c1')).thenAnswer((_) async {});
    async.flushMicrotasks();
    h.rtc.emit(const RtcConnected());
    async.flushMicrotasks();

    async.elapse(const Duration(seconds: 46));

    verify(() => h.repo.heartbeat('c1')).called(3);
  });

  withHarness('a heartbeat refused because the call ended brings the phone to the ended screen',
      (h, async) {
    h.serverShows(_active());
    stubJoin(h);
    when(() => h.repo.connected('c1')).thenAnswer((_) async => _active());
    when(() => h.repo.heartbeat('c1')).thenThrow(_error('ERROR_CALL_NOT_ACTIVE', 409));
    async.flushMicrotasks();
    h.rtc.emit(const RtcConnected());
    async.flushMicrotasks();
    h.serverShows(call(state: 'ENDED', endReason: 'DROPPED'));

    async.elapse(const Duration(seconds: 16));

    expect(h.state.phase, CallPhase.ended);
    expect(h.state.call!.endReason, CallEndReason.dropped);
  });

  withHarness('a network error on a heartbeat is ignored and the next one tries again', (h, async) {
    h.serverShows(_active());
    stubJoin(h);
    when(() => h.repo.connected('c1')).thenAnswer((_) async => _active());
    when(() => h.repo.heartbeat('c1'))
        .thenThrow(const ApiError(type: ApiErrorType.network, message: 'offline'));
    async.flushMicrotasks();
    h.rtc.emit(const RtcConnected());
    async.flushMicrotasks();

    async.elapse(const Duration(seconds: 31));

    expect(h.state.phase, CallPhase.active);
    verify(() => h.repo.heartbeat('c1')).called(2);
  });

  withHarness('when the server ends the call the room is left and the timers stop', (h, async) {
    h.serverShows(_active());
    stubJoin(h);
    when(() => h.repo.connected('c1')).thenAnswer((_) async => _active());
    when(() => h.repo.heartbeat('c1')).thenAnswer((_) async {});
    async.flushMicrotasks();
    h.rtc.emit(const RtcConnected());
    async.flushMicrotasks();
    h.serverShows(call(state: 'ENDED', endReason: 'MAX_DURATION'));

    async.elapse(const Duration(seconds: 13));
    expect(h.state.phase, CallPhase.ended);
    clearInteractions(h.repo);
    async.elapse(const Duration(seconds: 60));

    expect(h.rtc.left, isTrue);
    expect(h.platform.calls.last, 'end');
    verifyNever(() => h.repo.heartbeat(any()));
    verifyNever(() => h.repo.get(any()));
  });

  withHarness('hanging up leaves the room at once and then tells the server', (h, async) {
    h.serverShows(_active());
    stubJoin(h);
    when(() => h.repo.connected('c1')).thenAnswer((_) async => _active());
    when(() => h.repo.end('c1')).thenAnswer(
      (_) async => call(state: 'ENDED', endReason: 'COMPLETED', durationSeconds: 61),
    );
    async.flushMicrotasks();
    h.rtc.emit(const RtcConnected());
    async.flushMicrotasks();

    unawaited(h.controller.hangUp());
    async.flushMicrotasks();

    expect(h.rtc.left, isTrue);
    expect(h.state.phase, CallPhase.ended);
    expect(h.state.call!.durationSeconds, 61);
  });

  withHarness('a room that cannot be joined ends the call and reports a join failure', (h, async) {
    h.serverShows(call(state: 'ACCEPTED'));
    stubJoin(h);
    h.rtc.joinError = StateError('no route');
    when(() => h.repo.end('c1'))
        .thenAnswer((_) async => call(state: 'ENDED', endReason: 'CANCELLED'));

    async.flushMicrotasks();

    expect(h.state.phase, CallPhase.failed);
    expect(h.state.problem, CallProblem.joinFailed);
    verify(() => h.repo.end('c1')).called(1);
  });

  withHarness('credentials the server refuses are a join failure with the server code', (h, async) {
    h.serverShows(call(state: 'ACCEPTED'));
    when(() => h.repo.join('c1')).thenThrow(_error('ERROR_CALL_FAILED', 503));
    when(() => h.repo.end('c1'))
        .thenAnswer((_) async => call(state: 'ENDED', endReason: 'CANCELLED'));

    async.flushMicrotasks();

    expect(h.state.problem, CallProblem.joinFailed);
    expect((h.state.error! as ApiError).code, 'ERROR_CALL_FAILED');
  });

  withHarness('the server saying it is not active when confirming sends the phone to read the call',
      (h, async) {
    h.serverShows(call(state: 'ACCEPTED'));
    stubJoin(h);
    when(() => h.repo.connected('c1')).thenThrow(_error('ERROR_CALL_NOT_ACTIVE', 409));
    async.flushMicrotasks();
    h.serverShows(call(state: 'ENDED', endReason: 'CANCELLED'));

    h.rtc.emit(const RtcConnected());
    async.flushMicrotasks();

    expect(h.state.phase, CallPhase.ended);
  });

  withHarness('a confirmation that keeps failing gives up after three tries', (h, async) {
    h.serverShows(call(state: 'ACCEPTED'));
    stubJoin(h);
    when(() => h.repo.connected('c1'))
        .thenThrow(const ApiError(type: ApiErrorType.network, message: 'offline'));
    when(() => h.repo.end('c1'))
        .thenAnswer((_) async => call(state: 'ENDED', endReason: 'CANCELLED'));
    async.flushMicrotasks();

    h.rtc.emit(const RtcConnected());
    async.elapse(const Duration(seconds: 5));

    verify(() => h.repo.connected('c1')).called(3);
    expect(h.state.phase, CallPhase.failed);
  });

  withHarness('the media connection dropping and coming back moves between reconnecting and active',
      (h, async) {
    h.serverShows(_active());
    stubJoin(h);
    when(() => h.repo.connected('c1')).thenAnswer((_) async => _active());
    when(() => h.repo.heartbeat('c1')).thenAnswer((_) async {});
    async.flushMicrotasks();
    h.rtc.emit(const RtcConnected());
    async.flushMicrotasks();

    h.rtc.emit(const RtcReconnecting());
    async.flushMicrotasks();
    expect(h.state.phase, CallPhase.reconnecting);

    h.rtc.emit(const RtcReconnected());
    async.flushMicrotasks();
    expect(h.state.phase, CallPhase.active);
  });

  withHarness('a connection lost for good stops the heartbeat and says so', (h, async) {
    h.serverShows(_active());
    stubJoin(h);
    when(() => h.repo.connected('c1')).thenAnswer((_) async => _active());
    when(() => h.repo.heartbeat('c1')).thenAnswer((_) async {});
    async.flushMicrotasks();
    h.rtc.emit(const RtcConnected());
    async.flushMicrotasks();

    h.rtc.emit(const RtcDisconnected(RtcDisconnectCause.failed));
    async.flushMicrotasks();
    clearInteractions(h.repo);
    async.elapse(const Duration(seconds: 60));

    expect(h.state.problem, CallProblem.connectionLost);
    verifyNever(() => h.repo.heartbeat('c1'));
  });

  withHarness('being removed from the room reads the call from the server', (h, async) {
    h.serverShows(_active());
    stubJoin(h);
    when(() => h.repo.connected('c1')).thenAnswer((_) async => _active());
    when(() => h.repo.heartbeat('c1')).thenAnswer((_) async {});
    async.flushMicrotasks();
    h.rtc.emit(const RtcConnected());
    async.flushMicrotasks();
    h.serverShows(call(state: 'ENDED', endReason: 'COMPLETED'));

    h.rtc.emit(const RtcDisconnected(RtcDisconnectCause.removed));
    async.flushMicrotasks();

    expect(h.state.phase, CallPhase.ended);
  });

  withHarness('a disconnect the phone caused itself is not an error', (h, async) {
    h.serverShows(_active());
    stubJoin(h);
    when(() => h.repo.connected('c1')).thenAnswer((_) async => _active());
    when(() => h.repo.end('c1'))
        .thenAnswer((_) async => call(state: 'ENDED', endReason: 'COMPLETED'));
    async.flushMicrotasks();
    h.rtc.emit(const RtcConnected());
    async.flushMicrotasks();

    unawaited(h.controller.hangUp());
    h.rtc.emit(const RtcDisconnected(RtcDisconnectCause.local));
    async.flushMicrotasks();

    expect(h.state.problem, isNull);
  });

  withHarness('the other person joining and leaving, and the line quality, are shown', (h, async) {
    h.serverShows(_active(type: 'VIDEO'));
    stubJoin(h, media: 'VIDEO', withVideo: true);
    when(() => h.repo.connected('c1')).thenAnswer((_) async => _active(type: 'VIDEO'));
    when(() => h.repo.heartbeat('c1')).thenAnswer((_) async {});
    async.flushMicrotasks();
    h.rtc.emit(const RtcConnected());
    async.flushMicrotasks();

    h.rtc.emit(const RtcRemoteChanged(present: true));
    h.rtc.emit(const RtcQualityChanged(RtcQuality.poor));
    async.flushMicrotasks();

    expect(h.state.remotePresent, isTrue);
    expect(h.state.lowBandwidth, isTrue);

    h.rtc.emit(const RtcQualityChanged(RtcQuality.good));
    async.flushMicrotasks();
    expect(h.state.lowBandwidth, isFalse);
  });

  withHarness('a weak line only offers Turn off video on a video call with the camera on',
      (h, async) {
    h.serverShows(_active());
    stubJoin(h);
    when(() => h.repo.connected('c1')).thenAnswer((_) async => _active());
    when(() => h.repo.heartbeat('c1')).thenAnswer((_) async {});
    async.flushMicrotasks();
    h.rtc.emit(const RtcConnected());
    h.rtc.emit(const RtcQualityChanged(RtcQuality.lost));
    async.flushMicrotasks();

    expect(h.state.lowBandwidth, isFalse);
  });

  withHarness('mute, camera, flip, speaker and Turn off video go to the media layer', (h, async) {
    h.serverShows(_active(type: 'VIDEO'));
    stubJoin(h, media: 'VIDEO', withVideo: true);
    when(() => h.repo.connected('c1')).thenAnswer((_) async => _active(type: 'VIDEO'));
    when(() => h.repo.heartbeat('c1')).thenAnswer((_) async {});
    async.flushMicrotasks();
    h.rtc.emit(const RtcConnected());
    async.flushMicrotasks();
    h.rtc.calls.clear();

    unawaited(h.controller.toggleMute());
    unawaited(h.controller.toggleMute());
    unawaited(h.controller.flipCamera());
    unawaited(h.controller.toggleSpeaker());
    unawaited(h.controller.toggleCamera());
    unawaited(h.controller.toggleCamera());
    unawaited(h.controller.turnOffVideo());
    unawaited(h.controller.turnOffVideo());
    async.flushMicrotasks();

    expect(h.rtc.calls, [
      'mic false',
      'mic true',
      'flip',
      'speaker false',
      'camera false',
      'camera true',
      'camera false',
    ]);
    expect(h.state.muted, isFalse);
    expect(h.state.cameraOn, isFalse);
    expect(h.state.speakerOn, isFalse);
    expect(h.controller.cameraLimits.maxFps, 24);
  });

  withHarness('the person called can decline, and the caller can cancel', (h, async) {
    h.serverShows(call(outgoing: false));
    when(() => h.repo.decline('c1'))
        .thenAnswer((_) async => call(state: 'ENDED', endReason: 'DECLINED', outgoing: false));
    async.flushMicrotasks();

    unawaited(h.controller.decline());
    async.flushMicrotasks();

    expect(h.state.phase, CallPhase.ended);
    expect(h.state.call!.endReason, CallEndReason.declined);
  });

  withHarness('cancelling a call before it is answered ends it', (h, async) {
    h.serverShows(call());
    when(() => h.repo.cancel('c1'))
        .thenAnswer((_) async => call(state: 'ENDED', endReason: 'CANCELLED'));
    async.flushMicrotasks();

    unawaited(h.controller.cancel());
    async.flushMicrotasks();

    expect(h.state.phase, CallPhase.ended);
    expect(h.state.call!.endReason, CallEndReason.cancelled);
  });

  withHarness('an action the server refuses because the call moved on reads the call again',
      (h, async) {
    h.serverShows(call(outgoing: false));
    when(() => h.repo.decline('c1')).thenThrow(_error('ERROR_CALL_NOT_ACTIVE', 409));
    async.flushMicrotasks();
    h.serverShows(call(state: 'ENDED', endReason: 'NO_ANSWER', outgoing: false));

    unawaited(h.controller.decline());
    async.flushMicrotasks();

    expect(h.state.phase, CallPhase.ended);
  });

  withHarness('an action that fails on the network keeps the screen and shows the error',
      (h, async) {
    h.serverShows(call());
    when(() => h.repo.cancel('c1'))
        .thenThrow(const ApiError(type: ApiErrorType.network, message: 'offline'));
    async.flushMicrotasks();

    unawaited(h.controller.cancel());
    async.flushMicrotasks();

    expect(h.state.phase, CallPhase.ringingOut);
    expect(h.state.busy, isFalse);
    expect(h.state.error, isA<ApiError>());
  });

  withHarness(
      'a call.updated event for this call reads it again, and one for another call does not',
      (h, async) {
    h.serverShows(call());
    async.flushMicrotasks();
    h.serverShows(call(state: 'ENDED', endReason: 'NO_ANSWER'));

    h.realtime.emit(RealtimeTypes.callUpdated, {'callId': 'other'});
    async.flushMicrotasks();
    expect(h.state.phase, CallPhase.ringingOut);

    h.realtime.emit(RealtimeTypes.callUpdated, {'callId': 'c1'});
    async.flushMicrotasks();
    expect(h.state.phase, CallPhase.ended);
  });

  withHarness('a reconnect of the live connection reads the call again', (h, async) {
    h.serverShows(call());
    async.flushMicrotasks();
    h.serverShows(call(state: 'ENDED', endReason: 'NO_ANSWER'));

    h.container.read(realtimeResyncProvider.notifier).bump();
    async.flushMicrotasks();

    expect(h.state.phase, CallPhase.ended);
  });

  withHarness('the ringing call is read again every three seconds', (h, async) {
    h.serverShows(call());
    async.flushMicrotasks();

    async.elapse(const Duration(seconds: 7));

    verify(() => h.repo.get('c1')).called(3);
  });

  test('disposing the controller of a call that was joined stops the phone help', () {
    fakeAsync((async) {
      final h = _Harness();
      h.serverShows(call(state: 'ACCEPTED'));
      stubJoin(h);
      async.flushMicrotasks();

      h.dispose();
      async.flushMicrotasks();

      expect(h.platform.calls, ['begin video=false', 'end']);
    });
  });
}
