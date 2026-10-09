import '../entities/home_location.dart';

enum LocationAccess {
  /// Permission given and the location service is on.
  granted,

  /// Not given yet, or refused once; asking again is allowed.
  denied,

  /// Refused for good; only the device settings can change it.
  deniedForever,

  /// The device location service is switched off.
  serviceOff,
}

abstract class LocationService {
  Future<LocationAccess> access();

  /// Asks the user for permission.
  Future<LocationAccess> request();

  /// Area and city of the device, or null when they cannot be found.
  Future<HomeLocation?> current();

  Future<void> openSettings();
}
