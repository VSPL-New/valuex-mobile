import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/services/google_id_token_source.dart';

/// Shows the Google account chooser and returns the ID token the backend verifies.
class NativeGoogleIdTokenSource implements GoogleIdTokenSource {
  final String _serverClientId;
  final String? _iosClientId;
  Future<void>? _initialized;

  NativeGoogleIdTokenSource({required String serverClientId, String? iosClientId})
      : _serverClientId = serverClientId,
        _iosClientId = (iosClientId == null || iosClientId.isEmpty) ? null : iosClientId;

  Future<void> _initialize() {
    return _initialized ??= GoogleSignIn.instance.initialize(
      clientId: _iosClientId,
      serverClientId: _serverClientId,
    );
  }

  @override
  Future<String?> idToken() async {
    try {
      await _initialize();
      final account = await GoogleSignIn.instance.authenticate();
      final token = account.authentication.idToken;
      if (token == null) throw const GoogleSignInUnavailable();
      // Forget the account so the next attempt shows the chooser again.
      unawaited(GoogleSignIn.instance.signOut().catchError((Object _) {}));
      return token;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      throw const GoogleSignInUnavailable();
    }
  }
}
