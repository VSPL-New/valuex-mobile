import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../features/settings/presentation/providers/locale_controller.dart';
import '../constants/app_constants.dart';
import '../network/api_client.dart';
import '../security/secure_storage_service.dart';
import 'push_service.dart';
import 'push_token_repository.dart';

/// The push provider. [NoopPushService] until `main` starts Firebase and overrides it.
final pushServiceProvider = Provider<PushService>((ref) => const NoopPushService());

final pushTokenRepositoryProvider =
    Provider<PushTokenRepository>((ref) => PushTokenRepository(ref.watch(apiClientProvider)));

/// Whether the person allowed notifications; read again each time a screen asks.
final pushPermissionGrantedProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(pushServiceProvider).permissionGranted(),
);

/// Opens the system settings page of the app, where notifications can be switched on.
final appSettingsOpenerProvider = Provider<Future<bool> Function()>((ref) => openAppSettings);

/// The random id of this install, made once and kept in secure storage across sign-outs.
final installIdProvider = FutureProvider<String>((ref) async {
  final storage = ref.watch(secureStorageServiceProvider);
  final saved = await storage.getInstallId();
  if (saved != null && saved.isNotEmpty) return saved;
  final created = const Uuid().v4();
  await storage.saveInstallId(created);
  return created;
});

/// Keeps the server's record of this phone right: which token, which language, and whether the
/// person allowed notifications. Push is best effort, so a failure never reaches the user: the
/// next start, token change or language change tries again.
class PushRegistration {
  static const Duration _signOutLimit = Duration(seconds: 3);

  final PushService _service;
  final PushTokenRepository _repository;
  final Future<String> Function() _installId;
  final String Function() _locale;
  final String _platform;

  PushRegistration({
    required PushService service,
    required PushTokenRepository repository,
    required Future<String> Function() installId,
    required String Function() locale,
    required String platform,
  })  : _service = service,
        _repository = repository,
        _installId = installId,
        _locale = locale,
        _platform = platform;

  /// Registers the current token with the server.
  Future<void> sync() async {
    if (!_service.isAvailable) return;
    try {
      final token = await _service.token();
      if (token == null) return;
      await _repository.register(
        deviceId: await _installId(),
        platform: _platform,
        token: token,
        locale: _locale(),
        appVersion: AppConstants.appVersion,
        permissionGranted: await _service.permissionGranted(),
      );
    } on Object catch (error) {
      developer.log('The push token was not registered ($error)', name: 'push');
    }
  }

  /// Removes this phone's tokens from the server. Call before the session is cleared: it needs the
  /// signed-in session. It waits only a moment, so sign-out is never held up.
  Future<void> unregister() async {
    if (!_service.isAvailable) return;
    try {
      await _repository.unregister(await _installId()).timeout(_signOutLimit);
    } on Object catch (error) {
      developer.log('The push token was not removed ($error)', name: 'push');
    }
  }

  /// Drops the token on this phone, so a phone that signed out (or whose session ended) gets
  /// nothing meant for the previous person; the provider then reports the old token as invalid.
  Future<void> forget() => _service.deleteToken();
}

final pushRegistrationProvider = Provider<PushRegistration>((ref) {
  return PushRegistration(
    service: ref.watch(pushServiceProvider),
    repository: ref.watch(pushTokenRepositoryProvider),
    installId: () => ref.read(installIdProvider.future),
    locale: () => ref.read(localeControllerProvider).languageCode,
    platform: defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID',
  );
});
