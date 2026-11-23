import 'package:flutter/widgets.dart';

import 'rtc_client.dart';

/// Why the room closed on this phone, as the gateway reports it.
enum GatewayDisconnectReason { local, removed, roomDeleted, duplicate, failed, other }

sealed class GatewayEvent {
  const GatewayEvent();
}

class GatewayConnected extends GatewayEvent {
  const GatewayConnected();
}

class GatewayReconnecting extends GatewayEvent {
  const GatewayReconnecting();
}

class GatewayReconnected extends GatewayEvent {
  const GatewayReconnected();
}

class GatewayDisconnected extends GatewayEvent {
  final GatewayDisconnectReason reason;

  const GatewayDisconnected(this.reason);
}

class GatewayRemote extends GatewayEvent {
  final bool present;

  const GatewayRemote({required this.present});
}

class GatewayQuality extends GatewayEvent {
  final RtcQuality quality;

  const GatewayQuality(this.quality);
}

/// A thin wrapper over the LiveKit room: no logic, so the mapping in [LiveKitRtcClient] can be tested
/// without the SDK. [SdkLiveKitRoomGateway] is the real one.
abstract class LiveKitRoomGateway {
  Stream<GatewayEvent> get events;

  Future<void> connect(String url, String token);

  Future<void> setMicrophoneEnabled({required bool enabled});

  Future<void> setCameraEnabled({
    required bool enabled,
    CameraLimits limits = const CameraLimits(),
  });

  Future<void> flipCamera();

  Future<void> setSpeakerOn({required bool on});

  Widget remoteVideo();

  Widget localVideo();

  Future<void> disconnect();
}
