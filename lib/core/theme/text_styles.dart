import 'package:flutter/material.dart';
import 'colors.dart';

/// Font families bundled in pubspec.yaml.
class AppFonts {
  AppFonts._();

  static const String heading = 'Poppins';
  static const String body = 'DMSans';

  /// DM Sans has no Devanagari glyphs; Poppins does.
  static const List<String> bodyFallback = [heading];
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
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: AppColors.brandForeground,
  );

  static const TextStyle input = TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: 16,
    height: 24 / 16,
    color: AppColors.brandForeground,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: 14,
    height: 20 / 14,
    color: AppColors.brandMutedText,
  );

  static const TextStyle label = TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: AppColors.brandMutedText,
  );

  /// Helper text, timers and messages under a field (14 px; 12 px is for captions only).
  static const TextStyle hint = TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: 14,
    height: 20 / 14,
    color: AppColors.brandMutedText,
  );

  /// Tappable text such as Resend code or Change number.
  static const TextStyle link = TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
    color: AppColors.brandLink,
  );

  /// Error message under a field; always shown with an icon, never colour alone.
  static const TextStyle error = TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    color: AppColors.brandError,
  );

  static const TextStyle button = TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.brandOnPrimary,
  );

  static const TextStyle dividerLabel = TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
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
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: 16,
    height: 23 / 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onboardingSubtitle,
  );

  static const TextStyle skipLabel = TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.onboardingSkipText,
  );

  static const TextStyle splashProgressLabel = TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.brandForeground,
  );

  /// Badges, chips and tab labels only; 12 px is not for body or helper text.
  static const TextStyle caption = TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    color: AppColors.brandMutedText,
  );

  /// Title of a section on a page (Browse, Featured Deals).
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
    color: AppColors.brandForeground,
  );

  /// Small tappable text such as See All; give it a 48 dp tap area.
  static const TextStyle linkSmall = TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    color: AppColors.brandLink,
  );

  // Home
  static const TextStyle cardTitle = TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    color: AppColors.brandForeground,
  );

  static const TextStyle cardPrice = TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w700,
    color: AppColors.brandLink,
  );

  /// Text on the brand gradient or on a dark promo card.
  static const TextStyle onGradientStrong = TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w700,
    color: AppColors.brandOnPrimary,
  );

  static const TextStyle onGradient = TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.brandOnPrimary,
  );

  static const TextStyle promoTitle = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
    color: AppColors.brandOnPrimary,
  );

  /// Caption under a photo-tip tile.
  static const TextStyle tipCaption = TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    color: AppColors.brandForeground,
  );
}
