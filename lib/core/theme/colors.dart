import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2E7D32);
  static const Color secondary = Color(0xFFFFA000);
  static const Color error = Color(0xFFD32F2F);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  // Brand tokens (Figma Make: src/styles/theme.css)
  static const Color brandBackground = Color(0xFFF4F6FF);
  static const Color brandForeground = Color(0xFF0A0D1E);
  static const Color brandPrimary = Color(0xFF2D6BFF);
  static const Color brandAccent = Color(0xFFC026D3);
  static const Color brandMuted = Color(0xFFE2E8FF);

  // Splash / onboarding (Figma: Just Qlic)
  static const Color splashGradientStart = Color(0xFF002442);
  static const Color splashGradientEnd = Color(0xFFC1E100);
  static const Color progressGradientStart = brandPrimary;
  static const Color progressGradientEnd = brandAccent;
  static const Color progressTrack = brandMuted;
  static const Color onboardingSkipBackground = Color(0xFFE9E9FF);
  static const Color onboardingSkipText = Color(0xFF5B5BF7);
  static const Color onboardingSubtitle = Color(0xFF8F8B8B);
  static const Color onboardingDotActive = Color(0xFFD708B7);
  static const Color onboardingDotInactive = Color(0xFF0149FD);
  static const Color onboardingBackButton = Color(0xFFE703B2);
  static const Color onboardingNextButton = Color(0xFF0149FD);
}
