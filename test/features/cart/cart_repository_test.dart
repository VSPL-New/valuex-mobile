import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/cart/data/cart_repository.dart';
import 'package:valuex_mobile/features/cart/domain/cart.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_secure_storage.dart';
import 'cart_fixtures.dart';

final _config = AppConfig.parse(
  env: 'dev',
  apiBaseUrl: 'http://localhost:8080/api/v1',
  aadhaarFlow: 'sandbox',
);

void main() {
  late FakeHttpAdapter adapter;
  late CartRepository repository;

  void answer(ResponseBody Function(RequestOptions options) reply) {
    adapter = FakeHttpAdapter((options) async => reply(options));
    repository = CartRepository(ApiClient(FakeSecureStorage(), _config, adapter: adapter));
  }

  group('the cart as the server sends it', () {
    test('reads groups, lines, prices, times and the total of what can be bought', () {
      final data = cartOf([
        groupJson('s1', 'Asha', [
          lineJson('i1', agreedPrice: 800, currentPrice: '900.00'),
          lineJson('i2', agreedPrice: '200.50', status: 'EXPIRED', problem: 'ERROR_CART_EXPIRED'),
        ]),
        groupJson('s2', null, [lineJson('i3', agreedPrice: '100.00', status: 'PENDING')]),
      ]);

      expect(data.cartId, 'c1');
      expect(data.itemCount, 3);
      expect(data.validCount, 1);
      expect(data.isEmpty, isFalse);
      expect(data.groups.map((g) => g.sellerName), ['Asha', null]);
      final line = data.groups.first.items.first;
      expect(line.agreedPrice, 800);
      expect(line.currentPrice, 900);
      expect(line.status, CartLineStatus.accepted);
      expect(line.agreementValidUntil, isNotNull);
      expect(data.groups.first.items.last.problem, 'ERROR_CART_EXPIRED');
      expect(data.payableTotal, 800);
    });

    test('an empty cart has no id and no groups', () {
      final data = cartOf([]);

      expect(data.cartId, isNull);
      expect(data.isEmpty, isTrue);
      expect(data.payableTotal, 0);
    });

    test('maps every status and treats an unknown one as expired', () {
      expect(CartLineStatus.fromApi('ACCEPTED'), CartLineStatus.accepted);
      expect(CartLineStatus.fromApi('PENDING'), CartLineStatus.pending);
      expect(CartLineStatus.fromApi('UNAVAILABLE'), CartLineStatus.unavailable);
      expect(CartLineStatus.fromApi('EXPIRED'), CartLineStatus.expired);
      expect(CartLineStatus.fromApi('SOMETHING'), CartLineStatus.expired);
      expect(CartLineStatus.fromApi(null), CartLineStatus.expired);
      expect(CartLineStatus.accepted.payable, isTrue);
      expect(CartLineStatus.pending.payable, isFalse);
    });

    test('a line without a listing has no title, price or agreement end', () {
      final line = CartLine.fromJson({
        ...lineJson('i1', title: null, currentPrice: null),
        'agreementValidUntil': null,
      });

      expect(line.title, isNull);
      expect(line.currentPrice, isNull);
      expect(line.agreementValidUntil, isNull);
    });

    test('the summary reads both numbers', () {
      final summary = CartSummary.fromJson({'itemCount': 4, 'validCount': 3});

      expect(summary.itemCount, 4);
      expect(summary.validCount, 3);
    });
  });

  group('repository', () {
    test('reads the cart from GET /cart', () async {
      answer((_) => FakeHttpAdapter.ok({
            'cartId': 'c1',
            'serverTime': cartServerTime.toIso8601String(),
            'itemCount': 0,
            'validCount': 0,
            'groups': <Object>[],
          }));

      final data = await repository.get();

      expect(adapter.requests.single.path, '/cart');
      expect(adapter.requests.single.method, 'GET');
      expect(data.isEmpty, isTrue);
    });

    test('reads the summary from GET /cart/summary', () async {
      answer((_) => FakeHttpAdapter.ok({'itemCount': 2, 'validCount': 1}));

      final summary = await repository.summary();

      expect(adapter.requests.single.path, '/cart/summary');
      expect(summary.itemCount, 2);
    });

    test('adds with only the listing id and tells a new line (201) from an existing one (200)',
        () async {
      var status = 201;
      answer((_) => FakeHttpAdapter.json(status, {'success': true, 'data': lineJson('i1')}));

      final first = await repository.add('l1');
      status = 200;
      final again = await repository.add('l1');

      expect(adapter.requests.first.path, '/cart/items');
      expect(adapter.requests.first.method, 'POST');
      expect(adapter.requests.first.data, {'listingId': 'l1'});
      expect(first.created, isTrue);
      expect(again.created, isFalse);
      expect(first.line.itemId, 'i1');
    });

    test('removes with DELETE /cart/items/{id} and treats 204 as done', () async {
      answer((_) => ResponseBody.fromString('', 204));

      await repository.remove('i1');

      expect(adapter.requests.single.path, '/cart/items/i1');
      expect(adapter.requests.single.method, 'DELETE');
    });

    test('surfaces the server code and details of a refusal', () async {
      answer((_) => FakeHttpAdapter.error(
          409, 'ERROR_MAX_CART_ITEMS', 'Cart limit reached (3 items)',
          details: {'limit': '3'}));

      await expectLater(
        repository.add('l1'),
        throwsA(isA<ApiError>()
            .having((e) => e.code, 'code', 'ERROR_MAX_CART_ITEMS')
            .having((e) => e.details['limit'], 'limit', '3')),
      );
    });
  });
}
