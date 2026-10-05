import 'dart:async';

import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../security/secure_storage_service.dart';
import 'api_error.dart';
import 'api_error_mapper.dart';
import 'api_response.dart';

/// Exchanges the stored refresh token for a new pair; concurrent callers share one request.
class TokenRefresher {
  final SecureStorageService _storage;
  final Dio _dio;
  final _expired = StreamController<void>.broadcast();
  Future<String?>? _inFlight;

  TokenRefresher(this._storage, this._dio);

  /// Emits when the session can no longer be renewed and the user must sign in again.
  Stream<void> get onSessionExpired => _expired.stream;

  /// Returns the new access token, or null when the session has expired.
  /// Throws a retryable [ApiError] when the failure is transient, keeping the tokens.
  Future<String?> refresh() {
    return _inFlight ??= _refresh().whenComplete(() => _inFlight = null);
  }

  Future<void> expire() async {
    await _storage.clearSession();
    _expired.add(null);
  }

  Future<String?> _refresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) {
      await expire();
      return null;
    }

    try {
      final response = await _dio.post<dynamic>(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      final data = ApiResponse.tryParse<Map<String, dynamic>>(
        response.data,
        parse: (raw) => raw as Map<String, dynamic>,
      )?.data;
      final accessToken = data?['accessToken'] as String?;
      final newRefreshToken = data?['refreshToken'] as String?;
      if (accessToken == null || newRefreshToken == null) {
        throw const ApiError(
            type: ApiErrorType.server, message: 'Invalid refresh response');
      }
      await _storage.saveAccessToken(accessToken);
      await _storage.saveRefreshToken(newRefreshToken);
      return accessToken;
    } on DioException catch (e) {
      final error = ApiErrorMapper.fromDio(e);
      if (error.isRetryable) throw error;
      await expire();
      return null;
    }
  }

  void dispose() => _expired.close();
}
