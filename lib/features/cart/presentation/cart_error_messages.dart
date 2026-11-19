import '../../../core/network/api_error.dart';
import '../../../l10n/app_localizations.dart';
import '../../buy_now/presentation/buy_now_error_messages.dart';

/// Text for a refused or failed cart action (US-019 error scenarios). A code the cart does not know
/// falls back to the Buy Now texts (reserved, sold, verification, rate limit), then to the
/// negotiation, contact, network and server texts.
String cartErrorMessage(AppLocalizations l10n, Object error) {
  if (error is ApiError) {
    return switch (error.code) {
      'ERROR_MAX_CART_ITEMS' => error.details['limit'] == null
          ? l10n.cartErrorMaxGeneric
          : l10n.cartErrorMax(error.details['limit']!),
      'ERROR_PRICE_NOT_ACCEPTED' => l10n.cartErrorNotAccepted,
      'ERROR_UNAUTHORIZED_CHECKOUT' => l10n.cartErrorOwnListing,
      'ERROR_CHECKOUT_NOT_APPLICABLE' => l10n.cartErrorNotApplicable,
      'ERROR_CART_ITEM_NOT_FOUND' => l10n.cartErrorNotInCart,
      'ERROR_CHECKOUT_UNAVAILABLE' => l10n.cartErrorUnavailableYet,
      _ => buyNowErrorMessage(l10n, error),
    };
  }
  return buyNowErrorMessage(l10n, error);
}

/// True when the listing page must be read again because what the buyer saw is no longer true.
bool cartErrorStalesPage(Object error) =>
    error is ApiError &&
    const {
      'ERROR_ITEM_RESERVED',
      'ERROR_PRICE_NOT_ACCEPTED',
      'ERROR_ITEM_UNAVAILABLE',
      'ERROR_LISTING_NOT_AVAILABLE',
    }.contains(error.code);

/// The line under a cart item that cannot be bought, from the server's problem code.
String? cartProblemText(AppLocalizations l10n, String? problem) => switch (problem) {
      null => null,
      'ERROR_PRICE_CHANGED' => l10n.cartProblemPriceChanged,
      'ERROR_CART_EXPIRED' => l10n.cartProblemExpired,
      'ERROR_ACCEPTANCE_EXPIRED' => l10n.cartProblemAcceptanceExpired,
      _ => l10n.cartProblemUnavailable,
    };
