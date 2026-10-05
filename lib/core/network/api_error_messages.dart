import '../../l10n/app_localizations.dart';
import 'api_error.dart';

/// User-facing text for an [ApiError]; business error codes are mapped per feature.
String apiErrorMessage(AppLocalizations l10n, ApiError error) {
  return switch (error.type) {
    ApiErrorType.network || ApiErrorType.timeout => l10n.errorUnableToConnect,
    ApiErrorType.sessionExpired => l10n.errorSessionExpired,
    _ => l10n.errorSomethingWentWrong,
  };
}
