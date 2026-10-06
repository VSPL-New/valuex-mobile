import 'account_status.dart';

class AuthSession {
  final String accessToken;
  final String refreshToken;
  final String userId;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
  });
}

/// Outcome of an endpoint that issues tokens.
class AuthResult {
  final AuthSession session;
  final AccountStatus status;
  final bool aadhaarVerified;

  const AuthResult({
    required this.session,
    required this.status,
    required this.aadhaarVerified,
  });
}
