/// Hides most of a contact detail for display ("98****3210", "a***@mail.com").
class Masking {
  Masking._();

  static String mobile(String value) {
    if (value.length < 6) return value;
    return '${value.substring(0, 2)}${'*' * (value.length - 6)}${value.substring(value.length - 4)}';
  }

  static String email(String value) {
    final at = value.indexOf('@');
    if (at < 1) return value;
    return '${value[0]}***${value.substring(at)}';
  }
}
