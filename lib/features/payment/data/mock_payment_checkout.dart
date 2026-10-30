import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_error.dart';
import '../domain/payment_checkout.dart';
import '../presentation/mock_checkout_sheet.dart';
import 'payment_repository.dart';

/// The dummy gateway's checkout. The tester picks Pay or Fail in a test sheet; the choice goes to the dev
/// simulate endpoint, which sends the same signed callback a real gateway would. Nothing is charged.
class MockPaymentCheckout implements PaymentCheckout {
  static const String declinedReason = 'MOCK_PAYMENT_DECLINED';

  final PaymentRepository _repository;

  MockPaymentCheckout(this._repository);

  @override
  Future<CheckoutOutcome> open(BuildContext context, CheckoutRequest request) async {
    final choice = await showModalBottomSheet<MockCheckoutChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MockCheckoutSheet(amount: request.amount, currency: request.currency),
    );
    switch (choice) {
      case MockCheckoutChoice.pay:
        await _repository.simulate(request.paymentId, success: true);
        return const CheckoutCompleted();
      case MockCheckoutChoice.fail:
        await _repository.simulate(request.paymentId, success: false);
        return const CheckoutFailed(declinedReason);
      case MockCheckoutChoice.cancel:
      case null:
        return const CheckoutCancelled();
    }
  }
}

/// Used when the app has no gateway (staging and production until the real gateway is chosen): paying
/// fails cleanly with the same error the server gives.
class UnavailablePaymentCheckout implements PaymentCheckout {
  const UnavailablePaymentCheckout();

  @override
  Future<CheckoutOutcome> open(BuildContext context, CheckoutRequest request) {
    throw const ApiError(
      type: ApiErrorType.server,
      message: 'Payment service is not available',
      code: 'ERROR_GATEWAY_UNAVAILABLE',
    );
  }
}

/// The dummy checkout only when the app config says so; the real gateway's checkout is added here later.
final paymentCheckoutProvider = Provider<PaymentCheckout>((ref) {
  if (ref.watch(appConfigProvider).useMockPayment) {
    return MockPaymentCheckout(ref.watch(paymentRepositoryProvider));
  }
  return const UnavailablePaymentCheckout();
});
