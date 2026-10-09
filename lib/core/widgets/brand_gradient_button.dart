import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/gradients.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Full-width primary action with the brand gradient.
/// Dimmed and non-interactive when [onPressed] is null; shows a spinner and
/// ignores taps while [isLoading].
class BrandGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const BrandGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null || isLoading;
    final radius = BorderRadius.circular(AppRadius.xl);
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: enabled
              ? const [
                  BoxShadow(color: Color(0x592D6BFF), blurRadius: 24),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: AppGradients.brand,
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: isLoading ? null : onPressed,
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
                    child: isLoading
                        ? Semantics(
                            label: label,
                            child: const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.brandOnPrimary,
                              ),
                            ),
                          )
                        : Text(label, textAlign: TextAlign.center, style: AppTextStyles.button),
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
