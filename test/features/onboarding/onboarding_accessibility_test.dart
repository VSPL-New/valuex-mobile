import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/features/onboarding/presentation/onboarding_content.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fonts.dart';
import '../../helpers/accessibility.dart';

void main() {
  setUpAll(loadBrandFonts);

  Future<void> goToSlide(
    WidgetTester tester,
    AppHarness harness,
    int index, {
    String next = 'Next',
  }) async {
    for (var i = 0; i < index; i++) {
      await tester.tap(find.bySemanticsLabel(next));
      await harness.settle();
    }
  }

  group('controls', () {
    for (final slide in [0, 1]) {
      testWidgets('slide ${slide + 1} meets the tap target, label and contrast guidelines', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        final harness = AppHarness(tester);
        await harness.launch();
        await goToSlide(tester, harness, slide);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrast));
        handle.dispose();
        await harness.dispose();
      });
    }

    testWidgets('Skip, Next and Back are announced and the dots describe the page', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final harness = AppHarness(tester);
      await harness.launch();

      expect(find.bySemanticsLabel('Skip'), findsOneWidget);
      expect(find.bySemanticsLabel('Next'), findsOneWidget);
      expect(find.bySemanticsLabel('Page 1 of ${onboardingPages.length}'), findsOneWidget);

      await goToSlide(tester, harness, 1);

      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      expect(find.bySemanticsLabel('Page 2 of ${onboardingPages.length}'), findsOneWidget);
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('the slide title is a heading', (tester) async {
      final handle = tester.ensureSemantics();
      final harness = AppHarness(tester);
      await harness.launch();

      expect(
        tester.getSemantics(find.text('JustQlic Makes Selling Simple')),
        isSemantics(isHeader: true),
      );
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('the controls are labelled in Hindi', (tester) async {
      tester.platformDispatcher.localesTestValue = [const Locale('hi')];
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final handle = tester.ensureSemantics();
      final harness = AppHarness(tester);
      await harness.launch();

      expect(find.bySemanticsLabel('आगे'), findsOneWidget);
      expect(find.bySemanticsLabel('छोड़ें'), findsOneWidget);
      handle.dispose();
      await harness.dispose();
    });
  });

  group('large text', () {
    for (final locale in const [Locale('en'), Locale('hi')]) {
      for (final slide in List.generate(onboardingPages.length, (i) => i)) {
        testWidgets(
            'slide ${slide + 1} in ${locale.languageCode} at 2x text keeps all copy on screen', (
          tester,
        ) async {
          tester.platformDispatcher.localesTestValue = [locale];
          tester.platformDispatcher.textScaleFactorTestValue = 2.0;
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          final harness = AppHarness(tester);
          await harness.launch();
          await tester.pump();
          await goToSlide(tester, harness, slide,
              next: locale.languageCode == 'hi' ? 'आगे' : 'Next');

          final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
          final texts = find.descendant(
            of: find.byType(Scaffold),
            matching: find.byType(Text),
          );
          expect(texts, findsWidgets);
          for (final text in texts.evaluate()) {
            final rect = tester.getRect(find.byElementPredicate((e) => e == text));
            expect(rect.top, greaterThanOrEqualTo(0), reason: '$text');
            expect(rect.bottom, lessThanOrEqualTo(screen.height), reason: '$text');
          }
          expect(tester.takeException(), isNull);
          await harness.dispose();
        });
      }
    }
  });
}
