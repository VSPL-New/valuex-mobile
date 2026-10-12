import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/gradients.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/widgets/avatar_image.dart';
import '../../domain/profile_summary.dart';
import 'profile_plan_badge.dart';
import 'profile_stats_row.dart';

/// Background of the Profile top section: a fade from the tint into the page colour, a soft
/// magenta glow and a bottom edge. It also keeps its content below the status bar.
class ProfileHero extends StatelessWidget {
  final Widget child;

  const ProfileHero({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.brandSurfaceTint, AppColors.brandBackground],
        ),
        border: Border(bottom: BorderSide(color: AppColors.brandBorder)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
                    child: SizedBox(
                      width: 288,
                      height: 144,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.brandAccent.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child),
          ),
        ],
      ),
    );
  }
}

/// Avatar, name with a verified mark, masked mobile, rating line, edit button, plan badge and
/// the Listings / Sold / Reviews figures.
class ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final ProfileSummary summary;
  final VoidCallback onEdit;
  final VoidCallback onUpgrade;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.summary,
    required this.onEdit,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final city = profile.city;
    final rating = summary.rating.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(avatarId: profile.avatarId ?? 'avatar-01', premium: summary.isPremium),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile.displayName ?? l10n.profileMissing,
                          style: AppTextStyles.heading2,
                        ),
                      ),
                      if (profile.aadhaarVerified) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Semantics(
                          label: l10n.profileVerified,
                          child: const Icon(Icons.verified, size: 20, color: AppColors.brandAccent),
                        ),
                      ],
                    ],
                  ),
                  if (profile.mobile != null)
                    Text(profile.mobile!, style: AppTextStyles.bodySecondary),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Semantics(
                        label: l10n.profileRatingLabel(rating),
                        excludeSemantics: true,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 16, color: AppColors.brandAccent),
                            const SizedBox(width: AppSpacing.xs),
                            Text(rating, style: AppTextStyles.cardTitle),
                          ],
                        ),
                      ),
                      const _Dot(),
                      Text(
                        l10n.profileTransactions(summary.transactions),
                        style: AppTextStyles.hint,
                      ),
                      if (city != null && city.isNotEmpty) ...[
                        const _Dot(),
                        Text(city, style: AppTextStyles.hint),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.profileEdit,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              color: AppColors.brandForeground,
              style: IconButton.styleFrom(
                minimumSize: const Size.square(AppSizes.minTouchTarget),
                backgroundColor: AppColors.brandSurface,
                side: const BorderSide(color: AppColors.brandControlBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ProfilePlanBadge(summary: summary, onUpgrade: onUpgrade),
        ),
        const SizedBox(height: AppSpacing.sm),
        ProfileStatsRow(summary: summary),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String avatarId;
  final bool premium;

  const _Avatar({required this.avatarId, required this.premium});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AvatarImage(avatarId: avatarId, size: 80),
          if (premium)
            const PositionedDirectional(
              top: -4,
              end: -4,
              child: DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.brand),
                child: SizedBox.square(
                  dimension: 24,
                  child: Icon(Icons.auto_awesome, size: 12, color: AppColors.brandOnPrimary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(child: Text('\u2022', style: AppTextStyles.hint));
  }
}
