import '../../../l10n/app_localizations.dart';
import '../domain/entities/listing.dart';

String conditionLabel(AppLocalizations l10n, ListingCondition condition) {
  return switch (condition) {
    ListingCondition.newItem => l10n.conditionNew,
    ListingCondition.likeNew => l10n.conditionLikeNew,
    ListingCondition.excellent => l10n.conditionExcellent,
    ListingCondition.good => l10n.conditionGood,
    ListingCondition.fair => l10n.conditionFair,
    ListingCondition.poor => l10n.conditionPoor,
  };
}
