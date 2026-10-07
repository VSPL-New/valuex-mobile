import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/core/widgets/brand_gradient_button.dart';
import 'package:valuex_mobile/core/widgets/field_error.dart';
import 'package:valuex_mobile/core/widgets/otp_input.dart';
import 'package:valuex_mobile/features/auth/domain/entities/otp_sent.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/fonts.dart';

void main() {
  setUpAll(loadBrandFonts);

  Future<void> openOtp(WidgetTester tester, AppHarness harness) async {
    when(
      () => harness.repository.initiateRegistration(any()),
    ).thenAnswer((_) async => const OtpSent(expiresInSeconds: 300));
    await harness.launch(location: RouteNames.signupMobile);
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pump();
    await tester.tap(find.byType(BrandGradientButton));
    await harness.settle();
  }

  Future<void> wrongCode(WidgetTester tester, AppHarness harness) async {
    when(
      () =>
          harness.repository.verifyMobileOtp(mobile: any(named: 'mobile'), otp: any(named: 'otp')),
    ).thenThrow(
      const ApiError(
        type: ApiErrorType.business,
        message: 'x',
        code: 'ERROR_INVALID_OTP',
        statusCode: 400,
      ),
    );
    await tester.enterText(find.byType(TextField), '000000');
    await tester.pump();
    await tester.tap(find.byType(BrandGradientButton));
    await harness.settle();
  }

  group('OTP screen', () {
    testWidgets('meets the guidelines with the resend link and with an error', (tester) async {
      final handle = tester.ensureSemantics();
      final harness = AppHarness(tester);
      await openOtp(tester, harness);
      await tester.pump(const Duration(seconds: 31));

      expect(find.text('Resend code'), findsOneWidget);
      for (final guideline in [
        androidTapTargetGuideline,
        iOSTapTargetGuideline,
        labeledTapTargetGuideline,
        textContrastGuideline,
      ]) {
        await expectLater(tester, meetsGuideline(guideline));
      }

      await wrongCode(tester, harness);

      expect(find.byType(FieldError), findsOneWidget);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('announces the typed digits', (tester) async {
      final handle = tester.ensureSemantics();
      final harness = AppHarness(tester);
      await openOtp(tester, harness);

      await tester.enterText(find.byType(TextField), '123');
      await tester.pump();

      expect(
        tester.getSemantics(find.byType(OtpInput)),
        isSemantics(label: '6-digit one-time code', value: '1 2 3', isTextField: true),
      );
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('empties the boxes when a new code is requested', (tester) async {
      final harness = AppHarness(tester);
      await openOtp(tester, harness);
      await tester.enterText(find.byType(TextField), '123');
      await tester.pump(const Duration(seconds: 31));

      await tester.tap(find.text('Resend code'));
      await harness.settle();

      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
      await harness.dispose();
    });

    for (final locale in const [Locale('en'), Locale('hi')]) {
      testWidgets('shows whole digits and the error in ${locale.languageCode} at 2x text', (
        tester,
      ) async {
        tester.platformDispatcher.localesTestValue = [locale];
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final harness = AppHarness(tester);
        await openOtp(tester, harness);
        await wrongCode(tester, harness);

        final box = tester.getRect(find.text('0').first);
        final boxContainer = tester.getRect(
          find.ancestor(of: find.text('0').first, matching: find.byType(Container)).first,
        );
        expect(boxContainer.height, greaterThanOrEqualTo(box.height));
        expect(find.byType(FieldError), findsOneWidget);
        expect(tester.takeException(), isNull);
        await harness.dispose();
      });
    }
  });
}
