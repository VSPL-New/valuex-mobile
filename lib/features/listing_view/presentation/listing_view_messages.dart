import '../../../core/network/api_error.dart';
import '../../../core/network/api_error_messages.dart';
import '../../../l10n/app_localizations.dart';

/// Text for a failed listing or seller request (US-012 error scenarios).
String listingViewErrorMessage(AppLocalizations l10n, Object error) {
  if (error is ApiError) {
    return switch (error.code) {
      'ERROR_LISTING_NOT_AVAILABLE' => l10n.listingViewNotAvailable,
      'ERROR_SELLER_SUSPENDED' => l10n.listingViewSellerSuspended,
      'SELLER_NOT_FOUND' => l10n.listingViewSellerNotFound,
      _ => apiErrorMessage(l10n, error),
    };
  }
  return apiErrorMessage(l10n, error);
}

/// A listing or seller that cannot be reopened by retrying, so the screen offers no Retry.
bool listingViewErrorFinal(Object error) =>
    error is ApiError &&
    const {'ERROR_LISTING_NOT_AVAILABLE', 'ERROR_SELLER_SUSPENDED', 'SELLER_NOT_FOUND'}
        .contains(error.code);
