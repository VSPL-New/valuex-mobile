import '../../../core/utils/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/negotiation.dart';

/// An amount typed by the user, ready to send: whole rupees or up to two decimals, above zero.
/// Null when the text is not such an amount. The server receives it as text, never as a float.
String? parseOfferAmount(String raw) {
  final text = raw.trim();
  if (!RegExp(r'^\d{1,9}(\.\d{1,2})?$').hasMatch(text)) return null;
  final value = double.parse(text);
  if (value <= 0) return null;
  return text.contains('.') ? double.parse(text).toStringAsFixed(2) : text;
}

/// Paise in an amount, so two amounts are compared without floating point drift.
int paise(num amount) => (amount * 100).round();

/// "4h 20m", "35m" or "under a minute"; a part of a minute counts as a whole one.
String durationLabel(AppLocalizations l10n, Duration duration) {
  if (duration.inSeconds < 60) return l10n.negotiationDurationLessThanMinute;
  // Rounded up, so a deadline 4 hours 20 minutes away reads "4h 20m" and not "4h 19m".
  final minutes = (duration.inSeconds + 59) ~/ 60;
  if (minutes < 60) return l10n.negotiationDurationMinutes(minutes);
  return l10n.negotiationDurationHoursMinutes(minutes ~/ 60, minutes % 60);
}

/// The one line that says where the negotiation stands for the person looking at it.
String negotiationStatusText(AppLocalizations l10n, Negotiation negotiation) {
  final offer = negotiation.pendingOffer;
  final amount = offer == null ? '' : Formatters.money(offer.amount);
  final isBuyer = negotiation.role == NegotiationRole.buyer;
  return switch (negotiation.state) {
    NegotiationState.sellerReviewing || NegotiationState.buyerReviewing => !negotiation
            .listing.available
        ? l10n.negotiationStatusUnavailable
        : negotiation.isMyTurn
            ? (isBuyer
                ? l10n.negotiationStatusSellerCountered(amount)
                : l10n.negotiationStatusBuyerOffered(amount))
            : (isBuyer ? l10n.negotiationStatusWaitingSeller : l10n.negotiationStatusWaitingBuyer),
    NegotiationState.offerAccepted =>
      l10n.negotiationStatusAccepted(Formatters.money(negotiation.agreedPrice ?? 0)),
    NegotiationState.offerRejected => l10n.negotiationStatusDeclined,
    NegotiationState.expired => l10n.negotiationStatusExpired,
    NegotiationState.cancelled => l10n.negotiationStatusCancelled,
    NegotiationState.converted => l10n.negotiationStatusConverted,
    NegotiationState.other => '',
  };
}
