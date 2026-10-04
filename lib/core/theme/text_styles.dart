import 'package:flutter/material.dart';
import 'colors.dart';

/// Font families bundled in pubspec.yaml.
class AppFonts {
  AppFonts._();

  static const String heading = 'Poppins';
  static const String body = 'DMSans';
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle heading1 = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 28,
    height: 38 / 28,
    fontWeight: FontWeight.w700,
    color: AppColors.brandForeground,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 24,
    height: 1.5,
    fontWeight: FontWeight.w700,
    color: AppColors.brandForeground,
  );

  static const TextStyle body = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: AppColors.brandForeground,
  );

  static const TextStyle input = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    height: 20 / 14,
    color: AppColors.brandForeground,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    height: 20 / 14,
    color: AppColors.brandMutedText,
  );

  static const TextStyle label = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.6,
    color: AppColors.brandMutedText,
  );

  static const TextStyle hint = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 12,
    height: 16 / 12,
    color: AppColors.brandPlaceholder,
  );

  static const TextStyle button = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.brandOnPrimary,
  );

  static const TextStyle dividerLabel = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    height: 1.4,
    letterSpacing: -0.28,
    fontWeight: FontWeight.w500,
    color: AppColors.brandForeground,
  );

  static const TextTheme textTheme = TextTheme(
    displayLarge: heading1,
    displayMedium: heading2,
    bodyLarge: body,
    bodyMedium: bodySecondary,
    labelLarge: button,
  );

  // Screen-specific
  static const TextStyle onboardingSubtitle = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 16,
    height: 23 / 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onboardingSubtitle,
  );

  static const TextStyle skipLabel = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.onboardingSkipText,
  );

  static const TextStyle splashProgressLabel = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.brandForeground,
  );
}
