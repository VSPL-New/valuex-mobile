import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/app_notification.dart';
import '../notification_presentation.dart';

/// "All" plus one tab per category that has notifications; a null [selected] means All.
class NotificationTabs extends StatelessWidget {
  final List<NotificationCategory> categories;
  final NotificationCategory? selected;
  final ValueChanged<NotificationCategory?> onSelected;

  const NotificationTabs({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.brandSurface,
        border: Border(bottom: BorderSide(color: AppColors.brandBorder)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            _Tab(
              label: l10n.notificationsTabAll,
              selected: selected == null,
              onTap: () => onSelected(null),
            ),
            for (final category in categories) ...[
              const SizedBox(width: AppSpacing.sm),
              _Tab(
                label: notificationCategoryLabel(l10n, category),
                selected: selected == category,
                onTap: () => onSelected(category),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? AppColors.brandPrimary : AppColors.brandSurfaceTint,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  label,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: selected ? AppColors.brandOnPrimary : AppColors.brandForeground,
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
