import 'auth_session.dart';

/// What the server decided after receiving a Google ID token.
sealed class GoogleSignInResult {
  const GoogleSignInResult();
}

/// The Google account was already linked: tokens were issued (and stored).
class GoogleSignedIn extends GoogleSignInResult {
  final AuthResult auth;

  const GoogleSignedIn(this.auth);
}

/// First time for this Google account: a mobile number must be verified before an
/// account is created or linked.
class GoogleNeedsMobile extends GoogleSignInResult {
  final String socialSessionToken;
  final String email;

  const GoogleNeedsMobile({required this.socialSessionToken, required this.email});
}
