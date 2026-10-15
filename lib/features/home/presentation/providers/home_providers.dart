import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../address/domain/saved_address.dart';
import '../../data/device_location_service.dart';
import '../../data/mock_home_repository.dart';
import '../../domain/entities/home_badges.dart';
import '../../domain/entities/home_location.dart';
import '../../domain/entities/listing.dart';
import '../../domain/entities/listing_category.dart';
import '../../domain/entities/promo.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/services/location_service.dart';

part 'home_providers.g.dart';

@Riverpod(keepAlive: true)
HomeRepository homeRepository(Ref ref) => const MockHomeRepository();

@Riverpod(keepAlive: true)
LocationService locationService(Ref ref) => const DeviceLocationService();

@riverpod
Future<List<ListingCategory>> categories(Ref ref) => ref.watch(homeRepositoryProvider).categories();

@riverpod
Future<List<Promo>> promos(Ref ref) => ref.watch(homeRepositoryProvider).promos();

@riverpod
Future<HomeBadges> homeBadges(Ref ref) => ref.watch(homeRepositoryProvider).badges();

/// Featured and nearby listings for the chosen place; empty until a place is known.
@riverpod
Future<List<Listing>> featuredListings(Ref ref) async {
  final location = await ref.watch(homeLocationControllerProvider.future);
  if (location is! LocationKnown) return const [];
  return ref.watch(homeRepositoryProvider).featuredListings(location.location);
}

/// Why Home cannot show items near the user yet.
enum LocationNeed {
  /// Permission was never asked, so the screen explains and asks.
  notAsked,
  denied,
  deniedForever,
  serviceOff,
  unavailable,
}

sealed class HomeLocationState {
  const HomeLocationState();
}

class LocationKnown extends HomeLocationState {
  final HomeLocation location;

  const LocationKnown(this.location);
}

class LocationNeeded extends HomeLocationState {
  final LocationNeed reason;

  const LocationNeeded(this.reason);
}

/// The place Home measures "near you" from: one of the user's saved addresses, otherwise the
/// device location when permission is given. The place is only used to find listings; it is kept
/// on the device and never saved as an address.
@Riverpod(keepAlive: true)
class HomeLocationController extends _$HomeLocationController {
  @override
  Future<HomeLocationState> build() async {
    final saved = HomeLocation.tryParse(
      await ref.read(preferencesServiceProvider).getString(StorageKeys.homeLocation),
    );
    if (saved != null) return LocationKnown(saved);

    final service = ref.read(locationServiceProvider);
    final access = await service.access();
    if (access != LocationAccess.granted) return LocationNeeded(_needFor(access, firstTime: true));
    return _fromDevice(service);
  }

  /// Asks for permission if needed, then uses the device location.
  Future<void> useDeviceLocation() async {
    final service = ref.read(locationServiceProvider);
    state = const AsyncLoading();
    var access = await service.access();
    if (access == LocationAccess.denied) access = await service.request();
    if (!ref.mounted) return;

    if (access != LocationAccess.granted) {
      state = AsyncData(LocationNeeded(_needFor(access, firstTime: false)));
      return;
    }
    final result = await _fromDevice(service);
    if (!ref.mounted) return;
    if (result is LocationKnown) {
      await ref.read(preferencesServiceProvider).remove(StorageKeys.homeLocation);
    }
    if (!ref.mounted) return;
    state = AsyncData(result);
  }

  /// Uses the city of a saved address; it is kept until the user picks another place.
  Future<void> useSavedAddress(SavedAddress address) async {
    final location =
        HomeLocation(city: address.city, state: address.state, pincode: address.pincode);
    await ref
        .read(preferencesServiceProvider)
        .setString(StorageKeys.homeLocation, location.toJson());
    if (!ref.mounted) return;
    state = AsyncData(LocationKnown(location));
  }

  Future<void> openSettings() => ref.read(locationServiceProvider).openSettings();

  Future<HomeLocationState> _fromDevice(LocationService service) async {
    final location = await service.current();
    if (location == null) return const LocationNeeded(LocationNeed.unavailable);
    return LocationKnown(location);
  }

  LocationNeed _needFor(LocationAccess access, {required bool firstTime}) {
    return switch (access) {
      LocationAccess.denied => firstTime ? LocationNeed.notAsked : LocationNeed.denied,
      LocationAccess.deniedForever => LocationNeed.deniedForever,
      LocationAccess.serviceOff => LocationNeed.serviceOff,
      LocationAccess.granted => LocationNeed.unavailable,
    };
  }
}
