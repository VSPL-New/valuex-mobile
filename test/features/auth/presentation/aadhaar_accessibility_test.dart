import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/widgets/brand_gradient_button.dart';
import 'package:valuex_mobile/core/widgets/field_error.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/aadhaar_transaction.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/fonts.dart';
import '../../../helpers/accessibility.dart';

void main() {
  setUpAll(loadBrandFonts);

  Future<AppHarness> openAadhaar(WidgetTester tester) async {
    final harness = AppHarness(tester)..signedInAs(AccountStatus.identityVerificationPending);
    await harness.launch();
    return harness;
  }

  Future<void> tapVerifyWithNothing(WidgetTester tester, AppHarness harness) async {
    await tester.ensureVisible(find.byType(BrandGradientButton));
    await tester.tap(find.byType(BrandGradientButton));
    await harness.settle();
  }

  Future<AppHarness> openDevOtp(WidgetTester tester) async {
    final harness = await openAadhaar(tester);
    when(
      () => harness.repository.initiateAadhaar(
        aadhaarNumber: any(named: 'aadhaarNumber'),
        consentToken: any(named: 'consentToken'),
      ),
    ).thenAnswer((_) async => const AadhaarTransaction(transactionId: 'txn-1'));
    await tester.enterText(find.byType(TextField), '234567890123');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.ensureVisible(find.byType(BrandGradientButton));
    await tester.tap(find.byType(BrandGradientButton));
    await harness.settle();
    return harness;
  }

  group('Aadhaar screen', () {
    testWidgets('meets the guidelines, also with its messages showing', (tester) async {
      final handle = tester.ensureSemantics();
      final harness = await openAadhaar(tester);
      for (final guideline in [
        androidTapTargetGuideline,
        iOSTapTargetGuideline,
        labeledTapTargetGuideline,
        textContrast,
      ]) {
        await expectLater(tester, meetsGuideline(guideline));
      }

      await tapVerifyWithNothing(tester, harness);

      expect(find.byType(FieldError), findsNWidgets(2));
      await expectLater(tester, meetsGuideline(textContrast));
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('announces the number field label', (tester) async {
      final handle = tester.ensureSemantics();
      final harness = await openAadhaar(tester);

      expect(find.bySemanticsLabel(RegExp('AADHAAR NUMBER')), findsWidgets);
      handle.dispose();
      await harness.dispose();
    });

    for (final locale in const [Locale('en'), Locale('hi')]) {
      testWidgets('keeps both messages reachable in ${locale.languageCode} at 2x text', (
        tester,
      ) async {
        tester.platformDispatcher.localesTestValue = [locale];
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final harness = await openAadhaar(tester);
        await tapVerifyWithNothing(tester, harness);

        final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
        for (final element in find.byType(FieldError).evaluate()) {
          final rect = tester.getRect(find.byElementPredicate((e) => e == element));
          expect(rect.bottom, lessThanOrEqualTo(screen.height));
        }
        expect(tester.takeException(), isNull);
        await harness.dispose();
      });
    }
  });

  group('development Aadhaar OTP screen', () {
    testWidgets('Verify with an incomplete code shows a message and sends nothing', (tester) async {
      final harness = await openDevOtp(tester);

      await tester.enterText(find.byType(TextField), '123');
      await tester.pump();
      await tester.tap(find.byType(BrandGradientButton));
      await harness.settle();

      expect(find.text('Enter the 6-digit code'), findsOneWidget);
      verifyNever(
        () => harness.repository.verifyAadhaar(
          transactionId: any(named: 'transactionId'),
          otp: any(named: 'otp'),
        ),
      );
      await harness.dispose();
    });

    testWidgets('meets the guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      final harness = await openDevOtp(tester);
      for (final guideline in [
        androidTapTargetGuideline,
        iOSTapTargetGuideline,
        labeledTapTargetGuideline,
        textContrast,
      ]) {
        await expectLater(tester, meetsGuideline(guideline));
      }
      handle.dispose();
      await harness.dispose();
    });
  });
}
