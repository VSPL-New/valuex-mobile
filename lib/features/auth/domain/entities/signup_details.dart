import 'gender.dart';

/// What the Sign Up form submits to complete registration.
class SignupDetails {
  final String displayName;
  final Gender gender;
  final DateTime dateOfBirth;
  final String state;
  final String city;
  final String address;
  final String pincode;
  final String avatarId;
  final bool termsAccepted;
  final bool consentGiven;
  final String termsVersion;

  const SignupDetails({
    required this.displayName,
    required this.gender,
    required this.dateOfBirth,
    required this.state,
    required this.city,
    required this.address,
    required this.pincode,
    required this.avatarId,
    required this.termsAccepted,
    required this.consentGiven,
    required this.termsVersion,
  });
}
