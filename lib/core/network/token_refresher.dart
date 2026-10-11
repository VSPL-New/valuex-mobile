import 'dart:async';

import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../security/secure_storage_service.dart';
import 'api_error.dart';
import 'api_error_mapper.dart';
import 'api_response.dart';
import 'session_event.dart';

/// Exchanges the stored refresh token for a new pair; concurrent callers share one request.
class TokenRefresher {
  static const _suspendedCode = 'ERROR_ACCOUNT_SUSPENDED';
  static const _recoveryRequiredCode = 'ERROR_ACCOUNT_RECOVERY_REQUIRED';

  final SecureStorageService _storage;
  final Dio _dio;
  final _events = StreamController<SessionEvent>.broadcast();
  Future<String?>? _inFlight;

  TokenRefresher(this._storage, this._dio);

  /// Emits after each refresh and when the session can no longer be renewed.
  Stream<SessionEvent> get events => _events.stream;

  /// Returns the new access token, or null when the session has expired.
  /// Throws a retryable [ApiError] when the failure is transient, keeping the tokens.
  Future<String?> refresh() {
    return _inFlight ??= _refresh().whenComplete(() => _inFlight = null);
  }

  Future<void> expire([SessionEndReason reason = SessionEndReason.expired]) async {
    await _storage.clearSession();
    _events.add(SessionEnded(reason));
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
        throw const ApiError(type: ApiErrorType.server, message: 'Invalid refresh response');
      }
      await _storage.saveAccessToken(accessToken);
      await _storage.saveRefreshToken(newRefreshToken);
      _events.add(SessionRefreshed(
        status: data?['status'] as String?,
        aadhaarVerified: data?['aadhaarVerified'] as bool?,
      ));
      return accessToken;
    } on DioException catch (e) {
      final error = ApiErrorMapper.fromDio(e);
      if (error.isRetryable) throw error;
      await expire(switch (error.code) {
        _suspendedCode => SessionEndReason.suspended,
        _recoveryRequiredCode => SessionEndReason.recoveryRequired,
        _ => SessionEndReason.expired,
      });
      return null;
    }
  }

  void dispose() => _events.close();
}
