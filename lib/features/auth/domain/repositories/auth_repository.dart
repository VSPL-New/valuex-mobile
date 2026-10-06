import '../entities/aadhaar_transaction.dart';
import '../entities/auth_session.dart';
import '../entities/otp_sent.dart';
import '../entities/signup_details.dart';
import '../entities/user_profile.dart';

abstract interface class AuthRepository {
  /// True when tokens are stored on this device.
  Future<bool> hasSession();

  Future<UserProfile> fetchProfile();

  Future<void> clearSession();

  Future<OtpSent> initiateRegistration(String mobile);

  /// Stores the issued tokens.
  Future<AuthResult> verifyMobileOtp({required String mobile, required String otp});

  Future<OtpSent> sendEmailOtp(String email);

  Future<void> verifyEmailOtp({required String email, required String otp});

  /// Stores the issued tokens.
  Future<AuthResult> skipAadhaar();

  Future<AadhaarTransaction> initiateAadhaar({
    required String aadhaarNumber,
    required String consentToken,
  });

  /// Stores the issued tokens.
  Future<AuthResult> verifyAadhaar({required String transactionId, required String otp});

  /// Finishes registration; stores the issued tokens.
  Future<AuthResult> completeSignup(SignupDetails details);
}
