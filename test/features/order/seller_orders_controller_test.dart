import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/order/data/mock_seller_order_repository.dart';
import 'package:valuex_mobile/features/order/data/seller_order_repository_impl.dart';
import 'package:valuex_mobile/features/order/domain/entities/incoming_order.dart';
import 'package:valuex_mobile/features/order/domain/repositories/seller_order_repository.dart';
import 'package:valuex_mobile/features/order/presentation/providers/seller_order_providers.dart';

import '../../helpers/mocks.dart';

class _MockRepository extends Mock implements SellerOrderRepository {}

IncomingOrder order(String id, {FulfilmentBucket bucket = FulfilmentBucket.newOrder}) =>
    IncomingOrder(
      id: id,
      orderNumber: 'VX-$id',
      bucket: bucket,
      orderState: 'SHIPPING_MODE_SELECTED',
      placedAt: DateTime(2026, 11, 28),
      amount: 1500,
      title: 'Item $id',
    );

const _offline = ApiError(type: ApiErrorType.network, message: 'offline');
const _refused =
    ApiError(type: ApiErrorType.business, message: 'moved', code: 'ERROR_ORDER_ACTION_NOT_ALLOWED');

void main() {
  late _MockRepository repository;
  late ProviderContainer container;

  SellerOrdersController controller() => container.read(sellerOrdersControllerProvider.notifier);
  SellerOrdersState state() => container.read(sellerOrdersControllerProvider);

  setUp(() {
    repository = _MockRepository();
    container = ProviderContainer(
      overrides: [sellerOrderRepositoryProvider.overrideWithValue(repository)],
    );
    // Keeps the auto-disposed controller alive between reads.
    container.listen(sellerOrdersControllerProvider, (_, __) {});
    addTearDown(container.dispose);
    when(() => repository.summary())
        .thenAnswer((_) async => const OrdersSummary(total: 3, newOrders: 2, packing: 1));
    when(() => repository.orders(page: any(named: 'page'))).thenAnswer((call) async {
      final page = call.namedArguments[#page] as int;
      return page == 0
          ? IncomingOrdersPage(items: [order('a'), order('b')], page: 0, hasMore: true)
          : IncomingOrdersPage(items: [order('c')], page: 1, hasMore: false);
    });
  });

  test('starts loading and has nothing to show', () {
    expect(state().isLoading, isTrue);
    expect(state().loaded, isFalse);
  });

  test('loads the counts and the first page together', () async {
    await controller().load();

    expect(state().loaded, isTrue);
    expect(state().summary.newOrders, 2);
    expect(state().items.map((o) => o.id), ['a', 'b']);
    expect(state().hasMore, isTrue);
    expect(state().nextPage, 1);
  });

  test('adds the next page, then stops when all are loaded', () async {
    await controller().load();

    expect(await controller().loadMore(), isNull);
    expect(state().items.map((o) => o.id), ['a', 'b', 'c']);
    expect(state().hasMore, isFalse);
    expect(await controller().loadMore(), isNull);
    verify(() => repository.orders(page: 1)).called(1);
  });

  test('a failed next page keeps the list and returns the error', () async {
    await controller().load();
    when(() => repository.orders(page: 1)).thenThrow(_offline);

    expect(await controller().loadMore(), _offline);
    expect(state().items, hasLength(2));
    expect(state().isLoadingMore, isFalse);
  });

  test('a failed first load has nothing to show and keeps the error', () async {
    when(() => repository.summary()).thenThrow(_offline);

    await controller().load();

    expect(state().error, _offline);
    expect(state().items, isEmpty);
    expect(state().loaded, isFalse);
  });

  test('a failed refresh keeps the last loaded list with the error', () async {
    await controller().load();
    when(() => repository.orders(page: 0)).thenThrow(_offline);

    await controller().load();

    expect(state().error, _offline);
    expect(state().items.map((o) => o.id), ['a', 'b']);
  });

  test('Start Packing calls the server and reloads', () async {
    await controller().load();
    when(() => repository.startPacking('a'))
        .thenAnswer((_) async => order('a', bucket: FulfilmentBucket.packing));

    expect(await controller().startPacking('a'), isNull);

    verify(() => repository.startPacking('a')).called(1);
    verify(() => repository.summary()).called(2);
    expect(state().busyOrderId, isNull);
  });

  test('a refused action returns the error and still reloads', () async {
    await controller().load();
    when(() => repository.markHandedOver('a')).thenThrow(_refused);

    expect(await controller().markHandedOver('a'), _refused);

    verify(() => repository.summary()).called(2);
  });

  test('a second tap while an action runs is ignored', () async {
    await controller().load();
    when(() => repository.startPacking('a')).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return order('a');
    });

    final first = controller().startPacking('a');
    expect(state().busyOrderId, 'a');
    expect(await controller().startPacking('a'), isNull);
    await first;

    verify(() => repository.startPacking('a')).called(1);
  });

  group('repository choice', () {
    AppConfig config({String sellerOrders = 'backend'}) => AppConfig.parse(
          env: 'dev',
          apiBaseUrl: 'http://localhost/api/v1',
          aadhaarFlow: 'sandbox',
          sellerOrders: sellerOrders,
        );

    test('uses the backend by default and the samples when asked', () {
      final backend = ProviderContainer(overrides: [
        appConfigProvider.overrideWithValue(config()),
        apiClientProvider.overrideWithValue(MockApiClient()),
      ]);
      final samples = ProviderContainer(overrides: [
        appConfigProvider.overrideWithValue(config(sellerOrders: 'mock')),
      ]);
      addTearDown(backend.dispose);
      addTearDown(samples.dispose);

      expect(backend.read(sellerOrderRepositoryProvider), isA<SellerOrderRepositoryImpl>());
      expect(samples.read(sellerOrderRepositoryProvider), isA<MockSellerOrderRepository>());
    });
  });
}
