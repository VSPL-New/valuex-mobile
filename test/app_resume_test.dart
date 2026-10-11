import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/app.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/session_event.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/widgets/error_view.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/user_profile.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/account_blocked_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/sign_in_mobile_screen.dart';
import 'package:valuex_mobile/features/home/presentation/home_screen.dart';
import 'package:valuex_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:valuex_mobile/features/splash/presentation/splash_screen.dart';

import 'helpers/mocks.dart';

final _config = AppConfig.parse(
  env: 'dev',
  apiBaseUrl: 'http://localhost:8080/api/v1',
  aadhaarFlow: 'sandbox',
);

void main() {
  late MockAuthRepository repository;
  late MockApiClient apiClient;
  late StreamController<SessionEvent> sessionExpired;

  setUp(() {
    repository = MockAuthRepository();
    apiClient = MockApiClient();
    sessionExpired = StreamController<SessionEvent>.broadcast();
    when(() => apiClient.sessionEvents).thenAnswer((_) => sessionExpired.stream);
    when(() => repository.clearSession()).thenAnswer((_) async {});
    addTearDown(sessionExpired.close);
  });

  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(_config),
          authRepositoryProvider.overrideWithValue(repository),
          apiClientProvider.overrideWithValue(apiClient),
        ],
        child: const ValueXApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  void signedInAs(AccountStatus status) {
    when(() => repository.hasSession()).thenAnswer((_) async => true);
    when(() => repository.fetchProfile()).thenAnswer(
      (_) async => UserProfile(userId: 'user-1', status: status, aadhaarVerified: false),
    );
  }

  testWidgets('signed out users continue to onboarding', (tester) async {
    when(() => repository.hasSession()).thenAnswer((_) async => false);

    await launch(tester);

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('an active account resumes at Home', (tester) async {
    signedInAs(AccountStatus.active);

    await launch(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('a suspended account sees the blocked page', (tester) async {
    signedInAs(AccountStatus.suspended);

    await launch(tester);

    expect(find.byType(AccountBlockedScreen), findsOneWidget);
  });

  testWidgets('a failed lookup stays on the splash and can be retried', (tester) async {
    when(() => repository.hasSession()).thenAnswer((_) async => true);
    when(() => repository.fetchProfile()).thenThrow(
      const ApiError(type: ApiErrorType.network, message: 'offline'),
    );

    await launch(tester);

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(ErrorView), findsOneWidget);

    signedInAs(AccountStatus.active);
    await tester.tap(find.text('Retry'));
    await settle(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('an ended session shows a notice and returns to sign-in', (tester) async {
    signedInAs(AccountStatus.active);
    await launch(tester);
    expect(find.byType(HomeScreen), findsOneWidget);

    sessionExpired.add(const SessionEnded(SessionEndReason.expired));
    await settle(tester);

    expect(find.byType(SignInMobileScreen), findsOneWidget);
    expect(find.text('Session expired — Login again'), findsOneWidget);
  });

  testWidgets('a suspension found while renewing the session shows the blocked page', (
    tester,
  ) async {
    signedInAs(AccountStatus.active);
    await launch(tester);
    expect(find.byType(HomeScreen), findsOneWidget);

    sessionExpired.add(const SessionEnded(SessionEndReason.suspended));
    await settle(tester);

    expect(find.byType(AccountBlockedScreen), findsOneWidget);
  });
}
