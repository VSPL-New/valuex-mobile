import 'account_status.dart';

class UserProfile {
  final String userId;
  final AccountStatus status;
  final bool aadhaarVerified;
  final String? mobile;
  final String? email;
  final String? displayName;
  final String? avatarId;
  final String? aadhaarName;
  final DateTime? memberSince;
  final String? gender;

  const UserProfile({
    required this.userId,
    required this.status,
    required this.aadhaarVerified,
    this.mobile,
    this.email,
    this.displayName,
    this.avatarId,
    this.aadhaarName,
    this.memberSince,
    this.gender,
  });
}
