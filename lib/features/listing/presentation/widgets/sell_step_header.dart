import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/gradients.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/square_back_button.dart';

/// Top of every Sell step: back button, the progress bar (Photos, Details, Plan, Review) and the
/// step title with its subtitle.
class SellStepHeader extends StatelessWidget {
  static const int steps = 4;

  /// Zero-based index of the current step.
  final int step;
  final String title;
  final String subtitle;

  /// When set, shown instead of [subtitle] as a blue banner with a sparkle (the AI notice).
  final String? aiNotice;
  final VoidCallback onBack;

  const SellStepHeader({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    this.aiNotice,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.brandBorder)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SquareBackButton(onPressed: onBack),
              const SizedBox(height: AppSpacing.sm),
              ExcludeSemantics(
                child: Row(
                  children: [
                    for (var i = 0; i < steps; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: i <= step ? AppGradients.brand : null,
                            color: i <= step ? null : AppColors.brandBorder,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Semantics(header: true, child: Text(title, style: AppTextStyles.heading2)),
              if (aiNotice == null)
                Text(subtitle, style: AppTextStyles.hint)
              else
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: _AiNotice(text: aiNotice!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Blue tinted box with a sparkle, as in Figma Make.
class _AiNotice extends StatelessWidget {
  final String text;

  const _AiNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandSurfaceTint,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.brandBorderFocused),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ExcludeSemantics(
              child: Icon(Icons.auto_awesome, size: 20, color: AppColors.brandLink),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodySecondary.copyWith(color: AppColors.brandLink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
