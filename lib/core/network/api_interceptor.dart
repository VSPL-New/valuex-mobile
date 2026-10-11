import 'package:dio/dio.dart';
import '../security/secure_storage_service.dart';
import 'api_error.dart';
import 'token_refresher.dart';

/// Per-request switches, set through `Options.extra`.
class ApiRequestFlags {
  ApiRequestFlags._();

  static const String authenticated = 'authenticated';
  static const String retried = 'retried';
}

/// Adds the bearer token and, on a 401, refreshes the session once and retries once.
class ApiInterceptor extends Interceptor {
  final Dio _dio;
  final SecureStorageService _storage;
  final TokenRefresher _refresher;

  ApiInterceptor(this._dio, this._storage, this._refresher);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra[ApiRequestFlags.authenticated] != false) {
      final token = await _storage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final isAuthenticated = options.extra[ApiRequestFlags.authenticated] != false;
    if (err.response?.statusCode != 401 || !isAuthenticated) {
      return handler.next(err);
    }

    if (options.extra[ApiRequestFlags.retried] == true) {
      await _refresher.expire();
      return handler.reject(_rejection(err, const ApiError.sessionExpired()));
    }

    final String? accessToken;
    try {
      accessToken = await _currentIfRenewed(options) ?? await _refresher.refresh();
    } on ApiError catch (error) {
      return handler.reject(_rejection(err, error));
    }
    if (accessToken == null) {
      return handler.reject(_rejection(err, const ApiError.sessionExpired()));
    }

    options.headers['Authorization'] = 'Bearer $accessToken';
    options.extra[ApiRequestFlags.retried] = true;
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.reject(retryError);
    }
  }

  /// A request that was sent before another call finished refreshing fails with the old
  /// token; retry it with the new one instead of spending another refresh token.
  Future<String?> _currentIfRenewed(RequestOptions options) async {
    final current = await _storage.getAccessToken();
    if (current == null || options.headers['Authorization'] == 'Bearer $current') return null;
    return current;
  }

  DioException _rejection(DioException source, ApiError error) {
    return DioException(
      requestOptions: source.requestOptions,
      response: source.response,
      type: DioExceptionType.unknown,
      error: error,
    );
  }
}
