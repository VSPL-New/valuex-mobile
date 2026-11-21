import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/features/cart/domain/cart.dart';
import 'package:valuex_mobile/features/cart/domain/delivery.dart';

import 'cart_fixtures.dart';

void main() {
  group('CartDelivery', () {
    test('a line the server sends without a choice has none', () {
      expect(CartLine.fromJson(lineJson('i1')).delivery.chosen, isFalse);
      expect(CartDelivery.fromJson(null).chosen, isFalse);
      expect(CartDelivery.fromJson(deliveryJson()).chosen, isFalse);
    });

    test('reads a delivery choice with its cost, date and warning', () {
      final delivery = CartLine.fromJson(
        lineJson(
          'i1',
          delivery: deliveryJson(
            mode: 'DELIVERY',
            addressId: 'a1',
            cost: 60,
            eta: '2026-11-25',
            warning: 'SHIPPING_EXCEEDS_PRICE',
          ),
        ),
      ).delivery;

      expect(delivery.chosen, isTrue);
      expect(delivery.mode, DeliveryMode.delivery);
      expect(delivery.addressId, 'a1');
      expect(delivery.shippingCost, 60);
      expect(delivery.shippingEta, DateTime(2026, 11, 25));
      expect(delivery.paymentOption, isNull);
      expect(delivery.warning, CartDelivery.shippingExceedsPrice);
    });

    test('reads a self-pickup choice with its payment option and no cost', () {
      final delivery = CartDelivery.fromJson(
        deliveryJson(mode: 'SELF_PICKUP', payment: 'PAY_AT_PICKUP'),
      );

      expect(delivery.mode, DeliveryMode.selfPickup);
      expect(delivery.paymentOption, PaymentOption.payAtPickup);
      expect(delivery.shippingCost, isNull);
      expect(delivery.addressId, isNull);
    });

    test('reads a cost sent as text', () {
      expect(CartDelivery.fromJson(deliveryJson(mode: 'DELIVERY', cost: '60.00')).shippingCost, 60);
    });

    test('knows the API words of both enums and ignores an unknown one', () {
      expect(DeliveryMode.delivery.api, 'DELIVERY');
      expect(DeliveryMode.selfPickup.api, 'SELF_PICKUP');
      expect(PaymentOption.payNow.api, 'PAY_NOW');
      expect(PaymentOption.payAtPickup.api, 'PAY_AT_PICKUP');
      expect(DeliveryMode.fromApi('TELEPORT'), isNull);
      expect(PaymentOption.fromApi(null), isNull);
    });
  });

  group('DeliveryOptions', () {
    test('reads both ways with the cost, date, courier and pickup place', () {
      final options = DeliveryOptions.fromJson(
        optionsJson(cost: '60.00', eta: '2026-11-25', warning: 'SHIPPING_EXCEEDS_PRICE'),
      );

      expect(options.itemId, 'i1');
      expect(options.delivery.available, isTrue);
      expect(options.delivery.cost, 60);
      expect(options.delivery.etaDate, DateTime(2026, 11, 25));
      expect(options.delivery.courierName, 'Standard delivery');
      expect(options.delivery.exceedsPrice, isTrue);
      expect(options.selfPickup.available, isTrue);
      expect(options.selfPickup.sellerName, 'Asha K');
      expect(options.selfPickup.place!.text, '4 FC Road, Pune, Maharashtra 411004');
    });

    test('says why a way is not possible', () {
      final options = DeliveryOptions.fromJson(optionsJson(delivery: false, pickup: false));

      expect(options.delivery.available, isFalse);
      expect(options.delivery.reason, 'ERROR_NO_DELIVERY_AVAILABLE');
      expect(options.delivery.exceedsPrice, isFalse);
      expect(options.selfPickup.available, isFalse);
      expect(options.selfPickup.reason, 'ERROR_NO_SELF_PICKUP');
      expect(options.selfPickup.place, isNull);
    });

    test('the pickup place leaves out what is not known', () {
      expect(const PickupPlace(city: 'Pune').text, 'Pune');
      expect(const PickupPlace(line1: 'Kharadi', city: 'Pune').text, 'Kharadi, Pune');
      expect(const PickupPlace(city: 'Pune', state: 'Maharashtra').text, 'Pune, Maharashtra');
      expect(const PickupPlace(line1: ' ', city: 'Pune', pincode: '411014').text, 'Pune, 411014');
      expect(const PickupPlace().text, isEmpty);
    });
  });
}
