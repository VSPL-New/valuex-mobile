import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/realtime/realtime_event.dart';
import '../../../../core/realtime/realtime_providers.dart';
import '../../data/call_permissions.dart';
import '../../data/call_platform.dart';
import '../../data/call_repository.dart';
import '../../data/rtc/livekit_rtc_client.dart';
import '../../data/rtc/rtc_client.dart';
import '../../data/rtc/sdk_livekit_room_gateway.dart';
import '../../domain/call.dart';

/// Where the call screen stands.
enum CallPhase {
  /// Reading the call.
  loading,

  /// The caller waits for an answer.
  ringingOut,

  /// The person called decides.
  ringingIn,

  /// Accepted: getting into the room and waiting for the other person.
  joining,

  /// Both are in the room.
  active,

  /// The media connection dropped and the phone is getting it back.
  reconnecting,

  /// The call is over. [CallUiState.call] holds how it ended.
  ended,

  /// The call could not be read or joined. [CallUiState.error] holds why.
  failed,
}

/// Why the call screen shows a problem.
enum CallProblem { loadFailed, joinFailed, connectionLost }

class CallUiState {
  final CallPhase phase;
  final CallSession? call;
  final bool muted;
  final bool cameraOn;
  final bool speakerOn;
  final bool remotePresent;
  final RtcQuality quality;
  final CallProblem? problem;
  final Object? error;

  /// An accept, decline, cancel or hang-up is running; a second tap is ignored.
  final bool busy;

  const CallUiState({
    this.phase = CallPhase.loading,
    this.call,
    this.muted = false,
    this.cameraOn = false,
    this.speakerOn = false,
    this.remotePresent = false,
    this.quality = RtcQuality.unknown,
    this.problem,
    this.error,
    this.busy = false,
  });

  bool get isVideo => call?.type.hasVideo ?? false;

  /// The picture or sound is poor enough on a video call to offer Turn off video.
  bool get lowBandwidth =>
      isVideo && cameraOn && (quality == RtcQuality.poor || quality == RtcQuality.lost);

  CallUiState copyWith({
    CallPhase? phase,
    CallSession? call,
    bool? muted,
    bool? cameraOn,
    bool? speakerOn,
    bool? remotePresent,
    RtcQuality? quality,
    CallProblem? problem,
    bool clearProblem = false,
    Object? error,
    bool? busy,
  }) =>
      CallUiState(
        phase: phase ?? this.phase,
        call: call ?? this.call,
        muted: muted ?? this.muted,
        cameraOn: cameraOn ?? this.cameraOn,
        speakerOn: speakerOn ?? this.speakerOn,
        remotePresent: remotePresent ?? this.remotePresent,
        quality: quality ?? this.quality,
        problem: clearProblem ? null : (problem ?? this.problem),
        error: clearProblem ? null : (error ?? this.error),
        busy: busy ?? this.busy,
      );
}

/// One call on this phone (US-014, US-015). The server decides the state; this follows it over REST,
/// the live connection's `call.updated` hints and a short poll, joins the media room when the call is
/// accepted, tells the server the phone is in the room, and sends a sign of life every 15 seconds.
class CallController extends Notifier<CallUiState> {
  static const heartbeatEvery = Duration(seconds: 15);
  static const _pollEvery = Duration(seconds: 3);
  static const _activePollEveryTicks = 4;
  static const _confirmAttempts = 3;
  static const _confirmRetryAfter = Duration(seconds: 1);

  final String callId;

  late final CallRepository _repository;
  late final RtcClient _rtc;
  late final CallPlatform _platform;
  Timer? _poller;
  Timer? _heartbeat;
  StreamSubscription<RtcEvent>? _rtcEvents;
  CallSession? _call;
  bool _joinStarted = false;
  bool _leaving = false;
  bool _finished = false;
  bool _confirmed = false;
  bool _ringing = false;
  bool _refreshing = false;
  int _ticks = 0;
  CameraLimits _limits = const CameraLimits();

  CallController(this.callId);

  @override
  CallUiState build() {
    _repository = ref.watch(callRepositoryProvider);
    _rtc = ref.watch(callRtcClientProvider(callId));
    _platform = ref.watch(callPlatformProvider);
    _rtcEvents = _rtc.events.listen(_onRtcEvent);
    final live = ref.watch(callEventsProvider).listen((event) {
      if (event.type == RealtimeTypes.callUpdated && event.data['callId'] == callId) {
        unawaited(_refresh());
      }
    });
    ref.listen<int>(realtimeResyncProvider, (previous, next) => unawaited(_refresh()));
    ref.onDispose(() {
      live.cancel();
      _rtcEvents?.cancel();
      _poller?.cancel();
      _heartbeat?.cancel();
      if (_ringing) unawaited(_platform.stopRinging());
      if (_joinStarted) unawaited(_platform.end());
    });
    Future<void>.microtask(_refresh);
    return const CallUiState();
  }

