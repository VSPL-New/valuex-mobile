import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/utils/provider_retry.dart';
import '../../data/address_repository.dart';
import '../../data/google_places_service.dart';
import '../../data/mock_address_search_service.dart';
import '../../domain/address_details.dart';
import '../../domain/address_search_service.dart';
import '../../domain/address_suggestion.dart';
import '../../domain/address_value.dart';
import '../../domain/saved_address.dart';

/// Fresh each time the saved-address list is opened.
final savedAddressesProvider = FutureProvider.autoDispose<List<SavedAddress>>(
  (ref) => ref.watch(addressRepositoryProvider).savedAddresses(),
  retry: noAutoRetry,
);

final addressSearchServiceProvider = Provider<AddressSearchService>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockAddressSearch) return const MockAddressSearchService();
  return GooglePlacesService(
    apiKey: config.googlePlacesApiKey,
    androidCert: config.googlePlacesAndroidCert,
  );
});

enum AddressSearchStatus { idle, searching, results, empty, unavailable }

class AddressSearchState {
  final AddressSearchStatus status;
  final List<AddressSuggestion> suggestions;

  const AddressSearchState({
    this.status = AddressSearchStatus.idle,
    this.suggestions = const [],
  });
}

/// Search as you type: waits for a pause, asks for suggestions and, when one is picked, for the
/// place's details. One session token covers the typing and the pick, then a new one starts.
class AddressSearchController extends Notifier<AddressSearchState> {
  static const Duration debounce = Duration(milliseconds: 300);
  static const int minCharacters = 3;

  Timer? _timer;
  String _sessionToken = const Uuid().v4();
  int _generation = 0;

  @override
  AddressSearchState build() {
    ref.onDispose(() => _timer?.cancel());
    return const AddressSearchState();
  }

  void onQueryChanged(String text) {
    final query = text.trim();
    _timer?.cancel();
    final generation = ++_generation;
    if (query.length < minCharacters) {
      state = const AddressSearchState();
      return;
    }
    state = AddressSearchState(
      status: AddressSearchStatus.searching,
      suggestions: state.suggestions,
    );
    _timer = Timer(debounce, () => _search(query, generation));
  }

  Future<void> _search(String query, int generation) async {
    try {
      final found =
          await ref.read(addressSearchServiceProvider).suggest(query, sessionToken: _sessionToken);
      if (generation != _generation || !ref.mounted) return;
      state = AddressSearchState(
        status: found.isEmpty ? AddressSearchStatus.empty : AddressSearchStatus.results,
        suggestions: found,
      );
    } on Object {
      if (generation != _generation || !ref.mounted) return;
      state = const AddressSearchState(status: AddressSearchStatus.unavailable);
    }
  }

  /// The place's details, or null when the search could not be used; the list closes either way.
  Future<AddressDetails?> select(AddressSuggestion suggestion) async {
    _timer?.cancel();
    final generation = ++_generation;
    try {
      final details = await ref
          .read(addressSearchServiceProvider)
          .details(suggestion.placeId, sessionToken: _sessionToken);
      if (!ref.mounted) return null;
      _sessionToken = const Uuid().v4();
      state = const AddressSearchState();
      return details;
    } on Object {
      if (generation == _generation && ref.mounted) {
        state = const AddressSearchState(status: AddressSearchStatus.unavailable);
      }
      return null;
    }
  }
}

final addressSearchControllerProvider =
    NotifierProvider.autoDispose<AddressSearchController, AddressSearchState>(
  AddressSearchController.new,
  retry: noAutoRetry,
);

enum AddressCheckStatus { idle, checking, verified, rejected, unavailable }

class AddressVerificationState {
  final AddressCheckStatus status;

  /// The backend error code that explains a rejection.
  final String? code;
  final AddressValue? checked;

  const AddressVerificationState({
    this.status = AddressCheckStatus.idle,
    this.code,
    this.checked,
  });
}

const Set<String> _rejectionCodes = {
  'ERROR_ADDRESS_NOT_VERIFIED',
  'ERROR_PINCODE_MISMATCH',
  'ERROR_ADDRESS_INVALID',
  'ERROR_INVALID_ADDRESS_STATE',
};

/// Whether the backend error means the address itself was refused (not that checking failed).
bool isAddressRejection(Object error) {
  return error is ApiError &&
      (_rejectionCodes.contains(error.code) || error.type == ApiErrorType.validation);
}

/// Checks the address with the backend once the user stops editing, so the form can say whether
/// it is verified before Submit. A failed check never blocks the user: the backend checks again.
class AddressVerificationController extends Notifier<AddressVerificationState> {
  static const Duration debounce = Duration(milliseconds: 700);

  Timer? _timer;
  AddressValue? _pending;

  @override
  AddressVerificationState build() {
    ref.onDispose(() => _timer?.cancel());
    return const AddressVerificationState();
  }

  /// The address is complete and valid: check it after a pause unless this exact one was checked.
  void schedule(AddressValue value) {
    _timer?.cancel();
    _pending = value;
    final settled =
        state.status == AddressCheckStatus.verified || state.status == AddressCheckStatus.rejected;
    if (settled && state.checked == value) return;
    state = const AddressVerificationState();
    _timer = Timer(debounce, () => _check(value));
  }

  /// The address is incomplete or being edited.
  void reset() {
    _timer?.cancel();
    _pending = null;
    if (state.status != AddressCheckStatus.idle) state = const AddressVerificationState();
  }

  /// Shows a refusal that came back when the address was saved.
  void reject(ApiError error, AddressValue? value) {
    _timer?.cancel();
    state = AddressVerificationState(
      status: AddressCheckStatus.rejected,
      code: error.code ?? 'ERROR_ADDRESS_INVALID',
      checked: value,
    );
  }

  Future<void> _check(AddressValue value) async {
    state = AddressVerificationState(status: AddressCheckStatus.checking, checked: value);
    try {
      await ref.read(addressRepositoryProvider).verify(value);
      if (!ref.mounted || _pending != value) return;
      state = AddressVerificationState(status: AddressCheckStatus.verified, checked: value);
    } on Object catch (error) {
      if (!ref.mounted || _pending != value) return;
      state = isAddressRejection(error)
          ? AddressVerificationState(
              status: AddressCheckStatus.rejected,
              code: error is ApiError ? error.code : null,
              checked: value,
            )
          : AddressVerificationState(status: AddressCheckStatus.unavailable, checked: value);
    }
  }
}

final addressVerificationProvider =
    NotifierProvider.autoDispose<AddressVerificationController, AddressVerificationState>(
  AddressVerificationController.new,
  retry: noAutoRetry,
);
