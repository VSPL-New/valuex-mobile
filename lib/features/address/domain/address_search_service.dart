import 'address_details.dart';
import 'address_suggestion.dart';

/// Search over places. [sessionToken] groups the typing and the final pick into one billed
/// session; use a new token after every pick.
abstract class AddressSearchService {
  Future<List<AddressSuggestion>> suggest(String query, {required String sessionToken});

  Future<AddressDetails> details(String placeId, {required String sessionToken});
}

/// The search service could not be used (offline, quota, bad key); the user types the address.
class AddressSearchUnavailable implements Exception {
  final String message;

  const AddressSearchUnavailable([this.message = 'Address search unavailable']);

  @override
  String toString() => 'AddressSearchUnavailable: $message';
}
