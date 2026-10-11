import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/widgets/brand_gradient_button.dart';
import 'package:valuex_mobile/core/widgets/single_tone_button.dart';
import 'package:valuex_mobile/features/auth/domain/entities/aadhaar_transaction.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_controller.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_state.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/aadhaar_dev_otp_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/aadhaar_screen.dart';
import 'package:valuex_mobile/features/home/presentation/home_screen.dart';

import '../../../helpers/app_harness.dart';

const _aadhaarNote =
    'You can ‘Skip for now’ but Aadhaar Verification is must before any transactions '
    '(Buy/Sell/Contact seller/buyer). So, before your first transaction, you must complete '
    'this one time Aadhaar Verification.';

const _signupPendingResult = AuthResult(
  session: AuthSession(accessToken: 'a', refreshToken: 'r', userId: 'user-1'),
  status: AccountStatus.signupPending,
  aadhaarVerified: false,
);

ApiError _businessError(String code) {
  return ApiError(type: ApiErrorType.business, message: 'x', code: code, statusCode: 400);
}

Future<void> _tapConsent(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(Checkbox));
  await tester.tap(find.byType(Checkbox));
  await tester.pump();
}

final _verifyAadhaarButton = find.widgetWithText(BrandGradientButton, 'Verify Aadhaar');

bool _enabled(WidgetTester tester, String label) {
  final gradient = find.widgetWithText(BrandGradientButton, label);
  if (gradient.evaluate().isNotEmpty) {
    return tester.widget<BrandGradientButton>(gradient).onPressed != null;
  }
  return tester.widget<SingleToneButton>(find.widgetWithText(SingleToneButton, label)).onPressed !=
      null;
}

