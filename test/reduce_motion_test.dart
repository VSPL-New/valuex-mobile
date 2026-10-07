import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

void main() {
  void reduceMotion(WidgetTester tester) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
  }

  testWidgets('the splash progress bar is shown full instead of animating', (tester) async {
    reduceMotion(tester);
    final harness = AppHarness(tester);
    await harness.launch(waitOutSplash: false);

    final bar = tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox));
    expect(bar.widthFactor, 1);
    await tester.pump(const Duration(seconds: 3));
    await harness.dispose();
  });

  testWidgets('onboarding changes page at once', (tester) async {
    reduceMotion(tester);
    final handle = tester.ensureSemantics();
    final harness = AppHarness(tester);
    await harness.launch();

    await tester.tap(find.bySemanticsLabel('Next'));
    await tester.pump();

    expect(find.bySemanticsLabel('Page 2 of 4'), findsOneWidget);
    handle.dispose();
    await harness.dispose();
  });
}
