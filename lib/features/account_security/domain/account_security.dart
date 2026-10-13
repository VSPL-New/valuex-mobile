/// `GET /users/me/account-security`: masked sign-in details and Aadhaar status.
class AccountSecurity {
  final String? mobile;
  final String? email;
  final bool aadhaarVerified;

  const AccountSecurity({this.mobile, this.email, required this.aadhaarVerified});
}

/// Which sign-in detail is being changed.
enum ContactKind { mobile, email }

/// One signed-in device from `GET /users/me/sessions`.
class ActiveSession {
  final String id;
  final String? deviceInfo;
  final String? ipAddress;
  final DateTime? lastActiveAt;
  final bool isCurrent;

  const ActiveSession({
    required this.id,
    this.deviceInfo,
    this.ipAddress,
    this.lastActiveAt,
    required this.isCurrent,
  });

  /// The app names itself in its User-Agent (`JustQlic/0.1.0 (iOS)`); anything else is shown
  /// as sent, and the Dart HTTP default (older sessions) carries no information.
  String? get deviceName {
    final raw = deviceInfo?.trim();
    if (raw == null || raw.isEmpty || raw.startsWith('Dart/')) return null;
    final app = RegExp(r'^JustQlic/\S+ \((.+)\)$').firstMatch(raw);
    if (app != null) return 'JustQlic \u00B7 ${app.group(1)}';
    return raw.length > 60 ? '${raw.substring(0, 60)}\u2026' : raw;
  }
}
