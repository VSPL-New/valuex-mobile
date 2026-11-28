import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/order/data/mock_seller_order_repository.dart';
import 'package:valuex_mobile/features/order/data/seller_order_repository_impl.dart';
import 'package:valuex_mobile/features/order/domain/entities/incoming_order.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_secure_storage.dart';

const _card = {
  'orderId': 'order-1',
  'orderNumber': 'VX-261128-000123',
  'bucket': 'NEW',
  'orderState': 'SHIPPING_MODE_SELECTED',
  'shipmentState': 'SHIPPING_NOT_REQUIRED',
  'deliveryMode': 'SELF_PICKUP',
  'tags': ['SELF_PICKUP', 'SOMETHING_NEW'],
  'placedAt': '2026-11-28T08:05:00Z',
  'amount': '42000.00',
  'item': {'listingId': 'listing-1', 'title': 'Vintage Leica M6', 'imageUrl': 'https://cdn/t.webp'},
  'buyer': {'displayName': 'Ananya Sharma'},
  'actions': ['VIEW_PICKUP_DETAILS', 'MARK_HANDED_OVER', 'REJECT', 'TELEPORT'],
  'pickupAddress': {
    'line1': '4 Park Street',
    'line2': 'Near the metro',
    'city': 'Kolkata',
    'state': 'West Bengal',
    'pincode': '700016',
    'label': 'Shop',
  },
};

