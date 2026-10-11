import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/core/widgets/brand_gradient_button.dart';
import 'package:valuex_mobile/core/widgets/field_error.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/fonts.dart';
import '../../../helpers/accessibility.dart';

void main() {
  setUpAll(loadBrandFonts);

  /// Shows the "no account" error, which also adds the Create an account link.
  Future<void> showNoAccountError(WidgetTester tester, AppHarness harness) async {
    when(() => harness.repository.initiateLogin(any())).thenThrow(
      const ApiError(
        type: ApiErrorType.business,
        message: 'x',
        code: 'ERROR_MOBILE_NOT_REGISTERED',
        statusCode: 400,
      ),
    );
    await harness.launch(location: RouteNames.signIn);
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pump();
    await tester.tap(find.byType(BrandGradientButton));
    await harness.settle();
  }

  group('Sign In screen', () {
    testWidgets('meets the guidelines, also with the error and the link showing', (tester) async {
      final handle = tester.ensureSemantics();
      final harness = AppHarness(tester);
      await harness.launch(location: RouteNames.signIn);
      for (final guideline in [
        androidTapTargetGuideline,
        iOSTapTargetGuideline,
        labeledTapTargetGuideline,
        textContrast,
      ]) {
        await expectLater(tester, meetsGuideline(guideline));
      }
      await harness.dispose();

      final withError = AppHarness(tester);
      await showNoAccountError(tester, withError);
      expect(find.text('Create an account'), findsOneWidget);
      for (final guideline in [
        androidTapTargetGuideline,
        labeledTapTargetGuideline,
        textContrast,
      ]) {
        await expectLater(tester, meetsGuideline(guideline));
      }
      handle.dispose();
      await withError.dispose();
    });

    testWidgets('marks the title as a heading and announces the error as a live region', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final harness = AppHarness(tester);
      await showNoAccountError(tester, harness);

      expect(tester.getSemantics(find.text('Sign In')), isSemantics(isHeader: true));
      expect(
        tester.getSemantics(
          find.text('No account found with this mobile number. Please create an account'),
        ),
        isSemantics(isLiveRegion: true),
      );
      handle.dispose();
      await harness.dispose();
    });

    for (final locale in const [Locale('en'), Locale('hi')]) {
      testWidgets(
          'keeps the error, the link and the button reachable in ${locale.languageCode} '
          'at 2x text', (tester) async {
        tester.platformDispatcher.localesTestValue = [locale];
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final harness = AppHarness(tester);
        await showNoAccountError(tester, harness);

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
