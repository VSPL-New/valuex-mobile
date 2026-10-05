import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/auth/domain/entities/otp_sent.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/signup_mobile_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/verify_mobile_otp_screen.dart';

import '../../../helpers/app_harness.dart';

const _mobilePath = '/signup/mobile';

Finder get _sendButton => find.text('Send OTP');

bool _enabled(WidgetTester tester) {
  final inkWell = tester.widget<InkWell>(
    find.descendant(
        of: find.ancestor(of: _sendButton, matching: find.byType(Ink)).first,
        matching: find.byType(InkWell)),
  );
  return inkWell.onTap != null;
}

void main() {
  late AppHarness harness;

  setUp(() {});

  Future<void> open(WidgetTester tester) async {
    harness = AppHarness(tester);
    await harness.launch(location: _mobilePath);
  }

  testWidgets('shows the mobile page with Send OTP disabled', (tester) async {
    await open(tester);

    expect(find.byType(SignupMobileScreen), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(_enabled(tester), isFalse);
    await harness.dispose();
  });

  testWidgets('enables Send OTP only for a valid Indian mobile number', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), '1234567890');
    await tester.pump();
    expect(_enabled(tester), isFalse);

    await tester.enterText(find.byType(TextField), '98765');
    await tester.pump();
    expect(_enabled(tester), isFalse);

    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pump();
    expect(_enabled(tester), isTrue);
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
