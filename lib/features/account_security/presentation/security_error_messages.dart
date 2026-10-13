import '../../../core/network/api_error.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_error_messages.dart';

/// User-facing text for an error from the Account Security endpoints.
String securityErrorMessage(AppLocalizations l10n, Object error) {
  if (error is ApiError) {
    switch (error.code) {
      case 'ERROR_NO_OTHER_SESSIONS':
        return l10n.securityNoOtherSessions;
      case 'ERROR_SAME_MOBILE':
        return l10n.securitySameMobile;
      case 'ERROR_SAME_EMAIL':
        return l10n.securitySameEmail;
    }
  }
  return authErrorMessage(l10n, error);
}
