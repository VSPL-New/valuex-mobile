import '../../../core/network/api_error.dart';
import '../../../core/network/api_error_messages.dart';
import '../../../l10n/app_localizations.dart';

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
    'ERROR_INVALID_ADDRESS_STATE' => l10n.authErrorInvalidAddressState,
    'ERROR_INVALID_DATE_OF_BIRTH' => l10n.authErrorInvalidDob,
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
