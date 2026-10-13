import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/security/secure_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  if (kDebugMode && const bool.fromEnvironment('CLEAR_LOCAL_SESSION')) {
    await SecureStorageService().clearSession();
    await SecureStorageService().clearPendingLogoutToken();
  }

  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const ValueXApp(),
    ),
  );
}
