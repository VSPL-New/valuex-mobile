import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class ProfileMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Items that need attention; no badge when zero.
  final int badge;

  const ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });
}

const profileCardShadow = [
  BoxShadow(color: Color(0x0F135CFF), blurRadius: 10, offset: Offset(0, 2)),
  BoxShadow(color: Color(0x0F000000), blurRadius: 3, offset: Offset(0, 1)),
];

/// A titled card of tappable rows (Buying, Selling, Account). Every row is announced as one
/// button and has at least a 48 dp tap area.
class ProfileMenuSection extends StatelessWidget {
  final String title;
  final List<ProfileMenuItem> items;

  const ProfileMenuSection({super.key, required this.title, required this.items});

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
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.brandBorder),
                  _MenuRow(item: items[i]),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final ProfileMenuItem item;

  const _MenuRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.badge > 0
          ? AppLocalizations.of(context).profileMenuBadgeLabel(item.label, item.badge)
          : item.label,
      excludeSemantics: true,
      onTap: item.onTap,
      child: InkWell(
        onTap: item.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.brandMuted,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: SizedBox.square(
                    dimension: 36,
                    child: Icon(item.icon, size: 18, color: AppColors.brandLink),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    item.label,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                if (item.badge > 0) ...[
                  _CountBadge(count: item.badge),
                  const SizedBox(width: AppSpacing.sm),
                ],
                const Icon(Icons.chevron_right, size: 20, color: AppColors.brandMutedText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Count pill; the number is capped at 99+ on screen, the screen reader hears the real count.
class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandPrimary,
        borderRadius: BorderRadius.circular(AppRadius.xl * 2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        child: Center(
          widthFactor: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: AppTextStyles.caption.copyWith(color: AppColors.brandOnPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Destructive action row, drawn in the error colour with an icon and text, never colour alone.
class ProfileSignOutTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData icon;

  const ProfileSignOutTile({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.logout,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: AppColors.brandError.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.brandError),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.brandError.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: SizedBox.square(
                      dimension: 36,
                      child: Icon(icon, size: 18, color: AppColors.brandError),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.brandError,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
