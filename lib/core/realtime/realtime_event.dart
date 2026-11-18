import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Where the live connection stands (US-130). The features only care whether it is [connected]:
/// when it is not, the screens that need fresh data poll.
enum RealtimeStatus {
  /// Not started: signed out, the account is not active, or the app has been in the background.
  idle,

  /// Opening the first connection of a session.
  connecting,

  /// The socket is open and events arrive.
  connected,

  /// The connection dropped and the app is trying again.
  reconnecting,

  /// Realtime is switched off on the server or could not be opened for a minute; polling covers it.
  degraded,

  /// Stopped on purpose: the account is not active (4403) or another device took the session (4409).
  stopped,
}

/// The event types the app receives (LLD A.4.3) and the frames it sends (A.4.4).
abstract final class RealtimeTypes {
  static const String chatMessageCreated = 'chat.message.created';
  static const String chatMessageDelivered = 'chat.message.delivered';
  static const String chatRead = 'chat.read';
  static const String chatTyping = 'chat.typing';
  static const String chatThreadUpdated = 'chat.thread.updated';
  static const String negotiationUpdated = 'negotiation.updated';
  static const String badgeUpdated = 'badge.updated';

  /// Frames the app sends.
  static const String ping = 'ping';
  static const String pong = 'pong';
  static const String appState = 'app.state';
  static const String chatDeliveredFrame = 'chat.delivered';
}

/// The WebSocket close codes the server uses (LLD A.4.5).
abstract final class RealtimeCloseCodes {
  static const int tokenExpired = 4401;
  static const int accountNotActive = 4403;
  static const int slowConsumer = 4408;
  static const int sessionReplaced = 4409;
  static const int frameTooLarge = 4413;
  static const int rateExceeded = 4429;
}

/// One event from the server. [id] is unique per event, so an event seen twice is applied once.
@immutable
class RealtimeEvent {
  final String id;
  final String type;
  final DateTime? at;
  final Map<String, dynamic> data;

  const RealtimeEvent({required this.id, required this.type, required this.data, this.at});

  /// The event in a text frame, or null when the frame is not an event (bad JSON, no type or id).
  static RealtimeEvent? tryParse(String frame) {
    try {
      final decoded = jsonDecode(frame);
      if (decoded is! Map<String, dynamic>) return null;
      final type = decoded['type'];
      final id = decoded['id'];
      if (type is! String || id is! String) return null;
      final data = decoded['data'];
      return RealtimeEvent(
        id: id,
        type: type,
        at: DateTime.tryParse(decoded['ts'] as String? ?? ''),
        data: data is Map<String, dynamic> ? data : const {},
      );
    } on FormatException {
      return null;
    }
  }
}

/// Remembers the last ids it was asked about, so an event delivered twice is applied once.
class EventDeduper {
  final int capacity;
  final _seen = <String>{};

  EventDeduper({this.capacity = 200});

  /// True the first time [id] is seen.
  bool firstTime(String id) {
    if (!_seen.add(id)) return false;
    if (_seen.length > capacity) _seen.remove(_seen.first);
    return true;
  }
}
