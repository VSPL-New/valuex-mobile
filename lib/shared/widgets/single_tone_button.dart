import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/text_styles.dart';

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
          child: SizedBox(
            height: AppSizes.buttonMedium,
            width: double.infinity,
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.button.copyWith(
                  color: AppColors.brandForeground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
