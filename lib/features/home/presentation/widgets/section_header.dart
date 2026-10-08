import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/gradients.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';

/// A section title (marked as a heading) with an optional action on the right.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final actionLabel = this.actionLabel;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: AppTextStyles.sectionTitle),
          ),
        ),
        if (actionLabel != null)
          Semantics(
            button: true,
            label: actionLabel,
            excludeSemantics: true,
            onTap: onAction,
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Center(
                    widthFactor: 1,
                    child: Text(actionLabel, style: AppTextStyles.linkSmall),
                  ),
                ),
              ),
            ),
          )
        else
          const SizedBox(height: AppSizes.minTouchTarget),
      ],
    );
  }
}

/// Dots for a carousel. The active one is a short bar, so position is not shown by colour alone.
class CarouselDots extends StatelessWidget {
  final int count;
  final int index;

  const CarouselDots({super.key, required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: i == index ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: i == index ? AppGradients.brand : null,
                color: i == index ? null : AppColors.brandControlBorder,
              ),
            ),
          ),
      ],
    );
  }
}
