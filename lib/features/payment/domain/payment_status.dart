/// The server's view of a payment, for the app to poll. Only the server moves a payment forward.
class PaymentStatus {
  static const String _initiated = 'PAYMENT_INITIATED';
  static const String _pending = 'PAYMENT_PENDING';
  static const String _failed = 'PAYMENT_FAILED';

  final String paymentId;
  final String status;
  final double amount;
  final String currency;
  final String? failureReason;

  const PaymentStatus({
    required this.paymentId,
    required this.status,
    required this.amount,
    required this.currency,
    this.failureReason,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) => PaymentStatus(
        paymentId: json['paymentId'] as String,
        status: json['status'] as String,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'INR',
        failureReason: json['failureReason'] as String?,
      );

  /// Waiting for the gateway; keep checking.
  bool get isOpen => status == _initiated || status == _pending;

  bool get isFailed => status == _failed;

  /// Paid. Any state past success (escrow, refund) still means the money arrived.
  bool get isPaid => !isOpen && !isFailed;
}

/// How a payment ended for the feature that asked for it.
enum PaymentResult {
  /// The server confirmed the payment.
  confirmed,

  /// The payment failed; the payer was not charged.
  failed,

  /// The payer backed out of the checkout.
  cancelled,

  /// The server has not settled it yet; the feature says "We're confirming your payment" and checks again later.
  pending,
}
