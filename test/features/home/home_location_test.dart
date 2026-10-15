import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valuex_mobile/core/constants/storage_keys.dart';
import 'package:valuex_mobile/core/storage/preferences_service.dart';
import 'package:valuex_mobile/features/address/domain/saved_address.dart';
import 'package:valuex_mobile/features/home/domain/entities/home_location.dart';
import 'package:valuex_mobile/features/home/domain/services/location_service.dart';
import 'package:valuex_mobile/features/home/presentation/providers/home_providers.dart';

import '../../helpers/fake_location_service.dart';

void main() {
  const mumbai = HomeLocation(area: 'Andheri (East)', city: 'Mumbai', state: 'Maharashtra');
  const pune = HomeLocation(city: 'Pune', state: 'Maharashtra', pincode: '411014');
  const puneHome = SavedAddress(
    id: 'a-1',
    label: 'Home',
    address: '12 FC Road, Shivajinagar',
    landmark: 'Flat 4',
    city: 'Pune',
    state: 'Maharashtra',
    pincode: '411014',
  );

  ProviderContainer containerWith(FakeLocationService service) {
    final container = ProviderContainer(
      overrides: [locationServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('HomeLocation', () {
    test('shows the area first, then the city and state', () {
      expect(mumbai.title, 'Andheri (East)');
      expect(mumbai.subtitle, 'Mumbai, Maharashtra');
      expect(pune.title, 'Pune');
    });

    test('survives being saved and read back', () {
      expect(HomeLocation.tryParse(mumbai.toJson()), mumbai);
      expect(HomeLocation.tryParse(pune.toJson()), pune);
    });

    test('ignores damaged or empty saved data', () {
      expect(HomeLocation.tryParse(null), isNull);
      expect(HomeLocation.tryParse('not json'), isNull);
      expect(HomeLocation.tryParse('{"city": ""}'), isNull);
    });
  });

  group('HomeLocationController', () {
    test('uses the device location when permission is given', () async {
      final container = containerWith(FakeLocationService());

      final state = await container.read(homeLocationControllerProvider.future);

      expect(state, isA<LocationKnown>());
      expect((state as LocationKnown).location, mumbai);
    });

    test('prefers a saved address the user chose over the device', () async {
      SharedPreferences.setMockInitialValues({StorageKeys.homeLocation: pune.toJson()});
      final container = containerWith(FakeLocationService());

      final state = await container.read(homeLocationControllerProvider.future);

      expect((state as LocationKnown).location, pune);
    });

    test('asks first when permission was never requested', () async {
      final container = containerWith(FakeLocationService(state: LocationAccess.denied));

      final state = await container.read(homeLocationControllerProvider.future);

      expect((state as LocationNeeded).reason, LocationNeed.notAsked);
    });

    test('reports a permanent refusal and a switched-off service', () async {
      final forever = containerWith(FakeLocationService(state: LocationAccess.deniedForever));
      final off = containerWith(FakeLocationService(state: LocationAccess.serviceOff));

      expect(
        ((await forever.read(homeLocationControllerProvider.future)) as LocationNeeded).reason,
        LocationNeed.deniedForever,
      );
      expect(
        ((await off.read(homeLocationControllerProvider.future)) as LocationNeeded).reason,
        LocationNeed.serviceOff,
      );
    });

    test('says the location is unavailable when the device cannot find the place', () async {
      final container = containerWith(FakeLocationService(device: null));

      final state = await container.read(homeLocationControllerProvider.future);

      expect((state as LocationNeeded).reason, LocationNeed.unavailable);
    });

    test('asking again after a refusal reports denied', () async {
      final service = FakeLocationService(
        state: LocationAccess.denied,
        afterRequest: LocationAccess.denied,
      );
      final container = containerWith(service);
      await container.read(homeLocationControllerProvider.future);

      await container.read(homeLocationControllerProvider.notifier).useDeviceLocation();

      final state = container.read(homeLocationControllerProvider).value;
      expect((state as LocationNeeded).reason, LocationNeed.denied);
      expect(service.requests, 1);
    });

    test('choosing a saved address keeps its city on the device, and using the device forgets it',
        () async {
      final container = containerWith(FakeLocationService());
      await container.read(homeLocationControllerProvider.future);
      final controller = container.read(homeLocationControllerProvider.notifier);

      await controller.useSavedAddress(puneHome);
      expect(
          (container.read(homeLocationControllerProvider).value as LocationKnown).location, pune);
      expect(
        HomeLocation.tryParse(
          await container.read(preferencesServiceProvider).getString(StorageKeys.homeLocation),
        ),
        pune,
      );

      await controller.useDeviceLocation();
      expect(
        await container.read(preferencesServiceProvider).getString(StorageKeys.homeLocation),
        isNull,
      );
      expect(
          (container.read(homeLocationControllerProvider).value as LocationKnown).location, mumbai);
    });
  });

  group('featuredListingsProvider', () {
    test('is empty until a place is known', () async {
      final container = containerWith(FakeLocationService(state: LocationAccess.denied));

      expect(await container.read(featuredListingsProvider.future), isEmpty);
    });

    test('lists Boosted deals for a known place', () async {
      final container = containerWith(FakeLocationService());

      final listings = await container.read(featuredListingsProvider.future);

      expect(listings, isNotEmpty);
      expect(listings.where((listing) => listing.isBoosted), isNotEmpty);
    });
  });
}
