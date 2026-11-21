import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/delivery.dart';

/// "9 Nov" or its Hindi form, for the day a delivery is expected.
String deliveryDate(BuildContext context, DateTime date) =>
    DateFormat.MMMd(Localizations.localeOf(context).toString()).format(date);

/// What the buyer chose for a cart line in one short line ("Delivery, ₹60, by 25 Nov"), or null when
/// nothing is chosen yet.
String? deliverySummary(BuildContext context, AppLocalizations l10n, CartDelivery delivery) {
  return switch (delivery.mode) {
    null => null,
    DeliveryMode.delivery => l10n.cartDeliverySummaryDelivery(
        Formatters.money(delivery.shippingCost ?? 0),
        delivery.shippingEta == null ? '' : deliveryDate(context, delivery.shippingEta!),
      ),
    DeliveryMode.selfPickup => delivery.paymentOption == PaymentOption.payAtPickup
        ? l10n.cartDeliverySummaryPickupLater
        : l10n.cartDeliverySummaryPickupNow,
  };
}
