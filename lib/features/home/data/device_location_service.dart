import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import '../domain/entities/home_location.dart';
import '../domain/services/location_service.dart';

/// Reads the approximate device location and turns it into an area and city.
/// Coordinates stay inside this class and are never stored or logged.
class DeviceLocationService implements LocationService {
  const DeviceLocationService();

  @override
  Future<LocationAccess> access() async {
    if (!await GeolocatorPlatform.instance.isLocationServiceEnabled()) {
      return LocationAccess.serviceOff;
    }
    return _map(await GeolocatorPlatform.instance.checkPermission());
  }

  @override
  Future<LocationAccess> request() async {
    if (!await GeolocatorPlatform.instance.isLocationServiceEnabled()) {
      return LocationAccess.serviceOff;
    }
    return _map(await GeolocatorPlatform.instance.requestPermission());
  }

  @override
  Future<HomeLocation?> current() async {
    try {
      final position = await _position();
      if (position == null) return null;
      final places =
          await Geocoding().placemarkFromCoordinates(position.latitude, position.longitude);
      if (places.isEmpty) return null;
      final place = places.first;
      final city = place.locality ?? place.subAdministrativeArea;
      if (city == null || city.isEmpty) return null;
      return HomeLocation(city: city, area: place.subLocality, state: place.administrativeArea);
    } on Exception {
      return null;
    }
  }

  @override
  Future<void> openSettings() async {
    await GeolocatorPlatform.instance.openAppSettings();
  }

  /// A fresh fix; when none arrives in time (emulators, weak signal) the last known one.
  Future<Position?> _position() async {
    try {
      return await GeolocatorPlatform.instance.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } on TimeoutException {
      return GeolocatorPlatform.instance.getLastKnownPosition();
    }
  }

  LocationAccess _map(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.always || LocationPermission.whileInUse => LocationAccess.granted,
      LocationPermission.deniedForever => LocationAccess.deniedForever,
      LocationPermission.denied || LocationPermission.unableToDetermine => LocationAccess.denied,
    };
  }
}
