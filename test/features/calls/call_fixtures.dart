import 'package:flutter/widgets.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/features/calls/data/call_permissions.dart';
import 'package:valuex_mobile/features/calls/data/call_platform.dart';
import 'package:valuex_mobile/features/calls/data/call_repository.dart';
import 'package:valuex_mobile/features/calls/domain/call.dart';

class MockCallRepository extends Mock implements CallRepository {}

/// What the person answers when a call asks for the microphone and camera.
class FakeCallPermissions implements CallPermissions {
  CallPermissionResult result = CallPermissionResult.granted;
  final List<bool> requests = [];
  int settingsOpened = 0;

  @override
  Future<CallPermissionResult> request({required bool video}) async {
    requests.add(video);
    return result;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

class FakeCallPlatform implements CallPlatform {
  final List<String> calls = [];

  @override
  Future<void> begin({required bool video}) async => calls.add('begin video=$video');

  @override
  Future<void> end() async => calls.add('end');

  @override
  Future<void> startRinging({required bool incoming}) async => calls.add('ring incoming=$incoming');

  @override
  Future<void> stopRinging() async => calls.add('stop ring');
}

/// The server's JSON of one call, from the side of the caller unless [outgoing] is false.
Map<String, dynamic> callJson({
  String id = 'c1',
  String type = 'VOICE',
  String state = 'RINGING',
  String? endReason,
  bool outgoing = true,
  String? threadId = 't1',
  String name = 'Asha Verma',
  String? title = 'iPhone 15 Pro Max',
  DateTime? connectedAt,
  DateTime? serverTime,
  int? durationSeconds,
  int maxMinutes = 30,
}) =>
    {
      'callId': id,
      'type': type,
      'media': type == 'VIDEO' ? 'VIDEO' : 'AUDIO',
      'state': state,
      'endReason': endReason,
      'direction': outgoing ? 'OUTGOING' : 'INCOMING',
      'threadId': threadId,
      'counterpart': {'userId': 'u2', 'displayName': name},
      'listing': {'listingId': 'l1', 'title': title},
      'ringingExpiresAt': '2026-11-22T10:00:45Z',
      'maxMinutes': maxMinutes,
      'connectedAt': connectedAt?.toUtc().toIso8601String(),
      'endedAt': null,
      'durationSeconds': durationSeconds,
      'serverTime': (serverTime ?? DateTime.utc(2026, 11, 22, 10)).toIso8601String(),
    };

CallSession call({
  String type = 'VOICE',
  String state = 'RINGING',
  String? endReason,
  bool outgoing = true,
  DateTime? connectedAt,
  int? durationSeconds,
  String name = 'Asha Verma',
}) =>
    CallSession.fromJson(
      callJson(
        type: type,
        state: state,
        endReason: endReason,
        outgoing: outgoing,
        connectedAt: connectedAt,
        durationSeconds: durationSeconds,
        name: name,
      ),
      receivedAt: DateTime.utc(2026, 11, 22, 10),
    );

Map<String, dynamic> credentialsJson({String media = 'AUDIO', bool withVideo = false}) => {
      'provider': 'livekit',
      'channel': 'c_abc',
      'identity': 'caller',
      'credentials': {'url': 'wss://x.livekit.cloud', 'token': 'jwt'},
      'expiresAt': '2026-11-22T10:31:00Z',
      'media': media,
      'video': withVideo ? {'maxHeight': 720, 'maxFps': 24} : null,
    };

/// A widget a test puts where the SDK's picture would be.
const Widget fakePicture = SizedBox.expand(key: Key('picture'));
