import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/buy_now_repository.dart';
import '../../domain/buy_now_reservation.dart';

/// What a Buy Now tap gave: the reservation, or the reason it was refused.
class BuyNowResult {
  final BuyNowReservation? reservation;
  final Object? error;

  const BuyNowResult.reserved(BuyNowReservation this.reservation) : error = null;
  const BuyNowResult.failed(Object this.error) : reservation = null;

  /// A second tap while a request is running.
  const BuyNowResult.ignored()
      : reservation = null,
        error = null;
}

/// Starts a Buy Now from a listing's button (US-068). While a request runs the state is true, so a
/// second tap does nothing and the server never sees two requests.
class BuyNowLauncher extends Notifier<bool> {
  @override
  bool build() => false;

  /// Reserves [listingId] at the price the buyer saw ([expectedPrice], a decimal string).
  Future<BuyNowResult> start(
    String listingId, {
    required String expectedPrice,
    required String clientRequestId,
  }) async {
    if (state) return const BuyNowResult.ignored();
    state = true;
    try {
      final reservation = await ref.read(buyNowRepositoryProvider).start(
            listingId,
            expectedPrice: expectedPrice,
            clientRequestId: clientRequestId,
          );
      return BuyNowResult.reserved(reservation);
    } on Object catch (error) {
      return BuyNowResult.failed(error);
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

final buyNowLauncherProvider = NotifierProvider.autoDispose<BuyNowLauncher, bool>(
  BuyNowLauncher.new,
);
