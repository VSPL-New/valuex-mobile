import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../domain/saved_listing.dart';

/// Save, remove and list the buyer's saved listings (US-073).
class SavedListingsRepository {
  static const String limitCode = 'ERROR_MAX_SAVED';
  static const String unavailableCode = 'ERROR_ITEM_UNAVAILABLE';

  /// Page size of Saved Items.
  static const int pageSize = 20;

  final ApiClient _client;

  SavedListingsRepository(this._client);

  /// Saves the listing; saving it twice is harmless. Throws [SavedListingLimitReached] or
  /// [SavedListingUnavailable] for those two refusals.
  Future<void> save(String listingId) async {
    try {
      await _client.put<void>(ApiConstants.savedListing(listingId));
    } on ApiError catch (error) {
      throw switch (error.code) {
        limitCode => SavedListingLimitReached(int.tryParse(error.details['max'] ?? '')),
        unavailableCode => const SavedListingUnavailable(),
        _ => error,
      };
    }
  }

  /// Removes the listing from the saved ones; removing one that is not saved is harmless.
  Future<void> remove(String listingId) =>
      _client.delete<void>(ApiConstants.savedListing(listingId));

  Future<SavedListingsPage> list({int page = 0}) => _client.get(
        ApiConstants.savedListings,
        queryParameters: {'page': page, 'size': pageSize},
        parse: (json) => SavedListingsPage.fromJson(json as Map<String, dynamic>),
      );
}

final savedListingsRepositoryProvider = Provider<SavedListingsRepository>(
  (ref) => SavedListingsRepository(ref.watch(apiClientProvider)),
);
