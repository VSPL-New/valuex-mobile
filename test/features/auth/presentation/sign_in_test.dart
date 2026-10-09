import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:valuex_mobile/features/auth/domain/entities/otp_sent.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_controller.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_state.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/account_blocked_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/create_account_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/sign_in_mobile_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/sign_in_otp_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/signup_email_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/signup_mobile_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/signup_profile_screen.dart';
import 'package:valuex_mobile/features/home/presentation/home_screen.dart';

import '../../../helpers/app_harness.dart';

ApiError _businessError(String code) {
  return ApiError(type: ApiErrorType.business, message: 'x', code: code, statusCode: 400);
}

AuthResult _result(AccountStatus status, {bool aadhaarVerified = false}) {
  return AuthResult(
    session: const AuthSession(accessToken: 'access', refreshToken: 'refresh', userId: 'user-1'),
    status: status,
    aadhaarVerified: aadhaarVerified,
  );
}

const _mobile = '9876543210';

Finder get _sendButton => find.text('Send OTP');
Finder get _verifyButton => find.text('Verify');

void main() {
  late AppHarness harness;

  Future<void> openSignIn(WidgetTester tester) async {
    harness = AppHarness(tester);
    await harness.launch(location: RouteNames.signIn);
  }

  Future<void> enterNumberAndSend(WidgetTester tester, [String number = _mobile]) async {
    await tester.enterText(find.byType(TextField), number);
    await tester.pump();
    await tester.tap(_sendButton);
    await harness.settle();
  }

  group('entry points', () {
    testWidgets('Sign In on Create Account opens the Sign In page', (tester) async {
      harness = AppHarness(tester);
      await harness.launch(location: RouteNames.createAccount);
      expect(find.byType(CreateAccountScreen), findsOneWidget);

      await tester.tap(find.text('Sign In'));
      await harness.settle();

      expect(find.byType(SignInMobileScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('the sign-up page has an Already have an account footer that opens Sign In', (
      tester,
    ) async {
      harness = AppHarness(tester);
      await harness.launch(location: RouteNames.signupMobile);
      expect(find.text('Already have an account?'), findsOneWidget);

      await tester.tap(find.text('Sign In'));
      await harness.settle();

      expect(find.byType(SignInMobileScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('Back to Sign In on the blocked page signs out and opens Sign In', (tester) async {
      harness = AppHarness(tester)..signedInAs(AccountStatus.suspended);
      await harness.launch();
      expect(find.byType(AccountBlockedScreen), findsOneWidget);

      await tester.tap(find.text('Back to Sign In'));
      await harness.settle();

      verify(() => harness.repository.clearSession()).called(1);
      expect(find.byType(SignInMobileScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a signed-in account cannot open Sign In', (tester) async {
      harness = AppHarness(tester)..signedInAs(AccountStatus.active);
      await harness.launch(location: RouteNames.signIn);

      expect(find.byType(SignInMobileScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      await harness.dispose();
    });
  });

  group('mobile screen', () {
    testWidgets('shows the Sign In title and welcome text', (tester) async {
      await openSignIn(tester);

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Welcome back! Please sign in to continue.'), findsOneWidget);
      expect(find.text("Don't have an account?"), findsOneWidget);
      await harness.dispose();
    });

    for (final entry in const {'too short': '98765', 'wrong first digit': '1234567890'}.entries) {
      testWidgets('shows an inline error and sends nothing for a number that is ${entry.key}', (
        tester,
      ) async {
        await openSignIn(tester);

        await enterNumberAndSend(tester, entry.value);

        expect(find.text('Enter a valid 10-digit mobile number'), findsOneWidget);
        verifyNever(() => harness.repository.initiateLogin(any()));
        await harness.dispose();
      });
    }

    testWidgets('sends the OTP and opens the verification screen', (tester) async {
      await openSignIn(tester);
      when(
        () => harness.repository.initiateLogin(_mobile),
      ).thenAnswer((_) async => const OtpSent(expiresInSeconds: 300));

      await enterNumberAndSend(tester);

      verify(() => harness.repository.initiateLogin(_mobile)).called(1);
      verifyNever(() => harness.repository.initiateRegistration(any()));
      expect(find.byType(SignInOtpScreen), findsOneWidget);
      expect(find.text('Enter the 6-digit code sent to +91 98****3210'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('an unregistered number shows the message and a link that carries the number', (
      tester,
    ) async {
      await openSignIn(tester);
      when(
        () => harness.repository.initiateLogin(any()),
      ).thenThrow(_businessError('ERROR_MOBILE_NOT_REGISTERED'));

      await enterNumberAndSend(tester);

      expect(
        find.text('No account found with this mobile number. Please create an account'),
        findsOneWidget,
      );
      expect(find.byType(SignInMobileScreen), findsOneWidget);

      await tester.tap(find.text('Create an account'));
      await harness.settle();

      expect(find.byType(SignupMobileScreen), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, _mobile);
      await harness.dispose();
    });

    testWidgets('an account whose mobile was never verified is pointed to registration', (
      tester,
    ) async {
      await openSignIn(tester);
      when(
        () => harness.repository.initiateLogin(any()),
      ).thenThrow(_businessError('ERROR_INVALID_STATE'));

      await enterNumberAndSend(tester);

      expect(
        find.text(
            "This number isn't verified yet. Please create an account to finish setting it up"),
        findsOneWidget,
      );
      expect(find.text('Create an account'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('the footer Sign up link opens registration with the typed number', (tester) async {
      await openSignIn(tester);
      await tester.enterText(find.byType(TextField), _mobile);
      await tester.pump();

      await tester.tap(find.text('Sign up'));
      await harness.settle();

      expect(find.byType(SignupMobileScreen), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, _mobile);
      await harness.dispose();
    });

    testWidgets('the footer Sign up link opens an empty registration when nothing is typed', (
      tester,
    ) async {
      await openSignIn(tester);

      await tester.tap(find.text('Sign up'));
      await harness.settle();

      expect(find.byType(SignupMobileScreen), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, isEmpty);
      await harness.dispose();
    });

    testWidgets('a suspended account sees the suspension message and no create-account link', (
      tester,
    ) async {
      await openSignIn(tester);
      when(
        () => harness.repository.initiateLogin(any()),
      ).thenThrow(_businessError('ERROR_ACCOUNT_SUSPENDED'));

      await enterNumberAndSend(tester);

      expect(find.text('Your account is suspended. Please contact support'), findsOneWidget);
      expect(find.text('Create an account'), findsNothing);
      await harness.dispose();
    });

    testWidgets('a banned or closed account sees the recovery message, not the Aadhaar one', (
      tester,
    ) async {
      await openSignIn(tester);
      when(
        () => harness.repository.initiateLogin(any()),
      ).thenThrow(_businessError('ERROR_ACCOUNT_RECOVERY_REQUIRED'));

      await enterNumberAndSend(tester);

      expect(find.text('Your account requires recovery. Please contact support'), findsOneWidget);
      expect(find.textContaining('Aadhaar'), findsNothing);
      await harness.dispose();
    });

    testWidgets('too many requests shows the rate limit message', (tester) async {
      await openSignIn(tester);
      when(
        () => harness.repository.initiateLogin(any()),
      ).thenThrow(_businessError('ERROR_OTP_RATE_LIMIT'));

      await enterNumberAndSend(tester);

      expect(find.text('Too many OTP requests. Please try again in 10 minutes'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a network failure shows the connection message', (tester) async {
      await openSignIn(tester);
      when(() => harness.repository.initiateLogin(any())).thenThrow(
        const ApiError(type: ApiErrorType.network, message: 'offline'),
      );

      await enterNumberAndSend(tester);

      expect(find.text('Unable to connect — Retry'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('editing the number removes the server error', (tester) async {
      await openSignIn(tester);
      when(
        () => harness.repository.initiateLogin(any()),
      ).thenThrow(_businessError('ERROR_MOBILE_NOT_REGISTERED'));
      await enterNumberAndSend(tester);
      expect(find.text('Create an account'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '987654321');
      await tester.pump();

      expect(find.text('Create an account'), findsNothing);
      await harness.dispose();
    });

    testWidgets('the typed number is not shared with the sign-up page', (tester) async {
      await openSignIn(tester);
      await tester.enterText(find.byType(TextField), '98765');
      await tester.pump();

      await tester.tap(find.text('Sign up'));
      await harness.settle();
      await tester.tap(find.text('Sign In'));
      await harness.settle();

      expect(find.byType(SignInMobileScreen), findsOneWidget);
      await tester.tap(_sendButton);
      await harness.settle();
      expect(find.text('Enter a valid 10-digit mobile number'), findsOneWidget);
      verifyNever(() => harness.repository.initiateLogin(any()));
      await harness.dispose();
    });
  });

  group('OTP screen', () {
    Future<void> openOtp(WidgetTester tester) async {
      await openSignIn(tester);
      when(
        () => harness.repository.initiateLogin(_mobile),
      ).thenAnswer((_) async => const OtpSent(expiresInSeconds: 300));
      await enterNumberAndSend(tester);
      expect(find.byType(SignInOtpScreen), findsOneWidget);
    }

    Future<void> submitCode(WidgetTester tester, String code) async {
      await tester.enterText(find.byType(TextField), code);
      await tester.pump();
      await tester.tap(_verifyButton);
      await harness.settle();
    }

    testWidgets('a correct code signs an active account in and opens Home', (tester) async {
      await openOtp(tester);
      when(
        () => harness.repository.verifyLogin(mobile: _mobile, otp: '123456'),
      ).thenAnswer((_) async => _result(AccountStatus.active, aadhaarVerified: true));

      await submitCode(tester, '123456');

      final session = harness.container.read(sessionControllerProvider).value;
      expect(session, isA<Authenticated>());
      expect((session as Authenticated).aadhaarVerified, isTrue);
      expect(find.byType(HomeScreen), findsOneWidget);
      await harness.dispose();
    });

    for (final entry in {
      AccountStatus.emailVerificationPending: SignupEmailScreen,
      AccountStatus.signupPending: SignupProfileScreen,
    }.entries) {
      testWidgets('an account that is ${entry.key.name} resumes at its step', (tester) async {
        await openOtp(tester);
        when(
          () => harness.repository.verifyLogin(mobile: _mobile, otp: '123456'),
        ).thenAnswer((_) async => _result(entry.key));
        // The resumed step loads the profile from the server.
        harness.signedInAs(entry.key);

        await submitCode(tester, '123456');

        expect(find.byType(entry.value), findsOneWidget);
        await harness.dispose();
      });
    }

    testWidgets('a wrong code shows the error and stays', (tester) async {
      await openOtp(tester);
      when(
        () => harness.repository.verifyLogin(mobile: any(named: 'mobile'), otp: any(named: 'otp')),
      ).thenThrow(_businessError('ERROR_INVALID_OTP'));

      await submitCode(tester, '000000');

      expect(find.text('Invalid or expired OTP'), findsOneWidget);
      expect(find.byType(SignInOtpScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('an account suspended between send and verify sees the suspension message', (
      tester,
    ) async {
      await openOtp(tester);
      when(
        () => harness.repository.verifyLogin(mobile: any(named: 'mobile'), otp: any(named: 'otp')),
      ).thenThrow(_businessError('ERROR_ACCOUNT_SUSPENDED'));

      await submitCode(tester, '123456');

      expect(find.text('Your account is suspended. Please contact support'), findsOneWidget);
      expect(find.byType(SignInOtpScreen), findsOneWidget);
      expect(harness.container.read(sessionControllerProvider).value, isA<Unauthenticated>());
      await harness.dispose();
    });

    testWidgets('a banned account sees the recovery message', (tester) async {
      await openOtp(tester);
      when(
        () => harness.repository.verifyLogin(mobile: any(named: 'mobile'), otp: any(named: 'otp')),
      ).thenThrow(_businessError('ERROR_ACCOUNT_RECOVERY_REQUIRED'));

      await submitCode(tester, '123456');

      expect(find.text('Your account requires recovery. Please contact support'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('too many failed attempts lock the code entry', (tester) async {
      await openOtp(tester);
      when(
        () => harness.repository.verifyLogin(mobile: any(named: 'mobile'), otp: any(named: 'otp')),
      ).thenThrow(_businessError('ERROR_OTP_MAX_ATTEMPTS'));

      await submitCode(tester, '111111');

      expect(find.text('Too many failed attempts. Please request a new OTP'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      await harness.dispose();
    });

    testWidgets('Resend sends a new sign-in code, not a registration code', (tester) async {
      await openOtp(tester);

      await tester.pump(const Duration(seconds: 30));
      await tester.tap(find.text('Resend code'));
      await harness.settle();

      verify(() => harness.repository.initiateLogin(_mobile)).called(2);
      verifyNever(() => harness.repository.initiateRegistration(any()));
      expect(find.text('A new code has been sent'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('Change number returns to Sign In', (tester) async {
      await openOtp(tester);

      await tester.tap(find.text('Change number'));
      await harness.settle();

      expect(find.byType(SignInMobileScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('opening the screen without a number goes back to Sign In', (tester) async {
      harness = AppHarness(tester);
      await harness.launch(location: RouteNames.signInVerify);

      expect(find.byType(SignInMobileScreen), findsOneWidget);
      await harness.dispose();
    });
  });
}
