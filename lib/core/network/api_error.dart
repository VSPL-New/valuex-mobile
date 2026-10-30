enum ApiErrorType {
  network,
  timeout,
  server,
  unauthorized,
  sessionExpired,
  validation,
  business,
  unknown,
}

/// Mirrors the backend error body `{ code, message, details }`.
class ApiError implements Exception {
  final ApiErrorType type;
  final String message;
  final String? code;
  final int? statusCode;
  final Map<String, String> details;

  /// The envelope's `data` when an error response carries one (the restricted-item check does).
  final Object? data;

  const ApiError({
    required this.type,
    required this.message,
    this.code,
    this.statusCode,
    this.details = const {},
    this.data,
  });

  const ApiError.sessionExpired()
      : type = ApiErrorType.sessionExpired,
        message = 'Session expired',
        code = null,
        statusCode = 401,
        details = const {},
        data = null;

  /// Network, timeout and 5xx failures: the request may succeed on retry.
  bool get isRetryable =>
      type == ApiErrorType.network || type == ApiErrorType.timeout || type == ApiErrorType.server;

  @override
  String toString() => 'ApiError(type: $type, code: $code, statusCode: $statusCode)';
}
