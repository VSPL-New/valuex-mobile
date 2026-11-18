import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/realtime/realtime_event.dart';
import '../../../../core/realtime/realtime_providers.dart';
import '../../../../core/utils/provider_retry.dart';
import '../../data/negotiation_repository.dart';
import '../../domain/negotiation.dart';

/// How often an open negotiation asks the server for news: every 15 seconds while the live connection
/// is down (LLD A.7 fallback), never while it is connected, because events and the re-read after each
/// reconnect cover it. Tests turn polling off by overriding this with null.
final negotiationPollIntervalProvider = Provider<Duration?>((ref) {
  final connected = ref.watch(realtimeStatusProvider) == RealtimeStatus.connected;
  return connected ? null : const Duration(seconds: 15);
});

/// One negotiation on screen (US-017). The server decides what each person may do, so every answer
/// replaces the state as a whole. News arrives as `negotiation.updated` events and, while the live
/// connection is down, by polling; after every reconnect it is read again.
class NegotiationController extends AsyncNotifier<Negotiation> {
  static const _uuid = Uuid();

  final String negotiationId;
  Timer? _pollTimer;

  /// Held while an answer is on its way, so a second tap on the same button does nothing.
  bool _busy = false;

  /// One client id per intended counter, kept until it is stored, so a retry never doubles it.
  String? _counterRequestId;
  String? _counterAmount;

  NegotiationController(this.negotiationId);

  @override
  Future<Negotiation> build() async {
    final repository = ref.watch(negotiationRepositoryProvider);
    ref.listen<Duration?>(
      negotiationPollIntervalProvider,
      (previous, next) => _pollEvery(next),
      fireImmediately: true,
    );
    ref.listen<int>(realtimeResyncProvider, (previous, next) => unawaited(refresh()));
    final events = ref.watch(negotiationEventsProvider).listen(_onEvent);
    ref.onDispose(() {
      events.cancel();
      _pollTimer?.cancel();
    });
    return repository.get(negotiationId);
  }

  void _pollEvery(Duration? interval) {
    _pollTimer?.cancel();
    _pollTimer = interval == null ? null : Timer.periodic(interval, (_) => unawaited(refresh()));
  }

  void _onEvent(RealtimeEvent event) {
    if (event.type != RealtimeTypes.negotiationUpdated) return;
    if (event.data['negotiationId'] != negotiationId) return;
    unawaited(refresh());
  }

  /// Reads the negotiation again without showing a spinner; a failure keeps what is on screen.
  Future<void> refresh() async {
    if (state.value == null) return;
    try {
      final fresh = await ref.read(negotiationRepositoryProvider).get(negotiationId);
      if (ref.mounted) state = AsyncData(fresh);
    } on Object {
      // The next poll, event or pull to refresh tries again.
    }
  }

  /// Accepts the other side's last price. Returns null when it worked, or what went wrong.
  Future<Object?> accept() => _answer((repository, offer) => repository.accept(offer.offerId));

  /// Declines the other side's last price; the negotiation ends.
  Future<Object?> reject() => _answer((repository, offer) => repository.reject(offer.offerId));

  /// Answers with [amount], a decimal text such as "850.00".
  Future<Object?> counter(String amount) {
    if (_counterAmount != amount) {
      _counterAmount = amount;
      _counterRequestId = _uuid.v4();
    }
    return _answer((repository, offer) =>
        repository.counter(offer.offerId, amount: amount, clientRequestId: _counterRequestId!));
  }

  /// The buyer withdraws the offer; an accepted price is released.
  Future<Object?> cancel() => _run((repository) => repository.cancel(negotiationId));

  Future<Object?> _answer(
    Future<Negotiation> Function(NegotiationRepository repository, NegotiationOffer offer) action,
  ) {
    final offer = state.value?.pendingOffer;
    if (offer == null) return Future.value(null);
    return _run((repository) => action(repository, offer));
  }

  Future<Object?> _run(
      Future<Negotiation> Function(NegotiationRepository repository) action) async {
    if (_busy) return null;
    _busy = true;
    try {
      final updated = await action(ref.read(negotiationRepositoryProvider));
      _counterAmount = null;
      if (ref.mounted) state = AsyncData(updated);
      return null;
    } on Object catch (error) {
      if (error is ApiError && _staleCodes.contains(error.code)) {
        await refresh();
      }
      return error;
    } finally {
      _busy = false;
    }
  }

  /// Refusals that mean the screen shows an old state; it is read again so the latest shows.
  static const _staleCodes = {
    'ERROR_OFFER_NOT_CURRENT',
    'ERROR_NEGOTIATION_EXPIRED',
    'ERROR_OFFER_EXPIRED',
    'ERROR_ITEM_UNAVAILABLE',
    'ERROR_ALREADY_ACCEPTED',
  };
}

final negotiationControllerProvider =
    AsyncNotifierProvider.autoDispose.family<NegotiationController, Negotiation, String>(
  NegotiationController.new,
  retry: noAutoRetry,
);
