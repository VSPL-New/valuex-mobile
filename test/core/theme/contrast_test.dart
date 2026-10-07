import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/theme/colors.dart';

import '../../helpers/contrast.dart';

/// Every text colour must reach WCAG AA (4.5:1) on the surface it is used on.
/// Add a row here whenever a new colour pair is introduced.
void main() {
  final textPairs = <String, (Color, Color)>{
    'onboarding subtitle on the page': (
      AppColors.onboardingSubtitle,
      AppColors.brandBackground,
    ),
    'onboarding Skip on its pill': (
      AppColors.onboardingSkipText,
      AppColors.onboardingSkipBackground,
    ),
    'body text on the page': (AppColors.brandForeground, AppColors.brandBackground),
  };

  textPairs.forEach((name, pair) {
    test('$name has at least 4.5:1 contrast', () {
      expect(contrastRatio(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
    });
  });

  final graphicPairs = <String, (Color, Color)>{
    'onboarding next button icon': (Colors.white, AppColors.onboardingNextButton),
    'onboarding back button icon': (Colors.white, AppColors.onboardingBackButton),
    'control border on white': (AppColors.brandControlBorder, AppColors.brandSurface),
    'control border on the page': (AppColors.brandControlBorder, AppColors.brandBackground),
    'control border on input fill': (AppColors.brandControlBorder, AppColors.brandSurfaceTint),
  };

  graphicPairs.forEach((name, pair) {
    test('$name has at least 3:1 contrast', () {
      expect(contrastRatio(pair.$1, pair.$2), greaterThanOrEqualTo(3));
    });
  });
}
