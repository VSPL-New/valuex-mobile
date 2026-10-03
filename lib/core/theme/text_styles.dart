import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextTheme textTheme = TextTheme(
    displayLarge: heading1,
    displayMedium: heading2,
    bodyLarge: body,
    bodyMedium: bodySecondary,
  );

  // Onboarding / splash: Figma Make brand fonts (Outfit headings, DM Sans body).
  static const TextStyle onboardingTitle = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 28,
    height: 38 / 28,
    fontWeight: FontWeight.w700,
    color: AppColors.brandForeground,
  );

  static const TextStyle onboardingSubtitle = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 16,
    height: 23 / 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onboardingSubtitle,
  );

  static const TextStyle skipLabel = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.onboardingSkipText,
  );

  static const TextStyle splashTagline = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );

  static const TextStyle splashProgressLabel = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.brandForeground,
  );
}
