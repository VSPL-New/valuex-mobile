import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:valuex_mobile/features/auth/domain/entities/otp_sent.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_controller.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_state.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/signup_email_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/signup_mobile_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/verify_email_otp_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/verify_mobile_otp_screen.dart';

import '../../../helpers/app_harness.dart';

ApiError _businessError(String code) {
  return ApiError(type: ApiErrorType.business, message: 'x', code: code, statusCode: 400);
}

const _emailPendingResult = AuthResult(
  session: AuthSession(accessToken: 'access', refreshToken: 'refresh', userId: 'user-1'),
  status: AccountStatus.emailVerificationPending,
  aadhaarVerified: false,
);

Finder get _verifyButton => find.text('Verify');

bool _verifyEnabled(WidgetTester tester) {
  final inkWell = tester.widget<InkWell>(
    find.descendant(
      of: find.ancestor(of: _verifyButton, matching: find.byType(Ink)).first,
      matching: find.byType(InkWell),
    ),
  );
  return inkWell.onTap != null;
}

void main() {
  group('mobile OTP screen', () {
    late AppHarness harness;

    Future<void> openVerifyScreen(WidgetTester tester) async {
      harness = AppHarness(tester);
      when(
        () => harness.repository.initiateRegistration('9876543210'),
      ).thenAnswer((_) async => const OtpSent(expiresInSeconds: 300));
      await harness.launch(location: '/signup/mobile');
      await tester.enterText(find.byType(TextField), '9876543210');
      await tester.pump();
      await tester.tap(find.text('Send OTP'));
      await harness.settle();
      expect(find.byType(VerifyMobileOtpScreen), findsOneWidget);
    }

    testWidgets('shows the masked number, expiry and resend countdown', (tester) async {
      await openVerifyScreen(tester);

      expect(find.text('Verify your number'), findsOneWidget);
      expect(find.text('Enter the 6-digit code sent to +91 98****3210'), findsOneWidget);
      expect(find.text('Code expires in 5:00'), findsOneWidget);
      expect(find.text('Resend code in 30s'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('Verify with an incomplete code shows an inline message and verifies nothing', (
      tester,
    ) async {
      await openVerifyScreen(tester);
      expect(_verifyEnabled(tester), isTrue);

      await tester.enterText(find.byType(TextField), '12345');
      await tester.pump();
      await tester.tap(_verifyButton);
      await harness.settle();

      expect(find.text('Enter the 6-digit code'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      verifyNever(
        () => harness.repository
            .verifyMobileOtp(mobile: any(named: 'mobile'), otp: any(named: 'otp')),
      );

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();

      expect(find.text('Enter the 6-digit code'), findsNothing);
      await harness.dispose();
    });

    testWidgets('a correct code stores the session and moves to the email step', (tester) async {
      await openVerifyScreen(tester);
      when(
        () => harness.repository.verifyMobileOtp(mobile: '9876543210', otp: '123456'),
      ).thenAnswer((_) async => _emailPendingResult);

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      await tester.tap(_verifyButton);
      await harness.settle();

      verify(
        () => harness.repository.verifyMobileOtp(mobile: '9876543210', otp: '123456'),
      ).called(1);
      final session = harness.container.read(sessionControllerProvider).value;
      expect((session as Authenticated).status, AccountStatus.emailVerificationPending);
      expect(find.byType(SignupEmailScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a wrong code shows the error and keeps the screen', (tester) async {
      await openVerifyScreen(tester);
      when(
        () => harness.repository
            .verifyMobileOtp(mobile: any(named: 'mobile'), otp: any(named: 'otp')),
      ).thenThrow(_businessError('ERROR_INVALID_OTP'));

      await tester.enterText(find.byType(TextField), '000000');
      await tester.pump();
      await tester.tap(_verifyButton);
      await harness.settle();

      expect(find.text('Invalid or expired OTP'), findsOneWidget);
      expect(find.byType(VerifyMobileOtpScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('editing the code clears the error', (tester) async {
      await openVerifyScreen(tester);
      when(
        () => harness.repository
            .verifyMobileOtp(mobile: any(named: 'mobile'), otp: any(named: 'otp')),
      ).thenThrow(_businessError('ERROR_INVALID_OTP'));
      await tester.enterText(find.byType(TextField), '000000');
      await tester.pump();
      await tester.tap(_verifyButton);
      await harness.settle();

      await tester.enterText(find.byType(TextField), '00000');
      await tester.pump();

      expect(find.text('Invalid or expired OTP'), findsNothing);
      await harness.dispose();
    });

    testWidgets('too many failed attempts lock the code entry', (tester) async {
      await openVerifyScreen(tester);
      when(
        () => harness.repository
            .verifyMobileOtp(mobile: any(named: 'mobile'), otp: any(named: 'otp')),
      ).thenThrow(_businessError('ERROR_OTP_MAX_ATTEMPTS'));

      await tester.enterText(find.byType(TextField), '111111');
      await tester.pump();
      await tester.tap(_verifyButton);
      await harness.settle();

      expect(find.text('Too many failed attempts. Please request a new OTP'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      await harness.dispose();
    });

    testWidgets('an expired code disables Verify and asks for a new one', (tester) async {
      await openVerifyScreen(tester);
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();

      await tester.pump(const Duration(seconds: 301));

      expect(find.text('The code has expired. Request a new one.'), findsOneWidget);
      expect(_verifyEnabled(tester), isFalse);
      await harness.dispose();
    });

    testWidgets('resend becomes available after 30 seconds and sends a new code', (tester) async {
      await openVerifyScreen(tester);

      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Resend code'), findsOneWidget);

      await tester.tap(find.text('Resend code'));
      await harness.settle();

      verify(() => harness.repository.initiateRegistration('9876543210')).called(2);
      expect(find.text('A new code has been sent'), findsOneWidget);
      expect(find.textContaining('Resend code in'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('resend stops after three sends', (tester) async {
      await openVerifyScreen(tester);

      for (var i = 0; i < 2; i++) {
        await tester.pump(const Duration(seconds: 31));
        await tester.tap(find.text('Resend code'));
        await harness.settle();
      }
      await tester.pump(const Duration(seconds: 31));

      expect(find.text('Resend limit reached. Please try again later.'), findsOneWidget);
      expect(find.text('Resend code'), findsNothing);
      verify(() => harness.repository.initiateRegistration('9876543210')).called(3);
      await harness.dispose();
    });

    testWidgets('a rate limit on resend shows the message', (tester) async {
      await openVerifyScreen(tester);
      when(
        () => harness.repository.initiateRegistration('9876543210'),
      ).thenThrow(_businessError('ERROR_OTP_RATE_LIMIT'));

      await tester.pump(const Duration(seconds: 30));
      await tester.tap(find.text('Resend code'));
      await harness.settle();

      expect(find.text('Too many OTP requests. Please try again in 10 minutes'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('Change number returns to the mobile page', (tester) async {
      await openVerifyScreen(tester);

      await tester.tap(find.text('Change number'));
      await harness.settle();

      expect(find.byType(SignupMobileScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('opening the screen without a number goes back to the mobile page', (tester) async {
      harness = AppHarness(tester);
      await harness.launch(location: '/signup/mobile/verify');

      expect(find.byType(SignupMobileScreen), findsOneWidget);
      await harness.dispose();
    });
  });

  group('email entry and OTP screens', () {
    late AppHarness harness;

    Future<void> openEmailEntry(WidgetTester tester) async {
      harness = AppHarness(tester)..signedInAs(AccountStatus.emailVerificationPending);
      await harness.launch();
      expect(find.byType(SignupEmailScreen), findsOneWidget);
    }

    Future<void> openEmailVerify(WidgetTester tester) async {
      await openEmailEntry(tester);
      when(
        () => harness.repository.sendEmailOtp('asha@example.com'),
      ).thenAnswer((_) async => const OtpSent(expiresInSeconds: 300));
      await tester.enterText(find.byType(TextField), 'asha@example.com');
      await tester.pump();
      await tester.tap(find.text('Send OTP'));
      await harness.settle();
      expect(find.byType(VerifyEmailOtpScreen), findsOneWidget);
    }

    testWidgets('resumes at the email step and has no Skip', (tester) async {
      await openEmailEntry(tester);

      expect(find.text('Verify Email'), findsOneWidget);
      expect(find.textContaining('Skip'), findsNothing);
      await harness.dispose();
    });

    testWidgets('an invalid email shows an inline error and sends nothing', (tester) async {
      await openEmailEntry(tester);
      expect(find.text('Enter a valid email address'), findsNothing);

      await tester.enterText(find.byType(TextField), 'not-an-email');
      await tester.pump();
      await tester.tap(find.text('Send OTP'));
      await harness.settle();

      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      verifyNever(() => harness.repository.sendEmailOtp(any()));

      await tester.enterText(find.byType(TextField), 'asha@example.com');
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsNothing);
      await harness.dispose();
    });

    testWidgets('an email linked to another account shows the message', (tester) async {
      await openEmailEntry(tester);
      when(
        () => harness.repository.sendEmailOtp(any()),
      ).thenThrow(_businessError('ERROR_EMAIL_ALREADY_REGISTERED'));

      await tester.enterText(find.byType(TextField), 'asha@example.com');
      await tester.pump();
      await tester.tap(find.text('Send OTP'));
      await harness.settle();

      expect(find.text('This email is already linked to another account'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(SignupEmailScreen), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'asha@example.org');
      await tester.pump();

      expect(find.text('This email is already linked to another account'), findsNothing);
      await harness.dispose();
    });

    testWidgets('the email OTP screen shows the masked address', (tester) async {
      await openEmailVerify(tester);

      expect(find.text('Verify your email'), findsOneWidget);
      expect(find.text('Enter the 6-digit code sent to a***@example.com'), findsOneWidget);
      expect(find.text('Change email'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a correct code refreshes the account status from the server', (tester) async {
      await openEmailVerify(tester);
      when(
        () => harness.repository.verifyEmailOtp(email: 'asha@example.com', otp: '654321'),
      ).thenAnswer((_) async {});
      harness.signedInAs(AccountStatus.identityVerificationPending);

      await tester.enterText(find.byType(TextField), '654321');
      await tester.pump();
      await tester.tap(find.text('Verify'));
      await harness.settle();

      verify(
        () => harness.repository.verifyEmailOtp(email: 'asha@example.com', otp: '654321'),
      ).called(1);
      final session = harness.container.read(sessionControllerProvider).value as Authenticated;
      expect(session.status, AccountStatus.identityVerificationPending);
      await harness.dispose();
    });

    testWidgets('a wrong email code shows the error', (tester) async {
      await openEmailVerify(tester);
      when(
        () => harness.repository.verifyEmailOtp(email: any(named: 'email'), otp: any(named: 'otp')),
      ).thenThrow(_businessError('ERROR_INVALID_OTP'));

      await tester.enterText(find.byType(TextField), '000000');
      await tester.pump();
      await tester.tap(find.text('Verify'));
      await harness.settle();

      expect(find.text('Invalid or expired OTP'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('resend sends the email code again', (tester) async {
      await openEmailVerify(tester);

      await tester.pump(const Duration(seconds: 30));
      await tester.tap(find.text('Resend code'));
      await harness.settle();

      verify(() => harness.repository.sendEmailOtp('asha@example.com')).called(2);
      await harness.dispose();
    });

    testWidgets('Change email returns to the email entry', (tester) async {
      await openEmailVerify(tester);

      await tester.tap(find.text('Change email'));
      await harness.settle();

      expect(find.byType(SignupEmailScreen), findsOneWidget);
      await harness.dispose();
    });
  });
}
