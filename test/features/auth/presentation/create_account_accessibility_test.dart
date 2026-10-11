import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/core/theme/spacing.dart';
import 'package:valuex_mobile/core/widgets/brand_gradient_button.dart';
import 'package:valuex_mobile/core/widgets/outlined_icon_button.dart';
import 'package:valuex_mobile/core/widgets/single_tone_button.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/fonts.dart';
import '../../../helpers/accessibility.dart';

void main() {
  setUpAll(loadBrandFonts);

  group('Create Account screen', () {
    testWidgets('meets the tap target, label and contrast guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      final harness = AppHarness(tester);
      await harness.launch(location: RouteNames.createAccount);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrast));
      handle.dispose();
      await harness.dispose();
    });

    for (final locale in const [Locale('en'), Locale('hi')]) {
      testWidgets('shows every full button label in ${locale.languageCode} at 2x text', (
        tester,
      ) async {
        tester.platformDispatcher.localesTestValue = [locale];
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final harness = AppHarness(tester);
        await harness.launch(location: RouteNames.createAccount);

        final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
        for (final button in [
          find.byType(BrandGradientButton),
          find.byType(SingleToneButton),
          find.byType(OutlinedIconButton),
        ]) {
          for (final element in button.evaluate()) {
            final rect = tester.getRect(find.byElementPredicate((e) => e == element));
            expect(rect.height, greaterThanOrEqualTo(AppSizes.buttonMedium));
            expect(rect.bottom, lessThanOrEqualTo(screen.height));
          }
        }
        for (final text in find
            .descendant(of: find.byType(OutlinedIconButton), matching: find.byType(Text))
            .evaluate()) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.byElementPredicate((e) => e == text),
          );
          expect(paragraph.didExceedMaxLines, isFalse);
        }
        expect(tester.takeException(), isNull);
        await harness.dispose();
      });
    }
  });

  group('shared buttons', () {
    Future<void> pump(WidgetTester tester, Widget child, {double scale = 1}) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale), size: const Size(360, 800)),
            child: Scaffold(
              body: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child),
            ),
          ),
        ),
      );
    }

    testWidgets('keep the 56 dp height with one line of text', (tester) async {
      await pump(tester, Column(children: [BrandGradientButton(label: 'Go', onPressed: () {})]));

      expect(tester.getSize(find.byType(BrandGradientButton)).height, AppSizes.buttonMedium);
    });

    testWidgets('grow instead of cutting a long label at 2x text', (tester) async {
      const label = 'Continue with a very long provider name';
      await pump(
        tester,
        Column(
          children: [
            BrandGradientButton(label: label, onPressed: () {}),
            SingleToneButton(label: label, onPressed: () {}),
            OutlinedIconButton(
                label: label, iconAsset: 'assets/icons/google.svg', onPressed: () {}),
          ],
        ),
        scale: 2,
      );

      expect(tester.takeException(), isNull);
      for (final type in [BrandGradientButton, SingleToneButton, OutlinedIconButton]) {
        expect(
          tester.getSize(find.byType(type)).height,
          greaterThan(AppSizes.buttonMedium),
          reason: '$type',
        );
      }
    });
  });

  testWidgets('the signed-in start screens are unaffected by the button change', (tester) async {
    final harness = AppHarness(tester)..signedInAs(AccountStatus.active);
    await harness.launch();

    expect(find.text('Featured Deals Near You'), findsOneWidget);
    await harness.dispose();
  });
}
