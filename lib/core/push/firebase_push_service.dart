import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'push_service.dart';

/// Push through Firebase Cloud Messaging (US-131). A push that arrives while the app is open is not
/// shown: the live connection already showed it, and a banner on top would repeat it.
class FirebasePushService implements PushService {
  final FirebaseMessaging _messaging;

  FirebasePushService._(this._messaging);

  /// Starts Firebase. Without the per-environment Firebase file the app still runs, with push off.
  static Future<PushService> create() async {
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
      return FirebasePushService._(messaging);
    } on Object catch (error) {
      developer.log('Push is off: Firebase did not start ($error)', name: 'push');
      return const NoopPushService();
    }
  }

  @override
  bool get isAvailable => true;

  static bool _allowed(NotificationSettings settings) =>
      settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;

  @override
  Future<bool> permissionGranted() async => _allowed(await _messaging.getNotificationSettings());

  @override
  Future<bool> requestPermission() async => _allowed(await _messaging.requestPermission());

  @override
  Future<String?> token() async {
    try {
      // The classic registration token is what the FCM HTTP v1 `token` field takes. The newer
      // register()/onRegistered pair returns an installation id, which the backend does not use.
      // ignore: deprecated_member_use
      return await _messaging.getToken();
    } on Object catch (error) {
      // On iOS the token waits for the Apple push registration, which needs the permission.
      developer.log('No push token yet ($error)', name: 'push');
      return null;
    }
  }

  @override
  Stream<String> get tokenChanges {
    // ignore: deprecated_member_use
    return _messaging.onTokenRefresh;
  }

  @override
  Stream<PushTap> get taps => FirebaseMessaging.onMessageOpenedApp.map(_tap);

  @override
  Future<PushTap?> initialTap() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _tap(message);
  }

  @override
  Future<void> deleteToken() async {
    try {
      // ignore: deprecated_member_use
      await _messaging.deleteToken();
    } on Object catch (error) {
      developer.log('The push token could not be deleted ($error)', name: 'push');
    }
  }

  static PushTap _tap(RemoteMessage message) => PushTap(
        deepLink: message.data['deepLink'] as String?,
        eventId: message.data['eventId'] as String?,
      );
}
