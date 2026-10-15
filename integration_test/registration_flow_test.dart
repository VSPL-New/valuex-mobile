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
import 'package:valuex_mobile/core/widgets/brand_gradient_button.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/gender.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/aadhaar_dev_otp_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/aadhaar_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/account_blocked_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/create_account_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/signup_email_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/signup_mobile_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/signup_profile_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/verify_email_otp_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/verify_mobile_otp_screen.dart';
import 'package:valuex_mobile/features/home/presentation/home_screen.dart';
import 'package:valuex_mobile/features/onboarding/presentation/onboarding_screen.dart';

import '../test/helpers/app_harness.dart' show FakeScreenProtection;
import '../test/helpers/fake_auth_repository.dart';
import '../test/helpers/mocks.dart';

/// Registration end to end through the real screens, router guard and session, with an
/// in-memory server standing in for the backend.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.parse(
    env: 'dev',
    apiBaseUrl: 'http://localhost:8080/api/v1',
    aadhaarFlow: 'sandbox',
  );

  Future<FakeScreenProtection> launch(WidgetTester tester, FakeAuthRepository server) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final apiClient = MockApiClient();
    when(() => apiClient.sessionEvents).thenAnswer((_) => const Stream<SessionEvent>.empty());
    final protection = FakeScreenProtection();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          authRepositoryProvider.overrideWithValue(server),
          apiClientProvider.overrideWithValue(apiClient),
          screenProtectionServiceProvider.overrideWithValue(protection),
        ],
        child: const ValueXApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2300));
    await _settle(tester);
    return protection;
  }

  Future<void> goThroughOnboarding(WidgetTester tester) async {
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await _settle(tester);
    expect(find.byType(CreateAccountScreen), findsOneWidget);
    await tester.tap(find.text('Create an Account'));
    await _settle(tester);
  }

  Future<void> registerMobile(WidgetTester tester) async {
    expect(find.byType(SignupMobileScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pump();
    await tester.tap(find.text('Send OTP'));
    await _settle(tester);

    expect(find.byType(VerifyMobileOtpScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Verify'));
    await _settle(tester);
  }

  Future<void> registerEmail(WidgetTester tester) async {
    expect(find.byType(SignupEmailScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'asha@example.com');
    await tester.pump();
    await tester.tap(find.text('Send OTP'));
    await _settle(tester);

    expect(find.byType(VerifyEmailOtpScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Verify'));
    await _settle(tester);
  }

  Future<void> fillSignup(WidgetTester tester) async {
    Finder field(String hint) => find.byWidgetPredicate(
          (widget) => widget is TextField && widget.decoration?.hintText == hint,
        );
    Future<void> type(String hint, String text) async {
      await tester.ensureVisible(field(hint));
      await tester.enterText(field(hint), text);
      await tester.pump();
    }

    Future<void> press(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder);
      await tester.pump(const Duration(milliseconds: 400));
    }

    expect(find.byType(SignupProfileScreen), findsOneWidget);
    await type('Your full name', 'Asha Verma');
    await press(find.text('Female'));
    await press(find.text('Terms and Conditions'));
    await _settle(tester);
    await tester.tap(find.byTooltip('Close'));
    await _settle(tester);
    await press(find.byType(Switch));
    await press(find.widgetWithText(BrandGradientButton, 'Submit'));
    await _settle(tester);
  }

  testWidgets('register with Aadhaar verification and land on Home', (tester) async {
    final server = FakeAuthRepository();
    final protection = await launch(tester, server);

    await goThroughOnboarding(tester);
    await registerMobile(tester);
    await registerEmail(tester);

    expect(find.byType(AadhaarScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), '123412341234');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.widgetWithText(BrandGradientButton, 'Verify Aadhaar'));
    await _settle(tester);

    expect(find.byType(AadhaarDevOtpScreen), findsOneWidget);
    expect(protection.isActive, isTrue);
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Verify'));
    await _settle(tester);

    expect(protection.isActive, isFalse);
    await fillSignup(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(server.status, AccountStatus.active);
    expect(server.aadhaarVerified, isTrue);
    expect(server.signup?.gender, Gender.female);
    expect(server.signup?.avatarId, 'avatar-05');
  });

  testWidgets('register skipping Aadhaar and land on Home', (tester) async {
    final server = FakeAuthRepository();
    await launch(tester, server);

    await goThroughOnboarding(tester);
    await registerMobile(tester);
    await registerEmail(tester);
    expect(find.byType(AadhaarScreen), findsOneWidget);
    await tester.tap(find.text('Skip for now'));
    await _settle(tester);
    await fillSignup(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(server.aadhaarVerified, isFalse);
    expect(server.calls, isNot(contains('initiateAadhaar')));
  });

  group('resume after the app is closed', () {
    final cases = <AccountStatus, Type>{
      AccountStatus.emailVerificationPending: SignupEmailScreen,
      AccountStatus.identityVerificationPending: AadhaarScreen,
      AccountStatus.signupPending: SignupProfileScreen,
      AccountStatus.active: HomeScreen,
      AccountStatus.suspended: AccountBlockedScreen,
    };

    for (final entry in cases.entries) {
      testWidgets('a ${entry.key.name} account reopens at ${entry.value}', (tester) async {
        await launch(tester, FakeAuthRepository(status: entry.key));

        expect(find.byType(entry.value), findsOneWidget);
      });
    }

    testWidgets('closing the app after the mobile step continues at the email step',
        (tester) async {
      final server = FakeAuthRepository();
      await launch(tester, server);
      await goThroughOnboarding(tester);
      await registerMobile(tester);
      expect(find.byType(SignupEmailScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await launch(tester, server);

      expect(find.byType(SignupEmailScreen), findsOneWidget);
    });
  });

  testWidgets('a signed-out user cannot skip ahead to Sign Up', (tester) async {
    await launch(tester, FakeAuthRepository());

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(SignupProfileScreen), findsNothing);
  });
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
}
