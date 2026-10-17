import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';

/// Blue for category, green for condition (Figma Make).
enum OptionChipTone { primary, success }

/// One choice in a single-select group (category, condition): a small bordered pill (Figma Make
/// size) with a check when selected, inside a 48 dp tap area, exposed to screen readers as a
/// radio button.
class OptionChip extends StatelessWidget {
  static const double iconSize = 16;
  static const double checkWidth = iconSize + AppSpacing.xs;
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 12, vertical: 4);

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final OptionChipTone tone;

  /// A button that opens more choices (the Others chip) rather than a choice itself.
  final bool isAction;

  const OptionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.tone = OptionChipTone.primary,
    this.isAction = false,
  });

  static TextStyle textStyle({required bool selected}) =>
      AppTextStyles.hint.copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w400);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSizes.minTouchTarget);
    final success = tone == OptionChipTone.success;
    final accent = success ? AppColors.brandSuccess : AppColors.brandPrimary;
    final selectedText = success ? AppColors.brandSuccessText : AppColors.brandLink;
    final selectedFill = success ? AppColors.brandSuccessTint : AppColors.brandSurfaceTint;
    final color = selected ? selectedText : AppColors.brandForeground;
    return Semantics(
      inMutuallyExclusiveGroup: !isAction,
      checked: isAction ? null : selected,
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Center(
            widthFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? selectedFill : AppColors.brandSurface,
                borderRadius: radius,
                border: Border.all(
                  color: selected ? accent : AppColors.brandControlBorder,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: padding,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected) ...[
                      Icon(Icons.check_rounded, size: iconSize, color: color),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        style: textStyle(selected: selected).copyWith(color: color),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
