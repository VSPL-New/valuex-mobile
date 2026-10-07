import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Full-width secondary action: same shape and type as [BrandGradientButton]
/// on a light tint of the brand blue. Dimmed when [onPressed] is null.
class SingleToneButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const SingleToneButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.xl);
    return Opacity(
      opacity: onPressed != null ? 1 : 0.4,
      child: Material(
        color: AppColors.brandMuted,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.buttonMedium,
              minWidth: double.infinity,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.brandForeground,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
