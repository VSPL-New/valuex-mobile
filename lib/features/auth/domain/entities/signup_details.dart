import 'gender.dart';

/// What the Sign Up form submits to complete registration.
class SignupDetails {
  final String displayName;

  /// Optional; the backend stores nothing when it is null.
  final Gender? gender;
  final String avatarId;
  final bool termsAccepted;
  final bool consentGiven;
  final String termsVersion;

  const SignupDetails({
    required this.displayName,
    this.gender,
    required this.avatarId,
    required this.termsAccepted,
    required this.consentGiven,
    required this.termsVersion,
  });
}
