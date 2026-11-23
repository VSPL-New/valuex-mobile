import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/features/calls/data/rtc/rtc_client.dart';
import 'package:valuex_mobile/features/calls/domain/call.dart';
import 'package:valuex_mobile/features/calls/domain/call_time.dart';

import 'call_fixtures.dart';

void main() {
  group('CallSession', () {
    test('reads the call from the side of the person looking', () {
      final session = CallSession.fromJson(callJson(type: 'VIDEO', state: 'ACCEPTED'));

      expect(session.callId, 'c1');
      expect(session.type, CallType.video);
      expect(session.type.hasVideo, isTrue);
      expect(session.state, CallState.accepted);
      expect(session.outgoing, isTrue);
      expect(session.counterpartName, 'Asha Verma');
      expect(session.listingTitle, 'iPhone 15 Pro Max');
      expect(session.endReason, isNull);
    });

    test('an incoming voice call that is ringing', () {
      final session = CallSession.fromJson(callJson(outgoing: false));

      expect(session.outgoing, isFalse);
      expect(session.type, CallType.voice);
      expect(session.state, CallState.ringing);
      expect(session.state.isLive, isTrue);
    });

    test('maps every state and end reason the server sends, and an unknown one to other', () {
      expect(CallState.from('ACTIVE'), CallState.active);
      expect(CallState.from('ENDED'), CallState.ended);
      expect(CallState.from('ENDED').isLive, isFalse);
      const reasons = {
        'COMPLETED': CallEndReason.completed,
        'DECLINED': CallEndReason.declined,
        'NO_ANSWER': CallEndReason.noAnswer,
        'CANCELLED': CallEndReason.cancelled,
        'DROPPED': CallEndReason.dropped,
        'MAX_DURATION': CallEndReason.maxDuration,
        'BLOCKED': CallEndReason.blocked,
        'JOIN_FAILED': CallEndReason.joinFailed,
        'SYSTEM_ERROR': CallEndReason.systemError,
        'SOMETHING_NEW': CallEndReason.other,
      };
      reasons.forEach((code, reason) => expect(CallEndReason.from(code), reason));
      expect(CallEndReason.from(null), isNull);
    });

    test('measures time on the server clock, not the phone clock', () {
      final connected = DateTime.utc(2026, 11, 22, 10, 0, 0);
      // The phone is 5 minutes behind the server.
      final phone = DateTime.utc(2026, 11, 22, 9, 55, 0);
      final session = CallSession.fromJson(
        callJson(
            state: 'ACTIVE', connectedAt: connected, serverTime: DateTime.utc(2026, 11, 22, 10)),
        receivedAt: phone,
      );

      expect(session.clockOffset, const Duration(minutes: 5));
      expect(session.elapsed(phone.add(const Duration(seconds: 90))), const Duration(seconds: 90));
    });

    test('elapsed is zero before the call connects and never negative', () {
      final ringing = call();
      expect(ringing.elapsed(DateTime.utc(2026, 11, 22, 11)), Duration.zero);

      final future = call(state: 'ACTIVE', connectedAt: DateTime.utc(2030));
      expect(future.elapsed(DateTime.utc(2026)), Duration.zero);
    });

    test('counts the ringing time and the time left of a call', () {
      final ringing = CallSession.fromJson(callJson(), receivedAt: DateTime.utc(2026, 11, 22, 10));
      expect(
          ringing.ringingLeft(DateTime.utc(2026, 11, 22, 10, 0, 30)), const Duration(seconds: 15));
      expect(ringing.ringingLeft(DateTime.utc(2026, 11, 22, 10, 5)), Duration.zero);
      expect(ringing.timeLeft(DateTime.utc(2026, 11, 22, 10)), isNull);

      final connected = DateTime.utc(2026, 11, 22, 10);
      final active = CallSession.fromJson(
        callJson(state: 'ACTIVE', connectedAt: connected, maxMinutes: 30),
        receivedAt: DateTime.utc(2026, 11, 22, 10),
      );
      expect(active.timeLeft(DateTime.utc(2026, 11, 22, 10, 28)), const Duration(minutes: 2));
      expect(active.timeLeft(DateTime.utc(2026, 11, 22, 11)), Duration.zero);
    });

    test('a call without a counterpart or a listing still reads', () {
      final session = CallSession.fromJson(const {
        'callId': 'c9',
        'type': 'VOICE',
        'state': 'RINGING',
        'direction': 'OUTGOING',
      });

      expect(session.counterpartName, isEmpty);
      expect(session.listingTitle, isNull);
      expect(session.maxMinutes, 30);
    });

    test('copyWith changes only the state and the reason', () {
      final ended = call(state: 'ACTIVE')
          .copyWith(state: CallState.ended, endReason: CallEndReason.completed);

      expect(ended.state, CallState.ended);
      expect(ended.endReason, CallEndReason.completed);
      expect(ended.callId, 'c1');
    });
  });

  group('CallCredentials', () {
    test('reads the room, the token and the camera limits of a video call', () {
      final credentials =
          CallCredentials.fromJson(credentialsJson(media: 'VIDEO', withVideo: true));

      expect(credentials.url, 'wss://x.livekit.cloud');
      expect(credentials.token, 'jwt');
      expect(credentials.media, CallType.video);
      expect(credentials.camera.maxHeight, 720);
      expect(credentials.camera.maxFps, 24);
    });

    test('a voice call carries no camera limits and falls back to the defaults', () {
      final credentials = CallCredentials.fromJson(credentialsJson());

      expect(credentials.media, CallType.voice);
      expect(credentials.camera.maxHeight, CameraLimits.defaultHeight);
      expect(credentials.camera.maxFps, CameraLimits.defaultFps);
    });
  });

  test('CameraLimits snaps to the largest standard height that fits', () {
    expect(const CameraLimits(maxHeight: 2160).standardHeight, 1080);
    expect(const CameraLimits(maxHeight: 1080).standardHeight, 1080);
    expect(const CameraLimits(maxHeight: 900).standardHeight, 720);
    expect(const CameraLimits().standardHeight, 720);
    expect(const CameraLimits(maxHeight: 600).standardHeight, 540);
    expect(const CameraLimits(maxHeight: 480).standardHeight, 360);
    expect(const CameraLimits(maxHeight: 100).standardHeight, 360);
  });

  test('a history line reads its outcome and direction', () {
    final item = CallHistoryItem.fromJson(const {
      'callId': 'c1',
      'type': 'VIDEO',
      'direction': 'INCOMING',
      'outcome': 'MISSED',
      'requestedAt': '2026-11-22T10:00:00Z',
      'durationSeconds': 12,
    });

    expect(item.type, CallType.video);
    expect(item.outgoing, isFalse);
    expect(item.outcome, 'MISSED');
    expect(item.durationSeconds, 12);
    expect(item.requestedAt, isNotNull);
  });

  group('formatCallDuration', () {
    test('shows minutes and seconds, and hours from an hour', () {
      expect(formatCallDuration(Duration.zero), '0:00');
      expect(formatCallDuration(const Duration(seconds: 7)), '0:07');
      expect(formatCallDuration(const Duration(minutes: 12, seconds: 5)), '12:05');
      expect(formatCallDuration(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
      expect(formatCallDuration(const Duration(seconds: -5)), '0:00');
    });
  });
}
