import 'package:flutter/material.dart';

/// Global colour tokens. `brand*` colours are shared across the whole app;
/// screen-specific colours (onboarding*) are used only where Figma defines them.
class AppColors {
  AppColors._();

  // Surfaces (Figma Make: theme.css)
  static const Color brandBackground = Color(0xFFF4F6FF);
  static const Color brandSurface = Color(0xFFFFFFFF);
  static const Color brandSurfaceTint = Color(0xFFEEF0FF);
  static const Color brandMuted = Color(0xFFE2E8FF);

  // Text
  static const Color brandForeground = Color(0xFF0A0D1E);
  static const Color brandMutedText = Color(0xFF3A4960);
  static const Color brandPlaceholder = Color(0xFF4A5A72);
  static const Color brandOnPrimary = Color(0xFFFFFFFF);

  // Brand: fixed by the brand kit (logos and corporate colours); never change these two or the gradient.
  static const Color brandPrimary = Color(0xFF135CFF);
  static const Color brandAccent = Color(0xFFC026D3);

  /// Blue for text links: 7.7:1 on the page, 7.4:1 on the input fill.
  static const Color brandLink = Color(0xFF0B3FC4);
  static const Color brandInstruction = Color(0xFF135CFF);

  // Lines and status
  static const Color brandBorder = Color(0x1F135CFF);

  /// Focus ring: solid brand blue (5.3:1 on white) so it reads at 3:1 or better.
  static const Color brandBorderFocused = Color(0xFF135CFF);
  static const Color brandOutline = Color(0xFFDEDEDE);

  /// Edge of a control that must be seen to be found (4.8:1 or better on white, page and input fill).
  static const Color brandControlBorder = Color(0xFF5B6B82);
  static const Color brandDivider = Color(0xFFDCE4E8);
  static const Color brandError = Color(0xFFA31515);

  /// Success marks (tick badges); 5:1 against white.
  static const Color brandSuccess = Color(0xFF15803D);

  // Sell flow (Figma: Create Listing, AI intro card)
  static const Color sellAiCardStart = Color(0xFFEDE9FF);
  static const Color sellAiCardEnd = Color(0xFFFBEAFF);
  static const Color sellSparkle = Color(0xFFF59E0B);
  static const Color sellAddTile = Color(0x14135CFF);

  /// Selected condition chip: green text on a pale green fill (text 4.5:1 or better).
  static const Color brandSuccessText = Color(0xFF14532D);
  static const Color brandSuccessTint = Color(0xFFE8F6ED);

  /// Price note card: pale amber fill and border (Figma Make).
  static const Color sellNoteTint = Color(0xFFFEF7EB);
  static const Color sellNoteBorder = Color(0x33F59E0B);

  /// Selected plan card glow by plan position (Figma Make: grey-blue 20%, magenta 25%, blue 30%).
  static const Color sellPlanGlowBasic = Color(0x338892B0);
  static const Color sellPlanGlowBoosted = Color(0x40C026D3);
  static const Color sellPlanGlowPriority = Color(0x4D135CFF);

  // Onboarding only (Figma: Just Qlic)
  static const Color onboardingSkipBackground = Color(0xFFE9E9FF);
  static const Color onboardingSkipText = Color(0xFF2F2FB5);
  static const Color onboardingSubtitle = Color(0xFF4A4646);
  static const Color onboardingDotActive = Color(0xFFB0068F);
  static const Color onboardingDotInactive = Color(0xFF0A38B0);
  static const Color onboardingBackButton = Color(0xFFB0068F);
  static const Color onboardingNextButton = Color(0xFF0A38B0);
}
