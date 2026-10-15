import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnv { dev, staging, prod }

enum AadhaarFlow { sandbox, thirdParty }

/// `mock` sends a made-up account to a backend running the mock Google verifier;
/// `native` shows the real Google account chooser.
enum GoogleSignInMode { mock, native }

/// `mock` suggests made-up Indian addresses without a key; `google` calls Google Places.
enum AddressSearchMode { mock, google }

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

  final AddressSearchMode addressSearch;

  /// Google Places API key, restricted per platform in Google Cloud; empty for the mock search.
  final String googlePlacesApiKey;

  /// SHA-1 of the Android signing certificate, sent so an Android-restricted key accepts the call.
  final String googlePlacesAndroidCert;

  const AppConfig._({
    required this.env,
    required this.apiBaseUrl,
    required this.aadhaarFlow,
    required this.googleSignIn,
    required this.googleServerClientId,
    required this.googleIosClientId,
    required this.addressSearch,
    required this.googlePlacesApiKey,
    required this.googlePlacesAndroidCert,
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig.parse(
      env: const String.fromEnvironment('ENV'),
      apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
      aadhaarFlow: const String.fromEnvironment('AADHAAR_FLOW'),
      googleSignIn: const String.fromEnvironment('GOOGLE_SIGN_IN', defaultValue: 'mock'),
      googleServerClientId: const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
      googleIosClientId: const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
      addressSearch: const String.fromEnvironment('ADDRESS_SEARCH', defaultValue: 'mock'),
      googlePlacesApiKey: const String.fromEnvironment('GOOGLE_PLACES_API_KEY'),
      googlePlacesAndroidCert: const String.fromEnvironment('GOOGLE_PLACES_ANDROID_CERT'),
    );
  }

  factory AppConfig.parse({
    required String env,
    required String apiBaseUrl,
    required String aadhaarFlow,
    String googleSignIn = 'mock',
    String googleServerClientId = '',
    String googleIosClientId = '',
    String addressSearch = 'mock',
    String googlePlacesApiKey = '',
    String googlePlacesAndroidCert = '',
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

    final parsedSearch = switch (addressSearch) {
      'mock' => AddressSearchMode.mock,
      'google' => AddressSearchMode.google,
      _ => throw AppConfigException(
          'ADDRESS_SEARCH must be mock or google (got "$addressSearch")',
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
    if (parsedEnv == AppEnv.prod && parsedSearch == AddressSearchMode.mock) {
      throw const AppConfigException('The mock address search is not allowed in prod');
    }
    if (parsedSearch == AddressSearchMode.google && googlePlacesApiKey.isEmpty) {
      throw const AppConfigException(
          'GOOGLE_PLACES_API_KEY is required for the Google address search');
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
      addressSearch: parsedSearch,
      googlePlacesApiKey: googlePlacesApiKey,
      googlePlacesAndroidCert: googlePlacesAndroidCert,
    );
  }

  bool get isProd => env == AppEnv.prod;

  bool get useAadhaarSandbox => aadhaarFlow == AadhaarFlow.sandbox;

  bool get useMockGoogleSignIn => googleSignIn == GoogleSignInMode.mock;

  bool get useMockAddressSearch => addressSearch == AddressSearchMode.mock;
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider must be overridden in main()'),
);
