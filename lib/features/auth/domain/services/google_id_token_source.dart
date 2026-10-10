/// Gets a Google ID token for the account the user picks; the server verifies it.
abstract interface class GoogleIdTokenSource {
  /// Null when the user dismissed the account chooser.
  /// Throws [GoogleSignInUnavailable] when Google sign-in cannot run on this device.
  Future<String?> idToken();
}

class GoogleSignInUnavailable implements Exception {
  const GoogleSignInUnavailable();

  @override
  String toString() => 'GoogleSignInUnavailable';
}
