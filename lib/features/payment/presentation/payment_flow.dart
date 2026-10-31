import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_error.dart';
import '../../../core/security/screen_protection_service.dart';
import '../data/mock_payment_checkout.dart';
import '../data/payment_repository.dart';
import '../domain/payment_checkout.dart';
import '../domain/payment_status.dart';

/// Runs one payment on the device: protects the screen, opens the checkout, reports its result to the server,
/// then asks the server until it has settled the payment. The checkout's "completed" is never treated as
/// success: only the server's status is.
class PaymentFlow {
  static const Duration defaultPollInterval = Duration(seconds: 2);
  static const Duration defaultTimeout = Duration(seconds: 60);

  final PaymentCheckout _checkout;
  final PaymentRepository _repository;
  final ScreenProtectionService _screenProtection;
  final Duration pollInterval;
  final Duration timeout;

  PaymentFlow(
    this._checkout,
    this._repository,
    this._screenProtection, {
    this.pollInterval = defaultPollInterval,
    this.timeout = defaultTimeout,
  });

  /// Throws an [ApiError] when the checkout cannot open (for example `ERROR_GATEWAY_UNAVAILABLE`).
  Future<PaymentResult> start(BuildContext context, CheckoutRequest request) async {
    await _screenProtection.enable();
    try {
      if (!context.mounted) return PaymentResult.cancelled;
      final outcome = await _checkout.open(context, request);
      return switch (outcome) {
        CheckoutCancelled() => await _cancelled(request),
        CheckoutCompleted(:final gatewayPaymentId) =>
          await _settle(request, 'COMPLETED', gatewayPaymentId),
        CheckoutFailed() => await _settle(request, 'FAILED', null),
      };
    } finally {
      await _screenProtection.disable();
    }
  }

  Future<PaymentResult> _cancelled(CheckoutRequest request) async {
    await _report(request.paymentId, 'CANCELLED', null);
    return PaymentResult.cancelled;
  }

  Future<PaymentResult> _settle(
      CheckoutRequest request, String result, String? gatewayPaymentId) async {
    final reported = await _report(request.paymentId, result, gatewayPaymentId);
    var elapsed = Duration.zero;
    var status = reported;
    while (true) {
      if (status != null) {
        if (status.isPaid) return PaymentResult.confirmed;
        if (status.isFailed) return PaymentResult.failed;
      }
      if (elapsed >= timeout) return PaymentResult.pending;
      await Future<void>.delayed(pollInterval);
      elapsed += pollInterval;
      status = await _fetch(request.paymentId) ?? status;
    }
  }

  Future<PaymentStatus?> _report(String paymentId, String result, String? gatewayPaymentId) async {
    try {
      return await _repository.reportCheckoutResult(
        paymentId,
        result: result,
        gatewayPaymentId: gatewayPaymentId,
      );
    } on ApiError catch (error) {
      developer.log('Reporting the checkout result failed: $error', name: 'payment');
      return null;
    }
  }

  Future<PaymentStatus?> _fetch(String paymentId) async {
    try {
      return await _repository.getStatus(paymentId);
    } on ApiError catch (error) {
      developer.log('Reading the payment status failed: $error', name: 'payment');
      return null;
    }
  }
}

final paymentFlowProvider = Provider<PaymentFlow>(
  (ref) => PaymentFlow(
    ref.watch(paymentCheckoutProvider),
    ref.watch(paymentRepositoryProvider),
    ref.watch(screenProtectionServiceProvider),
  ),
);
