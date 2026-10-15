import '../../../l10n/app_localizations.dart';

/// Text for a refusal from the address check, chosen by backend error code.
String addressCheckMessage(AppLocalizations l10n, String? code) {
  return switch (code) {
    'ERROR_ADDRESS_NOT_VERIFIED' => l10n.addressCheckNotVerified,
    'ERROR_PINCODE_MISMATCH' => l10n.addressCheckMismatch,
    'ERROR_INVALID_ADDRESS_STATE' => l10n.authErrorInvalidAddressState,
    _ => l10n.addressCheckInvalid,
  };
}
