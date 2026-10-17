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
  static const Color brandMutedText = Color(0xFF5B6B82);
  static const Color brandPlaceholder = Color(0xFF5F6D83);
  static const Color brandOnPrimary = Color(0xFFFFFFFF);

  // Brand
  static const Color brandPrimary = Color(0xFF135CFF);
  static const Color brandAccent = Color(0xFFC026D3);

  /// Blue for text links; `brandPrimary` is 4.9:1 on the page, this is 5.3:1.
  static const Color brandLink = Color(0xFF1F5AE6);
  static const Color brandInstruction = Color(0xFF135CFF);

  // Lines and status
  static const Color brandBorder = Color(0x1F135CFF);
  static const Color brandBorderFocused = Color(0x4D135CFF);
  static const Color brandOutline = Color(0xFFDEDEDE);

  /// Edge of a control that must be seen to be found (3:1 on white, page and input fill).
  static const Color brandControlBorder = Color(0xFF76839B);
  static const Color brandDivider = Color(0xFFDCE4E8);
  static const Color brandError = Color(0xFFC81E1E);

  /// Success marks (tick badges); 3:1 against white.
  static const Color brandSuccess = Color(0xFF16A34A);

  // Sell flow (Figma: Create Listing, AI intro card)
  static const Color sellAiCardStart = Color(0xFFEDE9FF);
  static const Color sellAiCardEnd = Color(0xFFFBEAFF);
  static const Color sellSparkle = Color(0xFFF59E0B);
  static const Color sellAddTile = Color(0x14135CFF);

  /// Selected condition chip: green text on a pale green fill (text 4.5:1 or better).
  static const Color brandSuccessText = Color(0xFF166534);
  static const Color brandSuccessTint = Color(0xFFE8F6ED);

  /// Price note card: pale amber fill and border (Figma Make).
  static const Color sellNoteTint = Color(0xFFFEF7EB);
  static const Color sellNoteBorder = Color(0x33F59E0B);

  // Onboarding only (Figma: Just Qlic)
  static const Color onboardingSkipBackground = Color(0xFFE9E9FF);
  static const Color onboardingSkipText = Color(0xFF4A4AE0);
  static const Color onboardingSubtitle = Color(0xFF6F6B6B);
  static const Color onboardingDotActive = Color(0xFFD708B7);
  static const Color onboardingDotInactive = Color(0xFF0149FD);
  static const Color onboardingBackButton = Color(0xFFE703B2);
  static const Color onboardingNextButton = Color(0xFF0149FD);
}