  // ---- reading the call

  Future<void> _refresh() async {
    if (_finished || _refreshing) return;
    _refreshing = true;
    try {
      _apply(await _repository.get(callId));
    } on ApiError catch (error) {
      if (_call == null) _fail(CallProblem.loadFailed, error);
    } finally {
      _refreshing = false;
    }
  }

  void _apply(CallSession call) {
    if (!ref.mounted || _finished) return;
    // A call that could not be joined stays a problem until the server says it is over.
    if (state.problem == CallProblem.joinFailed && call.state != CallState.ended) return;
    _call = call;
    if (call.state == CallState.ended) {
      unawaited(_finish(call));
      return;
    }
    _startPoller();
    switch (call.state) {
      case CallState.ringing:
        _emit(call, call.outgoing ? CallPhase.ringingOut : CallPhase.ringingIn);
      case CallState.accepted:
        if (!_joinStarted) {
          unawaited(_join());
        } else {
          _emit(
            call,
            state.phase == CallPhase.reconnecting ? CallPhase.reconnecting : CallPhase.joining,
          );
        }
      case CallState.active:
        if (!_joinStarted) {
          unawaited(_join());
        } else {
          _emit(call, _confirmed ? _activePhase : CallPhase.joining);
          _startHeartbeat();
        }
      case CallState.ended:
        break;
    }
  }

  CallPhase get _activePhase =>
      state.phase == CallPhase.reconnecting ? CallPhase.reconnecting : CallPhase.active;

  void _emit(CallSession call, CallPhase phase) {
    _syncRing(phase);
    state = state.copyWith(call: call, phase: phase, busy: false);
  }

  /// The phone rings only while the call waits for an answer.
  void _syncRing(CallPhase phase) {
    final wanted = phase == CallPhase.ringingIn || phase == CallPhase.ringingOut;
    if (wanted == _ringing) return;
    _ringing = wanted;
    if (wanted) {
      unawaited(_platform.startRinging(incoming: phase == CallPhase.ringingIn));
    } else {
      unawaited(_platform.stopRinging());
    }
  }

  void _fail(CallProblem problem, Object error) {
    if (!ref.mounted) return;
    _syncRing(CallPhase.failed);
    state = state.copyWith(phase: CallPhase.failed, problem: problem, error: error, busy: false);
  }

  void _startPoller() {
    _poller ??= Timer.periodic(_pollEvery, (_) {
      _ticks++;
      final active = state.phase == CallPhase.active;
      if (!active || _ticks % _activePollEveryTicks == 0) unawaited(_refresh());
    });
  }

  // ---- joining the room

  Future<void> _join() async {
    _joinStarted = true;
    final call = _call!;
    _syncRing(CallPhase.joining);
    state = state.copyWith(call: call, phase: CallPhase.joining, busy: false);
    try {
      final credentials = await _repository.join(callId);
      _limits = credentials.camera;
      await _rtc.join(
        url: credentials.url,
        token: credentials.token,
        video: credentials.media.hasVideo,
        camera: credentials.camera,
      );
      final video = credentials.media.hasVideo;
      final speaker = video;
      state = state.copyWith(cameraOn: video, speakerOn: speaker);
      await _rtc.setSpeakerOn(on: speaker);
      await _platform.begin(video: video);
    } on Object catch (error) {
      await _joinFailed(error);
    }
  }

  Future<void> _joinFailed(Object error) async {
    if (_finished) return;
    _joinStarted = false;
    try {
      await _rtc.leave();
      await _repository.end(callId);
    } on Object {
      // The server ends the call by itself when nobody joins in time.
    }
    _fail(CallProblem.joinFailed, error);
  }

  Future<void> _confirmConnected() async {
    for (var attempt = 0; attempt < _confirmAttempts; attempt++) {
      try {
        final call = await _repository.connected(callId);
        _confirmed = true;
        _apply(call);
        return;
      } on ApiError catch (error) {
        if (error.statusCode == 409) {
          await _refresh();
          return;
        }
        if (attempt == _confirmAttempts - 1) {
          await _joinFailed(error);
          return;
        }
        await Future<void>.delayed(_confirmRetryAfter);
      }
    }
  }

  void _onRtcEvent(RtcEvent event) {
    if (_finished || !ref.mounted) return;
    switch (event) {
      case RtcConnected():
        unawaited(_confirmConnected());
      case RtcReconnecting():
        state = state.copyWith(phase: CallPhase.reconnecting);
      case RtcReconnected():
        state = state.copyWith(
          phase: state.call?.state == CallState.active ? CallPhase.active : CallPhase.joining,
          clearProblem: true,
        );
        if (state.phase == CallPhase.active) _startHeartbeat();
      case RtcDisconnected(:final cause):
        _onDisconnected(cause);
      case RtcRemoteChanged(:final present):
        state = state.copyWith(remotePresent: present);
      case RtcQualityChanged(:final quality):
        state = state.copyWith(quality: quality);
    }
  }

