import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/widgets/brand_gradient_button.dart';
import 'package:valuex_mobile/core/widgets/field_error.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/fonts.dart';
import '../../../helpers/accessibility.dart';

void main() {
  setUpAll(loadBrandFonts);

  Future<AppHarness> openSignup(WidgetTester tester) async {
    final harness = AppHarness(tester)..signedInAs(AccountStatus.signupPending);
    await harness.launch();
    return harness;
  }

  Future<void> tapSubmit(WidgetTester tester, AppHarness harness) async {
    await tester.ensureVisible(find.byType(BrandGradientButton));
    await tester.tap(find.byType(BrandGradientButton));
    await harness.settle();
  }

  group('Sign Up screen', () {
    testWidgets('meets the guidelines, also with every message showing', (tester) async {
      final handle = tester.ensureSemantics();
      final harness = await openSignup(tester);
      for (final guideline in [
        androidTapTargetGuideline,
        iOSTapTargetGuideline,
        labeledTapTargetGuideline,
        textContrast,
      ]) {
        await expectLater(tester, meetsGuideline(guideline));
      }

      await tapSubmit(tester, harness);

      expect(find.byType(FieldError), findsWidgets);
      await expectLater(tester, meetsGuideline(textContrast));
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('announces the label of every text field and of the terms switch', (tester) async {
      final handle = tester.ensureSemantics();
      final harness = await openSignup(tester);

      for (final label in ['FULL NAME']) {
        expect(find.bySemanticsLabel(RegExp(label, caseSensitive: false)), findsWidgets,
            reason: label);
      }
      expect(find.bySemanticsLabel(RegExp('I agree to the')), findsWidgets);
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('keeps each gender word on one line at 2x text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final harness = await openSignup(tester);

      for (final label in ['Male', 'Female', 'Others']) {
        await tester.ensureVisible(find.text(label));
        final lineHeight = tester.getSize(find.text(label)).height;
        expect(lineHeight, lessThan(60), reason: '$label wrapped');
      }
      await harness.dispose();
    });

    for (final locale in const [Locale('en'), Locale('hi')]) {
      testWidgets('lays out with every message in ${locale.languageCode} at 2x text', (
        tester,
      ) async {
        tester.platformDispatcher.localesTestValue = [locale];
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final harness = await openSignup(tester);
        await tapSubmit(tester, harness);

        expect(find.byType(FieldError), findsWidgets);
        expect(tester.takeException(), isNull);
        await harness.dispose();
      });
    }
  });
}
