import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/profile_summary.dart';

/// Three equal tiles: Listings, Sold and Reviews. Tiles grow together with the text size.
class ProfileStatsRow extends StatelessWidget {
  final ProfileSummary summary;

  const ProfileStatsRow({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rating = summary.rating.toStringAsFixed(1);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _Stat(label: l10n.profileStatListings, value: '${summary.listings}')),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _Stat(label: l10n.profileStatSold, value: '${summary.sold}')),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _Stat(label: l10n.profileStatReviews, value: rating, star: true)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final bool star;

  const _Stat({required this.label, required this.value, this.star = false});

  static final _valueStyle = AppTextStyles.sectionTitle.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label $value',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.brandPrimary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.brandBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 2,
                children: [
                  Text(value, style: _valueStyle),
                  if (star) const Icon(Icons.star, size: 16, color: AppColors.brandAccent),
                ],
              ),
              Text(label, style: AppTextStyles.hint, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
