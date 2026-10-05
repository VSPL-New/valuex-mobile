import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnv { dev, staging, prod }

enum AadhaarFlow { sandbox, thirdParty }

class AppConfigException implements Exception {
  final String message;

  const AppConfigException(this.message);

  @override
  String toString() => 'AppConfigException: $message';
}

/// Build-time configuration supplied with `--dart-define-from-file=config/<env>.json`.
class AppConfig {
  final AppEnv env;
  final String apiBaseUrl;
  final AadhaarFlow aadhaarFlow;

  const AppConfig._({
    required this.env,
    required this.apiBaseUrl,
    required this.aadhaarFlow,
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig.parse(
      env: const String.fromEnvironment('ENV'),
      apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
      aadhaarFlow: const String.fromEnvironment('AADHAAR_FLOW'),
    );
  }

  factory AppConfig.parse({
    required String env,
    required String apiBaseUrl,
    required String aadhaarFlow,
  }) {
    final parsedEnv = switch (env) {
      'dev' => AppEnv.dev,
      'staging' => AppEnv.staging,
      'prod' => AppEnv.prod,
      _ => throw AppConfigException(
          'ENV must be dev, staging or prod (got "$env"). '
          'Run with --dart-define-from-file=config/<file>.json',
        ),
    };

    final parsedFlow = switch (aadhaarFlow) {
      'sandbox' => AadhaarFlow.sandbox,
      'thirdparty' => AadhaarFlow.thirdParty,
      _ => throw AppConfigException(
          'AADHAAR_FLOW must be sandbox or thirdparty (got "$aadhaarFlow")',
        ),
    };

    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
      throw const AppConfigException('API_BASE_URL is missing or invalid');
    }
    if (parsedEnv != AppEnv.dev && uri.scheme != 'https') {
      throw const AppConfigException('API_BASE_URL must use https outside dev');
    }
    if (parsedEnv == AppEnv.prod && parsedFlow == AadhaarFlow.sandbox) {
      throw const AppConfigException('The Aadhaar sandbox flow is not allowed in prod');
    }

    return AppConfig._(
      env: parsedEnv,
      apiBaseUrl:
          apiBaseUrl.endsWith('/') ? apiBaseUrl.substring(0, apiBaseUrl.length - 1) : apiBaseUrl,
      aadhaarFlow: parsedFlow,
    );
  }

  bool get isProd => env == AppEnv.prod;

  bool get useAadhaarSandbox => aadhaarFlow == AadhaarFlow.sandbox;
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider must be overridden in main()'),
);