void main() {
  late AppHarness harness;

  Future<void> openAadhaar(WidgetTester tester) async {
    harness = AppHarness(tester)..signedInAs(AccountStatus.identityVerificationPending);
    await harness.launch();
    expect(find.byType(AadhaarScreen), findsOneWidget);
  }

  Future<void> fillValidForm(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), '123412341234');
    await _tapConsent(tester);
    await tester.pump();
  }

  Future<void> openDevOtp(WidgetTester tester) async {
    await openAadhaar(tester);
    when(
      () => harness.repository.initiateAadhaar(
        aadhaarNumber: any(named: 'aadhaarNumber'),
        consentToken: any(named: 'consentToken'),
      ),
    ).thenAnswer((_) async => const AadhaarTransaction(transactionId: 'txn-1'));
    await fillValidForm(tester);
    await tester.tap(_verifyAadhaarButton);
    await harness.settle();
    expect(find.byType(AadhaarDevOtpScreen), findsOneWidget);
  }

  group('Aadhaar screen', () {
    testWidgets('resumes here at identity verification and shows the required note', (
      tester,
    ) async {
      await openAadhaar(tester);

      expect(_verifyAadhaarButton, findsOneWidget);
      expect(find.text(_aadhaarNote), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('Verify Aadhaar shows what is missing and sends nothing', (tester) async {
      await openAadhaar(tester);
      expect(_enabled(tester, 'Verify Aadhaar'), isTrue);

      await tester.enterText(find.byType(TextField), '12341234');
      await tester.pump();
      await tester.ensureVisible(_verifyAadhaarButton);
      await tester.tap(_verifyAadhaarButton);
      await harness.settle();

      expect(find.text('Enter your 12-digit Aadhaar number'), findsOneWidget);
      expect(find.text('Please accept to continue'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      verifyNever(
        () => harness.repository.initiateAadhaar(
          aadhaarNumber: any(named: 'aadhaarNumber'),
          consentToken: any(named: 'consentToken'),
        ),
      );

      await tester.enterText(find.byType(TextField), '123412341234');
      await tester.pump();
      expect(find.text('Enter your 12-digit Aadhaar number'), findsNothing);
      expect(find.text('Please accept to continue'), findsOneWidget);

      await _tapConsent(tester);
      expect(find.text('Please accept to continue'), findsNothing);
      await harness.dispose();
    });

    testWidgets('the number is hidden until the user shows it', (tester) async {
      await openAadhaar(tester);
      expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);

      await tester.ensureVisible(find.byTooltip('Show Aadhaar number'));
      await tester.tap(find.byTooltip('Show Aadhaar number'));
      await tester.pump();

      expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isFalse);
      await harness.dispose();
    });

    testWidgets('the field only takes twelve digits', (tester) async {
      await openAadhaar(tester);

      await tester.enterText(find.byType(TextField), '12ab34567890123456');
      await tester.pump();

      expect(
          tester.widget<EditableText>(find.byType(EditableText)).controller.text, '123456789012');
      await harness.dispose();
    });

    testWidgets('sends the number with a timestamp as the consent token', (tester) async {
      await openDevOtp(tester);

      final captured = verify(
        () => harness.repository.initiateAadhaar(
          aadhaarNumber: '123412341234',
          consentToken: captureAny(named: 'consentToken'),
        ),
      ).captured.single as String;
      expect(DateTime.tryParse(captured), isNotNull);
      await harness.dispose();
    });

    testWidgets('Skip for now skips Aadhaar and the account moves to Sign Up', (tester) async {
      await openAadhaar(tester);
      when(() => harness.repository.skipAadhaar()).thenAnswer((_) async => _signupPendingResult);

      await tester.tap(find.text('Skip for now'));
      await harness.settle();

      verify(() => harness.repository.skipAadhaar()).called(1);
      final session = harness.container.read(sessionControllerProvider).value as Authenticated;
      expect(session.status, AccountStatus.signupPending);
      await harness.dispose();
    });

    testWidgets('an Aadhaar linked to another account shows the message', (tester) async {
      await openAadhaar(tester);
      when(
        () => harness.repository.initiateAadhaar(
          aadhaarNumber: any(named: 'aadhaarNumber'),
          consentToken: any(named: 'consentToken'),
        ),
      ).thenThrow(_businessError('ERROR_AADHAAR_ALREADY_USED'));
      await fillValidForm(tester);

      await tester.tap(_verifyAadhaarButton);
      await harness.settle();

      expect(find.text('This Aadhaar is already linked to an account'), findsOneWidget);
      expect(find.byType(AadhaarScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('service downtime offers a retry message and keeps Skip available', (tester) async {
      await openAadhaar(tester);
      when(
        () => harness.repository.initiateAadhaar(
          aadhaarNumber: any(named: 'aadhaarNumber'),
          consentToken: any(named: 'consentToken'),
        ),
      ).thenThrow(_businessError('ERROR_AADHAAR_SERVICE_UNAVAILABLE'));
      await fillValidForm(tester);

      await tester.tap(_verifyAadhaarButton);
      await harness.settle();

      expect(
        find.text('Verification service temporarily unavailable. Please try again'),
        findsOneWidget,
      );
      expect(_enabled(tester, 'Skip for now'), isTrue);
      await harness.dispose();
    });

    testWidgets('screenshot protection is on while the screen shows and off after', (tester) async {
      await openAadhaar(tester);
      expect(harness.screenProtection.isActive, isTrue);

      await harness.dispose();

      expect(harness.screenProtection.isActive, isFalse);
    });
  });

  group('Aadhaar later, after registration', () {
    testWidgets('an active account without Aadhaar can open it and sees Not now', (tester) async {
      harness = AppHarness(tester)..signedInAs(AccountStatus.active);
      await harness.launch(location: '/signup/aadhaar');

      expect(find.byType(AadhaarScreen), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
      expect(find.text('Skip for now'), findsNothing);
      await harness.dispose();
    });

    testWidgets('Not now goes back to Home without calling the server', (tester) async {
      harness = AppHarness(tester)..signedInAs(AccountStatus.active);
      await harness.launch(location: '/signup/aadhaar');

      await tester.tap(find.text('Not now'));
      await harness.settle();

      expect(find.byType(HomeScreen), findsOneWidget);
      verifyNever(() => harness.repository.skipAadhaar());
      await harness.dispose();
    });

    testWidgets('verifying later keeps the account active', (tester) async {
      harness = AppHarness(tester)..signedInAs(AccountStatus.active);
      await harness.launch(location: '/signup/aadhaar');
      when(
        () => harness.repository.initiateAadhaar(
          aadhaarNumber: any(named: 'aadhaarNumber'),
          consentToken: any(named: 'consentToken'),
        ),
      ).thenAnswer((_) async => const AadhaarTransaction(transactionId: 'txn-1'));
      when(() => harness.repository.verifyAadhaar(transactionId: 'txn-1', otp: '123456'))
          .thenAnswer(
        (_) async => const AuthResult(
          session: AuthSession(accessToken: 'a', refreshToken: 'r', userId: 'user-1'),
          status: AccountStatus.active,
          aadhaarVerified: true,
        ),
      );

      await fillValidForm(tester);
      await tester.tap(_verifyAadhaarButton);
      await harness.settle();
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      await tester.tap(find.text('Verify'));
      await harness.settle();

      expect(find.byType(HomeScreen), findsOneWidget);
      await harness.dispose();
    });
  });

  group('production build', () {
    final prod = AppConfig.parse(
      env: 'prod',
      apiBaseUrl: 'https://api.example.com/api/v1',
      aadhaarFlow: 'thirdparty',
      googleSignIn: 'native',
      googleServerClientId: 'web-client-id',
    );

    testWidgets('hides number entry and offers only Skip for now', (tester) async {
      harness = AppHarness(tester, config: prod)
        ..signedInAs(AccountStatus.identityVerificationPending);
      await harness.launch();

      expect(find.byType(TextField), findsNothing);
      expect(_verifyAadhaarButton, findsNothing);
      expect(
        find.textContaining('Aadhaar verification is coming soon'),
        findsOneWidget,
      );
      expect(find.text('Skip for now'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('the development OTP screen cannot be opened', (tester) async {
      harness = AppHarness(tester, config: prod)
        ..signedInAs(AccountStatus.identityVerificationPending);
      await harness.launch(location: '/dev/aadhaar-otp');

      expect(find.byType(AadhaarDevOtpScreen), findsNothing);
      expect(find.byType(AadhaarScreen), findsOneWidget);
      await harness.dispose();
    });
  });

  group('development Aadhaar OTP screen', () {
    testWidgets('is visibly marked as development only', (tester) async {
      await openDevOtp(tester);

      expect(find.byKey(const Key('aadhaarDevBanner')), findsOneWidget);
      expect(
        find.text(
          'DEVELOPMENT ONLY — to be replaced with the third-party Aadhaar verification service provider',
        ),
        findsOneWidget,
      );
      await harness.dispose();
    });

    testWidgets('keeps screenshot protection on across the two Aadhaar screens', (tester) async {
      await openDevOtp(tester);

      expect(harness.screenProtection.isActive, isTrue);
      await harness.dispose();
      expect(harness.screenProtection.isActive, isFalse);
    });

    testWidgets('a correct code moves the account on to Sign Up', (tester) async {
      await openDevOtp(tester);
      when(() => harness.repository.verifyAadhaar(transactionId: 'txn-1', otp: '123456'))
          .thenAnswer(
        (_) async => const AuthResult(
          session: AuthSession(accessToken: 'a', refreshToken: 'r', userId: 'user-1'),
          status: AccountStatus.signupPending,
          aadhaarVerified: true,
        ),
      );

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      await tester.tap(find.text('Verify'));
      await harness.settle();

      final session = harness.container.read(sessionControllerProvider).value as Authenticated;
      expect(session.status, AccountStatus.signupPending);
      expect(session.aadhaarVerified, isTrue);
      await harness.dispose();
    });

    testWidgets('a failed verification shows the message', (tester) async {
      await openDevOtp(tester);
      when(
        () => harness.repository.verifyAadhaar(
          transactionId: any(named: 'transactionId'),
          otp: any(named: 'otp'),
        ),
      ).thenThrow(_businessError('ERROR_AADHAAR_VERIFICATION_FAILED'));

      await tester.enterText(find.byType(TextField), '000000');
      await tester.pump();
      await tester.tap(find.text('Verify'));
      await harness.settle();

      expect(find.text('Unable to verify Aadhaar. Please try again'), findsOneWidget);
      expect(find.byType(AadhaarDevOtpScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('an expired Aadhaar session returns to number entry', (tester) async {
      await openDevOtp(tester);
      when(
        () => harness.repository.verifyAadhaar(
          transactionId: any(named: 'transactionId'),
          otp: any(named: 'otp'),
        ),
      ).thenThrow(_businessError('ERROR_AADHAAR_SESSION_EXPIRED'));

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      await tester.tap(find.text('Verify'));
      await harness.settle();

      expect(find.byType(AadhaarScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('without a transaction it goes back to the Aadhaar screen', (tester) async {
      harness = AppHarness(tester)..signedInAs(AccountStatus.identityVerificationPending);
      await harness.launch(location: '/dev/aadhaar-otp');

      expect(find.byType(AadhaarScreen), findsOneWidget);
      await harness.dispose();
    });
  });
}
