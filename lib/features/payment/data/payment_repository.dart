import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/payment_status.dart';

/// Payment status and checkout results (US-117). A report never changes a payment: the server asks
/// the gateway and settles only if it is paid.
class PaymentRepository {
  final ApiClient _client;

  PaymentRepository(this._client);

  Future<PaymentStatus> getStatus(String paymentId) => _client.get(
        ApiConstants.payment(paymentId),
        parse: (json) => PaymentStatus.fromJson(json as Map<String, dynamic>),
      );

  /// [result] is `COMPLETED`, `CANCELLED` or `FAILED`, as the checkout reported it.
  Future<PaymentStatus> reportCheckoutResult(
    String paymentId, {
    required String result,
    String? gatewayPaymentId,
  }) {
    return _client.post(
      ApiConstants.paymentCheckoutResult(paymentId),
      data: {
        'result': result,
        if (gatewayPaymentId != null) 'gatewayPaymentId': gatewayPaymentId,
      },
      parse: (json) => PaymentStatus.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Dev only: asks the dummy gateway to finish the payment as paid or failed.
  Future<PaymentStatus> simulate(String paymentId, {required bool success}) {
    return _client.post(
      ApiConstants.paymentSimulate(paymentId),
      data: {'outcome': success ? 'SUCCESS' : 'FAILURE'},
      parse: (json) => PaymentStatus.fromJson(json as Map<String, dynamic>),
    );
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(ref.watch(apiClientProvider)),
);
