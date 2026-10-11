import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/gradients.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/profile_summary.dart';

/// "Vision Plan — Active" on the brand gradient for premium users, otherwise a button that
/// invites them to upgrade (48 dp tap area around the pill).
class ProfilePlanBadge extends StatelessWidget {
  final ProfileSummary summary;
  final VoidCallback onUpgrade;

  const ProfilePlanBadge({super.key, required this.summary, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (summary.isPremium) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.brand,
          borderRadius: BorderRadius.circular(AppRadius.xl * 2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md - 4, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: AppColors.brandOnPrimary),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  l10n.profilePlanActive(summary.planName),
                  style: AppTextStyles.onGradientStrong,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final label = l10n.profileUpgrade;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onUpgrade,
      child: InkWell(
        onTap: onUpgrade,
        borderRadius: BorderRadius.circular(AppRadius.xl * 2),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Center(
            widthFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.xl * 2),
                border: Border.all(color: AppColors.brandLink),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md - 4, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 14, color: AppColors.brandLink),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(child: Text(label, style: AppTextStyles.linkSmall)),
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
