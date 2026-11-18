import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/buy_now_reservation.dart';

/// Direct Buy Now (US-068). Failures surface as `ApiError`; the screens map the codes to text. The
/// price is sent as a decimal string and is only what the buyer saw: the server charges its own.
class BuyNowRepository {
  final ApiClient _client;

  BuyNowRepository(this._client);

  /// Reserves the listing at its asking price. A buyer who already holds it gets the same
  /// reservation back, so a retry after a lost answer is safe.
  Future<BuyNowReservation> start(
    String listingId, {
    required String expectedPrice,
    required String clientRequestId,
  }) =>
      _client.post<BuyNowReservation>(
        ApiConstants.listingBuyNow(listingId),
        data: {'expectedPrice': expectedPrice, 'clientRequestId': clientRequestId},
        parse: (json) => BuyNowReservation.fromJson(json as Map<String, dynamic>),
      );

  /// Lets the reservation go so the item is open to everyone again; repeating it is harmless.
  Future<void> release(String agreementId) =>
      _client.delete<void>(ApiConstants.priceAgreement(agreementId));
}

final buyNowRepositoryProvider =
    Provider<BuyNowRepository>((ref) => BuyNowRepository(ref.watch(apiClientProvider)));
