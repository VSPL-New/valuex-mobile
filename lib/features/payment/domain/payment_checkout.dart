import 'package:flutter/widgets.dart';

/// What the checkout needs to open: the order the server created for one payment.
class CheckoutRequest {
  final String paymentId;
  final String orderId;
  final double amount;
  final String currency;

  /// The gateway's public key; never a secret.
  final String publicKey;

  const CheckoutRequest({
    required this.paymentId,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.publicKey,
  });

  factory CheckoutRequest.fromJson(Map<String, dynamic> json) => CheckoutRequest(
        paymentId: json['paymentId'] as String,
        orderId: json['orderId'] as String,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'INR',
        publicKey: json['publicKey'] as String? ?? '',
      );
}

/// What the checkout reported. This is a report only: the server decides whether the payment succeeded.
sealed class CheckoutOutcome {
  const CheckoutOutcome();
}

class CheckoutCompleted extends CheckoutOutcome {
  final String? gatewayPaymentId;

  const CheckoutCompleted({this.gatewayPaymentId});
}

class CheckoutCancelled extends CheckoutOutcome {
  const CheckoutCancelled();
}

class CheckoutFailed extends CheckoutOutcome {
  final String reason;

  const CheckoutFailed(this.reason);
}

/// Opens a gateway's checkout. The dummy gateway shows a test sheet; the real gateway's SDK is added here
/// when it is chosen, with no change to the features that pay.
abstract interface class PaymentCheckout {
  Future<CheckoutOutcome> open(BuildContext context, CheckoutRequest request);
}
