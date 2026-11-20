import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/realtime/realtime_event.dart';
import 'package:valuex_mobile/core/realtime/realtime_providers.dart';
import 'package:valuex_mobile/features/cart/data/cart_repository.dart';
import 'package:valuex_mobile/features/cart/presentation/providers/cart_providers.dart';

import '../../core/realtime/realtime_fakes.dart';
import 'cart_fixtures.dart';

const _offline = ApiError(type: ApiErrorType.network, message: 'offline');

void main() {
  late MockCartRepository cart;
  late FakeRealtimeClient realtime;

  ProviderContainer container() {
    final value = ProviderContainer(overrides: [
      cartRepositoryProvider.overrideWithValue(cart),
      realtimeClientProvider.overrideWithValue(realtime),
    ]);
    addTearDown(value.dispose);
    return value;
  }

  Future<void> tick() => Future<void>.delayed(Duration.zero);

  setUp(() {
    cart = MockCartRepository();
    realtime = FakeRealtimeClient();
    when(() => cart.get()).thenAnswer((_) async => cartOf([
          groupJson('s1', 'Asha', [lineJson('i1')]),
        ]));
  });

  group('the cart', () {
    test('is read when the screen opens', () async {
      final c = container();
      c.listen(cartProvider, (previous, next) {});

      final data = await c.read(cartProvider.future);

      expect(data.itemCount, 1);
      verify(() => cart.get()).called(1);
    });

    test('a failed first read is an error, not an empty cart', () async {
      when(() => cart.get()).thenThrow(_offline);
      final c = container();
      c.listen(cartProvider, (previous, next) {});

      await expectLater(c.read(cartProvider.future), throwsA(isA<ApiError>()));
      expect(c.read(cartProvider).hasError, isTrue);
    });

    test('refresh reads again and replaces the cart; a failure is left to the caller', () async {
      final c = container();
      c.listen(cartProvider, (previous, next) {});
      await c.read(cartProvider.future);
      when(() => cart.get()).thenAnswer((_) async => cartOf([]));

      await c.read(cartProvider.notifier).refresh();
      expect(c.read(cartProvider).requireValue.isEmpty, isTrue);

      when(() => cart.get()).thenThrow(_offline);
      await expectLater(c.read(cartProvider.notifier).refresh(), throwsA(isA<ApiError>()));
      expect(c.read(cartProvider).requireValue.isEmpty, isTrue);
    });

    test('an agreement event reads the cart again, and other events do not', () async {
      final c = container();
      c.listen(cartProvider, (previous, next) {});
      await c.read(cartProvider.future);
      when(() => cart.get()).thenAnswer((_) async => cartOf([]));

      realtime.emit(RealtimeTypes.negotiationUpdated, {'negotiationId': 'n1'});
      await tick();
      verify(() => cart.get()).called(1);

      realtime.emit(RealtimeTypes.agreementUpdated, {'listingId': 'l1'});
      await tick();
      await tick();

      verify(() => cart.get()).called(1);
      expect(c.read(cartProvider).requireValue.isEmpty, isTrue);
    });

    test('a reconnect reads the cart again and a failed read keeps what it held', () async {
      final c = container();
      c.listen(cartProvider, (previous, next) {});
      await c.read(cartProvider.future);
      when(() => cart.get()).thenThrow(_offline);

      c.read(realtimeResyncProvider.notifier).bump();
      await tick();
      await tick();

      expect(c.read(cartProvider).requireValue.itemCount, 1);
      verify(() => cart.get()).called(2);
    });

    test('remove deletes the line, refreshes the home badge and reads the cart', () async {
      when(() => cart.remove('i1')).thenAnswer((_) async {});
      final c = container();
      c.listen(cartProvider, (previous, next) {});
      await c.read(cartProvider.future);
      when(() => cart.get()).thenAnswer((_) async => cartOf([]));

      await c.read(cartProvider.notifier).remove('i1');

      verify(() => cart.remove('i1')).called(1);
      expect(c.read(cartProvider).requireValue.isEmpty, isTrue);
    });

    test('a removal the server refuses throws and leaves the cart as it was', () async {
      when(() => cart.remove('i1')).thenThrow(_offline);
      final c = container();
      c.listen(cartProvider, (previous, next) {});
      await c.read(cartProvider.future);

      await expectLater(c.read(cartProvider.notifier).remove('i1'), throwsA(isA<ApiError>()));
      expect(c.read(cartProvider).requireValue.itemCount, 1);
    });
  });

  group('the adder', () {
    test('adds and reports the line; the busy flag is back off afterwards', () async {
      when(() => cart.add('l1')).thenAnswer((_) async => addedLine());
      final c = container();
      c.listen(cartAdderProvider, (previous, next) {});

      final result = await c.read(cartAdderProvider.notifier).add('l1');

      expect(result.added?.created, isTrue);
      expect(result.error, isNull);
      expect(c.read(cartAdderProvider), isFalse);
    });

    test('a screen that only reads the adder still gets the added line', () async {
      when(() => cart.add('l1')).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return addedLine();
      });
      final c = container();

      final result = await c.read(cartAdderProvider.notifier).add('l1');

      expect(result.added, isNotNull);
      expect(result.error, isNull);
    });

    test('a refusal comes back as an error, not an exception', () async {
      when(() => cart.add('l1')).thenThrow(_offline);
      final c = container();
      c.listen(cartAdderProvider, (previous, next) {});

      final result = await c.read(cartAdderProvider.notifier).add('l1');

      expect(result.added, isNull);
      expect(result.error, _offline);
      expect(c.read(cartAdderProvider), isFalse);
    });

    test('a second tap while a request runs never reaches the server', () async {
      final pending = Completer<AddedLine>();
      when(() => cart.add('l1')).thenAnswer((_) => pending.future);
      final c = container();
      c.listen(cartAdderProvider, (previous, next) {});

      final first = c.read(cartAdderProvider.notifier).add('l1');
      expect(c.read(cartAdderProvider), isTrue);
      final second = await c.read(cartAdderProvider.notifier).add('l1');
      pending.complete(addedLine());
      await first;

      expect(second.added, isNull);
      expect(second.error, isNull);
      verify(() => cart.add('l1')).called(1);
    });
  });
}
