import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:valuex_mobile/features/auth/domain/entities/google_sign_in_result.dart';
import 'package:valuex_mobile/features/auth/domain/entities/otp_sent.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_controller.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_state.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/aadhaar_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/create_account_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/google_mobile_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/google_otp_screen.dart';
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
const _newGoogleAccount = GoogleNeedsMobile(
  socialSessionToken: 'social-1',
  email: 'tester@gmail.com',
);

Finder get _googleButton => find.text('Continue with Google');
Finder get _sendButton => find.text('Send OTP');
Finder get _verifyButton => find.text('Verify');

void main() {
  late AppHarness harness;

  Future<void> openCreateAccount(WidgetTester tester) async {
    harness = AppHarness(tester);
    await harness.launch(location: RouteNames.createAccount);
  }

  /// Taps Continue with Google and confirms the development account chooser.
  Future<void> chooseMockAccount(WidgetTester tester, {String name = 'tester'}) async {
    await tester.tap(_googleButton);
    await harness.settle();
    await tester.enterText(find.byType(TextField), name);
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await harness.settle();
  }

  Future<void> reachMobileStep(WidgetTester tester) async {
    await openCreateAccount(tester);
    when(() => harness.repository.signInWithGoogle('mock-tester'))
        .thenAnswer((_) async => _newGoogleAccount);
    await chooseMockAccount(tester);
    expect(find.byType(GoogleMobileScreen), findsOneWidget);
  }

  Future<void> sendNumber(WidgetTester tester, [String number = _mobile]) async {
    await tester.enterText(find.byType(TextField), number);
    await tester.pump();
    await tester.tap(_sendButton);
    await harness.settle();
  }

  group('Create Account', () {
    testWidgets('Continue with Google opens the development account chooser', (tester) async {
      await openCreateAccount(tester);

      await tester.tap(_googleButton);
      await harness.settle();

      expect(find.text('Mock Google account'), findsOneWidget);
      expect(find.byKey(const Key('googleMockBanner')), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('closing the chooser sends nothing', (tester) async {
      await openCreateAccount(tester);

      await tester.tap(_googleButton);
      await harness.settle();
      await tester.tap(find.text('Cancel'));
      await harness.settle();

      verifyNever(() => harness.repository.signInWithGoogle(any()));
      expect(find.byType(CreateAccountScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('the chosen account is sent as a mock ID token', (tester) async {
      await openCreateAccount(tester);
      when(() => harness.repository.signInWithGoogle('mock-alice'))
          .thenAnswer((_) async => _newGoogleAccount);

      await chooseMockAccount(tester, name: 'Alice!');

      verify(() => harness.repository.signInWithGoogle('mock-alice')).called(1);
      await harness.dispose();
    });

    testWidgets('a returning Google user is signed in and opens Home', (tester) async {
      await openCreateAccount(tester);
      when(() => harness.repository.signInWithGoogle(any())).thenAnswer(
        (_) async => GoogleSignedIn(_result(AccountStatus.active, aadhaarVerified: true)),
      );

      await chooseMockAccount(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(harness.container.read(sessionControllerProvider).value, isA<Authenticated>());
      await harness.dispose();
    });

    testWidgets('a returning Google user mid-registration resumes at that step', (tester) async {
      await openCreateAccount(tester);
      when(() => harness.repository.signInWithGoogle(any())).thenAnswer(
        (_) async => GoogleSignedIn(_result(AccountStatus.identityVerificationPending)),
      );

      await chooseMockAccount(tester);

      expect(find.byType(AadhaarScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a rejected Google token shows the message under the button', (tester) async {
      await openCreateAccount(tester);
      when(() => harness.repository.signInWithGoogle(any()))
          .thenThrow(_businessError('ERROR_INVALID_GOOGLE_TOKEN'));

      await chooseMockAccount(tester);

      expect(find.text('Google sign-in failed. Please try again'), findsOneWidget);
      expect(find.byType(CreateAccountScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a suspended account sees the suspension message and stays signed out', (
      tester,
    ) async {
      await openCreateAccount(tester);
      when(() => harness.repository.signInWithGoogle(any()))
          .thenThrow(_businessError('ERROR_ACCOUNT_SUSPENDED'));

      await chooseMockAccount(tester);

      expect(
        find.text('Your account is suspended. Please contact support'),
        findsOneWidget,
      );
      expect(harness.container.read(sessionControllerProvider).value, isA<Unauthenticated>());
      await harness.dispose();
    });
  });

  group('mobile step', () {
    testWidgets('shows the Google email and asks for the mobile number', (tester) async {
      await reachMobileStep(tester);

      expect(find.text('Add your mobile number'), findsOneWidget);
      expect(find.textContaining('tester@gmail.com'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('sends the session token and number, then opens the code screen', (tester) async {
      await reachMobileStep(tester);
      when(
        () => harness.repository.initiateGoogleMobile(
          socialSessionToken: 'social-1',
          mobile: _mobile,
        ),
      ).thenAnswer((_) async => const OtpSent(expiresInSeconds: 300));

      await sendNumber(tester);

      verify(
        () => harness.repository.initiateGoogleMobile(
          socialSessionToken: 'social-1',
          mobile: _mobile,
        ),
      ).called(1);
      expect(find.byType(GoogleOtpScreen), findsOneWidget);
      expect(find.text('Enter the 6-digit code sent to +91 98****3210'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('an invalid number is rejected without a request', (tester) async {
      await reachMobileStep(tester);

      await sendNumber(tester, '98765');

      expect(find.text('Enter a valid 10-digit mobile number'), findsOneWidget);
      verifyNever(
        () => harness.repository.initiateGoogleMobile(
          socialSessionToken: any(named: 'socialSessionToken'),
          mobile: any(named: 'mobile'),
        ),
      );
      await harness.dispose();
    });

    for (final entry in const {
      'ERROR_INVALID_STATE':
          'This number has an unfinished registration. Sign in with your mobile number to finish it',
      'ERROR_SOCIAL_ACCOUNT_ALREADY_LINKED':
          'This Google account is already linked to another JustQlic account',
      'ERROR_SOCIAL_SESSION_EXPIRED':
          'Google sign-in session expired. Please sign in with Google again',
      'ERROR_ACCOUNT_RECOVERY_REQUIRED': 'Your account requires recovery. Please contact support',
    }.entries) {
      testWidgets('${entry.key} shows its message', (tester) async {
        await reachMobileStep(tester);
        when(
          () => harness.repository.initiateGoogleMobile(
            socialSessionToken: any(named: 'socialSessionToken'),
            mobile: any(named: 'mobile'),
          ),
        ).thenThrow(_businessError(entry.key));

        await sendNumber(tester);

        expect(find.text(entry.value), findsOneWidget);
        expect(find.byType(GoogleMobileScreen), findsOneWidget);
        await harness.dispose();
      });
    }

    testWidgets('opening the step without a Google session returns to Create Account', (
      tester,
    ) async {
      harness = AppHarness(tester);
      await harness.launch(location: RouteNames.googleMobile);

      expect(find.byType(CreateAccountScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('Back returns to Create Account', (tester) async {
      await reachMobileStep(tester);

      await tester.tap(find.bySemanticsLabel('Back'));
      await harness.settle();

      expect(find.byType(CreateAccountScreen), findsOneWidget);
      await harness.dispose();
    });
  });

  group('code step', () {
    Future<void> reachCodeStep(WidgetTester tester) async {
      await reachMobileStep(tester);
      when(
        () => harness.repository.initiateGoogleMobile(
          socialSessionToken: 'social-1',
          mobile: _mobile,
        ),
      ).thenAnswer((_) async => const OtpSent(expiresInSeconds: 300));
      await sendNumber(tester);
      expect(find.byType(GoogleOtpScreen), findsOneWidget);
    }

    Future<void> submitCode(WidgetTester tester, String code) async {
      await tester.enterText(find.byType(TextField), code);
      await tester.pump();
      await tester.tap(_verifyButton);
      await harness.settle();
    }

    testWidgets('a new account continues to Aadhaar verification', (tester) async {
      await reachCodeStep(tester);
      when(
        () => harness.repository.verifyGoogleMobile(
          socialSessionToken: 'social-1',
          mobile: _mobile,
          otp: '123456',
        ),
      ).thenAnswer((_) async => _result(AccountStatus.identityVerificationPending));

      await submitCode(tester, '123456');

      expect(find.byType(AadhaarScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('Google linked to an existing active account opens Home', (tester) async {
      await reachCodeStep(tester);
      when(
        () => harness.repository.verifyGoogleMobile(
          socialSessionToken: 'social-1',
          mobile: _mobile,
          otp: '123456',
        ),
      ).thenAnswer((_) async => _result(AccountStatus.active, aadhaarVerified: true));

      await submitCode(tester, '123456');

      expect(find.byType(HomeScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a wrong code shows the error and stays', (tester) async {
      await reachCodeStep(tester);
      when(
        () => harness.repository.verifyGoogleMobile(
          socialSessionToken: any(named: 'socialSessionToken'),
          mobile: any(named: 'mobile'),
          otp: any(named: 'otp'),
        ),
      ).thenThrow(_businessError('ERROR_INVALID_OTP'));

      await submitCode(tester, '000000');

      expect(find.text('Invalid or expired OTP'), findsOneWidget);
      expect(find.byType(GoogleOtpScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('an expired Google session explains that Google sign-in must restart', (
      tester,
    ) async {
      await reachCodeStep(tester);
      when(
        () => harness.repository.verifyGoogleMobile(
          socialSessionToken: any(named: 'socialSessionToken'),
          mobile: any(named: 'mobile'),
          otp: any(named: 'otp'),
        ),
      ).thenThrow(_businessError('ERROR_SOCIAL_SESSION_EXPIRED'));

      await submitCode(tester, '123456');

      expect(
        find.text('Google sign-in session expired. Please sign in with Google again'),
        findsOneWidget,
      );
      await harness.dispose();
    });

    testWidgets('Change number returns to the mobile step', (tester) async {
      await reachCodeStep(tester);

      await tester.tap(find.text('Change number'));
      await harness.settle();

      expect(find.byType(GoogleMobileScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('opening the code step without a number returns to Create Account', (
      tester,
    ) async {
      harness = AppHarness(tester);
      await harness.launch(location: RouteNames.googleVerify);

      expect(find.byType(CreateAccountScreen), findsOneWidget);
      await harness.dispose();
    });
  });

  testWidgets('a signed-in account cannot open the Google steps', (tester) async {
    harness = AppHarness(tester)..signedInAs(AccountStatus.active);
    await harness.launch(location: RouteNames.googleMobile);

    expect(find.byType(GoogleMobileScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    await harness.dispose();
  });
}
