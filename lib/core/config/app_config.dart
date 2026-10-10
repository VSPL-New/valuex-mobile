import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnv { dev, staging, prod }

enum AadhaarFlow { sandbox, thirdParty }

/// `mock` sends a made-up account to a backend running the mock Google verifier;
/// `native` shows the real Google account chooser.
enum GoogleSignInMode { mock, native }

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
  final GoogleSignInMode googleSignIn;

  /// OAuth web client ID; the ID token's audience, which the backend verifies.
  final String googleServerClientId;

  /// OAuth iOS client ID; empty when it is supplied through Info.plist instead.
  final String googleIosClientId;

  const AppConfig._({
    required this.env,
    required this.apiBaseUrl,
    required this.aadhaarFlow,
    required this.googleSignIn,
    required this.googleServerClientId,
    required this.googleIosClientId,
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig.parse(
      env: const String.fromEnvironment('ENV'),
      apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
      aadhaarFlow: const String.fromEnvironment('AADHAAR_FLOW'),
      googleSignIn: const String.fromEnvironment('GOOGLE_SIGN_IN', defaultValue: 'mock'),
      googleServerClientId: const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
      googleIosClientId: const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
    );
  }

  factory AppConfig.parse({
    required String env,
    required String apiBaseUrl,
    required String aadhaarFlow,
    String googleSignIn = 'mock',
    String googleServerClientId = '',
    String googleIosClientId = '',
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

    final parsedGoogle = switch (googleSignIn) {
      'mock' => GoogleSignInMode.mock,
      'native' => GoogleSignInMode.native,
      _ => throw AppConfigException(
          'GOOGLE_SIGN_IN must be mock or native (got "$googleSignIn")',
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
    if (parsedEnv == AppEnv.prod && parsedGoogle == GoogleSignInMode.mock) {
      throw const AppConfigException('The mock Google sign-in is not allowed in prod');
    }
    if (parsedGoogle == GoogleSignInMode.native && googleServerClientId.isEmpty) {
      throw const AppConfigException(
          'GOOGLE_SERVER_CLIENT_ID is required for native Google sign-in');
    }

    return AppConfig._(
      env: parsedEnv,
      apiBaseUrl:
          apiBaseUrl.endsWith('/') ? apiBaseUrl.substring(0, apiBaseUrl.length - 1) : apiBaseUrl,
      aadhaarFlow: parsedFlow,
      googleSignIn: parsedGoogle,
      googleServerClientId: googleServerClientId,
      googleIosClientId: googleIosClientId,
    );
  }

  bool get isProd => env == AppEnv.prod;

  bool get useAadhaarSandbox => aadhaarFlow == AadhaarFlow.sandbox;

  bool get useMockGoogleSignIn => googleSignIn == GoogleSignInMode.mock;
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider must be overridden in main()'),
);
