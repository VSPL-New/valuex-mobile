import '../../../l10n/app_localizations.dart';
import '../../listing/domain/listing_details.dart' as details;
import '../../search/domain/search_criteria.dart';
import '../../search/presentation/search_labels.dart';

/// The criteria of a saved search in a line a buyer can read: text, category, Buy/Rent/Lease,
/// price, conditions, place and how many other filters are on.
String savedSearchSummary(AppLocalizations l10n, SearchCriteria criteria) {
  final parts = <String>[
    if (criteria.trimmedQuery.isNotEmpty) criteria.trimmedQuery,
    if (criteria.categoryName != null) criteria.categoryName!,
    if (criteria.intent != null) intentLabel(l10n, criteria.intent!),
    ..._price(l10n, criteria),
    for (final code in criteria.conditions.toList()..sort())
      if (details.ListingCondition.fromApi(code) case final condition?)
        searchConditionLabel(l10n, condition),
    if (criteria.city != null) criteria.city!,
    if (criteria.state != null) criteria.state!,
    if (criteria.facets.isNotEmpty) l10n.savedSearchSummaryFilters(criteria.facets.length),
  ];
  return parts.join(' · ');
}

List<String> _price(AppLocalizations l10n, SearchCriteria criteria) {
  final min = criteria.priceMin;
  final max = criteria.priceMax;
  if (min != null && max != null) {
    return [
      l10n.savedSearchSummaryPrice(
        SearchCriteria.formatPrice(min),
        SearchCriteria.formatPrice(max),
      ),
    ];
  }
  if (min != null) return [l10n.savedSearchSummaryPriceFrom(SearchCriteria.formatPrice(min))];
  if (max != null) return [l10n.savedSearchSummaryPriceUpTo(SearchCriteria.formatPrice(max))];
  return const [];
}
