import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../profile/presentation/widgets/profile_menu_section.dart';

/// A button at the end of a [SecurityRow]. [semanticLabel] says what it changes when the
/// visible [label] is shared by several rows.
class SecurityAction {
  final String label;
  final String? semanticLabel;
  final VoidCallback onPressed;

  const SecurityAction({required this.label, this.semanticLabel, required this.onPressed});
}

/// A titled card of rows, in the same style as the Profile menu sections.
class SecuritySection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SecuritySection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Semantics(header: true, child: Text(title, style: AppTextStyles.label)),
        ),
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.brandSurface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.brandBorder),
            boxShadow: profileCardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.brandBorder),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Icon tile, a label with its value and an optional trailing button. The row is read as one
/// piece by a screen reader; the button stays separately focusable.
class SecurityRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final IconData? valueIcon;
  final String? hint;
  final String? tag;
  final bool emphasiseLabel;
  final SecurityAction? action;

  const SecurityRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.valueIcon,
    this.hint,
    this.tag,
    this.emphasiseLabel = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    // A long label next to the text would overflow at large text sizes, so it moves below it.
    final stacked = MediaQuery.textScalerOf(context).scale(14) > 14 * 1.3;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.brandMuted,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: SizedBox.square(
                  dimension: 36,
                  child: Icon(icon, size: 18, color: AppColors.brandLink),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MergeSemantics(child: _content()),
                  if (action != null && stacked) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _actionButton(action),
                  ],
                ],
              ),
            ),
            if (action != null && !stacked) ...[
              const SizedBox(width: AppSpacing.sm),
              _actionButton(action),
            ],
          ],
        ),
      ),
    );
  }

  Widget _content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: emphasiseLabel
              ? AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)
              : AppTextStyles.label,
        ),
        if (value != null) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              if (valueIcon != null) ...[
                Icon(valueIcon, size: 16, color: AppColors.brandMutedText),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  value!,
                  style: emphasiseLabel ? AppTextStyles.bodySecondary : AppTextStyles.body,
                ),
              ),
            ],
          ),
        ],
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(hint!, style: AppTextStyles.hint),
        ],
        if (tag != null) ...[
          const SizedBox(height: AppSpacing.xs),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.brandSurfaceTint,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.brandControlBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
              child: Text(
                tag!,
                style: AppTextStyles.hint.copyWith(color: AppColors.brandForeground),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _actionButton(SecurityAction action) {
    return Semantics(
      button: true,
      label: action.semanticLabel ?? action.label,
      excludeSemantics: true,
      onTap: action.onPressed,
      child: TextButton(
        onPressed: action.onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
        ),
        child: Text(action.label, style: AppTextStyles.link),
      ),
    );
  }
}
