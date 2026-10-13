class ApiConstants {
  ApiConstants._();

  static const String registerInitiate = '/auth/register/initiate';
  static const String registerVerifyMobile = '/auth/register/verify-mobile';
  static const String registerComplete = '/auth/register/complete';
  static const String loginInitiate = '/auth/login/initiate';
  static const String loginVerifyMobile = '/auth/login/verify-mobile';
  static const String googleSignIn = '/auth/social/google';
  static const String googleInitiateMobile = '/auth/social/google/initiate-mobile';
  static const String googleVerifyMobile = '/auth/social/google/verify-mobile';
  static const String skipAadhaar = '/auth/register/skip-aadhaar';
  static const String emailSendOtp = '/auth/email/send-otp';
  static const String emailVerifyOtp = '/auth/email/verify-otp';
  static const String aadhaarInitiate = '/auth/aadhaar/initiate';
  static const String aadhaarVerify = '/auth/aadhaar/verify';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String currentUser = '/users/me';
  static const String profileMenuSummary = '/users/me/menu-summary';
  static const String accountSecurity = '/users/me/account-security';
  static const String mobileChangeInitiate = '/users/me/mobile/change/initiate';
  static const String mobileChangeVerify = '/users/me/mobile/change/verify';
  static const String emailChangeInitiate = '/users/me/email/change/initiate';
  static const String emailChangeVerify = '/users/me/email/change/verify';
  static const String sessions = '/users/me/sessions';
  static const String revokeOtherSessions = '/users/me/sessions/revoke-others';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
