import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/address_value.dart';
import '../domain/saved_address.dart';

class AddressRepository {
  final ApiClient _client;

  AddressRepository(this._client);

  /// The user's saved addresses, default first.
  Future<List<SavedAddress>> savedAddresses() {
    return _client.get(
      ApiConstants.savedAddresses,
      parse: (json) => [for (final item in json as List<dynamic>) SavedAddress.fromJson(item)],
    );
  }

  /// Completes when the backend accepts the address; an [ApiError] says why it did not. The answer
  /// is true when a provider confirmed the address and false when it only passed the backend's own
  /// checks (US-113); the caller shows a "verified" mark only for true.
  Future<bool> verify(AddressValue value) {
    return _client.post<bool>(
      ApiConstants.addressVerify,
      data: _fields(value),
      parse: (json) => (json as Map<String, dynamic>)['verified'] == true,
    );
  }

  /// Saves a verified address (US-020). The server checks it again, then saves it; the first
  /// address a user saves becomes the default.
  Future<SavedAddress> create(AddressValue value, {String? label, bool makeDefault = false}) {
    return _client.post<SavedAddress>(
      ApiConstants.savedAddresses,
      data: {
        ..._fields(value),
        if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
        'makeDefault': makeDefault,
      },
      parse: SavedAddress.fromJson,
    );
  }

  /// Changes a saved address (US-113). The backend checks the address again only when a field
  /// other than the name changed; a missing [label] removes the name.
  Future<SavedAddress> update(String id, AddressValue value, {String? label}) {
    return _client.put<SavedAddress>(
      ApiConstants.savedAddress(id),
      data: {
        ..._fields(value),
        if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
      },
      parse: SavedAddress.fromJson,
    );
  }

  /// Makes the address the default one (US-113).
  Future<SavedAddress> setDefault(String id) {
    return _client.put<SavedAddress>(ApiConstants.savedAddressDefault(id),
        parse: SavedAddress.fromJson);
  }

  /// Deletes the address (US-113); `ERROR_ADDRESS_IN_USE` says a cart line or listing uses it.
  Future<void> delete(String id) {
    return _client.delete<void>(ApiConstants.savedAddress(id));
  }

  Map<String, dynamic> _fields(AddressValue value) => {
        'address': value.address,
        if (value.landmark != null && value.landmark!.isNotEmpty) 'landmark': value.landmark,
        'city': value.city,
        'state': value.state,
        'pincode': value.pincode,
        if (value.placeId != null) 'placeId': value.placeId,
      };
}

final addressRepositoryProvider = Provider<AddressRepository>(
  (ref) => AddressRepository(ref.watch(apiClientProvider)),
);
