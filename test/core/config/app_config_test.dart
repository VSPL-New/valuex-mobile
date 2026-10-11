import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/config/app_config.dart';

void main() {
  group('AppConfig.parse', () {
    test('parses a valid dev config and trims the trailing slash', () {
      final config = AppConfig.parse(
        env: 'dev',
        apiBaseUrl: 'http://10.0.2.2:8080/api/v1/',
        aadhaarFlow: 'sandbox',
      );

      expect(config.env, AppEnv.dev);
      expect(config.apiBaseUrl, 'http://10.0.2.2:8080/api/v1');
      expect(config.useAadhaarSandbox, isTrue);
      expect(config.isProd, isFalse);
    });

    test('parses a valid prod config', () {
      final config = AppConfig.parse(
        env: 'prod',
        apiBaseUrl: 'https://api.example.com/api/v1',
        aadhaarFlow: 'thirdparty',
        googleSignIn: 'native',
        googleServerClientId: 'web-client-id',
      );

      expect(config.isProd, isTrue);
      expect(config.aadhaarFlow, AadhaarFlow.thirdParty);
      expect(config.googleSignIn, GoogleSignInMode.native);
      expect(config.googleServerClientId, 'web-client-id');
    });

    test('Google sign-in is mocked by default outside prod', () {
      final config = AppConfig.parse(
        env: 'dev',
        apiBaseUrl: 'http://localhost:8080/api/v1',
        aadhaarFlow: 'sandbox',
      );

      expect(config.useMockGoogleSignIn, isTrue);
    });

    test('rejects an unknown Google sign-in mode', () {
      expect(
        () => AppConfig.parse(
          env: 'dev',
          apiBaseUrl: 'http://localhost:8080/api/v1',
          aadhaarFlow: 'sandbox',
          googleSignIn: 'fake',
        ),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('rejects the mock Google sign-in in prod', () {
      expect(
        () => AppConfig.parse(
          env: 'prod',
          apiBaseUrl: 'https://api.example.com/api/v1',
          aadhaarFlow: 'thirdparty',
        ),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('native Google sign-in needs the server client ID', () {
      expect(
        () => AppConfig.parse(
          env: 'dev',
          apiBaseUrl: 'http://localhost:8080/api/v1',
          aadhaarFlow: 'sandbox',
          googleSignIn: 'native',
        ),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('fails fast when values are missing', () {
      expect(
        () => AppConfig.parse(env: '', apiBaseUrl: '', aadhaarFlow: ''),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('rejects an unknown Aadhaar flow', () {
      expect(
        () => AppConfig.parse(
          env: 'dev',
          apiBaseUrl: 'http://localhost:8080/api/v1',
          aadhaarFlow: 'other',
        ),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('rejects a missing base URL', () {
      expect(
        () => AppConfig.parse(env: 'dev', apiBaseUrl: '', aadhaarFlow: 'sandbox'),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('requires https outside dev', () {
      expect(
        () => AppConfig.parse(
          env: 'staging',
          apiBaseUrl: 'http://staging.example.com/api/v1',
          aadhaarFlow: 'sandbox',
        ),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('rejects the Aadhaar sandbox flow in prod', () {
      expect(
        () => AppConfig.parse(
          env: 'prod',
          apiBaseUrl: 'https://api.example.com/api/v1',
          aadhaarFlow: 'sandbox',
          googleSignIn: 'native',
          googleServerClientId: 'web-client-id',
        ),
        throwsA(isA<AppConfigException>()),
      );
    });
  });
}
