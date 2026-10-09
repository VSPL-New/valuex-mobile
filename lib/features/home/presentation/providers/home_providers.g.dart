// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(homeRepository)
const homeRepositoryProvider = HomeRepositoryProvider._();

final class HomeRepositoryProvider
    extends $FunctionalProvider<HomeRepository, HomeRepository, HomeRepository>
    with $Provider<HomeRepository> {
  const HomeRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'homeRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$homeRepositoryHash();

  @$internal
  @override
  $ProviderElement<HomeRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HomeRepository create(Ref ref) {
    return homeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeRepository>(value),
    );
  }
}

String _$homeRepositoryHash() => r'fb4f0de04e88837063c9071e5a6bbf03f219acd6';

@ProviderFor(locationService)
const locationServiceProvider = LocationServiceProvider._();

final class LocationServiceProvider
    extends $FunctionalProvider<LocationService, LocationService, LocationService>
    with $Provider<LocationService> {
  const LocationServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'locationServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$locationServiceHash();

  @$internal
  @override
  $ProviderElement<LocationService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocationService create(Ref ref) {
    return locationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationService>(value),
    );
  }
}

String _$locationServiceHash() => r'4c4dd57dd4144057ab2361e237186dacd0d0ca2d';

@ProviderFor(categories)
const categoriesProvider = CategoriesProvider._();

final class CategoriesProvider extends $FunctionalProvider<AsyncValue<List<ListingCategory>>,
        List<ListingCategory>, FutureOr<List<ListingCategory>>>
    with $FutureModifier<List<ListingCategory>>, $FutureProvider<List<ListingCategory>> {
  const CategoriesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'categoriesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$categoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<ListingCategory>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<ListingCategory>> create(Ref ref) {
    return categories(ref);
  }
}

String _$categoriesHash() => r'a403df085289ccd1b174ad109da707cc8985dc45';

@ProviderFor(promos)
const promosProvider = PromosProvider._();

final class PromosProvider
    extends $FunctionalProvider<AsyncValue<List<Promo>>, List<Promo>, FutureOr<List<Promo>>>
    with $FutureModifier<List<Promo>>, $FutureProvider<List<Promo>> {
  const PromosProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'promosProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$promosHash();

  @$internal
  @override
  $FutureProviderElement<List<Promo>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Promo>> create(Ref ref) {
    return promos(ref);
  }
}

String _$promosHash() => r'ac0ddc16bfc60fbad23252b553664ce6b6338bd4';

@ProviderFor(homeBadges)
const homeBadgesProvider = HomeBadgesProvider._();

final class HomeBadgesProvider
    extends $FunctionalProvider<AsyncValue<HomeBadges>, HomeBadges, FutureOr<HomeBadges>>
    with $FutureModifier<HomeBadges>, $FutureProvider<HomeBadges> {
  const HomeBadgesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'homeBadgesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$homeBadgesHash();

  @$internal
  @override
  $FutureProviderElement<HomeBadges> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<HomeBadges> create(Ref ref) {
    return homeBadges(ref);
  }
}

String _$homeBadgesHash() => r'440a92ddc37a00f9b77eb38c9e88012fd978da55';

/// Featured and nearby listings for the chosen place; empty until a place is known.

@ProviderFor(featuredListings)
const featuredListingsProvider = FeaturedListingsProvider._();

/// Featured and nearby listings for the chosen place; empty until a place is known.

final class FeaturedListingsProvider
    extends $FunctionalProvider<AsyncValue<List<Listing>>, List<Listing>, FutureOr<List<Listing>>>
    with $FutureModifier<List<Listing>>, $FutureProvider<List<Listing>> {
  /// Featured and nearby listings for the chosen place; empty until a place is known.
  const FeaturedListingsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'featuredListingsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$featuredListingsHash();

  @$internal
  @override
  $FutureProviderElement<List<Listing>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Listing>> create(Ref ref) {
    return featuredListings(ref);
  }
}

String _$featuredListingsHash() => r'fa37a618af07d1d8fc7f936169422f1dbac19e38';

/// The place Home measures "near you" from: an address the user chose, otherwise the device
/// location when permission is given.

@ProviderFor(HomeLocationController)
const homeLocationControllerProvider = HomeLocationControllerProvider._();

/// The place Home measures "near you" from: an address the user chose, otherwise the device
/// location when permission is given.
final class HomeLocationControllerProvider
    extends $AsyncNotifierProvider<HomeLocationController, HomeLocationState> {
  /// The place Home measures "near you" from: an address the user chose, otherwise the device
  /// location when permission is given.
  const HomeLocationControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'homeLocationControllerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$homeLocationControllerHash();

  @$internal
  @override
  HomeLocationController create() => HomeLocationController();
}

String _$homeLocationControllerHash() => r'0e848525a52551a56d2a7ead379251fe804dd8be';

/// The place Home measures "near you" from: an address the user chose, otherwise the device
/// location when permission is given.

abstract class _$HomeLocationController extends $AsyncNotifier<HomeLocationState> {
  FutureOr<HomeLocationState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<HomeLocationState>, HomeLocationState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<HomeLocationState>, HomeLocationState>,
        AsyncValue<HomeLocationState>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
