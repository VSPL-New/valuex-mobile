import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/utils/masking.dart';
import 'package:valuex_mobile/core/utils/validators.dart';

void main() {
  group('Validators.isValidMobile', () {
    test('accepts ten digits starting with 6 to 9', () {
      for (final number in ['9876543210', '6000000000', '7123456789', '8123456789']) {
        expect(Validators.isValidMobile(number), isTrue, reason: number);
      }
    });

    test('rejects other numbers', () {
      for (final number in [
        '',
        '987654321',
        '98765432100',
        '1234567890',
        '5876543210',
        '98765a3210'
      ]) {
        expect(Validators.isValidMobile(number), isFalse, reason: number);
      }
    });
  });

  group('Validators.isValidEmail', () {
    test('accepts ordinary addresses including long top-level domains', () {
      for (final email in ['a@b.co', 'first.last@example.com', 'x+tag@mail.technology']) {
        expect(Validators.isValidEmail(email), isTrue, reason: email);
      }
    });

    test('trims surrounding spaces', () {
      expect(Validators.isValidEmail('  a@b.com  '), isTrue);
    });

    test('rejects malformed addresses', () {
      for (final email in ['', 'plain', '@b.com', 'a@', 'a@b', 'a b@c.com', 'a@b.c']) {
        expect(Validators.isValidEmail(email), isFalse, reason: email);
      }
    });
  });

  test('isValidOtp needs exactly six digits', () {
    expect(Validators.isValidOtp('123456'), isTrue);
    expect(Validators.isValidOtp('12345'), isFalse);
    expect(Validators.isValidOtp('1234567'), isFalse);
    expect(Validators.isValidOtp('12345a'), isFalse);
  });

  test('isValidAadhaar needs exactly twelve digits', () {
    expect(Validators.isValidAadhaar('123456789012'), isTrue);
    expect(Validators.isValidAadhaar('12345678901'), isFalse);
  });

  group('Masking', () {
    test('hides the middle of a mobile number', () {
      expect(Masking.mobile('9876543210'), '98****3210');
    });

    test('hides most of an email local part', () {
      expect(Masking.email('asha@example.com'), 'a***@example.com');
    });

    test('leaves values too short to mask unchanged', () {
      expect(Masking.mobile('12345'), '12345');
      expect(Masking.email('plain'), 'plain');
    });
  });
}
