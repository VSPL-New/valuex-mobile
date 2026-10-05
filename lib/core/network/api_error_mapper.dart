import 'package:dio/dio.dart';
import 'api_error.dart';
import 'api_response.dart';

class ApiErrorMapper {
  ApiErrorMapper._();

  static const String validationErrorCode = 'VALIDATION_ERROR';

  static ApiError fromDio(DioException e) {
    final inner = e.error;
    if (inner is ApiError) return inner;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiError(
            type: ApiErrorType.timeout, message: 'Request timed out');
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return const ApiError(
            type: ApiErrorType.network, message: 'No connection');
      case DioExceptionType.badResponse:
        return _fromResponse(e.response);
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return const ApiError(
            type: ApiErrorType.unknown, message: 'Unexpected error');
    }
  }

  static ApiError _fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode;
    final envelope = ApiResponse.tryParse<Object?>(response?.data);
    final message = envelope?.errorMessage ?? 'Request failed';

    if (status == 401) {
      return ApiError(
        type: ApiErrorType.unauthorized,
        message: message,
        code: envelope?.errorCode,
        statusCode: status,
      );
    }
    if (status != null && status >= 500) {
      return ApiError(
        type: ApiErrorType.server,
        message: message,
        code: envelope?.errorCode,
        statusCode: status,
      );
    }
    return ApiError(
      type: envelope?.errorCode == validationErrorCode
          ? ApiErrorType.validation
          : ApiErrorType.business,
      message: message,
      code: envelope?.errorCode,
      statusCode: status,
      details: envelope?.errorDetails ?? const {},
    );
  }
}
