import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/auth/domain/entities/otp_sent.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/signup_mobile_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/verify_mobile_otp_screen.dart';

import '../../../helpers/app_harness.dart';

const _mobilePath = '/signup/mobile';

const _invalidMessage = 'Enter a valid 10-digit mobile number';

Finder get _sendButton => find.text('Send OTP');

void main() {
  late AppHarness harness;

  setUp(() {});

  Future<void> open(WidgetTester tester) async {
    harness = AppHarness(tester);
    await harness.launch(location: _mobilePath);
  }

  testWidgets('shows the mobile page with Send OTP available and no error', (tester) async {
    await open(tester);

    expect(find.byType(SignupMobileScreen), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text(_invalidMessage), findsNothing);
    await harness.dispose();
  });

  for (final entry in const {'too short': '98765', 'wrong first digit': '1234567890'}.entries) {
    testWidgets('shows an inline error and sends nothing for a number that is ${entry.key}', (
      tester,
    ) async {
      await open(tester);

      await tester.enterText(find.byType(TextField), entry.value);
      await tester.pump();
      await tester.tap(_sendButton);
      await harness.settle();

      expect(find.text(_invalidMessage), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      verifyNever(() => harness.repository.initiateRegistration(any()));
      await harness.dispose();
    });
  }

  testWidgets('clears the invalid number error once the number is valid', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), '98765');
    await tester.pump();
    await tester.tap(_sendButton);
    await harness.settle();
    expect(find.text(_invalidMessage), findsOneWidget);

    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pump();

    expect(find.text(_invalidMessage), findsNothing);
    await harness.dispose();
  });

  testWidgets('sends the OTP and opens the verification screen', (tester) async {
    await open(tester);
    when(
      () => harness.repository.initiateRegistration('9876543210'),
    ).thenAnswer((_) async => const OtpSent(expiresInSeconds: 300));

    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pump();
    await tester.tap(_sendButton);
    await harness.settle();

    verify(() => harness.repository.initiateRegistration('9876543210')).called(1);
    expect(find.byType(VerifyMobileOtpScreen), findsOneWidget);
    expect(find.textContaining('+91 98****3210'), findsOneWidget);
    await harness.dispose();
  });

  testWidgets('shows a message and stays when the mobile is already registered', (tester) async {
    await open(tester);
    when(() => harness.repository.initiateRegistration(any())).thenThrow(
      const ApiError(
        type: ApiErrorType.business,
        message: 'x',
        code: 'ERROR_MOBILE_ALREADY_REGISTERED',
        statusCode: 400,
      ),
    );

    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pump();
    await tester.tap(_sendButton);
    await harness.settle();

    expect(find.text('This mobile number is already registered'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(SignupMobileScreen), findsOneWidget);
    await harness.dispose();
  });

  testWidgets('shows the connection message when the network fails', (tester) async {
    await open(tester);
    when(() => harness.repository.initiateRegistration(any())).thenThrow(
      const ApiError(type: ApiErrorType.network, message: 'offline'),
    );

    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pump();
    await tester.tap(_sendButton);
    await harness.settle();

    expect(find.text('Unable to connect — Retry'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    await harness.dispose();
  });

  testWidgets('removes the server error when the number is edited', (tester) async {
    await open(tester);
    when(() => harness.repository.initiateRegistration(any())).thenThrow(
      const ApiError(
        type: ApiErrorType.business,
        message: 'x',
        code: 'ERROR_MOBILE_ALREADY_REGISTERED',
        statusCode: 400,
      ),
    );
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pump();
    await tester.tap(_sendButton);
    await harness.settle();
    expect(find.text('This mobile number is already registered'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '987654321');
    await tester.pump();

    expect(find.text('This mobile number is already registered'), findsNothing);
    await harness.dispose();
  });

  testWidgets('shows a rate limit message', (tester) async {
    await open(tester);
    when(() => harness.repository.initiateRegistration(any())).thenThrow(
      const ApiError(
        type: ApiErrorType.business,
        message: 'x',
        code: 'ERROR_OTP_RATE_LIMIT',
        statusCode: 400,
      ),
    );

    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pump();
    await tester.tap(_sendButton);
    await harness.settle();

    expect(find.text('Too many OTP requests. Please try again in 10 minutes'), findsOneWidget);
    await harness.dispose();
  });
}