  void _onDisconnected(RtcDisconnectCause cause) {
    if (_leaving) return;
    switch (cause) {
      case RtcDisconnectCause.removed || RtcDisconnectCause.roomEnded:
        unawaited(_refresh());
      case RtcDisconnectCause.local:
        break;
      case RtcDisconnectCause.duplicate || RtcDisconnectCause.failed || RtcDisconnectCause.other:
        _heartbeat?.cancel();
        _heartbeat = null;
        state = state.copyWith(problem: CallProblem.connectionLost);
    }
  }

  // ---- the sign of life

  void _startHeartbeat() {
    if (_heartbeat != null || state.problem == CallProblem.connectionLost) return;
    _heartbeat = Timer.periodic(heartbeatEvery, (_) => unawaited(_beat()));
  }

  Future<void> _beat() async {
    try {
      await _repository.heartbeat(callId);
    } on ApiError catch (error) {
      if (error.code == 'ERROR_CALL_NOT_ACTIVE') await _refresh();
    }
  }

  // ---- what the person does

  /// Accepts the ringing call after the permissions are granted. Returns what the person answered.
  Future<CallPermissionResult> accept() async {
    final call = _call;
    if (call == null || state.busy || state.phase != CallPhase.ringingIn) {
      return CallPermissionResult.granted;
    }
    final permission = await ref.read(callPermissionsProvider).request(video: call.type.hasVideo);
    if (permission != CallPermissionResult.granted || !ref.mounted) return permission;
    state = state.copyWith(busy: true);
    await _act(_repository.accept);
    return permission;
  }

  Future<void> decline() => _act(_repository.decline);

  Future<void> cancel() => _act(_repository.cancel);

  /// Hangs up: leaves the room first so the sound stops at once, then tells the server.
  Future<void> hangUp() async {
    if (state.busy || _finished) return;
    state = state.copyWith(busy: true);
    _leaving = true;
    try {
      await _rtc.leave();
    } on Object {
      // The server ends the room anyway.
    }
    await _act(_repository.end);
  }

  Future<void> _act(Future<CallSession> Function(String callId) action) async {
    if (_finished) return;
    _syncRing(CallPhase.joining);
    state = state.copyWith(busy: true);
    try {
      _apply(await action(callId));
    } on ApiError catch (error) {
      if (error.statusCode == 409 || error.statusCode == 404) {
        await _refresh();
      } else if (ref.mounted) {
        state = state.copyWith(busy: false, error: error);
      }
    }
  }

  Future<void> toggleMute() async {
    final muted = !state.muted;
    state = state.copyWith(muted: muted);
    await _rtc.setMicrophoneEnabled(enabled: !muted);
  }

  Future<void> toggleCamera() async {
    final on = !state.cameraOn;
    state = state.copyWith(cameraOn: on);
    await _rtc.setCameraEnabled(enabled: on);
  }

  /// The camera is on for the whole call unless the person (or the weak line) turns it off.
  Future<void> turnOffVideo() async {
    if (!state.cameraOn) return;
    state = state.copyWith(cameraOn: false);
    await _rtc.setCameraEnabled(enabled: false);
  }

  Future<void> flipCamera() => _rtc.flipCamera();

  Future<void> toggleSpeaker() async {
    final on = !state.speakerOn;
    state = state.copyWith(speakerOn: on);
    await _rtc.setSpeakerOn(on: on);
  }

  CameraLimits get cameraLimits => _limits;

  // ---- the end

  Future<void> _finish(CallSession call) async {
    if (_finished) return;
    _finished = true;
    _syncRing(CallPhase.ended);
    _poller?.cancel();
    _heartbeat?.cancel();
    _poller = null;
    _heartbeat = null;
    try {
      await _rtc.leave();
    } on Object {
      // Already out of the room.
    }
    await _platform.end();
    if (!ref.mounted) return;
    state = state.copyWith(call: call, phase: CallPhase.ended, busy: false, clearProblem: true);
  }
}

final callControllerProvider =
    NotifierProvider.autoDispose.family<CallController, CallUiState, String>(CallController.new);

/// The media connection of one call. Each call has its own; tests replace it with a fake.
final callRtcClientProvider = Provider.autoDispose.family<RtcClient, String>((ref, callId) {
  final client = LiveKitRtcClient(SdkLiveKitRoomGateway());
  ref.onDispose(() => unawaited(client.leave()));
  return client;
});

/// The phone's clock, once a second, for the timer and the ringing countdown.
final callTickProvider = StreamProvider.autoDispose<DateTime>(
  (ref) => Stream<DateTime>.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
);
