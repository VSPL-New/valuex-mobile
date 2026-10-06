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
  static final RegExp _pincode = RegExp(r'^[1-9]\d{5}$');

  /// 3 to 50 letters, spaces and . ' -
  static bool isValidName(String value) {
    final trimmed = value.trim();
    return trimmed.length >= 3 && trimmed.length <= 50 && _letters.hasMatch(trimmed);
  }

  /// 2 to 100 letters, spaces and . ' -
  static bool isValidCity(String value) {
    final trimmed = value.trim();
    return trimmed.length >= 2 && trimmed.length <= 100 && _letters.hasMatch(trimmed);
  }

  static bool isValidAddress(String value) {
    final length = value.trim().length;
    return length >= 10 && length <= 255;
  }

  static bool isValidPincode(String value) => _pincode.hasMatch(value);

  /// Parses DD/MM/YYYY; null unless it is a real calendar date from 1900 up to today
  /// (there is no minimum age).
  static DateTime? parseDateOfBirth(String text, {DateTime? today}) {
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(text);
    if (match == null) return null;
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    final isRealDate = date.year == year && date.month == month && date.day == day;
    if (!isRealDate || year < 1900) return null;
    final now = today ?? DateTime.now();
    return date.isAfter(DateTime(now.year, now.month, now.day)) ? null : date;
  }

  /// True for a well-formed date that lies in the future.
  static bool isFutureDate(String text, {DateTime? today}) {
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(text);
    if (match == null) return false;
    final date = DateTime(
      int.parse(match.group(3)!),
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
    );
    final now = today ?? DateTime.now();
    return date.isAfter(DateTime(now.year, now.month, now.day));
  }

  static String formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year.toString().padLeft(4, '0')}';
  }
}
