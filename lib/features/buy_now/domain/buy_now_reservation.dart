/// A listing held for the buyer at its asking price (US-068). [serverTime] is the server's clock when
/// it answered, so the countdown does not depend on the phone's clock.
class BuyNowReservation {
  final String agreementId;

  /// `BUY_NOW` for a reservation made here, or `OFFER` when the buyer already held an accepted price.
  final String source;
  final num agreedPrice;
  final DateTime validUntil;
  final DateTime serverTime;

  const BuyNowReservation({
    required this.agreementId,
    required this.source,
    required this.agreedPrice,
    required this.validUntil,
    required this.serverTime,
  });

  factory BuyNowReservation.fromJson(Map<String, dynamic> json) => BuyNowReservation(
        agreementId: json['agreementId'] as String,
        source: json['source'] as String? ?? 'BUY_NOW',
        agreedPrice: num.parse(json['agreedPrice'].toString()),
        validUntil: DateTime.parse(json['validUntil'] as String),
        serverTime: DateTime.parse(json['serverTime'] as String),
      );
}
