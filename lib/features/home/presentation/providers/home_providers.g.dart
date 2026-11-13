// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(homeRepository)
final homeRepositoryProvider = HomeRepositoryProvider._();

final class HomeRepositoryProvider
    extends $FunctionalProvider<HomeRepository, HomeRepository, HomeRepository>
    with $Provider<HomeRepository> {
  HomeRepositoryProvider._()
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

String _$homeRepositoryHash() => r'2b8375cb614157cbbaa28ed1a7dde1a907e5b057';

@ProviderFor(locationService)
final locationServiceProvider = LocationServiceProvider._();

final class LocationServiceProvider
    extends $FunctionalProvider<LocationService, LocationService, LocationService>
    with $Provider<LocationService> {
  LocationServiceProvider._()
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

@ProviderFor(promos)
final promosProvider = PromosProvider._();

final class PromosProvider
    extends $FunctionalProvider<AsyncValue<List<Promo>>, List<Promo>, FutureOr<List<Promo>>>
    with $FutureModifier<List<Promo>>, $FutureProvider<List<Promo>> {
  PromosProvider._()
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
final homeBadgesProvider = HomeBadgesProvider._();

final class HomeBadgesProvider
    extends $FunctionalProvider<AsyncValue<HomeBadges>, HomeBadges, FutureOr<HomeBadges>>
    with $FutureModifier<HomeBadges>, $FutureProvider<HomeBadges> {
  HomeBadgesProvider._()
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
final featuredListingsProvider = FeaturedListingsProvider._();

/// Featured and nearby listings for the chosen place; empty until a place is known.

final class FeaturedListingsProvider
    extends $FunctionalProvider<AsyncValue<List<Listing>>, List<Listing>, FutureOr<List<Listing>>>
    with $FutureModifier<List<Listing>>, $FutureProvider<List<Listing>> {
  /// Featured and nearby listings for the chosen place; empty until a place is known.
  FeaturedListingsProvider._()
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

String _$featuredListingsHash() => r'96315245719bc121925bf7836cc195478be804d6';

/// The place Home measures "near you" from: one of the user's saved addresses, otherwise the
/// device location when permission is given. The place is only used to find listings; it is kept
/// on the device and never saved as an address.

@ProviderFor(HomeLocationController)
final homeLocationControllerProvider = HomeLocationControllerProvider._();

/// The place Home measures "near you" from: one of the user's saved addresses, otherwise the
/// device location when permission is given. The place is only used to find listings; it is kept
/// on the device and never saved as an address.
final class HomeLocationControllerProvider
    extends $AsyncNotifierProvider<HomeLocationController, HomeLocationState> {
  /// The place Home measures "near you" from: one of the user's saved addresses, otherwise the
  /// device location when permission is given. The place is only used to find listings; it is kept
  /// on the device and never saved as an address.
  HomeLocationControllerProvider._()
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

String _$homeLocationControllerHash() => r'c931ef2a5688e438c5b60630b4e7a3a43731eaf2';

/// The place Home measures "near you" from: one of the user's saved addresses, otherwise the
/// device location when permission is given. The place is only used to find listings; it is kept
/// on the device and never saved as an address.

abstract class _$HomeLocationController extends $AsyncNotifier<HomeLocationState> {
  FutureOr<HomeLocationState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<HomeLocationState>, HomeLocationState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<HomeLocationState>, HomeLocationState>,
        AsyncValue<HomeLocationState>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
