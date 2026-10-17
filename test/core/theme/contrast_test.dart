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
    'secondary text on the page': (AppColors.brandMutedText, AppColors.brandBackground),
    'secondary text on white': (AppColors.brandMutedText, AppColors.brandSurface),
    'secondary text on the input fill': (AppColors.brandMutedText, AppColors.brandSurfaceTint),
    'placeholder on the input fill': (AppColors.brandPlaceholder, AppColors.brandSurfaceTint),
    'placeholder on the page': (AppColors.brandPlaceholder, AppColors.brandBackground),
    'link text on the page': (AppColors.brandLink, AppColors.brandBackground),
    'link text on white': (AppColors.brandLink, AppColors.brandSurface),
    'link text on the input fill': (AppColors.brandLink, AppColors.brandSurfaceTint),
    'instruction text on the page': (AppColors.brandInstruction, AppColors.brandBackground),
    'error text on the page': (AppColors.brandError, AppColors.brandBackground),
    'error text on white': (AppColors.brandError, AppColors.brandSurface),
    'error text on the input fill': (AppColors.brandError, AppColors.brandSurfaceTint),
    'card price on white': (AppColors.brandLink, AppColors.brandSurface),
    'condition chip on its tint': (AppColors.brandForeground, AppColors.brandSurfaceTint),
    'selected chip text on its blue tint': (AppColors.brandLink, AppColors.brandSurfaceTint),
    'selected condition text on its green tint': (
      AppColors.brandSuccessText,
      AppColors.brandSuccessTint,
    ),
    'price note text on the amber card': (AppColors.brandMutedText, AppColors.sellNoteTint),
    'Boosted badge': (AppColors.brandOnPrimary, AppColors.brandAccent),
    'promo text on the dark card': (AppColors.brandOnPrimary, AppColors.brandForeground),
    'active tab label on white': (AppColors.brandLink, AppColors.brandSurface),
    'inactive tab label on white': (AppColors.brandMutedText, AppColors.brandSurface),
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
