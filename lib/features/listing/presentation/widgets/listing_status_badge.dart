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

/// What a status means and what the seller can do about it, for a listing that cannot be opened for
/// editing. Until the read-only listing page exists (US-123) this is shown in a sheet.
String listingStatusExplanation(AppLocalizations l10n, ListingBadge badge) => switch (badge) {
      ListingBadge.processingPayment => l10n.myListingsStatusProcessing,
      ListingBadge.underReview => l10n.myListingsStatusUnderReview,
      ListingBadge.expired => l10n.myListingsStatusExpired,
      ListingBadge.rejected => l10n.myListingsStatusRejected,
      _ => l10n.myListingsStatusUnavailable,
    };

/// The pill that names a listing's status. The words carry the meaning; the colour only supports
/// them.
class ListingStatusBadge extends StatelessWidget {
  final ListingBadge badge;

  const ListingStatusBadge({super.key, required this.badge});

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
          listingBadgeLabel(AppLocalizations.of(context), badge),
          style: AppTextStyles.caption.copyWith(color: foreground, fontSize: 12, height: 16 / 12),
        ),
      ),
    );
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
