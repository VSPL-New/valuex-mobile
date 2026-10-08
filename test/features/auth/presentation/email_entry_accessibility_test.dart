import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/widgets/brand_gradient_button.dart';
import 'package:valuex_mobile/core/widgets/field_error.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/fonts.dart';

void main() {
  setUpAll(loadBrandFonts);

  Future<void> showInvalidError(WidgetTester tester, AppHarness harness) async {
    harness.signedInAs(AccountStatus.emailVerificationPending);
    await harness.launch();
    await tester.enterText(find.byType(TextField), 'asha@');
    await tester.pump();
    await tester.tap(find.byType(BrandGradientButton));
    await harness.settle();
  }

  group('Email entry screen', () {
    testWidgets('meets the guidelines, also with an error showing', (tester) async {
      final handle = tester.ensureSemantics();
      final harness = AppHarness(tester)..signedInAs(AccountStatus.emailVerificationPending);
      await harness.launch();
      for (final guideline in [
        androidTapTargetGuideline,
        iOSTapTargetGuideline,
        labeledTapTargetGuideline,
        textContrastGuideline,
      ]) {
        await expectLater(tester, meetsGuideline(guideline));
      }

      await tester.enterText(find.byType(TextField), 'asha@');
      await tester.pump();
      await tester.tap(find.byType(BrandGradientButton));
      await harness.settle();

      expect(find.byType(FieldError), findsOneWidget);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('announces the field label and marks the title as a heading', (tester) async {
      final handle = tester.ensureSemantics();
      final harness = AppHarness(tester)..signedInAs(AccountStatus.emailVerificationPending);
      await harness.launch();

      expect(find.bySemanticsLabel(RegExp('EMAIL ADDRESS')), findsWidgets);
      expect(tester.getSemantics(find.text('Verify Email')), isSemantics(isHeader: true));
      handle.dispose();
      await harness.dispose();
    });

    for (final locale in const [Locale('en'), Locale('hi')]) {
      testWidgets('keeps the error and the button on screen in ${locale.languageCode} at 2x text', (
        tester,
      ) async {
        tester.platformDispatcher.localesTestValue = [locale];
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final harness = AppHarness(tester);
        await showInvalidError(tester, harness);

        final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
        final error = tester.getRect(find.byType(FieldError));
        expect(error.top, greaterThanOrEqualTo(0));
        expect(error.bottom, lessThanOrEqualTo(screen.height));
        expect(
          tester.getRect(find.byType(BrandGradientButton)).bottom,
          lessThanOrEqualTo(screen.height),
        );
        expect(tester.takeException(), isNull);
        await harness.dispose();
      });
    }
  });
}
