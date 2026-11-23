import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/features/calls/data/rtc/livekit_room_gateway.dart';
import 'package:valuex_mobile/features/calls/data/rtc/livekit_rtc_client.dart';
import 'package:valuex_mobile/features/calls/data/rtc/rtc_client.dart';

class _FakeGateway implements LiveKitRoomGateway {
  final StreamController<GatewayEvent> controller = StreamController<GatewayEvent>.broadcast();
  final List<String> calls = [];
  CameraLimits? limits;
  Object? connectError;

  @override
  Stream<GatewayEvent> get events => controller.stream;

  @override
  Future<void> connect(String url, String token) async {
    calls.add('connect $url $token');
    if (connectError != null) throw connectError!;
  }

  @override
  Future<void> setMicrophoneEnabled({required bool enabled}) async => calls.add('mic $enabled');

  @override
  Future<void> setCameraEnabled({
    required bool enabled,
    CameraLimits limits = const CameraLimits(),
  }) async {
    this.limits = limits;
    calls.add('camera $enabled');
  }

  @override
  Future<void> flipCamera() async => calls.add('flip');

  @override
  Future<void> setSpeakerOn({required bool on}) async => calls.add('speaker $on');

  @override
  Widget remoteVideo() => const SizedBox(key: Key('remote'));

  @override
  Widget localVideo() => const SizedBox(key: Key('local'));

  @override
  Future<void> disconnect() async => calls.add('disconnect');
}

void main() {
  late _FakeGateway gateway;
  late LiveKitRtcClient client;
  late List<RtcEvent> seen;

  setUp(() {
    gateway = _FakeGateway();
    client = LiveKitRtcClient(gateway);
    seen = [];
    client.events.listen(seen.add);
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('a voice call connects and turns the microphone on, without the camera', () async {
    await client.join(url: 'wss://x', token: 't', video: false);

    expect(gateway.calls, ['connect wss://x t', 'mic true']);
  });

  test('a video call also turns the camera on, within the limits the server gave', () async {
    await client.join(
      url: 'wss://x',
      token: 't',
      video: true,
      camera: const CameraLimits(maxHeight: 540, maxFps: 15),
    );

    expect(gateway.calls, ['connect wss://x t', 'mic true', 'camera true']);
    expect(gateway.limits!.maxHeight, 540);
    expect(gateway.limits!.maxFps, 15);
  });

  test('turning the camera on later keeps the limits of the call', () async {
    await client.join(
      url: 'wss://x',
      token: 't',
      video: false,
      camera: const CameraLimits(maxHeight: 360, maxFps: 12),
    );

    await client.setCameraEnabled(enabled: true);

    expect(gateway.limits!.maxHeight, 360);
    expect(gateway.limits!.maxFps, 12);
  });

  test('a connection that cannot be made is thrown to the caller', () async {
    gateway.connectError = StateError('no route');

    expect(() => client.join(url: 'wss://x', token: 't', video: false), throwsStateError);
  });

  test('every gateway event becomes one of ours', () async {
    await client.join(url: 'wss://x', token: 't', video: false);
    gateway.controller
      ..add(const GatewayConnected())
      ..add(const GatewayReconnecting())
      ..add(const GatewayReconnected())
      ..add(const GatewayRemote(present: true))
      ..add(const GatewayQuality(RtcQuality.poor))
      ..add(const GatewayDisconnected(GatewayDisconnectReason.removed));
    await settle();

    expect(seen[0], isA<RtcConnected>());
    expect(seen[1], isA<RtcReconnecting>());
    expect(seen[2], isA<RtcReconnected>());
    expect((seen[3] as RtcRemoteChanged).present, isTrue);
    expect((seen[4] as RtcQualityChanged).quality, RtcQuality.poor);
    expect((seen[5] as RtcDisconnected).cause, RtcDisconnectCause.removed);
  });

  test('each way the room can close has its own cause', () async {
    await client.join(url: 'wss://x', token: 't', video: false);
    const pairs = {
      GatewayDisconnectReason.local: RtcDisconnectCause.local,
      GatewayDisconnectReason.removed: RtcDisconnectCause.removed,
      GatewayDisconnectReason.roomDeleted: RtcDisconnectCause.roomEnded,
      GatewayDisconnectReason.duplicate: RtcDisconnectCause.duplicate,
      GatewayDisconnectReason.failed: RtcDisconnectCause.failed,
      GatewayDisconnectReason.other: RtcDisconnectCause.other,
    };
    for (final entry in pairs.entries) {
      gateway.controller.add(GatewayDisconnected(entry.key));
    }
    await settle();

    expect(seen.whereType<RtcDisconnected>().map((e) => e.cause), pairs.values);
  });

  test('controls pass through to the gateway', () async {
    await client.join(url: 'wss://x', token: 't', video: false);
    gateway.calls.clear();

    await client.setMicrophoneEnabled(enabled: false);
    await client.flipCamera();
    await client.setSpeakerOn(on: true);

    expect(gateway.calls, ['mic false', 'flip', 'speaker true']);
    expect(client.remoteVideo().key, const Key('remote'));
    expect(client.localVideo().key, const Key('local'));
  });

  test('leave closes the room once, and leaving again does nothing', () async {
    await client.join(url: 'wss://x', token: 't', video: false);
    gateway.calls.clear();

    await client.leave();
    await client.leave();

    expect(gateway.calls, ['disconnect']);
  });

  test('leave before joining does nothing', () async {
    await client.leave();

    expect(gateway.calls, isEmpty);
  });
}
