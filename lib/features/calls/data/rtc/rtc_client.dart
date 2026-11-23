import 'package:flutter/widgets.dart';

/// How good the connection to the other person is, as the call SDK reports it.
enum RtcQuality { unknown, lost, poor, good, excellent }

/// Why the media connection ended, in our own terms (the SDK's reasons stay inside the adapter).
enum RtcDisconnectCause { local, removed, roomEnded, duplicate, failed, other }

/// What the media layer tells the call controller. The controller never sees the SDK's types.
sealed class RtcEvent {
  const RtcEvent();
}

/// This phone is in the room and the media is flowing.
class RtcConnected extends RtcEvent {
  const RtcConnected();
}

/// The connection dropped and the SDK is trying to get it back.
class RtcReconnecting extends RtcEvent {
  const RtcReconnecting();
}

class RtcReconnected extends RtcEvent {
  const RtcReconnected();
}

class RtcDisconnected extends RtcEvent {
  final RtcDisconnectCause cause;

  const RtcDisconnected(this.cause);
}

/// The other person's media joined or left the room.
class RtcRemoteChanged extends RtcEvent {
  final bool present;

  const RtcRemoteChanged({required this.present});
}

class RtcQualityChanged extends RtcEvent {
  final RtcQuality quality;

  const RtcQualityChanged(this.quality);
}

/// The camera limits the server sends for a video call (US-015). The picture is never larger than
/// [maxHeight] lines or faster than [maxFps] frames a second.
class CameraLimits {
  static const int defaultHeight = 720;
  static const int defaultFps = 24;

  final int maxHeight;
  final int maxFps;

  const CameraLimits({this.maxHeight = defaultHeight, this.maxFps = defaultFps});

  /// The largest standard picture height that fits [maxHeight]: 360, 540, 720 or 1080.
  int get standardHeight {
    if (maxHeight >= 1080) return 1080;
    if (maxHeight >= 720) return 720;
    if (maxHeight >= 540) return 540;
    return 360;
  }
}

/// What a call needs from its media provider (US-014, US-015). The call controller talks only to this
/// interface; [LiveKitRtcClient] implements it for LiveKit and [FakeRtcClient] is used in tests.
abstract class RtcClient {
  Stream<RtcEvent> get events;

  /// Joins the room with the credentials the server issued for this call. A video call publishes the
  /// camera within [camera]. Throws when the connection cannot be made.
  Future<void> join({
    required String url,
    required String token,
    required bool video,
    CameraLimits camera = const CameraLimits(),
  });

  Future<void> setMicrophoneEnabled({required bool enabled});

  Future<void> setCameraEnabled({required bool enabled});

  Future<void> flipCamera();

  Future<void> setSpeakerOn({required bool on});

  /// The other person's picture, or an empty widget while there is none.
  Widget remoteVideo();

  /// This phone's own preview, or an empty widget while the camera is off.
  Widget localVideo();

  /// Leaves the room and frees the camera and microphone. Safe to call more than once.
  Future<void> leave();
}
