import '../../../l10n/app_localizations.dart';
import '../../home/domain/entities/listing.dart';
import '../../listing/domain/listing_details.dart' as details;
import '../domain/search_listing.dart';
import '../domain/search_sort.dart';
import '../domain/transaction_intent.dart';

/// The search result as a Home card, so both lists share one card.
extension SearchListingCard on SearchListing {
  Listing toCardListing() => Listing(
        id: id,
        title: title,
        priceInr: price,
        city: city,
        sellerRating: sellerRating,
        condition: switch (condition) {
          'NEW' => ListingCondition.newItem,
          'LIKE_NEW' => ListingCondition.likeNew,
          'GOOD' => ListingCondition.good,
          'FAIR' => ListingCondition.fair,
          'POOR' => ListingCondition.poor,
          _ => null,
        },
        isBoosted: badge == SearchBadge.boosted,
        isFeatured: badge == SearchBadge.featured,
        startingFrom: startingFrom,
        image: cardUrl ?? thumbnailUrl ?? '',
      );
}

String intentLabel(AppLocalizations l10n, TransactionIntent intent) => switch (intent) {
      TransactionIntent.sale => l10n.searchIntentBuy,
      TransactionIntent.rent => l10n.searchIntentRent,
      TransactionIntent.lease => l10n.searchIntentLease,
    };

String sortLabel(AppLocalizations l10n, SearchSort sort) => switch (sort) {
      SearchSort.relevance => l10n.filterSortRelevance,
      SearchSort.newest => l10n.filterSortNewest,
      SearchSort.priceAsc => l10n.filterSortPriceAsc,
      SearchSort.priceDesc => l10n.filterSortPriceDesc,
    };

String searchConditionLabel(AppLocalizations l10n, details.ListingCondition condition) =>
    switch (condition) {
      details.ListingCondition.brandNew => l10n.conditionNew,
      details.ListingCondition.likeNew => l10n.conditionLikeNew,
      details.ListingCondition.good => l10n.conditionGood,
      details.ListingCondition.fair => l10n.conditionFair,
      details.ListingCondition.poor => l10n.conditionPoor,
    };
