import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef FakeHandler = Future<ResponseBody> Function(RequestOptions options);

/// Routes every Dio request to [handler]; records the requests it saw.
class FakeHttpAdapter implements HttpClientAdapter {
  final FakeHandler handler;
  final List<RequestOptions> requests = [];

  FakeHttpAdapter(this.handler);

  static ResponseBody json(int status, Object body) {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  static ResponseBody ok(Object? data) =>
      json(200, {'success': true, 'data': data});

  static ResponseBody error(int status, String code, String message,
      {Map<String, String>? details}) {
    return json(status, {
      'success': false,
      'error': {
        'code': code,
        'message': message,
        if (details != null) 'details': details
      },
    });
  }

  int count(String path) => requests.where((r) => r.path == path).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}