void main() {
  group('backend repository', () {
    late FakeHttpAdapter adapter;
    late SellerOrderRepositoryImpl repository;

    setUp(() {
      adapter = FakeHttpAdapter((request) async => switch (request.path) {
            '/seller/orders' => FakeHttpAdapter.json(200, {
                'success': true,
                'data': [_card],
                'metadata': {'page': 1, 'size': 20, 'totalElements': 41, 'totalPages': 3},
              }),
            '/seller/orders/summary' => FakeHttpAdapter.ok(
                {'total': 4, 'new': 1, 'packing': 1, 'scheduled': 1, 'shipped': 1}),
            '/seller/orders/order-1/start-packing' => FakeHttpAdapter.error(409,
                'ERROR_ORDER_ACTION_NOT_ALLOWED', 'This order has already moved to the next step'),
            _ => FakeHttpAdapter.ok(_card),
          });
      final client = ApiClient(
        FakeSecureStorage(accessToken: 'access', refreshToken: 'refresh'),
        AppConfig.parse(env: 'dev', apiBaseUrl: 'http://localhost/api/v1', aadhaarFlow: 'sandbox'),
        adapter: adapter,
      );
      addTearDown(client.dispose);
      repository = SellerOrderRepositoryImpl(client);
    });

    test('reads a page of cards, asking for the page and size', () async {
      final page = await repository.orders(page: 1);

      final request = adapter.requests.single;
      expect(request.path, '/seller/orders');
      expect(request.queryParameters, {'page': 1, 'size': 20});
      expect(page.page, 1);
      expect(page.hasMore, isTrue);
      final order = page.items.single;
      expect(order.id, 'order-1');
      expect(order.orderNumber, 'VX-261128-000123');
      expect(order.bucket, FulfilmentBucket.newOrder);
      expect(order.amount, 42000);
      expect(order.title, 'Vintage Leica M6');
      expect(order.imageUrl, 'https://cdn/t.webp');
      expect(order.buyerName, 'Ananya Sharma');
      expect(order.placedAt, DateTime.utc(2026, 11, 28, 8, 5).toLocal());
      expect(order.pickupAddress!.lines,
          ['4 Park Street', 'Near the metro', 'Kolkata, West Bengal 700016']);
    });

    test('leaves out actions and tags it does not know', () async {
      final order = (await repository.orders()).items.single;

      expect(order.tags, [OrderTag.selfPickup]);
      expect(order.actions, [
        SellerOrderAction.viewPickupDetails,
        SellerOrderAction.markHandedOver,
        SellerOrderAction.reject,
      ]);
    });

    test('reads the counts', () async {
      final summary = await repository.summary();

      expect(summary.total, 4);
      expect(summary.newOrders, 1);
      expect(summary.count(FulfilmentBucket.scheduled), 1);
      expect(summary.count(FulfilmentBucket.shipped), 1);
    });

    test('posts the hand-over and reads the returned card', () async {
      final order = await repository.markHandedOver('order-1');

      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.path, '/seller/orders/order-1/mark-handed-over');
      expect(order.id, 'order-1');
    });

    test('passes a refusal on with its code', () async {
      await expectLater(
        repository.startPacking('order-1'),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'ERROR_ORDER_ACTION_NOT_ALLOWED')),
      );
      expect(adapter.requests.single.method, 'POST');
    });
  });

  group('parsing', () {
    test('a card with only an id still reads, with safe defaults', () {
      final order = parseIncomingOrder({'orderId': 'x', 'bucket': 'SHIPPED', 'amount': 'abc'});

      expect(order.bucket, FulfilmentBucket.shipped);
      expect(order.amount, 0);
      expect(order.tags, isEmpty);
      expect(order.actions, isEmpty);
      expect(order.buyerName, isNull);
      expect(order.pickupAddress, isNull);
    });

    test('every group reads from its name', () {
      for (final (name, bucket) in [
        ('NEW', FulfilmentBucket.newOrder),
        ('PACKING', FulfilmentBucket.packing),
        ('SCHEDULED', FulfilmentBucket.scheduled),
        ('SHIPPED', FulfilmentBucket.shipped),
      ]) {
        expect(parseIncomingOrder({'orderId': 'x', 'bucket': name}).bucket, bucket);
      }
    });

    test('an address without its first line is left out', () {
      final order = parseIncomingOrder({
        'orderId': 'x',
        'pickupAddress': {'city': 'Pune'},
      });

      expect(order.pickupAddress, isNull);
    });

    test('missing counts read as zero', () {
      final summary = parseOrdersSummary({'new': 2});

      expect(summary.newOrders, 2);
      expect(summary.total, 0);
      expect(summary.count(FulfilmentBucket.packing), 0);
    });
  });

  group('sample repository', () {
    test('serves the four Make orders, one per group, newest group first', () async {
      final repository = MockSellerOrderRepository(now: () => DateTime(2026, 11, 28, 10));

      final page = await repository.orders();
      final summary = await repository.summary();

      expect(page.items.map((o) => o.orderNumber),
          ['ORD-S-1001', 'ORD-S-1000', 'ORD-S-0999', 'ORD-S-0998']);
      expect(page.items.first.has(OrderTag.urgent), isTrue);
      expect(page.items.every((o) => o.imageUrl == null), isTrue);
      expect(page.hasMore, isFalse);
      expect(summary.total, 4);
      expect(summary.newOrders, 1);
      expect(summary.shipped, 1);
    });

    test('pages the samples', () async {
      final repository = MockSellerOrderRepository();

      final first = await repository.orders(size: 3);
      final second = await repository.orders(page: 1, size: 3);

      expect(first.items, hasLength(3));
      expect(first.hasMore, isTrue);
      expect(second.items.single.orderNumber, 'ORD-S-0998');
      expect(second.hasMore, isFalse);
    });

    test('Start Packing moves the New sample to Packing, and a repeat changes nothing', () async {
      final repository = MockSellerOrderRepository();

      final moved = await repository.startPacking('mock-1001');
      final again = await repository.startPacking('mock-1001');
      final summary = await repository.summary();

      expect(moved.bucket, FulfilmentBucket.packing);
      expect(moved.actions, [SellerOrderAction.continuePacking]);
      expect(again.bucket, FulfilmentBucket.packing);
      expect(summary.newOrders, 0);
      expect(summary.packing, 2);
      expect((await repository.markHandedOver('mock-0998')).orderNumber, 'ORD-S-0998');
    });
  });
}
