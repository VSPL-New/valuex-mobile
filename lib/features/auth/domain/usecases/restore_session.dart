import '../../../../core/network/api_error.dart';
import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

/// Reads the account state of the user stored on this device from the server.
class RestoreSession {
  static const _userNotFoundCode = 'ERROR_USER_NOT_FOUND';

  final AuthRepository _repository;

  RestoreSession(this._repository);

  /// Null when nobody is signed in or the stored session is no longer valid.
  /// Retryable failures (network, 5xx) are rethrown so the caller can offer a retry.
  Future<UserProfile?> call() async {
    if (!await _repository.hasSession()) return null;

    try {
      return await _repository.fetchProfile();
    } on ApiError catch (error) {
      if (error.type == ApiErrorType.sessionExpired || error.code == _userNotFoundCode) {
        await _repository.clearSession();
        return null;
      }
      rethrow;
    }
  }
}
