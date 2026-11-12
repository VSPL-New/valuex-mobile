import '../../l10n/app_localizations.dart';
import 'api_error.dart';

/// User-facing text for an [ApiError]; business error codes are mapped per feature.
String apiErrorMessage(AppLocalizations l10n, Object error) {
  if (error is! ApiError) return l10n.errorSomethingWentWrong;
  return switch (error.type) {
    ApiErrorType.network || ApiErrorType.timeout => l10n.errorUnableToConnect,
    ApiErrorType.sessionExpired => l10n.errorSessionExpired,
    _ => l10n.errorSomethingWentWrong,
  };
}

/// User-facing text for a search error code (US-011, LLD B.9); null for any other code.
String? searchCodeMessage(AppLocalizations l10n, String? code) {
  return switch (code) {
    'ERROR_QUERY_TOO_LONG' => l10n.searchErrorTooLong,
    'ERROR_INVALID_PRICE_RANGE' => l10n.searchErrorPriceRange,
    'ERROR_INVALID_FILTERS' => l10n.searchErrorInvalidFilters,
    'ERROR_INTENT_REQUIRED' => l10n.searchErrorIntentRequired,
    'ERROR_INTENT_NOT_SUPPORTED' => l10n.searchErrorIntentNotSupported,
    'ERROR_SEARCH_UNAVAILABLE' => l10n.searchErrorUnavailable,
    'CATEGORY_NOT_FOUND' => l10n.searchErrorCategoryUnavailable,
    _ => null,
  };
}

/// Text for a failed search: its own codes, the rate limit (HTTP 429), then the general errors.
String searchErrorMessage(AppLocalizations l10n, Object error) {
  if (error is ApiError) {
    if (error.statusCode == 429) return l10n.searchErrorRateLimit;
    return searchCodeMessage(l10n, error.code) ?? apiErrorMessage(l10n, error);
  }
  return apiErrorMessage(l10n, error);
}
