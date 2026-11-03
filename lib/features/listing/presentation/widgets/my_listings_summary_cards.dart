import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/my_listings.dart';

/// Active, Sold and Total Views above the list (US-010). Views stay at zero until they are
/// tracked (US-067).
class MyListingsSummaryCards extends StatelessWidget {
  final MyListingsSummary summary;

  const MyListingsSummaryCards({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Three cards of the same height, whatever the text size; IntrinsicHeight because a stretched
    // Row cannot take an unbounded height from the list around it.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _SummaryCard(
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.brandSuccess,
              value: summary.active,
              label: l10n.myListingsSummaryActive,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SummaryCard(
              icon: Icons.sell_outlined,
              color: AppColors.brandPrimary,
              value: summary.sold,
              label: l10n.myListingsSummarySold,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SummaryCard(
              icon: Icons.visibility_outlined,
              color: AppColors.brandAccent,
              value: summary.totalViews,
              label: l10n.myListingsSummaryViews,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;

  const _SummaryCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    // One announcement per card: "12 Active", not the number and the word apart.
    return Semantics(
      container: true,
      label: '$value $label',
      excludeSemantics: true,
      child: SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
        radius: AppRadius.lg,
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('$value', style: AppTextStyles.heading2.copyWith(height: 1.2)),
            ),
            Text(
              label,
              style: AppTextStyles.hint,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
