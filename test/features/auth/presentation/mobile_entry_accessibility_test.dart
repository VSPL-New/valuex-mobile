import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/core/widgets/brand_gradient_button.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/fonts.dart';
import '../../../helpers/accessibility.dart';

void main() {
  setUpAll(loadBrandFonts);

  Future<void> showInvalidError(WidgetTester tester, AppHarness harness) async {
    await harness.launch(location: RouteNames.signupMobile);
    await tester.enterText(find.byType(TextField), '12345');
    await tester.pump();
    await tester.tap(find.byType(BrandGradientButton));
    await harness.settle();
  }

  group('Mobile entry screen', () {
    testWidgets('meets the guidelines, also with an error showing', (tester) async {
      final handle = tester.ensureSemantics();
      final harness = AppHarness(tester);
      await harness.launch(location: RouteNames.signupMobile);
      for (final guideline in [
        androidTapTargetGuideline,
        iOSTapTargetGuideline,
        labeledTapTargetGuideline,
        textContrast,
      ]) {
        await expectLater(tester, meetsGuideline(guideline));
      }

      await tester.enterText(find.byType(TextField), '12345');
      await tester.pump();
      await tester.tap(find.byType(BrandGradientButton));
      await harness.settle();

      await expectLater(tester, meetsGuideline(textContrast));
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('announces the field label and marks the title as a heading', (tester) async {
      final handle = tester.ensureSemantics();
      final harness = AppHarness(tester);
      await harness.launch(location: RouteNames.signupMobile);

      expect(find.bySemanticsLabel(RegExp('MOBILE NUMBER')), findsWidgets);
      expect(tester.getSemantics(find.text('Create Account')), isSemantics(isHeader: true));
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('announces the error as a live region', (tester) async {
      final handle = tester.ensureSemantics();
      final harness = AppHarness(tester);
      await showInvalidError(tester, harness);

      expect(
        tester.getSemantics(find.text('Enter a valid 10-digit mobile number')),
        isSemantics(isLiveRegion: true),
      );
      handle.dispose();
      await harness.dispose();
    });

    for (final locale in const [Locale('en'), Locale('hi')]) {
      testWidgets('keeps the error and the button reachable in ${locale.languageCode} at 2x text', (
        tester,
      ) async {
        tester.platformDispatcher.localesTestValue = [locale];
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final harness = AppHarness(tester);
        await showInvalidError(tester, harness);

        final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
        final error = tester.getRect(find.byIcon(Icons.error_outline_rounded));
        expect(error.top, greaterThanOrEqualTo(0));
        expect(error.bottom, lessThanOrEqualTo(screen.height));
        expect(tester.getRect(find.byType(BrandGradientButton)).bottom,
            lessThanOrEqualTo(screen.height));
        expect(tester.takeException(), isNull);
        await harness.dispose();
      });
    }
  });
}
