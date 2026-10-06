class ApiConstants {
  ApiConstants._();

  static const String registerInitiate = '/auth/register/initiate';
  static const String registerVerifyMobile = '/auth/register/verify-mobile';
  static const String registerComplete = '/auth/register/complete';
  static const String skipAadhaar = '/auth/register/skip-aadhaar';
  static const String emailSendOtp = '/auth/email/send-otp';
  static const String emailVerifyOtp = '/auth/email/verify-otp';
  static const String aadhaarInitiate = '/auth/aadhaar/initiate';
  static const String aadhaarVerify = '/auth/aadhaar/verify';
  static const String refreshToken = '/auth/refresh';
  static const String currentUser = '/users/me';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
