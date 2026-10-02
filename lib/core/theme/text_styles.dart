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

  // Onboarding / splash (Figma uses Poppins/General Sans/Parkinsans — mapped to
  // the bundled Inter family since those fonts are not part of this project).
  static const TextStyle onboardingTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    height: 1.35,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle onboardingSubtitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: AppColors.onboardingSubtitle,
  );

  static const TextStyle skipLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.onboardingSkipText,
  );

  static const TextStyle splashTagline = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );

  static const TextStyle splashProgressLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
}
