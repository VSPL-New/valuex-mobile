import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/cart.dart';

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
}

final cartRepositoryProvider =
    Provider<CartRepository>((ref) => CartRepository(ref.watch(apiClientProvider)));
