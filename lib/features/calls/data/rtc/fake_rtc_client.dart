import 'dart:async';

import 'package:flutter/widgets.dart';

import 'rtc_client.dart';

/// A test double for [RtcClient]: records what the controller asked for and lets a test push events.
class FakeRtcClient implements RtcClient {
  final StreamController<RtcEvent> _events = StreamController<RtcEvent>.broadcast();

  final List<String> calls = [];
  Object? joinError;
  bool left = false;

  CameraLimits? lastCamera;

  @override
  Stream<RtcEvent> get events => _events.stream;

  void emit(RtcEvent event) => _events.add(event);

  @override
  Future<void> join({
    required String url,
    required String token,
    required bool video,
    CameraLimits camera = const CameraLimits(),
  }) async {
    calls.add('join video=$video');
    lastCamera = camera;
    final error = joinError;
    if (error != null) throw error;
  }

  @override
  Future<void> setMicrophoneEnabled({required bool enabled}) async => calls.add('mic $enabled');

  @override
  Future<void> setCameraEnabled({required bool enabled}) async => calls.add('camera $enabled');

  @override
  Future<void> flipCamera() async => calls.add('flip');

  @override
  Future<void> setSpeakerOn({required bool on}) async => calls.add('speaker $on');

  @override
  Widget remoteVideo() => const SizedBox.shrink(key: Key('fake-remote-video'));

  @override
  Widget localVideo() => const SizedBox.shrink(key: Key('fake-local-video'));

  @override
  Future<void> leave() async {
    left = true;
    calls.add('leave');
  }
}
