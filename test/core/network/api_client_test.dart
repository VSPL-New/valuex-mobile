import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/network/session_event.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_secure_storage.dart';

final _config = AppConfig.parse(
  env: 'dev',
  apiBaseUrl: 'http://localhost:8080/api/v1',
  aadhaarFlow: 'sandbox',
);

ApiClient _client(FakeSecureStorage storage, FakeHttpAdapter adapter) {
  return ApiClient(storage, _config, adapter: adapter);
}

Future<ApiError> _expectError(Future<Object?> call) async {
  try {
    await call;
  } on ApiError catch (e) {
    return e;
  }
  fail('Expected an ApiError');
}

void main() {
  group('envelope and errors', () {
    test('unwraps the data field and parses it', () async {
      final adapter = FakeHttpAdapter((_) async => FakeHttpAdapter.ok({'status': 'ACTIVE'}));
      final client = _client(FakeSecureStorage(), adapter);

      final status = await client.get<String>(
        '/users/me',
        parse: (data) => (data as Map<String, dynamic>)['status'] as String,
      );

      expect(status, 'ACTIVE');
    });

    test('maps a business error to its code and message', () async {
      final adapter = FakeHttpAdapter(
        (_) async => FakeHttpAdapter.error(400, 'ERROR_INVALID_OTP', 'Invalid or expired OTP'),
      );
      final client = _client(FakeSecureStorage(), adapter);

      final error = await _expectError(client.post<Object?>('/x', authenticated: false));

      expect(error.type, ApiErrorType.business);
      expect(error.code, 'ERROR_INVALID_OTP');
      expect(error.statusCode, 400);
    });

    test('maps field validation errors with details', () async {
      final adapter = FakeHttpAdapter(
        (_) async => FakeHttpAdapter.error(
          400,
          'VALIDATION_ERROR',
          'Request validation failed',
          details: {'mobile': 'Invalid mobile'},
        ),
      );
      final client = _client(FakeSecureStorage(), adapter);

      final error = await _expectError(client.post<Object?>('/x', authenticated: false));

      expect(error.type, ApiErrorType.validation);
      expect(error.details['mobile'], 'Invalid mobile');
    });

    test('maps 5xx to a server error', () async {
      final adapter = FakeHttpAdapter(
        (_) async => FakeHttpAdapter.error(500, 'INTERNAL_ERROR', 'boom'),
      );
      final client = _client(FakeSecureStorage(), adapter);

      final error = await _expectError(client.get<Object?>('/x', authenticated: false));

      expect(error.type, ApiErrorType.server);
      expect(error.isRetryable, isTrue);
    });

    test('maps connection failures to a network error', () async {
      final adapter = FakeHttpAdapter((options) async {
        throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
      });
      final client = _client(FakeSecureStorage(), adapter);

      final error = await _expectError(client.get<Object?>('/x', authenticated: false));

      expect(error.type, ApiErrorType.network);
    });

    test('maps timeouts to a timeout error', () async {
      final adapter = FakeHttpAdapter((options) async {
        throw DioException(requestOptions: options, type: DioExceptionType.receiveTimeout);
      });
      final client = _client(FakeSecureStorage(), adapter);

      final error = await _expectError(client.get<Object?>('/x', authenticated: false));

      expect(error.type, ApiErrorType.timeout);
    });

    test('a non-envelope success body is an error', () async {
      final adapter = FakeHttpAdapter((_) async => FakeHttpAdapter.json(200, {'foo': 1}));
      final client = _client(FakeSecureStorage(), adapter);

      final error = await _expectError(client.get<Object?>('/x', authenticated: false));

      expect(error.type, ApiErrorType.server);
    });
  });

  group('headers', () {
    test('adds the bearer token and a correlation id to authenticated calls', () async {
      final adapter = FakeHttpAdapter((_) async => FakeHttpAdapter.ok(null));
      final client = _client(FakeSecureStorage(accessToken: 'access-1'), adapter);

      await client.get<Object?>('/users/me');

      final headers = adapter.requests.single.headers;
      expect(headers['Authorization'], 'Bearer access-1');
      expect(headers['X-Correlation-Id'], isNotEmpty);
    });

    test('sends no bearer token to public endpoints', () async {
      final adapter = FakeHttpAdapter((_) async => FakeHttpAdapter.ok(null));
      final client = _client(FakeSecureStorage(accessToken: 'access-1'), adapter);

      await client.post<Object?>('/auth/register/initiate', authenticated: false);

      expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('refresh once on 401', () {
    ResponseBody tokens(String access, String refresh) {
      return FakeHttpAdapter.ok({'accessToken': access, 'refreshToken': refresh});
    }

    test('refreshes the tokens and retries the request once', () async {
      final storage = FakeSecureStorage(accessToken: 'old', refreshToken: 'refresh-1');
      final adapter = FakeHttpAdapter((options) async {
        if (options.path == '/auth/refresh') return tokens('new', 'refresh-2');
        return options.headers['Authorization'] == 'Bearer new'
            ? FakeHttpAdapter.ok({'ok': true})
            : FakeHttpAdapter.error(401, 'UNAUTHORIZED', 'expired');
      });
      final client = _client(storage, adapter);

      final result = await client.get<Object?>('/users/me');

      expect(result, {'ok': true});
      expect(adapter.count('/users/me'), 2);
      expect(adapter.count('/auth/refresh'), 1);
      expect(storage.accessToken, 'new');
      expect(storage.refreshToken, 'refresh-2');
    });

    test('concurrent 401s share one refresh request', () async {
      final storage = FakeSecureStorage(accessToken: 'old', refreshToken: 'refresh-1');
      final adapter = FakeHttpAdapter((options) async {
        if (options.path == '/auth/refresh') return tokens('new', 'refresh-2');
        return options.headers['Authorization'] == 'Bearer new'
            ? FakeHttpAdapter.ok({'ok': true})
            : FakeHttpAdapter.error(401, 'UNAUTHORIZED', 'expired');
      });
      final client = _client(storage, adapter);

      await Future.wait([client.get<Object?>('/a'), client.get<Object?>('/b')]);

      expect(adapter.count('/auth/refresh'), 1);
    });

    test('an expired refresh token clears the session', () async {
      final storage = FakeSecureStorage(accessToken: 'old', refreshToken: 'refresh-1');
      final adapter = FakeHttpAdapter((options) async {
        if (options.path == '/auth/refresh') {
          return FakeHttpAdapter.error(400, 'ERROR_REFRESH_TOKEN_EXPIRED', 'expired');
        }
        return FakeHttpAdapter.error(401, 'UNAUTHORIZED', 'expired');
      });
      final client = _client(storage, adapter);
      final events = <SessionEvent>[];
      client.sessionEvents.listen(events.add);

      final error = await _expectError(client.get<Object?>('/users/me'));
      await Future<void>.delayed(Duration.zero);

      expect(error.type, ApiErrorType.sessionExpired);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(events.single, isA<SessionEnded>());
      expect((events.single as SessionEnded).reason, SessionEndReason.expired);
    });

    for (final (code, reason) in [
      ('ERROR_ACCOUNT_SUSPENDED', SessionEndReason.suspended),
      ('ERROR_ACCOUNT_RECOVERY_REQUIRED', SessionEndReason.recoveryRequired),
      ('ERROR_INVALID_REFRESH_TOKEN', SessionEndReason.expired),
      ('ERROR_WRONG_TOKEN_TYPE', SessionEndReason.expired),
    ]) {
      test('refresh failing with $code ends the session as $reason', () async {
        final storage = FakeSecureStorage(accessToken: 'old', refreshToken: 'refresh-1');
        final adapter = FakeHttpAdapter((options) async {
          if (options.path == '/auth/refresh') {
            return FakeHttpAdapter.error(400, code, 'message');
          }
          return FakeHttpAdapter.error(401, 'UNAUTHORIZED', 'expired');
        });
        final client = _client(storage, adapter);
        final events = <SessionEvent>[];
        client.sessionEvents.listen(events.add);

        final error = await _expectError(client.get<Object?>('/users/me'));
        await Future<void>.delayed(Duration.zero);

        expect(error.type, ApiErrorType.sessionExpired);
        expect(storage.refreshToken, isNull);
        expect((events.single as SessionEnded).reason, reason);
      });
    }

    test('a successful refresh reports the account state the server read', () async {
      final storage = FakeSecureStorage(accessToken: 'old', refreshToken: 'refresh-1');
      final adapter = FakeHttpAdapter((options) async {
        if (options.path == '/auth/refresh') {
          return FakeHttpAdapter.ok({
            'accessToken': 'new',
            'refreshToken': 'refresh-2',
            'status': 'ACTIVE',
            'aadhaarVerified': true,
          });
        }
        return options.headers['Authorization'] == 'Bearer new'
            ? FakeHttpAdapter.ok({'ok': true})
            : FakeHttpAdapter.error(401, 'UNAUTHORIZED', 'expired');
      });
      final client = _client(storage, adapter);
      final events = <SessionEvent>[];
      client.sessionEvents.listen(events.add);

      await client.get<Object?>('/users/me');
      await Future<void>.delayed(Duration.zero);

      final refreshed = events.single as SessionRefreshed;
      expect(refreshed.status, 'ACTIVE');
      expect(refreshed.aadhaarVerified, isTrue);
    });

    test(
        'a request that failed with a token another call already replaced is retried '
        'without a second refresh', () async {
      final storage = FakeSecureStorage(accessToken: 'old', refreshToken: 'refresh-1');
      late final ApiClient client;
      final adapter = FakeHttpAdapter((options) async {
        if (options.path == '/auth/refresh') return tokens('new', 'refresh-2');
        if (options.path == '/slow') {
          if (options.headers['Authorization'] == 'Bearer new') {
            return FakeHttpAdapter.ok({'ok': true});
          }
          // Another call finishes refreshing while this one is still in flight.
          await client.get<Object?>('/fast');
          return FakeHttpAdapter.error(401, 'UNAUTHORIZED', 'expired');
        }
        return options.headers['Authorization'] == 'Bearer new'
            ? FakeHttpAdapter.ok({'ok': true})
            : FakeHttpAdapter.error(401, 'UNAUTHORIZED', 'expired');
      });
      client = _client(storage, adapter);

      final result = await client.get<Object?>('/slow');

      expect(result, {'ok': true});
      expect(adapter.count('/auth/refresh'), 1);
      expect(adapter.count('/slow'), 2);
    });

    test('a missing refresh token ends the session without calling refresh', () async {
      final storage = FakeSecureStorage(accessToken: 'old');
      final adapter = FakeHttpAdapter(
        (_) async => FakeHttpAdapter.error(401, 'UNAUTHORIZED', 'expired'),
      );
      final client = _client(storage, adapter);

      final error = await _expectError(client.get<Object?>('/users/me'));

      expect(error.type, ApiErrorType.sessionExpired);
      expect(adapter.count('/auth/refresh'), 0);
    });

    test('a network failure during refresh keeps the tokens', () async {
      final storage = FakeSecureStorage(accessToken: 'old', refreshToken: 'refresh-1');
      final adapter = FakeHttpAdapter((options) async {
        if (options.path == '/auth/refresh') {
          throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
        }
        return FakeHttpAdapter.error(401, 'UNAUTHORIZED', 'expired');
      });
      final client = _client(storage, adapter);

      final error = await _expectError(client.get<Object?>('/users/me'));

      expect(error.type, ApiErrorType.network);
      expect(storage.refreshToken, 'refresh-1');
    });

    test('a second 401 after the retry is not refreshed again', () async {
      final storage = FakeSecureStorage(accessToken: 'old', refreshToken: 'refresh-1');
      final adapter = FakeHttpAdapter((options) async {
        if (options.path == '/auth/refresh') return tokens('new', 'refresh-2');
        return FakeHttpAdapter.error(401, 'UNAUTHORIZED', 'still rejected');
      });
      final client = _client(storage, adapter);

      final error = await _expectError(client.get<Object?>('/users/me'));

      expect(error.type, ApiErrorType.sessionExpired);
      expect(adapter.count('/auth/refresh'), 1);
      expect(adapter.count('/users/me'), 2);
    });

    test('public endpoints never trigger a refresh', () async {
      final storage = FakeSecureStorage(accessToken: 'old', refreshToken: 'refresh-1');
      final adapter = FakeHttpAdapter(
        (_) async => FakeHttpAdapter.error(401, 'UNAUTHORIZED', 'nope'),
      );
      final client = _client(storage, adapter);

      final error = await _expectError(client.post<Object?>('/auth/login', authenticated: false));

      expect(error.type, ApiErrorType.unauthorized);
      expect(adapter.count('/auth/refresh'), 0);
    });
  });
}
