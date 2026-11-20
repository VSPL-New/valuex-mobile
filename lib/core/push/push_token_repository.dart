import '../constants/api_constants.dart';
import '../network/api_client.dart';

/// Tells the server which phone belongs to the signed-in person (US-131). Failures surface as
/// `ApiError`; the callers treat them as "try again later", because push is best effort.
class PushTokenRepository {
  final ApiClient _client;

  PushTokenRepository(this._client);

  Future<void> register({
    required String deviceId,
    required String platform,
    required String token,
    required String locale,
    required String appVersion,
    required bool permissionGranted,
  }) =>
      _client.put<void>(
        ApiConstants.devicePushToken,
        data: {
          'deviceId': deviceId,
          'platform': platform,
          'token': token,
          'locale': locale,
          'appVersion': appVersion,
          'permissionGranted': permissionGranted,
        },
      );

  Future<void> unregister(String deviceId) =>
      _client.delete<void>(ApiConstants.devicePushToken, data: {'deviceId': deviceId});
}
