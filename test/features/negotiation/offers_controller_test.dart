import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/realtime/realtime_event.dart';
import 'package:valuex_mobile/core/realtime/realtime_providers.dart';
import 'package:valuex_mobile/features/negotiation/data/negotiation_repository.dart';
import 'package:valuex_mobile/features/negotiation/domain/offers.dart';
import 'package:valuex_mobile/features/negotiation/presentation/providers/negotiation_controller.dart';
import 'package:valuex_mobile/features/negotiation/presentation/providers/offers_controller.dart';

import '../../core/realtime/realtime_fakes.dart';
import 'negotiation_fixtures.dart';
import 'offers_fixtures.dart';

void main() {
  late MockNegotiationRepository repo;
  late FakeRealtimeClient realtime;

  setUpAll(() => registerFallbackValue(OffersFilter.pending));

  const received = (OffersSide.received, OffersFilter.pending);
  const sent = (OffersSide.sent, OffersFilter.pending);

  ProviderContainer container({Duration? poll}) {
    final value = ProviderContainer(overrides: [
      negotiationRepositoryProvider.overrideWithValue(repo),
      negotiationPollIntervalProvider.overrideWithValue(poll),
      realtimeClientProvider.overrideWithValue(realtime),
    ]);
    addTearDown(value.dispose);
    return value;
  }

  Future<OffersListController> started(ProviderContainer c, [OffersQuery query = received]) async {
    final provider = offersListControllerProvider(query);
    c.listen(provider, (previous, next) {});
    await c.read(provider.future);
    return c.read(provider.notifier);
  }

  setUp(() {
    repo = MockNegotiationRepository();
    realtime = FakeRealtimeClient();
    when(() => repo.receivedOffers(any(), page: any(named: 'page')))
        .thenAnswer((_) async => receivedPage([receivedJson()]));
    when(() => repo.sentOffers(any(), page: any(named: 'page')))
        .thenAnswer((_) async => sentPage([sentJson()]));
    when(() => repo.offersSummary())
        .thenAnswer((_) async => const OffersSummary(pending: 2, accepted: 1, expiringSoon: 1));
  });

  group('the list', () {
    test('loads the received offers of its filter', () async {
      final c = container();

      await started(c, (OffersSide.received, OffersFilter.accepted));

      verify(() => repo.receivedOffers(OffersFilter.accepted, page: 0)).called(1);
      verifyNever(() => repo.sentOffers(any(), page: any(named: 'page')));
      expect(
          c
              .read(offersListControllerProvider((OffersSide.received, OffersFilter.accepted)))
              .value!
              .items,
          hasLength(1));
    });

    test('loads the sent offers on the Sent side', () async {
      final c = container();

      await started(c, sent);

      verify(() => repo.sentOffers(OffersFilter.pending, page: 0)).called(1);
      verifyNever(() => repo.receivedOffers(any(), page: any(named: 'page')));
    });

    test('keeps the filter chosen and starts on pending', () {
      final c = container();
      c.listen(offersFilterProvider, (previous, next) {});

      expect(c.read(offersFilterProvider), OffersFilter.pending);
      c.read(offersFilterProvider.notifier).select(OffersFilter.closed);
      expect(c.read(offersFilterProvider), OffersFilter.closed);
    });

    test('a negotiation or badge event reads the first page again', () async {
      final c = container();
      await started(c);
      when(() => repo.receivedOffers(any(), page: any(named: 'page')))
          .thenAnswer((_) async => receivedPage([receivedJson(), receivedJson(id: 'n2')]));

      realtime.emit(RealtimeTypes.negotiationUpdated, {'negotiationId': 'n2'});
      await Future<void>.delayed(Duration.zero);
      expect(c.read(offersListControllerProvider(received)).value!.items, hasLength(2));

      when(() => repo.receivedOffers(any(), page: any(named: 'page')))
          .thenAnswer((_) async => receivedPage([receivedJson()]));
      realtime.emit(RealtimeTypes.badgeUpdated, {'offersAwaiting': 1});
      await Future<void>.delayed(Duration.zero);
      expect(c.read(offersListControllerProvider(received)).value!.items, hasLength(1));
    });

    test('other events are ignored', () async {
      final c = container();
      await started(c);

      realtime.emit('chat.message.created', {});
      realtime.emit('agreement.updated', {});
      await Future<void>.delayed(Duration.zero);

      verify(() => repo.receivedOffers(any(), page: any(named: 'page'))).called(1);
    });

    test('a resync after a reconnect reads it again', () async {
      final c = container();
      await started(c);

      c.read(realtimeResyncProvider.notifier).bump();
      await Future<void>.delayed(Duration.zero);

      verify(() => repo.receivedOffers(any(), page: any(named: 'page'))).called(2);
    });

    test('a failed quiet re-read keeps what is on screen', () async {
      final c = container();
      await started(c);
      when(() => repo.receivedOffers(any(), page: any(named: 'page')))
          .thenThrow(const ApiError(type: ApiErrorType.network, message: 'offline'));

      realtime.emit(RealtimeTypes.negotiationUpdated, {});
      await Future<void>.delayed(Duration.zero);

      expect(c.read(offersListControllerProvider(received)).value!.items, hasLength(1));
    });

    test('a pull to refresh replaces the list and lets a failure reach the caller', () async {
      final c = container();
      final controller = await started(c);
      when(() => repo.receivedOffers(any(), page: any(named: 'page')))
          .thenAnswer((_) async => receivedPage([receivedJson(id: 'fresh')]));

      await controller.refresh();

      expect(c.read(offersListControllerProvider(received)).value!.items.single.negotiationId,
          'fresh');
      when(() => repo.receivedOffers(any(), page: any(named: 'page')))
          .thenThrow(const ApiError(type: ApiErrorType.network, message: 'offline'));
      await expectLater(controller.refresh(), throwsA(isA<ApiError>()));
    });

    test('loads the next page and skips offers it already has', () async {
      when(() => repo.receivedOffers(any(), page: 0))
          .thenAnswer((_) async => receivedPage([receivedJson()], hasNext: true));
      when(() => repo.receivedOffers(any(), page: 1))
          .thenAnswer((_) async => receivedPage([receivedJson(), receivedJson(id: 'n2')], page: 1));
      final c = container();
      final controller = await started(c);

      expect(await controller.loadMore(), isTrue);

      final state = c.read(offersListControllerProvider(received)).value!;
      expect(state.items.map((card) => card.negotiationId), ['n1', 'n2']);
      expect(state.hasNext, isFalse);
      expect(await controller.loadMore(), isTrue);
      verify(() => repo.receivedOffers(any(), page: 1)).called(1);
    });

    test('a failed next page keeps the list and says so', () async {
      when(() => repo.receivedOffers(any(), page: 0))
          .thenAnswer((_) async => receivedPage([receivedJson()], hasNext: true));
      when(() => repo.receivedOffers(any(), page: 1))
          .thenThrow(const ApiError(type: ApiErrorType.network, message: 'offline'));
      final c = container();
      final controller = await started(c);

      expect(await controller.loadMore(), isFalse);

      final state = c.read(offersListControllerProvider(received)).value!;
      expect(state.items, hasLength(1));
      expect(state.loadingMore, isFalse);
      expect(state.hasNext, isTrue);
    });

    test('polls while the connection is down and stops when the list goes away', () {
      fakeAsync((async) {
        final c = ProviderContainer(overrides: [
          negotiationRepositoryProvider.overrideWithValue(repo),
          negotiationPollIntervalProvider.overrideWithValue(const Duration(seconds: 15)),
          realtimeClientProvider.overrideWithValue(realtime),
        ]);
        final subscription = c.listen(offersListControllerProvider(received), (p, n) {});
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 31));
        async.flushMicrotasks();

        verify(() => repo.receivedOffers(any(), page: any(named: 'page'))).called(3);
        subscription.close();
        c.dispose();
        async.elapse(const Duration(seconds: 60));
        async.flushMicrotasks();
      });
    });
  });

  group('the summary', () {
    test('loads the counts and reads them again on an event or a resync', () async {
      final c = container();
      c.listen(offersSummaryProvider, (previous, next) {});
      expect((await c.read(offersSummaryProvider.future)).pending, 2);
      when(() => repo.offersSummary()).thenAnswer((_) async => const OffersSummary(pending: 5));

      realtime.emit(RealtimeTypes.negotiationUpdated, {});
      await Future<void>.delayed(Duration.zero);
      expect(c.read(offersSummaryProvider).value!.pending, 5);

      when(() => repo.offersSummary()).thenAnswer((_) async => const OffersSummary(pending: 6));
      c.read(realtimeResyncProvider.notifier).bump();
      await Future<void>.delayed(Duration.zero);
      expect(c.read(offersSummaryProvider).value!.pending, 6);
    });

    test('ignores other events and keeps the counts when a re-read fails', () async {
      final c = container();
      c.listen(offersSummaryProvider, (previous, next) {});
      await c.read(offersSummaryProvider.future);

      realtime.emit('chat.read', {});
      await Future<void>.delayed(Duration.zero);
      verify(() => repo.offersSummary()).called(1);

      when(() => repo.offersSummary())
          .thenThrow(const ApiError(type: ApiErrorType.network, message: 'offline'));
      realtime.emit(RealtimeTypes.negotiationUpdated, {});
      await Future<void>.delayed(Duration.zero);
      expect(c.read(offersSummaryProvider).value!.pending, 2);
    });
  });
}
