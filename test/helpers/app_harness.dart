import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/app.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/routing/app_router.dart';
import 'package:valuex_mobile/core/security/screen_protection_service.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/user_profile.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/auth_providers.dart';

import 'mocks.dart';

final testConfig = AppConfig.parse(
  env: 'dev',
  apiBaseUrl: 'http://localhost:8080/api/v1',
  aadhaarFlow: 'sandbox',
);

/// Records how often screenshot protection is switched on and off.
class FakeScreenProtection implements ScreenProtectionService {
  int enabled = 0;
  int disabled = 0;

  bool get isActive => enabled > disabled;

  @override
  Future<void> enable() async => enabled++;

  @override
  Future<void> disable() async => disabled++;
}

/// The real app wired to a mocked auth repository, so screens, the router guard and
/// the session controller run together.
class AppHarness {
  final WidgetTester tester;
  final MockAuthRepository repository = MockAuthRepository();
  final MockApiClient apiClient = MockApiClient();
  final FakeScreenProtection screenProtection = FakeScreenProtection();
  final StreamController<void> sessionExpired = StreamController<void>.broadcast();
  final AppConfig config;

  AppHarness(this.tester, {AppConfig? config}) : config = config ?? testConfig {
    when(() => apiClient.onSessionExpired).thenAnswer((_) => sessionExpired.stream);
    when(() => repository.hasSession()).thenAnswer((_) async => false);
    when(() => repository.clearSession()).thenAnswer((_) async {});
  }

  ProviderContainer get container =>
      ProviderScope.containerOf(tester.element(find.byType(ValueXApp)));

  void signedInAs(AccountStatus status, {bool aadhaarVerified = false}) {
    when(() => repository.hasSession()).thenAnswer((_) async => true);
    when(() => repository.fetchProfile()).thenAnswer(
      (_) async => UserProfile(
        userId: 'user-1',
        status: status,
        aadhaarVerified: aadhaarVerified,
        mobile: '98****3210',
        email: 'a***@mail.com',
      ),
    );
  }

  /// Starts the app, waits out the splash and optionally opens [location].
  Future<void> launch({String? location}) async {
    // A typical phone: 360x800 logical pixels.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          authRepositoryProvider.overrideWithValue(repository),
          apiClientProvider.overrideWithValue(apiClient),
          screenProtectionServiceProvider.overrideWithValue(screenProtection),
        ],
        child: const ValueXApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2300));
    await settle();
    if (location != null) {
      container.read(appRouterProvider).go(location);
      await settle();
    }
  }

  Future<void> settle() async {
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Future<void> dispose() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await sessionExpired.close();
  }
}
