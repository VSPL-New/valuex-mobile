import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/auth/domain/entities/google_sign_in_result.dart';
import 'package:valuex_mobile/features/auth/domain/entities/otp_sent.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/google_mobile_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/google_otp_screen.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/fonts.dart';

const _guidelines = <String, AccessibilityGuideline>{
  'android tap target': androidTapTargetGuideline,
  'labelled tap targets': labeledTapTargetGuideline,
  'text contrast': textContrastGuideline,
};

void main() {
  setUpAll(loadBrandFonts);

  Future<void> check(WidgetTester tester) async {
    for (final guideline in _guidelines.values) {
      await expectLater(tester, meetsGuideline(guideline));
    }
  }

  Future<AppHarness> reachMobileStep(WidgetTester tester) async {
    final harness = AppHarness(tester);
    await harness.launch(location: RouteNames.createAccount);
    when(() => harness.repository.signInWithGoogle('mock-tester')).thenAnswer(
      (_) async => const GoogleNeedsMobile(socialSessionToken: 'social-1', email: 'a@gmail.com'),
    );
    await tester.tap(find.text('Continue with Google'));
    await harness.settle();
    await tester.tap(find.text('Continue'));
    await harness.settle();
    expect(find.byType(GoogleMobileScreen), findsOneWidget);
    return harness;
  }

  testWidgets('Create Account meets the guidelines with the Google error showing', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final harness = AppHarness(tester);
    await harness.launch(location: RouteNames.createAccount);
    when(() => harness.repository.signInWithGoogle(any())).thenThrow(
      const ApiError(
        type: ApiErrorType.business,
        message: 'x',
        code: 'ERROR_INVALID_GOOGLE_TOKEN',
        statusCode: 400,
      ),
    );
    await tester.tap(find.text('Continue with Google'));
    await harness.settle();
    await tester.tap(find.text('Continue'));
    await harness.settle();
    expect(find.text('Google sign-in failed. Please try again'), findsOneWidget);

    await check(tester);
    handle.dispose();
    await harness.dispose();
  });

  testWidgets('the development account chooser meets the guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    final harness = AppHarness(tester);
    await harness.launch(location: RouteNames.createAccount);
    await tester.tap(find.text('Continue with Google'));
    await harness.settle();
    expect(find.text('Mock Google account'), findsOneWidget);

    await check(tester);
    handle.dispose();
    await harness.dispose();
  });

  testWidgets('the Google mobile step meets the guidelines, also with an error', (tester) async {
    final handle = tester.ensureSemantics();
    final harness = await reachMobileStep(tester);
    await check(tester);

    when(
      () => harness.repository.initiateGoogleMobile(
        socialSessionToken: any(named: 'socialSessionToken'),
        mobile: any(named: 'mobile'),
      ),
    ).thenThrow(
      const ApiError(
        type: ApiErrorType.business,
        message: 'x',
        code: 'ERROR_INVALID_STATE',
        statusCode: 400,
      ),
    );
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pump();
    await tester.tap(find.text('Send OTP'));
    await harness.settle();
    expect(find.textContaining('unfinished registration'), findsOneWidget);

    await check(tester);
    handle.dispose();
    await harness.dispose();
  });

  testWidgets('the Google code step meets the guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    final harness = await reachMobileStep(tester);
    when(
      () => harness.repository.initiateGoogleMobile(
        socialSessionToken: any(named: 'socialSessionToken'),
        mobile: any(named: 'mobile'),
      ),
    ).thenAnswer((_) async => const OtpSent(expiresInSeconds: 300));
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pump();
    await tester.tap(find.text('Send OTP'));
    await harness.settle();
    expect(find.byType(GoogleOtpScreen), findsOneWidget);

    await check(tester);
    handle.dispose();
    await harness.dispose();
  });
}
