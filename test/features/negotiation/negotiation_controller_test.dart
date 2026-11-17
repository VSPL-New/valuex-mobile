import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/realtime/realtime_event.dart';
import 'package:valuex_mobile/core/realtime/realtime_providers.dart';
import 'package:valuex_mobile/features/negotiation/data/negotiation_repository.dart';
import 'package:valuex_mobile/features/negotiation/domain/negotiation.dart';
import 'package:valuex_mobile/features/negotiation/presentation/providers/negotiation_controller.dart';

import '../../core/realtime/realtime_fakes.dart';
import 'negotiation_fixtures.dart';

void main() {
  late MockNegotiationRepository repo;
  late FakeRealtimeClient realtime;

  ProviderContainer container({Duration? poll}) {
    final value = ProviderContainer(overrides: [
      negotiationRepositoryProvider.overrideWithValue(repo),
      negotiationPollIntervalProvider.overrideWithValue(poll),
      realtimeClientProvider.overrideWithValue(realtime),
    ]);
    addTearDown(value.dispose);
    return value;
  }

  Future<NegotiationController> started(ProviderContainer c) async {
    final provider = negotiationControllerProvider('n1');
    c.listen(provider, (previous, next) {});
    await c.read(provider.future);
    return c.read(provider.notifier);
  }

  setUp(() {
    repo = MockNegotiationRepository();
    realtime = FakeRealtimeClient();
    when(() => repo.get('n1')).thenAnswer((_) async => sellerTurn());
  });

  test('loads the negotiation', () async {
    final c = container();

    await started(c);

    expect(c.read(negotiationControllerProvider('n1')).value?.role, NegotiationRole.seller);
  });

  test('accept answers the pending offer and replaces the state', () async {
    final accepted =
        negotiation(role: 'SELLER', state: 'OFFER_ACCEPTED', awaiting: 'NONE', agreedPrice: 12000);
    when(() => repo.accept('o1')).thenAnswer((_) async => accepted);
    final c = container();
    final controller = await started(c);

    final error = await controller.accept();

    expect(error, isNull);
    expect(
        c.read(negotiationControllerProvider('n1')).value?.state, NegotiationState.offerAccepted);
    verify(() => repo.accept('o1')).called(1);
  });

  test('reject and cancel call their endpoints', () async {
    when(() => repo.reject('o1'))
        .thenAnswer((_) async => negotiation(state: 'OFFER_REJECTED', awaiting: 'NONE'));
    when(() => repo.cancel('n1'))
        .thenAnswer((_) async => negotiation(state: 'NEGOTIATION_CANCELLED', awaiting: 'NONE'));
    final c = container();
    final controller = await started(c);

    expect(await controller.reject(), isNull);
    expect(
        c.read(negotiationControllerProvider('n1')).value?.state, NegotiationState.offerRejected);
    expect(await controller.cancel(), isNull);
    expect(c.read(negotiationControllerProvider('n1')).value?.state, NegotiationState.cancelled);
  });

  test('does nothing when no offer is waiting for an answer', () async {
    when(() => repo.get('n1')).thenAnswer((_) async => negotiation(
          state: 'OFFER_ACCEPTED',
          awaiting: 'NONE',
          offers: [offerJson('o1', 'BUYER', 12000, 1, status: 'ACCEPTED')],
        ));
    final c = container();
    final controller = await started(c);

    expect(await controller.accept(), isNull);
    expect(await controller.reject(), isNull);
    expect(await controller.counter('13000'), isNull);

    verifyNever(() => repo.accept(any()));
  });

  test('a second tap while an answer is on its way is ignored', () async {
    final pending = Completer<Negotiation>();
    when(() => repo.accept('o1')).thenAnswer((_) => pending.future);
    final c = container();
    final controller = await started(c);

    final first = controller.accept();
    final second = await controller.accept();
    pending.complete(negotiation(state: 'OFFER_ACCEPTED', awaiting: 'NONE'));
    await first;

    expect(second, isNull);
    verify(() => repo.accept('o1')).called(1);
  });

  test('counter keeps one client id for the same amount and a new one for another', () async {
    final ids = <String>[];
    when(() => repo.counter('o1',
        amount: any(named: 'amount'),
        clientRequestId: any(named: 'clientRequestId'))).thenAnswer((invocation) async {
      ids.add(invocation.namedArguments[#clientRequestId] as String);
      throw const ApiError(type: ApiErrorType.network, message: 'offline');
    });
    final c = container();
    final controller = await started(c);

    expect(await controller.counter('13000'), isA<ApiError>());
    await controller.counter('13000');
    await controller.counter('13100');

    expect(ids[0], ids[1]);
    expect(ids[2], isNot(ids[0]));
  });

  test('a stored counter replaces the state and the next one gets a new client id', () async {
    final ids = <String>[];
    when(() => repo.counter('o1',
        amount: any(named: 'amount'),
        clientRequestId: any(named: 'clientRequestId'))).thenAnswer((invocation) async {
      ids.add(invocation.namedArguments[#clientRequestId] as String);
      return negotiation(role: 'SELLER', state: 'BUYER_REVIEWING', awaiting: 'BUYER', round: 2);
    });
    final c = container();
    final controller = await started(c);

    expect(await controller.counter('13000'), isNull);
    await controller.counter('13000');

    expect(c.read(negotiationControllerProvider('n1')).value?.round, 2);
    expect(ids, hasLength(2));
    expect(ids[0], isNot(ids[1]));
  });

  test('a stale or expired refusal reads the negotiation again and returns the error', () async {
    when(() => repo.accept('o1')).thenThrow(const ApiError(
      type: ApiErrorType.business,
      message: 'x',
      code: 'ERROR_OFFER_NOT_CURRENT',
      statusCode: 409,
    ));
    final c = container();
    final controller = await started(c);
    when(() => repo.get('n1')).thenAnswer((_) async => negotiation(role: 'SELLER', round: 3));

    final error = await controller.accept();

    expect((error as ApiError).code, 'ERROR_OFFER_NOT_CURRENT');
    expect(c.read(negotiationControllerProvider('n1')).value?.round, 3);
  });

  test('another refusal returns its error without a re-read', () async {
    when(() => repo.accept('o1')).thenThrow(const ApiError(
      type: ApiErrorType.business,
      message: 'x',
      code: 'RATE_LIMIT_EXCEEDED',
      statusCode: 429,
    ));
    final c = container();
    final controller = await started(c);

    final error = await controller.accept();

    expect((error as ApiError).code, 'RATE_LIMIT_EXCEEDED');
    verify(() => repo.get('n1')).called(1);
  });

  test('a negotiation.updated event for this negotiation reads it again', () async {
    final c = container();
    await started(c);
    when(() => repo.get('n1')).thenAnswer((_) async => negotiation(role: 'SELLER', round: 4));

    realtime.emit(RealtimeTypes.negotiationUpdated, {'negotiationId': 'n1'});
    await Future<void>.delayed(Duration.zero);

    expect(c.read(negotiationControllerProvider('n1')).value?.round, 4);
  });

  test('events of another negotiation or another type are ignored', () async {
    final c = container();
    await started(c);

    realtime.emit(RealtimeTypes.negotiationUpdated, {'negotiationId': 'other'});
    realtime.emit('agreement.updated', {'negotiationId': 'n1'});
    await Future<void>.delayed(Duration.zero);

    verify(() => repo.get('n1')).called(1);
  });

  test('a resync after a reconnect reads it again', () async {
    final c = container();
    await started(c);

    c.read(realtimeResyncProvider.notifier).bump();
    await Future<void>.delayed(Duration.zero);

    verify(() => repo.get('n1')).called(2);
  });

  test('a failed re-read keeps what is on screen', () async {
    final c = container();
    final controller = await started(c);
    when(() => repo.get('n1'))
        .thenThrow(const ApiError(type: ApiErrorType.network, message: 'offline'));

    await controller.refresh();

    expect(c.read(negotiationControllerProvider('n1')).value?.role, NegotiationRole.seller);
  });

  test('polls while the connection is down and stops when the controller goes away', () {
    fakeAsync((async) {
      final c = ProviderContainer(overrides: [
        negotiationRepositoryProvider.overrideWithValue(repo),
        negotiationPollIntervalProvider.overrideWithValue(const Duration(seconds: 15)),
        realtimeClientProvider.overrideWithValue(realtime),
      ]);
      final provider = negotiationControllerProvider('n1');
      final subscription = c.listen(provider, (previous, next) {});
      async.flushMicrotasks();

      async.elapse(const Duration(seconds: 31));
      async.flushMicrotasks();

      verify(() => repo.get('n1')).called(3);
      subscription.close();
      c.dispose();
      async.elapse(const Duration(seconds: 60));
      async.flushMicrotasks();
    });
  });

  test('the poll interval is 15 seconds until the live connection is up, then off', () {
    final c = ProviderContainer(overrides: [realtimeClientProvider.overrideWithValue(realtime)]);
    addTearDown(c.dispose);
    c.listen(negotiationPollIntervalProvider, (previous, next) {});

    expect(c.read(negotiationPollIntervalProvider), const Duration(seconds: 15));

    c.read(realtimeStatusProvider.notifier).update(RealtimeStatus.connected);
    expect(c.read(negotiationPollIntervalProvider), isNull);
  });
}
