import 'package:flutter/material.dart';
import '../theme/gradients.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Full-width primary action with the brand gradient.
/// Dimmed and non-interactive when [onPressed] is null.
class BrandGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const BrandGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
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
              onTap: onPressed,
              child: SizedBox(
                height: AppSizes.buttonMedium,
                width: double.infinity,
                child: Center(
                  child: Text(label, style: AppTextStyles.button),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
