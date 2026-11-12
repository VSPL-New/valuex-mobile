import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/category_icon.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../listing/domain/category.dart';

class CategoryBranchHeading extends StatelessWidget {
  final CategoryNode node;
  final bool? expanded;
  final VoidCallback onTap;
  final VoidCallback? onViewAll;

  const CategoryBranchHeading({
    super.key,
    required this.node,
    required this.expanded,
    required this.onTap,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final heading = Semantics(
      header: true,
      expanded: expanded,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                if (node.level == 1) ...[
                  CategoryIcon(name: node.name, code: node.code),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(child: Text(node.name, style: AppTextStyles.sectionTitle)),
                if (expanded != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    expanded! ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: AppColors.brandMutedText,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (onViewAll == null) return heading;
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(child: heading),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.brandLink,
            minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
          ),
          onPressed: onViewAll,
          child: Text(
            l10n.searchViewAll,
            semanticsLabel: l10n.searchViewAllIn(node.name),
          ),
        ),
      ],
    );
  }
}

class CategoryLeafGrid extends StatelessWidget {
  final List<CategoryNode> nodes;
  final ValueChanged<CategoryNode> onSelected;
  final IconData? fallbackIcon;

  const CategoryLeafGrid({
    super.key,
    required this.nodes,
    required this.onSelected,
    this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final columns = (constraints.maxWidth / (88 * scale)).floor().clamp(1, 3);
        final width = (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final node in nodes)
              SizedBox(
                width: width,
                child: Semantics(
                  button: true,
                  label: node.name,
                  excludeSemantics: true,
                  onTap: () => onSelected(node),
                  child: InkWell(
                    onTap: () => onSelected(node),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Column(
                        children: [
                          CategoryIcon(
                            name: node.name,
                            code: node.code,
                            size: 64,
                            fallback: fallbackIcon,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            node.name,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.brandForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
