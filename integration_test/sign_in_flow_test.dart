import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/app.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/session_event.dart';
import 'package:valuex_mobile/core/security/screen_protection_service.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/sign_in_mobile_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/sign_in_otp_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/signup_email_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/signup_mobile_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/signup_profile_screen.dart';
import 'package:valuex_mobile/features/home/presentation/home_screen.dart';
import 'package:valuex_mobile/features/onboarding/presentation/onboarding_screen.dart';

import '../test/helpers/app_harness.dart' show FakeScreenProtection;
import '../test/helpers/fake_auth_repository.dart';
import '../test/helpers/mocks.dart';

/// Returning-user sign in end to end through the real screens, router guard and session, with
/// an in-memory server standing in for the backend (OTP is always 123456).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.parse(
    env: 'dev',
    apiBaseUrl: 'http://localhost:8080/api/v1',
    aadhaarFlow: 'sandbox',
  );

  /// A server that already knows an account in [status], with this device signed out.
  Future<FakeAuthRepository> serverWithAccount(AccountStatus status) async {
    final server = FakeAuthRepository(status: status)..mobile = '9876543210';
    await server.clearSession();
    return server;
  }

  Future<void> launch(WidgetTester tester, FakeAuthRepository server) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final apiClient = MockApiClient();
    when(() => apiClient.sessionEvents).thenAnswer((_) => const Stream<SessionEvent>.empty());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          authRepositoryProvider.overrideWithValue(server),
          apiClientProvider.overrideWithValue(apiClient),
          screenProtectionServiceProvider.overrideWithValue(FakeScreenProtection()),
        ],
        child: const ValueXApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2300));
    await _settle(tester);
  }

  Future<void> openSignIn(WidgetTester tester) async {
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await _settle(tester);
    await tester.tap(find.text('Sign In'));
    await _settle(tester);
    expect(find.byType(SignInMobileScreen), findsOneWidget);
  }

  Future<void> sendCode(WidgetTester tester, String mobile) async {
    await tester.enterText(find.byType(TextField), mobile);
    await tester.pump();
    await tester.tap(find.text('Send OTP'));
    await _settle(tester);
  }

  Future<void> enterCode(WidgetTester tester, String code) async {
    expect(find.byType(SignInOtpScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), code);
    await tester.pump();
    await tester.tap(find.text('Verify'));
    await _settle(tester);
  }

  testWidgets('an active user signs in with the OTP and lands on Home', (tester) async {
    final server = await serverWithAccount(AccountStatus.active);
    await launch(tester, server);

    await openSignIn(tester);
    await sendCode(tester, '9876543210');
    await enterCode(tester, '123456');

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(server.calls, containsAllInOrder(['initiateLogin', 'verifyLogin']));
    expect(server.calls, isNot(contains('initiateRegistration')));
  });

  testWidgets('a user who left registration at the email step resumes there', (tester) async {
    final server = await serverWithAccount(AccountStatus.emailVerificationPending);
    await launch(tester, server);

    await openSignIn(tester);
    await sendCode(tester, '9876543210');
    await enterCode(tester, '123456');

    expect(find.byType(SignupEmailScreen), findsOneWidget);
  });

  testWidgets('a user who left registration at Sign Up resumes there', (tester) async {
    final server = await serverWithAccount(AccountStatus.signupPending);
    await launch(tester, server);

    await openSignIn(tester);
    await sendCode(tester, '9876543210');
    await enterCode(tester, '123456');

    expect(find.byType(SignupProfileScreen), findsOneWidget);
  });

  testWidgets('a wrong code keeps the user on the OTP screen', (tester) async {
    final server = await serverWithAccount(AccountStatus.active);
    await launch(tester, server);

    await openSignIn(tester);
    await sendCode(tester, '9876543210');
    await enterCode(tester, '000000');

    expect(find.byType(SignInOtpScreen), findsOneWidget);
    expect(find.text('Invalid or expired OTP'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('an unknown number leads to registration with the number carried over', (
    tester,
  ) async {
    await launch(tester, FakeAuthRepository());

    await openSignIn(tester);
    await sendCode(tester, '9123456780');

    expect(
      find.text('No account found with this mobile number. Please create an account'),
      findsOneWidget,
    );
    await tester.tap(find.text('Create an account'));
    await _settle(tester);

    expect(find.byType(SignupMobileScreen), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, '9123456780');
  });

  testWidgets('a suspended account is told so and cannot continue', (tester) async {
    final server = await serverWithAccount(AccountStatus.suspended);
    await launch(tester, server);

    await openSignIn(tester);
    await sendCode(tester, '9876543210');

    expect(find.text('Your account is suspended. Please contact support'), findsOneWidget);
    expect(find.byType(SignInOtpScreen), findsNothing);
  });
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
}
