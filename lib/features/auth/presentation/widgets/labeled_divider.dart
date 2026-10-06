import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';

/// Horizontal rule with a centred label, e.g. "Or login with".
class LabeledDivider extends StatelessWidget {
  final String label;

  const LabeledDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    const line = Expanded(
      child: SizedBox(
        height: 1,
        child: ColoredBox(color: AppColors.brandDivider),
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 325),
      child: Row(
        children: [
          line,
          const SizedBox(width: AppSpacing.lg),
          Text(label, style: AppTextStyles.dividerLabel),
          const SizedBox(width: AppSpacing.lg),
          line,
        ],
      ),
    );
  }
}
