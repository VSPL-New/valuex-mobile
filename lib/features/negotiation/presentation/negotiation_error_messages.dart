import '../../../core/network/api_error.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../../chat/presentation/contact_error_messages.dart';

/// Text for a refused or failed offer, counter, answer or withdrawal (US-017 error scenarios). A code
/// the negotiation does not know falls back to the contact messages (blocked, own listing, ...), then
/// to the general network and server texts.
String negotiationErrorMessage(AppLocalizations l10n, Object error) {
  if (error is ApiError) {
    final min = _amount(error.details['min']);
    final max = _amount(error.details['max']);
    return switch (error.code) {
      'ERROR_INVALID_OFFER' => max == null
          ? l10n.negotiationErrorUnavailable
          : l10n.negotiationErrorInvalidOffer(min ?? '1', max),
      'ERROR_INVALID_COUNTER' => min == null || max == null
          ? l10n.negotiationErrorNotCurrent
          : l10n.negotiationErrorInvalidCounter(min, max),
      'ERROR_MAX_NEGOTIATIONS' => l10n.negotiationErrorMax,
      'WARNING_MAX_NEGOTIATIONS' => l10n.negotiationErrorMaxSeller,
      'ERROR_NEGOTIATION_EXPIRED' => l10n.negotiationErrorExpired,
      'ERROR_NOT_NEGOTIABLE' => l10n.negotiationErrorNotNegotiable,
      'ERROR_NEGOTIATION_EXISTS' => l10n.negotiationErrorExists,
      'ERROR_NEGOTIATION_COOLDOWN' => l10n.negotiationErrorCooldown,
      'ERROR_TOO_MANY_NEGOTIATIONS' => l10n.negotiationErrorTooMany,
      'ERROR_OFFER_NOT_CURRENT' => l10n.negotiationErrorNotCurrent,
      'ERROR_ITEM_RESERVED' => l10n.negotiationErrorReserved,
      'ERROR_ITEM_UNAVAILABLE' => l10n.negotiationErrorUnavailable,
      'ERROR_ALREADY_ACCEPTED' => l10n.negotiationErrorAlreadyAccepted,
      'AADHAAR_VERIFICATION_REQUIRED' => l10n.negotiationErrorAadhaar,
      'RATE_LIMIT_EXCEEDED' => l10n.negotiationErrorRateLimited,
      _ => contactErrorMessage(l10n, error),
    };
  }
  return contactErrorMessage(l10n, error);
}

/// An amount the server put in `details` ("800.01"), shown without needless decimals.
String? _amount(String? value) {
  final parsed = value == null ? null : num.tryParse(value);
  return parsed == null ? null : Formatters.money(parsed).replaceFirst('₹', '');
}
