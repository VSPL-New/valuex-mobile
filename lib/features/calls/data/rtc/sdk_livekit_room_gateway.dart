import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import 'livekit_room_gateway.dart';
import 'rtc_client.dart';

/// [LiveKitRoomGateway] over the LiveKit Flutter SDK. This is the only file that touches the SDK's
/// room, so it stays thin: it forwards calls and translates events. The camera is capped at 720p and
/// 24 frames per second (US-015).
class SdkLiveKitRoomGateway implements LiveKitRoomGateway {
  static const double _maxFrameRate = 24;

  final lk.Room _room = lk.Room(
    roomOptions: const lk.RoomOptions(
      adaptiveStream: true,
      dynacast: true,
      defaultCameraCaptureOptions: lk.CameraCaptureOptions(
        params: lk.VideoParametersPresets.h720_169,
        maxFrameRate: _maxFrameRate,
      ),
    ),
  );
  final StreamController<GatewayEvent> _events = StreamController<GatewayEvent>.broadcast();
  late final lk.EventsListener<lk.RoomEvent> _listener = _room.createListener();
  bool _listening = false;

  @override
  Stream<GatewayEvent> get events => _events.stream;

  void _listen() {
    if (_listening) return;
    _listening = true;
    _listener
      ..on<lk.RoomReconnectingEvent>((_) => _events.add(const GatewayReconnecting()))
      ..on<lk.RoomResumingEvent>((_) => _events.add(const GatewayReconnecting()))
      ..on<lk.RoomReconnectedEvent>((_) => _events.add(const GatewayReconnected()))
      ..on<lk.RoomDisconnectedEvent>((e) => _events.add(GatewayDisconnected(_reason(e.reason))))
      ..on<lk.ParticipantConnectedEvent>((_) => _events.add(const GatewayRemote(present: true)))
      ..on<lk.ParticipantDisconnectedEvent>(
        (_) => _events.add(GatewayRemote(present: _room.remoteParticipants.isNotEmpty)),
      )
      ..on<lk.ParticipantConnectionQualityUpdatedEvent>(
        (e) => _events.add(GatewayQuality(_quality(e.connectionQuality))),
      );
  }

  @override
  Future<void> connect(String url, String token) async {
    _listen();
    await _room.connect(url, token);
    _events.add(const GatewayConnected());
    if (_room.remoteParticipants.isNotEmpty) {
      _events.add(const GatewayRemote(present: true));
    }
  }

  @override
  Future<void> setMicrophoneEnabled({required bool enabled}) async {
    await _room.localParticipant?.setMicrophoneEnabled(enabled);
  }

  @override
  Future<void> setCameraEnabled({
    required bool enabled,
    CameraLimits limits = const CameraLimits(),
  }) async {
    await _room.localParticipant?.setCameraEnabled(
      enabled,
      cameraCaptureOptions: lk.CameraCaptureOptions(
        params: _preset(limits.standardHeight),
        maxFrameRate: limits.maxFps.toDouble(),
      ),
    );
  }

  static lk.VideoParameters _preset(int height) => switch (height) {
        1080 => lk.VideoParametersPresets.h1080_169,
        720 => lk.VideoParametersPresets.h720_169,
        540 => lk.VideoParametersPresets.h540_169,
        _ => lk.VideoParametersPresets.h360_169,
      };

  @override
  Future<void> flipCamera() async {
    final track = _room.localParticipant?.videoTrackPublications.firstOrNull?.track;
    if (track is! lk.LocalVideoTrack) return;
    final options = track.currentOptions;
    final front =
        options is! lk.CameraCaptureOptions || options.cameraPosition == lk.CameraPosition.front;
    await track.setCameraPosition(front ? lk.CameraPosition.back : lk.CameraPosition.front);
  }

  @override
  Future<void> setSpeakerOn({required bool on}) async {
    await lk.AudioManager.instance.setSpeakerOutputPreferred(on);
  }

  @override
  Widget remoteVideo() {
    for (final participant in _room.remoteParticipants.values) {
      for (final pub in participant.videoTrackPublications) {
        final track = pub.track;
        if (track != null && pub.subscribed && !pub.muted) {
          return lk.VideoTrackRenderer(track, fit: lk.VideoViewFit.cover);
        }
      }
    }
    return const SizedBox.shrink();
  }

  @override
  Widget localVideo() {
    final pub = _room.localParticipant?.videoTrackPublications.firstOrNull;
    final track = pub?.track;
    if (track != null && !(pub?.muted ?? true)) {
      return lk.VideoTrackRenderer(track, fit: lk.VideoViewFit.cover);
    }
    return const SizedBox.shrink();
  }

  @override
  Future<void> disconnect() async {
    await _room.disconnect();
    await _listener.cancelAll();
    await _room.dispose();
  }

  static GatewayDisconnectReason _reason(lk.DisconnectReason? reason) => switch (reason) {
        lk.DisconnectReason.clientInitiated => GatewayDisconnectReason.local,
        lk.DisconnectReason.participantRemoved => GatewayDisconnectReason.removed,
        lk.DisconnectReason.roomDeleted => GatewayDisconnectReason.roomDeleted,
        lk.DisconnectReason.duplicateIdentity => GatewayDisconnectReason.duplicate,
        lk.DisconnectReason.joinFailure ||
        lk.DisconnectReason.stateMismatch ||
        lk.DisconnectReason.serverShutdown =>
          GatewayDisconnectReason.failed,
        _ => GatewayDisconnectReason.other,
      };

  static RtcQuality _quality(lk.ConnectionQuality quality) => switch (quality) {
        lk.ConnectionQuality.lost => RtcQuality.lost,
        lk.ConnectionQuality.poor => RtcQuality.poor,
        lk.ConnectionQuality.good => RtcQuality.good,
        lk.ConnectionQuality.excellent => RtcQuality.excellent,
        _ => RtcQuality.unknown,
      };
}
