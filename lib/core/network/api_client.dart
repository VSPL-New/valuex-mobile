import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../security/secure_storage_service.dart';
import 'api_error.dart';
import 'api_error_mapper.dart';
import 'api_interceptor.dart';
import 'api_log_interceptor.dart';
import 'api_response.dart';
import 'session_event.dart';
import 'token_refresher.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    ref.watch(secureStorageServiceProvider),
    ref.watch(appConfigProvider),
  );
  ref.onDispose(client.dispose);
  return client;
});

/// All HTTP goes through this client: envelope unwrapping, typed errors,
/// bearer token and refresh-once on 401.
class ApiClient {
  static const _uuid = Uuid();

  late final Dio dio;
  late final TokenRefresher _refresher;

  ApiClient(
    SecureStorageService storage,
    AppConfig config, {
    HttpClientAdapter? adapter,
  }) {
    final options = BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Names this device in the active-sessions list; browsers do not allow the header.
        if (!kIsWeb)
          'User-Agent': 'JustQlic/${AppConstants.appVersion} (${defaultTargetPlatform.name})',
      },
    );

    // The refresh call must not pass through the interceptor that triggers it.
    final refreshDio = Dio(options);
    dio = Dio(options);
    if (adapter != null) {
      refreshDio.httpClientAdapter = adapter;
      dio.httpClientAdapter = adapter;
    }

    _refresher = TokenRefresher(storage, refreshDio);
    dio.interceptors.addAll([
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['X-Correlation-Id'] = _uuid.v4();
          handler.next(options);
        },
      ),
      ApiInterceptor(dio, storage, _refresher),
      ApiLogInterceptor(),
    ]);
  }

  /// Emits after each token refresh and when the session cannot be renewed.
  Stream<SessionEvent> get sessionEvents => _refresher.events;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
    T Function(Object? data)? parse,
  }) {
    return _send(
      () => dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: _options(authenticated),
      ),
      parse,
    );
  }

  /// [bearerToken] sends that token instead of the stored one, without a refresh on 401.
  Future<T> post<T>(
    String path, {
    Object? data,
    bool authenticated = true,
    String? bearerToken,
    T Function(Object? data)? parse,
  }) {
    return _send(
      () => dio.post<dynamic>(
        path,
        data: data,
        options: _options(authenticated && bearerToken == null, bearerToken: bearerToken),
      ),
      parse,
    );
  }

  Future<T> put<T>(
    String path, {
    Object? data,
    bool authenticated = true,
    T Function(Object? data)? parse,
  }) {
    return _send(
      () => dio.put<dynamic>(path, data: data, options: _options(authenticated)),
      parse,
    );
  }

  Future<T> patch<T>(
    String path, {
    Object? data,
    bool authenticated = true,
    T Function(Object? data)? parse,
  }) {
    return _send(
      () => dio.patch<dynamic>(path, data: data, options: _options(authenticated)),
      parse,
    );
  }

  Future<T> delete<T>(
    String path, {
    Object? data,
    bool authenticated = true,
    T Function(Object? data)? parse,
  }) {
    return _send(
      () => dio.delete<dynamic>(path, data: data, options: _options(authenticated)),
      parse,
    );
  }

  Options _options(bool authenticated, {String? bearerToken}) {
    return Options(
      extra: {ApiRequestFlags.authenticated: authenticated},
      headers: bearerToken == null ? null : {'Authorization': 'Bearer $bearerToken'},
    );
  }

  Future<T> _send<T>(
    Future<Response<dynamic>> Function() call,
    T Function(Object? data)? parse,
  ) async {
    final Response<dynamic> response;
    try {
      response = await call();
    } on DioException catch (e) {
      throw ApiErrorMapper.fromDio(e);
    }

    try {
      final envelope = ApiResponse.tryParse<T>(response.data, parse: parse);
      if (envelope == null || !envelope.success) {
        throw ApiError(
          type: ApiErrorType.server,
          message: envelope?.errorMessage ?? 'Unexpected response',
          code: envelope?.errorCode,
          statusCode: response.statusCode,
        );
      }
      return envelope.data as T;
    } on TypeError {
      throw ApiError(
        type: ApiErrorType.server,
        message: 'Unexpected response',
        statusCode: response.statusCode,
      );
    }
  }

  void dispose() {
    _refresher.dispose();
    dio.close();
  }
}
