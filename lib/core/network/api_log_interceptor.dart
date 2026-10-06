import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs method, path and status only; never bodies, headers or query strings
/// (OTPs, Aadhaar numbers and tokens travel in them).
class ApiLogInterceptor extends Interceptor {
  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _log('${response.requestOptions.method} ${response.requestOptions.uri.path} '
        '-> ${response.statusCode}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log('${err.requestOptions.method} ${err.requestOptions.uri.path} '
        'failed: ${err.type.name} ${err.response?.statusCode ?? ''}');
    handler.next(err);
  }

  void _log(String message) {
    if (kDebugMode) developer.log(message, name: 'api');
  }
}
