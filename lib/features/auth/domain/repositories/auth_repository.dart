import '../entities/aadhaar_transaction.dart';
import '../entities/auth_session.dart';
import '../entities/google_sign_in_result.dart';
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

  /// Sends a sign-in OTP to an already registered mobile number.
  Future<OtpSent> initiateLogin(String mobile);

  /// Stores the issued tokens; the result carries the account's current status.
  Future<AuthResult> verifyLogin({required String mobile, required String otp});

  /// Sends a Google ID token to the server. When the account is already linked the issued
  /// tokens are stored; otherwise the result carries the session for mobile verification.
  Future<GoogleSignInResult> signInWithGoogle(String idToken);

  /// Sends the OTP that proves the mobile number to create or link the account.
  /// Terms and consent are collected later at Sign Up, so they are not sent here.
  Future<OtpSent> initiateGoogleMobile({
    required String socialSessionToken,
    required String mobile,
  });

  /// Stores the issued tokens; the result carries the account's status.
  Future<AuthResult> verifyGoogleMobile({
    required String socialSessionToken,
    required String mobile,
    required String otp,
  });

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
