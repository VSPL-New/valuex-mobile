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
      );

      expect(config.isProd, isTrue);
      expect(config.aadhaarFlow, AadhaarFlow.thirdParty);
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
        ),
        throwsA(isA<AppConfigException>()),
      );
    });
  });
}
