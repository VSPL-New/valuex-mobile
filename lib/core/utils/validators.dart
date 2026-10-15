/// Input rules shared with the backend validation (see the auth DTOs).
class Validators {
  Validators._();

  static final RegExp _mobile = RegExp(r'^[6-9]\d{9}$');
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final RegExp _otp = RegExp(r'^\d{6}$');
  static final RegExp _aadhaar = RegExp(r'^\d{12}$');

  static bool isValidMobile(String value) => _mobile.hasMatch(value);

  static bool isValidEmail(String value) {
    final trimmed = value.trim();
    return trimmed.length <= 255 && _email.hasMatch(trimmed);
  }

  static bool isValidOtp(String value) => _otp.hasMatch(value);

  static bool isValidAadhaar(String value) => _aadhaar.hasMatch(value);

  static final RegExp _letters = RegExp(r"^[\p{L}\p{M} .'-]+$", unicode: true);

  /// 3 to 50 letters, spaces and . ' -
  static bool isValidName(String value) {
    final trimmed = value.trim();
    return trimmed.length >= 3 && trimmed.length <= 50 && _letters.hasMatch(trimmed);
  }
}
