import 'package:flutter/foundation.dart';

/// A tap on a notification: where it opens and which event it was, so a repeated tap is ignored.
@immutable
class PushTap {
  final String? deepLink;
  final String? eventId;

  const PushTap({this.deepLink, this.eventId});
}

/// What the app needs from the push provider (US-131). The real one is Firebase Cloud Messaging; a
/// phone without the Firebase files, a test and the simulator use [NoopPushService], so the app
/// starts and works with push switched off.
abstract class PushService {
  /// False when push cannot work here (no Firebase configuration).
  bool get isAvailable;

  /// Whether the person allowed notifications for the app.
  Future<bool> permissionGranted();

  /// Shows the system permission prompt; true when the person allowed notifications.
  Future<bool> requestPermission();

  /// This phone's push token, or null when it has none yet.
  Future<String?> token();

  /// The new token every time the provider changes it.
  Stream<String> get tokenChanges;

  /// Taps on a notification while the app was in the background.
  Stream<PushTap> get taps;

  /// The tap that opened the app from a closed state, if any.
  Future<PushTap?> initialTap();

  /// Forgets this phone's token, so a signed-out phone gets nothing for the previous person.
  Future<void> deleteToken();
}

/// Push switched off: nothing is requested, registered or received.
class NoopPushService implements PushService {
  const NoopPushService();

  @override
  bool get isAvailable => false;

  @override
  Future<bool> permissionGranted() async => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenChanges => const Stream<String>.empty();

  @override
  Stream<PushTap> get taps => const Stream<PushTap>.empty();

  @override
  Future<PushTap?> initialTap() async => null;

  @override
  Future<void> deleteToken() async {}
}
