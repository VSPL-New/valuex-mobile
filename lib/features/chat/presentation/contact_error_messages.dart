import '../../../core/network/api_error.dart';
import '../../../core/network/api_error_messages.dart';
import '../../../l10n/app_localizations.dart';

/// Text for a refused or failed attempt to contact a seller (US-069 error scenarios). A signed-out
/// or expired session gets the story's "Please login" text.
String contactErrorMessage(AppLocalizations l10n, Object error) {
  if (error is ApiError) {
    if (error.type == ApiErrorType.unauthorized || error.type == ApiErrorType.sessionExpired) {
      return l10n.contactLoginRequired;
    }
    return switch (error.code) {
      'ERROR_BLOCKED' => l10n.contactBlocked,
      'ERROR_SELLER_UNAVAILABLE' => l10n.contactSellerUnavailable,
      'WARNING_RATE_LIMIT' => l10n.contactRateLimited,
      'ERROR_LISTING_NOT_AVAILABLE' => l10n.listingViewNotAvailable,
      'ERROR_OWN_LISTING' => l10n.contactOwnListing,
      'ERROR_ACCOUNT_NOT_ACTIVE' => l10n.contactAccountNotActive,
      _ => apiErrorMessage(l10n, error),
    };
  }
  return apiErrorMessage(l10n, error);
}
