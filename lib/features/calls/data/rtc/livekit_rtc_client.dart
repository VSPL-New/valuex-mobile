import 'dart:async';

import 'package:flutter/widgets.dart';

import 'livekit_room_gateway.dart';
import 'rtc_client.dart';

/// [RtcClient] for LiveKit (US-014, US-015). It joins with the URL and token the server issued and
/// turns the gateway's events into ours. A person who joins a video call publishes the camera too.
class LiveKitRtcClient implements RtcClient {
  final LiveKitRoomGateway _gateway;
  final StreamController<RtcEvent> _events = StreamController<RtcEvent>.broadcast();
  StreamSubscription<GatewayEvent>? _subscription;
  bool _joined = false;
  CameraLimits _camera = const CameraLimits();

  LiveKitRtcClient(this._gateway);

  @override
  Stream<RtcEvent> get events => _events.stream;

  @override
  Future<void> join({
    required String url,
    required String token,
    required bool video,
    CameraLimits camera = const CameraLimits(),
  }) async {
    _subscription ??= _gateway.events.listen(_forward);
    await _gateway.connect(url, token);
    _joined = true;
    _camera = camera;
    await _gateway.setMicrophoneEnabled(enabled: true);
    if (video) await _gateway.setCameraEnabled(enabled: true, limits: camera);
  }

  void _forward(GatewayEvent event) {
    switch (event) {
      case GatewayConnected():
        _events.add(const RtcConnected());
      case GatewayReconnecting():
        _events.add(const RtcReconnecting());
      case GatewayReconnected():
        _events.add(const RtcReconnected());
      case GatewayDisconnected(:final reason):
        _events.add(RtcDisconnected(_cause(reason)));
      case GatewayRemote(:final present):
        _events.add(RtcRemoteChanged(present: present));
      case GatewayQuality(:final quality):
        _events.add(RtcQualityChanged(quality));
    }
  }

  static RtcDisconnectCause _cause(GatewayDisconnectReason reason) => switch (reason) {
        GatewayDisconnectReason.local => RtcDisconnectCause.local,
        GatewayDisconnectReason.removed => RtcDisconnectCause.removed,
        GatewayDisconnectReason.roomDeleted => RtcDisconnectCause.roomEnded,
        GatewayDisconnectReason.duplicate => RtcDisconnectCause.duplicate,
        GatewayDisconnectReason.failed => RtcDisconnectCause.failed,
        GatewayDisconnectReason.other => RtcDisconnectCause.other,
      };

  @override
  Future<void> setMicrophoneEnabled({required bool enabled}) =>
      _gateway.setMicrophoneEnabled(enabled: enabled);

  @override
  Future<void> setCameraEnabled({required bool enabled}) =>
      _gateway.setCameraEnabled(enabled: enabled, limits: _camera);

  @override
  Future<void> flipCamera() => _gateway.flipCamera();

  @override
  Future<void> setSpeakerOn({required bool on}) => _gateway.setSpeakerOn(on: on);

  @override
  Widget remoteVideo() => _gateway.remoteVideo();

  @override
  Widget localVideo() => _gateway.localVideo();

  @override
  Future<void> leave() async {
    await _subscription?.cancel();
    _subscription = null;
    if (_joined) {
      _joined = false;
      await _gateway.disconnect();
    }
  }
}
