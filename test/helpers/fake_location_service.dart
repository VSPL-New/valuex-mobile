import 'package:valuex_mobile/features/home/domain/entities/home_location.dart';
import 'package:valuex_mobile/features/home/domain/services/location_service.dart';

/// Stands in for the device: set [state] and [device] to describe what the phone would report.
class FakeLocationService implements LocationService {
  LocationAccess state;

  /// What the permission becomes after the user answers the request.
  LocationAccess afterRequest;
  HomeLocation? device;
  int requests = 0;
  int settingsOpened = 0;

  FakeLocationService({
    this.state = LocationAccess.granted,
    this.afterRequest = LocationAccess.granted,
    this.device = const HomeLocation(area: 'Andheri (East)', city: 'Mumbai', state: 'Maharashtra'),
  });

  @override
  Future<LocationAccess> access() async => state;

  @override
  Future<LocationAccess> request() async {
    requests++;
    state = afterRequest;
    return state;
  }

  @override
  Future<HomeLocation?> current() async => device;

  @override
  Future<void> openSettings() async => settingsOpened++;
}
