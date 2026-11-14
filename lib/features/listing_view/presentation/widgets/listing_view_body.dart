import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/public_listing.dart';
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
            child: Text(
              listing.description,
              style: AppTextStyles.bodySecondary.copyWith(height: 1.7),
            ),
          ),
        if (listing.attributes.isNotEmpty)
          _Section(
            title: l10n.previewItemDetails,
            child: Column(
              children: [for (final attribute in listing.attributes) _AttributeRow(attribute)],
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(listing.title, style: AppTextStyles.heading2),
                ),
              ),
              if (condition != null) ...[
                const SizedBox(width: AppSpacing.sm),
                _Chip(text: condition),
              ],
            ],
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
                  style: AppTextStyles.heading2.copyWith(color: AppColors.brandLink),
                ),
                if (listing.negotiable) Text(l10n.previewNegotiable, style: AppTextStyles.hint),
              ],
            ),
          ],
          if (intent != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(alignment: AlignmentDirectional.centerStart, child: _Chip(text: intent)),
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
          if (listing.conditionNotes != null && listing.conditionNotes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${l10n.previewConditionNotes}: ${listing.conditionNotes}',
              style: AppTextStyles.bodySecondary,
            ),
          ],
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

  const _Section({required this.title, required this.child});

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
            child: Text(title.toUpperCase(), style: AppTextStyles.label),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _AttributeRow extends StatelessWidget {
  final ListingAttribute attribute;

  const _AttributeRow(this.attribute);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = formatAttributeValue(l10n, attribute);
    return Semantics(
      container: true,
      label: '${attribute.label}: $value',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: Text(attribute.label, style: AppTextStyles.hint)),
            const SizedBox(width: AppSpacing.md),
            Expanded(flex: 3, child: Text(value, style: AppTextStyles.body)),
          ],
        ),
      ),
    );
  }
}

/// The attribute's value as text: Yes/No for a boolean, a comma list for several, then its unit.
String formatAttributeValue(AppLocalizations l10n, ListingAttribute attribute) {
  final value = attribute.value;
  final text = switch (value) {
    bool flag => flag ? l10n.itemYes : l10n.itemNo,
    List<dynamic> items => items.join(', '),
    num number => number == number.roundToDouble() ? '${number.toInt()}' : '$number',
    _ => '$value',
  };
  final unit = attribute.unit;
  return unit == null || unit.isEmpty || value is bool ? text : '$text $unit';
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
      child: Text(l10n.listingViewViewSeller, style: AppTextStyles.linkSmall),
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
                          ? const Icon(Icons.person_outline_rounded)
                          : Text(name.characters.first.toUpperCase(), style: AppTextStyles.body),
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

  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandSurfaceTint,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Text(
          text,
          style: AppTextStyles.caption.copyWith(color: AppColors.brandForeground),
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
        ExcludeSemantics(child: Icon(icon, size: 16, color: AppColors.brandMutedText)),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(text, style: AppTextStyles.hint)),
      ],
    );
  }
}
