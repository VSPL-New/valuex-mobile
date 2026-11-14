import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/listing.dart';
import '../home_labels.dart';

/// A listing in the Featured Deals grid. Announced as one button with its key facts.
class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;

  const ListingCard({super.key, required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final listingCondition = listing.condition;
    final condition = listingCondition == null ? null : conditionLabel(l10n, listingCondition);
    final rating = listing.sellerRating;
    final priceInr = listing.priceInr;
    final price = priceInr == null ? null : Formatters.money(priceInr);
    final badge = listing.isFeatured
        ? l10n.searchFeatured
        : listing.isBoosted
            ? l10n.homeBoosted
            : null;
    final radius = BorderRadius.circular(AppRadius.xl);

    final spoken = [
      listing.title,
      if (price != null) '${listing.startingFrom ? '${l10n.searchStartingFrom} ' : ''}$price',
      listing.locationLabel,
      if (rating != null) l10n.homeRatingLabel(rating.toStringAsFixed(1)),
      if (condition != null) condition,
      if (badge != null) badge,
    ].join(', ');

    return Semantics(
      button: true,
      label: spoken,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: AppColors.brandSurface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: AppColors.brandControlBorder),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 177 / 128,
                    child: AppImage(source: listing.image, cacheWidth: 420),
                  ),
                  if (badge != null)
                    Positioned(
                      left: AppSpacing.sm,
                      top: AppSpacing.sm,
                      child: _Pill(
                        label: badge,
                        background:
                            listing.isFeatured ? AppColors.brandPrimary : AppColors.brandAccent,
                        textColor: AppColors.brandOnPrimary,
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle,
                      ),
                      const SizedBox(height: 2),
                      if (listing.startingFrom && price != null)
                        Text(l10n.searchStartingFrom, style: AppTextStyles.hint),
                      if (price != null) Text(price, style: AppTextStyles.cardPrice),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              listing.locationLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.hint,
                            ),
                          ),
                          if (rating != null) ...[
                            SvgPicture.asset(AppAssets.homeStarIcon, width: 12, height: 12),
                            const SizedBox(width: 2),
                            Text(rating.toStringAsFixed(1), style: AppTextStyles.hint),
                          ],
                        ],
                      ),
                      const Spacer(),
                      if (condition != null) ...[
                        const SizedBox(height: AppSpacing.sm - 2),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _Pill(
                            label: condition,
                            background: AppColors.brandSurfaceTint,
                            textColor: AppColors.brandForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;

  const _Pill({required this.label, required this.background, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        child: Text(label, style: AppTextStyles.caption.copyWith(color: textColor)),
      ),
    );
  }
}
