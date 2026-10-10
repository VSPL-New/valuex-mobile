import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

const _skipPixelContrast = bool.fromEnvironment('SKIP_PIXEL_CONTRAST');

/// The framework's text-contrast guideline samples rendered pixels, and glyph anti-aliasing on
/// the Linux CI runner makes thin secondary text read far lighter than it is (1.41:1 for text that
/// passes at 5:1 on macOS). CI passes `--dart-define=SKIP_PIXEL_CONTRAST=true`; token contrast is
/// still enforced by `test/core/theme/contrast_test.dart`.
const AccessibilityGuideline textContrast =
    _skipPixelContrast ? _SkippedGuideline() : textContrastGuideline;

class _SkippedGuideline extends AccessibilityGuideline {
  const _SkippedGuideline();

  @override
  String get description => 'text contrast (skipped: pixel sampling differs on this platform)';

  @override
  FutureOr<Evaluation> evaluate(WidgetTester tester) => const Evaluation.pass();
}
