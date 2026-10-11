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
import 'package:valuex_mobile/features/auth/presentation/screens/aadhaar_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/create_account_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/google_mobile_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/google_otp_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/signup_profile_screen.dart';
import 'package:valuex_mobile/features/home/presentation/home_screen.dart';
import 'package:valuex_mobile/features/onboarding/presentation/onboarding_screen.dart';

import '../test/helpers/app_harness.dart' show FakeScreenProtection;
import '../test/helpers/fake_auth_repository.dart';
import '../test/helpers/mocks.dart';

/// Google sign-in end to end through the real screens, router guard and session, with an
/// in-memory server standing in for the backend (OTP is always 123456; the account chooser is
/// the development one).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.parse(
    env: 'dev',
    apiBaseUrl: 'http://localhost:8080/api/v1',
    aadhaarFlow: 'sandbox',
  );

  /// A server where Google account `mock-tester` is already linked to an account in [status],
  /// with this device signed out.
  Future<FakeAuthRepository> serverWithLinkedGoogle(AccountStatus status) async {
    final server = FakeAuthRepository(status: status)
      ..mobile = '9876543210'
      ..linkedGoogleTokens.add('mock-tester')
      ..linkedGoogleStatus = status;
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

  Future<void> openGoogleChooser(WidgetTester tester) async {
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await _settle(tester);
    expect(find.byType(CreateAccountScreen), findsOneWidget);
    await tester.tap(find.text('Continue with Google'));
    await _settle(tester);
  }

  Future<void> chooseAccount(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), 'tester');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await _settle(tester);
  }

  Future<void> sendCode(WidgetTester tester, String mobile) async {
    expect(find.byType(GoogleMobileScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), mobile);
    await tester.pump();
    await tester.tap(find.text('Send OTP'));
    await _settle(tester);
  }

  Future<void> enterCode(WidgetTester tester, String code) async {
    expect(find.byType(GoogleOtpScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), code);
    await tester.pump();
    await tester.tap(find.text('Verify'));
    await _settle(tester);
  }

  testWidgets('a new Google user verifies a mobile number and continues to Aadhaar',
      (tester) async {
    final server = FakeAuthRepository();
    await launch(tester, server);

    await openGoogleChooser(tester);
    await chooseAccount(tester);
    await sendCode(tester, '9876543210');
    await enterCode(tester, '123456');

    expect(find.byType(AadhaarScreen), findsOneWidget);
    expect(server.status, AccountStatus.identityVerificationPending);
    expect(
      server.calls,
      containsAllInOrder(['signInWithGoogle', 'initiateGoogleMobile', 'verifyGoogleMobile']),
    );
    expect(server.calls, isNot(contains('initiateRegistration')));
  });

  testWidgets('skipping Aadhaar after Google sign-up leads to the Sign Up step', (tester) async {
    final server = FakeAuthRepository();
    await launch(tester, server);

    await openGoogleChooser(tester);
    await chooseAccount(tester);
    await sendCode(tester, '9876543210');
    await enterCode(tester, '123456');
    await tester.tap(find.text('Skip for now'));
    await _settle(tester);

    expect(find.byType(SignupProfileScreen), findsOneWidget);
  });

  testWidgets('a returning Google user is signed in without a code and lands on Home', (
    tester,
  ) async {
    final server = await serverWithLinkedGoogle(AccountStatus.active);
    await launch(tester, server);

    await openGoogleChooser(tester);
    await chooseAccount(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(server.calls, ['signInWithGoogle']);
  });

  testWidgets('a returning Google user mid-registration resumes at that step', (tester) async {
    final server = await serverWithLinkedGoogle(AccountStatus.identityVerificationPending);
    await launch(tester, server);

    await openGoogleChooser(tester);
    await chooseAccount(tester);

    expect(find.byType(AadhaarScreen), findsOneWidget);
  });

  testWidgets('a suspended returning Google user is told so and stays signed out', (tester) async {
    final server = await serverWithLinkedGoogle(AccountStatus.suspended);
    await launch(tester, server);

    await openGoogleChooser(tester);
    await chooseAccount(tester);

    expect(find.text('Your account is suspended. Please contact support'), findsOneWidget);
    expect(find.byType(CreateAccountScreen), findsOneWidget);
  });

  testWidgets('Google can be linked to an existing active account with its mobile number', (
    tester,
  ) async {
    final server = FakeAuthRepository()..googleExistingAccount = AccountStatus.active;
    await launch(tester, server);

    await openGoogleChooser(tester);
    await chooseAccount(tester);
    await sendCode(tester, '9876543210');
    await enterCode(tester, '123456');

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('linking is refused for an account that has not finished registration', (
    tester,
  ) async {
    final server = FakeAuthRepository()
      ..googleExistingAccount = AccountStatus.emailVerificationPending;
    await launch(tester, server);

    await openGoogleChooser(tester);
    await chooseAccount(tester);
    await sendCode(tester, '9876543210');

    expect(find.byType(GoogleMobileScreen), findsOneWidget);
    expect(find.textContaining('unfinished registration'), findsOneWidget);
  });

  testWidgets('a wrong code keeps the user on the code screen', (tester) async {
    final server = FakeAuthRepository();
    await launch(tester, server);

    await openGoogleChooser(tester);
    await chooseAccount(tester);
    await sendCode(tester, '9876543210');
    await enterCode(tester, '000000');

    expect(find.byType(GoogleOtpScreen), findsOneWidget);
    expect(find.text('Invalid or expired OTP'), findsOneWidget);
  });
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
}
