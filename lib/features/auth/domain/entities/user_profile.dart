import 'account_status.dart';

class UserProfile {
  final String userId;
  final AccountStatus status;
  final bool aadhaarVerified;
  final String? mobile;
  final String? email;
  final String? displayName;
  final String? avatarId;
  final String? city;
  final String? aadhaarName;
  final DateTime? memberSince;
  final String? gender;
  final String? dateOfBirth;
  final String? state;
  final String? address;
  final String? pincode;

  const UserProfile({
    required this.userId,
    required this.status,
    required this.aadhaarVerified,
    this.mobile,
    this.email,
    this.displayName,
    this.avatarId,
    this.city,
    this.aadhaarName,
    this.memberSince,
    this.gender,
    this.dateOfBirth,
    this.state,
    this.address,
    this.pincode,
  });
}
