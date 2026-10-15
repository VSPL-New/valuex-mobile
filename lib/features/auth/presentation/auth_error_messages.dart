import '../../../core/network/api_error.dart';
import '../../../core/network/api_error_messages.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/services/google_id_token_source.dart';

/// User-facing text for an error from an auth endpoint, chosen by backend error code.
String authErrorMessage(AppLocalizations l10n, Object error) {
  if (error is! ApiError) return l10n.errorSomethingWentWrong;
  if (error.type == ApiErrorType.validation) return l10n.authErrorValidation;

  return switch (error.code) {
    'ERROR_MOBILE_ALREADY_REGISTERED' => l10n.authErrorMobileRegistered,
    'ERROR_EMAIL_ALREADY_REGISTERED' => l10n.authErrorEmailRegistered,
    'ERROR_INVALID_OTP' => l10n.authErrorInvalidOtp,
    'ERROR_OTP_EXPIRED' => l10n.authErrorOtpExpired,
    'ERROR_OTP_RATE_LIMIT' => l10n.authErrorOtpRateLimit,
    'ERROR_OTP_MAX_ATTEMPTS' => l10n.authErrorOtpMaxAttempts,
    'ERROR_INVALID_STATE' || 'ERROR_MOBILE_NOT_FOUND' => l10n.authErrorInvalidState,
    'ERROR_USER_NOT_FOUND' => l10n.authErrorUserNotFound,
    'ERROR_MOBILE_NOT_REGISTERED' => l10n.authErrorMobileNotRegistered,
    'ERROR_ACCOUNT_SUSPENDED' => l10n.authErrorAccountSuspended,
    'ERROR_TERMS_NOT_ACCEPTED' => l10n.authErrorTermsNotAccepted,
    'ERROR_CONSENT_REQUIRED' => l10n.authErrorConsentRequired,
    'ERROR_INVALID_AVATAR' => l10n.authErrorInvalidAvatar,
    'ERROR_AADHAAR_ALREADY_USED' => l10n.authErrorAadhaarUsed,
    'ERROR_ACCOUNT_RECOVERY_REQUIRED' => l10n.authErrorAadhaarRecovery,
    'ERROR_AADHAAR_SERVICE_UNAVAILABLE' => l10n.authErrorAadhaarUnavailable,
    'ERROR_AADHAAR_SESSION_EXPIRED' ||
    'ERROR_INVALID_TRANSACTION' =>
      l10n.authErrorAadhaarSessionExpired,
    'ERROR_AADHAAR_VERIFICATION_FAILED' => l10n.authErrorAadhaarFailed,
    _ => apiErrorMessage(l10n, error),
  };
}

/// Sign-in errors whose fix is to create (or finish creating) an account.
bool signInNeedsAccount(Object error) {
  return error is ApiError &&
      (error.code == 'ERROR_MOBILE_NOT_REGISTERED' || error.code == 'ERROR_INVALID_STATE');
}

/// Like [authErrorMessage], but for the sign-in screens, where a few codes mean something
/// different than during registration.
String signInErrorMessage(AppLocalizations l10n, Object error) {
  if (error is ApiError) {
    switch (error.code) {
      case 'ERROR_INVALID_STATE':
        return l10n.authErrorSignInIncomplete;
      case 'ERROR_ACCOUNT_RECOVERY_REQUIRED':
        return l10n.authErrorAccountRecovery;
    }
  }
  return authErrorMessage(l10n, error);
}

/// Like [authErrorMessage], for the Google sign-in screens and the mobile step that follows.
String googleErrorMessage(AppLocalizations l10n, Object error) {
  if (error is GoogleSignInUnavailable) return l10n.googleErrorUnavailable;
  if (error is ApiError) {
    switch (error.code) {
      case 'ERROR_INVALID_GOOGLE_TOKEN':
        return l10n.googleErrorFailed;
      case 'ERROR_GOOGLE_SERVICE_UNAVAILABLE':
        return l10n.googleErrorUnavailable;
      case 'ERROR_SOCIAL_ACCOUNT_ALREADY_LINKED':
        return l10n.googleErrorAlreadyLinked;
      case 'ERROR_SOCIAL_SESSION_EXPIRED' ||
            'ERROR_SOCIAL_SESSION_INVALID' ||
            'ERROR_MOBILE_MISMATCH':
        return l10n.googleErrorSessionExpired;
      case 'ERROR_INVALID_STATE':
        return l10n.googleErrorIncompleteAccount;
      case 'ERROR_ACCOUNT_RECOVERY_REQUIRED':
        return l10n.authErrorAccountRecovery;
    }
  }
  return authErrorMessage(l10n, error);
}
