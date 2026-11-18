import '../../../core/network/api_error.dart';
import '../../../l10n/app_localizations.dart';
import '../../negotiation/presentation/negotiation_error_messages.dart';

/// Text for a refused or failed Buy Now (US-068 error scenarios). A code Buy Now does not know falls
/// back to the negotiation texts (reserved, verification, ...), then to the contact, network and
/// server texts.
String buyNowErrorMessage(AppLocalizations l10n, Object error) {
  if (error is ApiError) {
    return switch (error.code) {
      'ERROR_ITEM_SOLD' => l10n.buyNowErrorSold,
      'ERROR_PRICE_CHANGED' => l10n.buyNowErrorPriceChanged,
      'ERROR_BUY_NOW_DISABLED' => l10n.buyNowErrorDisabled,
      'ERROR_BUY_NOW_NOT_APPLICABLE' => l10n.buyNowErrorNotApplicable,
      'ERROR_CHECKOUT_UNAVAILABLE' => l10n.buyNowErrorCheckoutUnavailable,
      'RATE_LIMIT_EXCEEDED' => l10n.buyNowErrorRateLimited,
      _ => negotiationErrorMessage(l10n, error),
    };
  }
  return negotiationErrorMessage(l10n, error);
}

/// True when the listing page must be read again because what the buyer saw is no longer true.
bool buyNowErrorStalesPage(Object error) =>
    error is ApiError &&
    const {
      'ERROR_ITEM_SOLD',
      'ERROR_PRICE_CHANGED',
      'ERROR_BUY_NOW_DISABLED',
      'ERROR_ITEM_RESERVED',
      'ERROR_LISTING_NOT_AVAILABLE',
    }.contains(error.code);
