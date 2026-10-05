import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Full-width outlined button with a leading SVG icon (social / guest login).
class OutlinedIconButton extends StatelessWidget {
  final String label;
  final String iconAsset;
  final VoidCallback onPressed;

  const OutlinedIconButton({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.md);
    return Material(
      color: AppColors.brandSurface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AppColors.brandOutline),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onPressed,
        child: SizedBox(
          height: AppSizes.buttonMedium,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(iconAsset, width: 29, height: 29),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTextStyles.button.copyWith(
                  color: AppColors.brandForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
