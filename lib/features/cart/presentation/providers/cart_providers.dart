import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/realtime/realtime_event.dart';
import '../../../../core/realtime/realtime_providers.dart';
import '../../../../core/utils/provider_retry.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../data/cart_repository.dart';
import '../../domain/cart.dart';

/// The buyer's cart (US-019). The server is the source of truth: the cart is read when the screen
/// opens, after every action, when an event says a price agreement changed (US-018) and after every
/// reconnect. The last answer stays on screen when a later read fails, so the buyer still sees what
/// the cart held a moment ago.
class CartController extends AsyncNotifier<CartData> {
  @override
  Future<CartData> build() {
    ref.listen<int>(realtimeResyncProvider, (previous, next) => unawaited(refreshQuietly()));
    final events = ref.watch(negotiationEventsProvider).listen((event) {
      if (event.type == RealtimeTypes.agreementUpdated) unawaited(refreshQuietly());
    });
    ref.onDispose(events.cancel);
    return ref.read(cartRepositoryProvider).get();
  }

  /// Reads the cart again for a pull to refresh; the error is left to the caller.
  Future<void> refresh() async {
    final fresh = await ref.read(cartRepositoryProvider).get();
    if (ref.mounted) state = AsyncData(fresh);
  }

  /// An event or a reconnect: a failed read changes nothing.
  Future<void> refreshQuietly() async {
    try {
      await refresh();
    } on Object {
      // The next event, pull to refresh or visit reads again.
    }
  }

  /// Removes a line, then reads the cart. Removing a line that is already gone is not an error.
  Future<void> remove(String itemId) async {
    await ref.read(cartRepositoryProvider).remove(itemId);
    ref.invalidate(homeBadgesProvider);
    await refreshQuietly();
  }
}

final cartProvider = AsyncNotifierProvider.autoDispose<CartController, CartData>(
  CartController.new,
  retry: noAutoRetry,
);

/// What an Add to Cart tap gave: the line, or the reason it was refused.
class AddToCartResult {
  final AddedLine? added;
  final Object? error;

  const AddToCartResult.added(AddedLine this.added) : error = null;
  const AddToCartResult.failed(Object this.error) : added = null;

  /// A second tap while a request is running.
  const AddToCartResult.ignored()
      : added = null,
        error = null;
}

/// Adds a listing to the cart from a button (US-019). While a request runs the state is true, so a
/// second tap does nothing and the server never sees two requests.
class CartAdder extends Notifier<bool> {
  @override
  bool build() => false;

  Future<AddToCartResult> add(String listingId) async {
    if (state) return const AddToCartResult.ignored();
    state = true;
    try {
      final added = await ref.read(cartRepositoryProvider).add(listingId);
      ref.invalidate(homeBadgesProvider);
      return AddToCartResult.added(added);
    } on Object catch (error) {
      return AddToCartResult.failed(error);
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

/// Not auto-dispose: a screen that only reads it (Saved items) would lose it while a request runs.
final cartAdderProvider = NotifierProvider<CartAdder, bool>(CartAdder.new);
