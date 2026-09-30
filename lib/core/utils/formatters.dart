import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String currency(num amount) {
    return _currencyFormat.format(amount);
  }

  static String phoneMasked(String phone) {
    if (phone.length < 10) return phone;
    final last4 = phone.substring(phone.length - 4);
    return '******$last4';
  }

  static String emailMasked(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '$name***@$domain';
    return '${name.substring(0, 2)}***@$domain';
  }
}
