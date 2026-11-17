import '../../../core/network/api_error.dart';
import '../../../core/network/api_error_messages.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/chat.dart';

/// Text for a message the server refused or that could not be sent (US-013 error scenarios).
/// [afterOverride] is true when the user had chosen Deliver message, where a rate limit means the
/// day's overrides are used up.
String chatSendErrorMessage(AppLocalizations l10n, Object error, {bool afterOverride = false}) {
  if (error is! ApiError) return l10n.chatErrorGeneric;
  return switch (error.code) {
    'ERROR_MESSAGE_TOO_LONG' => l10n.chatErrorTooLong(chatMessageMaxChars),
    'ERROR_EMPTY_MESSAGE' => l10n.chatErrorEmpty,
    'RATE_LIMIT_EXCEEDED' =>
      afterOverride ? l10n.chatErrorOverrideLimit : l10n.chatErrorRateLimited,
    'ERROR_BLOCKED' => l10n.chatErrorBlocked,
    'ERROR_SELLER_UNAVAILABLE' => l10n.chatErrorSellerUnavailable,
    'ERROR_THREAD_READ_ONLY' => l10n.chatErrorThreadClosed,
    'ERROR_IMAGE_TOO_LARGE' => l10n.chatErrorImageTooLarge(_megabytes(error.message)),
    'ERROR_IMAGE_INVALID' => l10n.chatErrorImageInvalid,
    'ERROR_POLICY_AGREEMENT_OUTDATED' => l10n.chatErrorAgreementOutdated,
    _ => error.isRetryable ? apiErrorMessage(l10n, error) : l10n.chatErrorGeneric,
  };
}

/// The limit in "Image exceeds 5 MB"; the usual 5 when the server's words differ.
int _megabytes(String message) {
  final match = RegExp(r'(\d+)\s*MB').firstMatch(message);
  return int.tryParse(match?.group(1) ?? '') ?? 5;
}

/// The words for why a conversation can no longer be written in.
String readOnlyMessage(AppLocalizations l10n, ReadOnlyReason reason) => switch (reason) {
      ReadOnlyReason.blocked => l10n.chatReadOnlyBlocked,
      ReadOnlyReason.accountUnavailable => l10n.chatReadOnlyUnavailable,
      ReadOnlyReason.listingRemoved => l10n.chatReadOnlyListingRemoved,
    };
