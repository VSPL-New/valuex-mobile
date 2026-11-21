import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/cart.dart';
import '../domain/delivery.dart';

/// What adding a line gave: the line, and whether this call made it (201) or it was already in the
/// cart (200).
class AddedLine {
  final CartLine line;
  final bool created;

  const AddedLine({required this.line, required this.created});
}

/// The buyer's cart (US-019). Failures surface as `ApiError`; the screens map the codes to text. No
/// price is ever sent: a line rests on the price the buyer agreed, which the server reads itself.
class CartRepository {
  final ApiClient _client;

  CartRepository(this._client);

  Future<CartData> get() => _client.get<CartData>(
        ApiConstants.cart,
        parse: (json) => CartData.fromJson(json as Map<String, dynamic>),
      );

  Future<CartSummary> summary() => _client.get<CartSummary>(
        ApiConstants.cartSummary,
        parse: (json) => CartSummary.fromJson(json as Map<String, dynamic>),
      );

  Future<AddedLine> add(String listingId) async {
    final (line, status) = await _client.postWithStatus<CartLine>(
      ApiConstants.cartItems,
      data: {'listingId': listingId},
      parse: (json) => CartLine.fromJson(json as Map<String, dynamic>),
    );
    return AddedLine(line: line, created: status == 201);
  }

  /// Removing a line that is already gone is not an error.
  Future<void> remove(String itemId) => _client.delete<void>(ApiConstants.cartItem(itemId));

  /// What the line allows for receiving the item. With an [addressId] the delivery option also carries
  /// the shipping cost and date for that address (US-020).
  Future<DeliveryOptions> deliveryOptions(String itemId, {String? addressId}) =>
      _client.get<DeliveryOptions>(
        ApiConstants.cartItemDeliveryOptions(itemId),
        queryParameters: {if (addressId != null) 'addressId': addressId},
        parse: (json) => DeliveryOptions.fromJson(json as Map<String, dynamic>),
      );

  /// Saves how the buyer receives the line and returns the line as the cart shows it now. The app
  /// sends the shipping cost it showed ([expectedShippingCost]), never a price: the server prices
  /// the delivery and refuses with `ERROR_SHIPPING_CHANGED` when the cost is no longer that.
  Future<CartLine> chooseDelivery(
    String itemId, {
    required DeliveryMode mode,
    String? addressId,
    PaymentOption? paymentOption,
    num? expectedShippingCost,
    required bool termsAccepted,
  }) =>
      _client.put<CartLine>(
        ApiConstants.cartItemDelivery(itemId),
        data: {
          'mode': mode.api,
          if (addressId != null) 'addressId': addressId,
          if (paymentOption != null) 'paymentOption': paymentOption.api,
          if (expectedShippingCost != null) 'expectedShippingCost': expectedShippingCost,
          'termsAccepted': termsAccepted,
        },
        parse: (json) => CartLine.fromJson(json as Map<String, dynamic>),
      );
}

final cartRepositoryProvider =
    Provider<CartRepository>((ref) => CartRepository(ref.watch(apiClientProvider)));
