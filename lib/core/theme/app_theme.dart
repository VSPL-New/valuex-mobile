import 'package:flutter/material.dart';
import 'colors.dart';
import 'spacing.dart';
import 'text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    OutlineInputBorder border(Color color, {double width = 1}) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandPrimary,
        primary: AppColors.brandPrimary,
        secondary: AppColors.brandAccent,
        error: AppColors.brandError,
        surface: AppColors.brandSurface,
      ),
      scaffoldBackgroundColor: AppColors.brandBackground,
      textTheme: AppTextStyles.textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.brandBackground,
        foregroundColor: AppColors.brandForeground,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: AppColors.brandOnPrimary,
          minimumSize: const Size.fromHeight(AppSizes.buttonMedium),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.brandSurfaceTint,
        border: border(AppColors.brandControlBorder),
        enabledBorder: border(AppColors.brandControlBorder),
        focusedBorder: border(AppColors.brandPrimary, width: 2),
        errorBorder: border(AppColors.brandError, width: 2),
        focusedErrorBorder: border(AppColors.brandError, width: 2),
        errorStyle: AppTextStyles.error,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        hintStyle: AppTextStyles.input.copyWith(
          color: AppColors.brandPlaceholder,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.brandSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.brandBorder),
        ),
      ),
    );
  }
}
