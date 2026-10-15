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

  /// Completes when the backend confirms the address; an [ApiError] says why it did not.
  Future<void> verify(AddressValue value) {
    return _client.post<void>(
      ApiConstants.addressVerify,
      data: {
        'address': value.address,
        if (value.landmark != null && value.landmark!.isNotEmpty) 'landmark': value.landmark,
        'city': value.city,
        'state': value.state,
        'pincode': value.pincode,
        if (value.placeId != null) 'placeId': value.placeId,
      },
    );
  }
}

final addressRepositoryProvider = Provider<AddressRepository>(
  (ref) => AddressRepository(ref.watch(apiClientProvider)),
);
