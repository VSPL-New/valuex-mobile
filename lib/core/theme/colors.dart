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
  static const Color brandMutedText = Color(0xFF64748B);
  static const Color brandPlaceholder = Color(0xFF94A3B8);
  static const Color brandOnPrimary = Color(0xFFFFFFFF);

  // Brand
  static const Color brandPrimary = Color(0xFF2D6BFF);
  static const Color brandAccent = Color(0xFFC026D3);

  // Lines and status
  static const Color brandBorder = Color(0x1F2D6BFF);
  static const Color brandBorderFocused = Color(0x4D2D6BFF);
  static const Color brandOutline = Color(0xFFDEDEDE);

  /// Edge of a control that must be seen to be found (3:1 on white, page and input fill).
  static const Color brandControlBorder = Color(0xFF76839B);
  static const Color brandDivider = Color(0xFFDCE4E8);
  static const Color brandError = Color(0xFFEF4444);

  // Onboarding only (Figma: Just Qlic)
  static const Color onboardingSkipBackground = Color(0xFFE9E9FF);
  static const Color onboardingSkipText = Color(0xFF4A4AE0);
  static const Color onboardingSubtitle = Color(0xFF6F6B6B);
  static const Color onboardingDotActive = Color(0xFFD708B7);
  static const Color onboardingDotInactive = Color(0xFF0149FD);
  static const Color onboardingBackButton = Color(0xFFE703B2);
  static const Color onboardingNextButton = Color(0xFF0149FD);
}
