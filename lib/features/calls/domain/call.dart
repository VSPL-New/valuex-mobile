import 'package:flutter/foundation.dart';

import '../data/rtc/rtc_client.dart';

/// Voice or video (US-014, US-015). A call is always from a buyer to the seller of a listing.
enum CallType {
  voice,
  video;

  static CallType from(String? value) => value == 'VIDEO' ? video : voice;

  bool get hasVideo => this == video;
}

/// Where a call is. [ended] is final.
enum CallState {
  ringing,
  accepted,
  active,
  ended;

  static CallState from(String? value) => switch (value) {
        'ACCEPTED' => accepted,
        'ACTIVE' => active,
        'ENDED' => ended,
        _ => ringing,
      };

  bool get isLive => this != ended;
}

/// Why a call ended, as the server reports it. [other] covers a reason a newer server adds.
enum CallEndReason {
  completed,
  declined,
  noAnswer,
  cancelled,
  dropped,
  maxDuration,
  blocked,
  joinFailed,
  systemError,
  other;

  static CallEndReason? from(String? value) => switch (value) {
        null => null,
        'COMPLETED' => completed,
        'DECLINED' => declined,
        'NO_ANSWER' => noAnswer,
        'CANCELLED' => cancelled,
        'DROPPED' => dropped,
        'MAX_DURATION' => maxDuration,
        'BLOCKED' => blocked,
        'JOIN_FAILED' => joinFailed,
        'SYSTEM_ERROR' => systemError,
        _ => other,
      };
}

DateTime? _date(Object? value) => DateTime.tryParse(value as String? ?? '')?.toLocal();

/// One call as the server shows it to this person.
@immutable
class CallSession {
  final String callId;
  final CallType type;
  final CallState state;
  final CallEndReason? endReason;

  /// True when this person made the call; false when they are the one called.
  final bool outgoing;
  final String? threadId;
  final String counterpartId;
  final String counterpartName;
  final String? listingId;
  final String? listingTitle;
  final DateTime? ringingExpiresAt;
  final int maxMinutes;
  final DateTime? connectedAt;
  final DateTime? endedAt;
  final int? durationSeconds;

  /// How far the phone's clock is behind the server's: add it to the phone's time to get the server's.
  final Duration clockOffset;

  const CallSession({
    required this.callId,
    required this.type,
    required this.state,
    required this.outgoing,
    required this.counterpartId,
    required this.counterpartName,
    this.endReason,
    this.threadId,
    this.listingId,
    this.listingTitle,
    this.ringingExpiresAt,
    this.maxMinutes = 30,
    this.connectedAt,
    this.endedAt,
    this.durationSeconds,
    this.clockOffset = Duration.zero,
  });

  factory CallSession.fromJson(Map<String, dynamic> json, {DateTime? receivedAt}) {
    final counterpart = json['counterpart'] as Map<String, dynamic>? ?? const {};
    final listing = json['listing'] as Map<String, dynamic>? ?? const {};
    final serverTime = _date(json['serverTime']);
    return CallSession(
      callId: json['callId'] as String,
      type: CallType.from(json['type'] as String?),
      state: CallState.from(json['state'] as String?),
      endReason: CallEndReason.from(json['endReason'] as String?),
      outgoing: json['direction'] != 'INCOMING',
      threadId: json['threadId'] as String?,
      counterpartId: counterpart['userId'] as String? ?? '',
      counterpartName: counterpart['displayName'] as String? ?? '',
      listingId: listing['listingId'] as String?,
      listingTitle: listing['title'] as String?,
      ringingExpiresAt: _date(json['ringingExpiresAt']),
      maxMinutes: (json['maxMinutes'] as num?)?.toInt() ?? 30,
      connectedAt: _date(json['connectedAt']),
      endedAt: _date(json['endedAt']),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      clockOffset:
          serverTime == null ? Duration.zero : serverTime.difference(receivedAt ?? DateTime.now()),
    );
  }

  CallSession copyWith({CallState? state, CallEndReason? endReason}) => CallSession(
        callId: callId,
        type: type,
        state: state ?? this.state,
        endReason: endReason ?? this.endReason,
        outgoing: outgoing,
        threadId: threadId,
        counterpartId: counterpartId,
        counterpartName: counterpartName,
        listingId: listingId,
        listingTitle: listingTitle,
        ringingExpiresAt: ringingExpiresAt,
        maxMinutes: maxMinutes,
        connectedAt: connectedAt,
        endedAt: endedAt,
        durationSeconds: durationSeconds,
        clockOffset: clockOffset,
      );

  /// The server's time now, from the phone's clock and the offset the last answer showed.
  DateTime serverNow(DateTime phoneNow) => phoneNow.add(clockOffset);

  /// How long the call has been on at [phoneNow]; zero before it connects.
  Duration elapsed(DateTime phoneNow) {
    final start = connectedAt;
    if (start == null) return Duration.zero;
    final end = serverNow(phoneNow);
    return end.isBefore(start) ? Duration.zero : end.difference(start);
  }

  /// How long a call that is still ringing will ring; zero once the time is over.
  Duration ringingLeft(DateTime phoneNow) {
    final until = ringingExpiresAt;
    if (until == null) return Duration.zero;
    final left = until.difference(serverNow(phoneNow));
    return left.isNegative ? Duration.zero : left;
  }

  /// How long until the longest call time ends the call; null before it connects.
  Duration? timeLeft(DateTime phoneNow) {
    if (connectedAt == null) return null;
    final left = Duration(minutes: maxMinutes) - elapsed(phoneNow);
    return left.isNegative ? Duration.zero : left;
  }
}

/// What to join a call with, as the server issued it for this phone only.
@immutable
class CallCredentials {
  final String url;
  final String token;
  final CallType media;
  final CameraLimits camera;

  const CallCredentials({
    required this.url,
    required this.token,
    required this.media,
    required this.camera,
  });

  factory CallCredentials.fromJson(Map<String, dynamic> json) {
    final credentials = json['credentials'] as Map<String, dynamic>? ?? const {};
    final video = json['video'] as Map<String, dynamic>?;
    return CallCredentials(
      url: credentials['url'] as String? ?? '',
      token: credentials['token'] as String? ?? '',
      media: json['media'] == 'VIDEO' ? CallType.video : CallType.voice,
      camera: video == null
          ? const CameraLimits()
          : CameraLimits(
              maxHeight: (video['maxHeight'] as num?)?.toInt() ?? CameraLimits.defaultHeight,
              maxFps: (video['maxFps'] as num?)?.toInt() ?? CameraLimits.defaultFps,
            ),
    );
  }
}

/// One line of a conversation's call history.
@immutable
class CallHistoryItem {
  final String callId;
  final CallType type;
  final bool outgoing;
  final String outcome;
  final DateTime? requestedAt;
  final int? durationSeconds;

  const CallHistoryItem({
    required this.callId,
    required this.type,
    required this.outgoing,
    required this.outcome,
    this.requestedAt,
    this.durationSeconds,
  });

  factory CallHistoryItem.fromJson(Map<String, dynamic> json) => CallHistoryItem(
        callId: json['callId'] as String,
        type: CallType.from(json['type'] as String?),
        outgoing: json['direction'] != 'INCOMING',
        outcome: json['outcome'] as String? ?? '',
        requestedAt: _date(json['requestedAt']),
        durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      );
}
