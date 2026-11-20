import 'dart:async';

import 'package:valuex_mobile/core/push/push_service.dart';

/// A push provider the test controls.
class FakePushService implements PushService {
  bool available = true;
  bool granted = true;
  bool grantOnRequest = true;
  // ignore: non_constant_identifier_names
  String? token_;
  PushTap? initial;
  int requests = 0;
  int deleted = 0;

  final StreamController<String> tokens = StreamController<String>.broadcast();
  final StreamController<PushTap> tapEvents = StreamController<PushTap>.broadcast();

  @override
  bool get isAvailable => available;

  @override
  Future<bool> permissionGranted() async => granted;

  @override
  Future<bool> requestPermission() async {
    requests++;
    granted = grantOnRequest;
    return granted;
  }

  @override
  Future<String?> token() async => token_;

  @override
  Stream<String> get tokenChanges => tokens.stream;

  @override
  Stream<PushTap> get taps => tapEvents.stream;

  @override
  Future<PushTap?> initialTap() async => initial;

  @override
  Future<void> deleteToken() async => deleted++;
}
