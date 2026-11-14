import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/public_listing.dart';
import 'listing_attribute_table.dart';
import 'listing_gallery.dart';

/// Everything a buyer reads about a listing, top to bottom. It shows only what the server sent.
class ListingViewBody extends StatelessWidget {
  final PublicListing listing;
  final VoidCallback onRefreshPhotos;
  final VoidCallback onOpenSeller;

  const ListingViewBody({
    super.key,
    required this.listing,
    required this.onRefreshPhotos,
    required this.onOpenSeller,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListingGallery(
          photos: listing.photos,
          onRefresh: listing.hasExpiringPhotos ? onRefreshPhotos : null,
        ),
        _Summary(listing: listing),
        if (listing.description.isNotEmpty)
          _Section(
            title: l10n.listingViewDescription,
            icon: Icons.notes_rounded,
            child: Text(
              listing.description,
              style: AppTextStyles.bodySecondary.copyWith(height: 1.7),
            ),
          ),
        if (listing.attributes.isNotEmpty || (listing.conditionNotes?.trim().isNotEmpty ?? false))
          _Section(
            title: l10n.previewItemDetails,
            icon: Icons.grid_view_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (listing.attributes.isNotEmpty)
                  ListingAttributeTable(attributes: listing.attributes),
                if (listing.conditionNotes?.trim().isNotEmpty ?? false) ...[
                  if (listing.attributes.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Divider(height: 1, color: AppColors.brandBorder),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ExcludeSemantics(
                        child:
                            Icon(Icons.info_outline_rounded, size: 16, color: AppColors.brandLink),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          '${l10n.previewConditionNotes}: ${listing.conditionNotes!.trim()}',
                          style: AppTextStyles.bodySecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        _SellerCard(seller: listing.seller, onOpen: onOpenSeller),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  final PublicListing listing;

  const _Summary({required this.listing});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final price = listing.price;
    final days = listing.ageInDays;
    final intent = _intentLabel(l10n, listing.transactionIntent);
    final condition = _conditionLabel(l10n, listing);
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (condition != null || (price != null && listing.negotiable) || intent != null) ...[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (condition != null)
                  _Chip(
                    text: condition.toUpperCase(),
                    condition:
                        listing.conditionCode == 'NEW' || listing.conditionCode == 'LIKE_NEW',
                  ),
                if (price != null && listing.negotiable) _Chip(text: l10n.previewNegotiable),
                if (intent != null) _Chip(text: intent),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Semantics(
            header: true,
            child: Text(listing.title, style: AppTextStyles.heading2),
          ),
          if (price != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  listing.startingFrom
                      ? l10n.listingViewStartingFrom(Formatters.money(price))
                      : Formatters.money(price),
                  style: AppTextStyles.heading2.copyWith(color: AppColors.brandPrimary),
                ),
                if (!listing.startingFrom)
                  Text(l10n.listingViewAskingPrice, style: AppTextStyles.hint),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              if (listing.seller.locationLabel.isNotEmpty)
                _IconText(icon: Icons.place_outlined, text: listing.seller.locationLabel),
              if (days != null)
                _IconText(icon: Icons.schedule_rounded, text: l10n.listingViewPosted(days)),
            ],
          ),
        ],
      ),
    );
  }

  static String? _intentLabel(AppLocalizations l10n, String? intent) => switch (intent) {
        'SALE' => l10n.listingViewIntentSale,
        'RENT' => l10n.listingViewIntentRent,
        'LEASE' => l10n.listingViewIntentLease,
        _ => null,
      };

  static String? _conditionLabel(AppLocalizations l10n, PublicListing listing) =>
      switch (listing.conditionCode) {
        null => null,
        'NEW' => l10n.conditionNew,
        'LIKE_NEW' => l10n.conditionLikeNew,
        'GOOD' => l10n.conditionGood,
        'FAIR' => l10n.conditionFair,
        'POOR' => l10n.conditionPoor,
        _ => listing.conditionLabel,
      };
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;

  const _Section({required this.title, required this.child, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.brandSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.brandBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.brandBorder,
            blurRadius: AppSpacing.sm,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Row(
              children: [
                if (icon != null) ...[
                  ExcludeSemantics(
                    child: Container(
                      width: AppSpacing.xl,
                      height: AppSpacing.xl,
                      decoration: BoxDecoration(
                        color: AppColors.brandSurfaceTint,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(icon, size: 18, color: AppColors.brandPrimary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.brandLink,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _SellerCard extends StatelessWidget {
  final ListingSeller seller;
  final VoidCallback onOpen;

  const _SellerCard({required this.seller, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rating = seller.rating;
    final name = seller.displayName.trim();
    final profileLink = TextButton(
      style: TextButton.styleFrom(
        minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
        foregroundColor: AppColors.brandLink,
      ),
      onPressed: onOpen,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(l10n.listingViewViewSeller, style: AppTextStyles.linkSmall)),
          const SizedBox(width: AppSpacing.xs),
          const ExcludeSemantics(child: Icon(Icons.chevron_right_rounded, size: 16)),
        ],
      ),
    );
    return _Section(
      title: l10n.listingViewSeller,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 280 || MediaQuery.textScalerOf(context).scale(14) > 20;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: AppSizes.minTouchTarget,
                      height: AppSizes.minTouchTarget,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.brandSurfaceTint,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: AppColors.brandBorder),
                      ),
                      child: name.isEmpty
                          ? const Icon(Icons.person_outline_rounded, color: AppColors.brandLink)
                          : Text(
                              name.characters.first.toUpperCase(),
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.brandLink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(seller.displayName, style: AppTextStyles.cardTitle),
                        const SizedBox(height: AppSpacing.xs),
                        if (rating == null)
                          Text(l10n.listingViewNoRating, style: AppTextStyles.hint)
                        else
                          Semantics(
                            label: l10n.listingViewRating(
                              rating.toStringAsFixed(1),
                              seller.ratingCount,
                            ),
                            excludeSemantics: true,
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 16, color: AppColors.sellSparkle),
                                const SizedBox(width: AppSpacing.xs),
                                Flexible(
                                  child: Text(rating.toStringAsFixed(1),
                                      style: AppTextStyles.cardTitle),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!stacked) profileLink,
                ],
              ),
              if (stacked) Align(alignment: AlignmentDirectional.centerEnd, child: profileLink),
            ],
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final bool condition;

  const _Chip({required this.text, this.condition = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: condition ? AppColors.brandSuccessTint : AppColors.brandSurfaceTint,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: condition ? AppColors.brandSuccessText : AppColors.brandLink,
          ),
        ),
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IconText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Icon(icon, size: 16, color: AppColors.brandLink)),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(text, style: AppTextStyles.hint)),
      ],
    );
  }
}
