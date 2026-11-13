import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/my_listings.dart';

/// The words of a listing status as the seller reads them (US-010).
String listingBadgeLabel(AppLocalizations l10n, ListingBadge badge) => switch (badge) {
      ListingBadge.active => l10n.myListingsBadgeActive,
      ListingBadge.sold => l10n.myListingsBadgeSold,
      ListingBadge.draft => l10n.myListingsBadgeDraft,
      ListingBadge.processingPayment => l10n.myListingsBadgeProcessing,
      ListingBadge.underReview => l10n.myListingsBadgeUnderReview,
      ListingBadge.needsChanges => l10n.myListingsBadgeNeedsChanges,
      ListingBadge.expired => l10n.myListingsBadgeExpired,
      ListingBadge.rejected => l10n.myListingsBadgeRejected,
      ListingBadge.unavailable => l10n.myListingsBadgeUnavailable,
    };

/// Sold, Rented or Leased, for a property the owner closed (US-118).
String closedOutcomeLabel(AppLocalizations l10n, ClosedOutcome outcome) => switch (outcome) {
      ClosedOutcome.sold => l10n.myListingsOutcomeSold,
      ClosedOutcome.rented => l10n.myListingsOutcomeRented,
      ClosedOutcome.leased => l10n.myListingsOutcomeLeased,
    };

/// The pill that names a listing's status. The words carry the meaning; the colour only supports
/// them.
class ListingStatusBadge extends StatelessWidget {
  final ListingBadge badge;

  /// How a closed property ended; replaces "Sold" on a property that was rented or leased.
  final ClosedOutcome? closedOutcome;

  const ListingStatusBadge({super.key, required this.badge, this.closedOutcome});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colors(badge);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Text(
          _label(AppLocalizations.of(context)),
          style: AppTextStyles.caption.copyWith(color: foreground, fontSize: 12, height: 16 / 12),
        ),
      ),
    );
  }

  String _label(AppLocalizations l10n) {
    final outcome = closedOutcome;
    if (badge == ListingBadge.sold && outcome != null) return closedOutcomeLabel(l10n, outcome);
    return listingBadgeLabel(l10n, badge);
  }

  static (Color, Color) _colors(ListingBadge badge) => switch (badge) {
        ListingBadge.active => (AppColors.brandSuccessTint, AppColors.brandSuccessText),
        ListingBadge.sold => (AppColors.brandSurfaceTint, AppColors.brandLink),
        ListingBadge.processingPayment || ListingBadge.underReview => (
            AppColors.sellNoteTint,
            AppColors.brandForeground
          ),
        ListingBadge.needsChanges || ListingBadge.rejected => (
            AppColors.brandErrorTint,
            AppColors.brandError
          ),
        ListingBadge.draft || ListingBadge.expired || ListingBadge.unavailable => (
            AppColors.brandMuted,
            AppColors.brandMutedText
          ),
      };
}
