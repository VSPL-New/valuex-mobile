import '../../../core/network/api_error.dart';
import '../../../core/network/api_error_messages.dart';
import '../../../l10n/app_localizations.dart';

/// User-facing text for a payment error code (US-117 error scenarios).
String? paymentCodeMessage(AppLocalizations l10n, String? code) {
  return switch (code) {
    'ERROR_GATEWAY_UNAVAILABLE' => l10n.paymentErrorGatewayUnavailable,
    'ERROR_PAYMENT_FAILED' => l10n.paymentErrorFailed,
    'ERROR_PAYMENT_TIMEOUT' => l10n.paymentErrorTimeout,
    _ => null,
  };
}

String paymentErrorMessage(AppLocalizations l10n, Object error) {
  if (error is ApiError) {
    return paymentCodeMessage(l10n, error.code) ?? apiErrorMessage(l10n, error);
  }
  return apiErrorMessage(l10n, error);
}
