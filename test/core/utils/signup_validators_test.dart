import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/utils/date_input_formatter.dart';
import 'package:valuex_mobile/core/utils/validators.dart';
import 'package:valuex_mobile/features/auth/domain/entities/avatar_catalog.dart';
import 'package:valuex_mobile/features/auth/domain/entities/gender.dart';
import 'package:valuex_mobile/features/auth/domain/entities/indian_states.dart';

void main() {
  group('name and city', () {
    test('a name needs 3 to 50 letters, spaces and . \' -', () {
      for (final name in ['Asha', 'Asha Verma', "D'Souza-Rao", 'Dr. A K', 'आशा वर्मा']) {
        expect(Validators.isValidName(name), isTrue, reason: name);
      }
      for (final name in ['', 'Al', 'Asha123', 'Asha@Home', 'x' * 51]) {
        expect(Validators.isValidName(name), isFalse, reason: name);
      }
    });

    test('a city needs 2 to 100 letters', () {
      expect(Validators.isValidCity('Pune'), isTrue);
      expect(Validators.isValidCity('Ra'), isTrue);
      expect(Validators.isValidCity('P'), isFalse);
      expect(Validators.isValidCity('City 9'), isFalse);
      expect(Validators.isValidCity('c' * 101), isFalse);
    });
  });

  group('address and pincode', () {
    test('an address needs 10 to 255 characters', () {
      expect(Validators.isValidAddress('12 MG Road'), isTrue);
      expect(Validators.isValidAddress('short'), isFalse);
      expect(Validators.isValidAddress('a' * 255), isTrue);
      expect(Validators.isValidAddress('a' * 256), isFalse);
    });

    test('a pincode is six digits not starting with 0', () {
      expect(Validators.isValidPincode('560038'), isTrue);
      expect(Validators.isValidPincode('012345'), isFalse);
      expect(Validators.isValidPincode('56003'), isFalse);
      expect(Validators.isValidPincode('5600388'), isFalse);
    });
  });

  group('date of birth', () {
    final today = DateTime(2026, 10, 6);

    test('parses a real past date', () {
      expect(Validators.parseDateOfBirth('17/05/1995', today: today), DateTime(1995, 5, 17));
    });

    test('accepts today, so there is no minimum age', () {
      expect(Validators.parseDateOfBirth('06/10/2026', today: today), DateTime(2026, 10, 6));
    });

    test('rejects the future', () {
      expect(Validators.parseDateOfBirth('07/10/2026', today: today), isNull);
      expect(Validators.isFutureDate('07/10/2026', today: today), isTrue);
      expect(Validators.isFutureDate('06/10/2026', today: today), isFalse);
    });

    test('rejects dates that do not exist and years before 1900', () {
      for (final text in ['31/02/2000', '00/01/2000', '15/13/2000', '01/01/1899', '1/1/2000', '']) {
        expect(Validators.parseDateOfBirth(text, today: today), isNull, reason: text);
      }
    });

    test('a leap day is accepted only in a leap year', () {
      expect(Validators.parseDateOfBirth('29/02/2000', today: today), isNotNull);
      expect(Validators.parseDateOfBirth('29/02/2001', today: today), isNull);
    });

    test('formats as DD/MM/YYYY', () {
      expect(Validators.formatDate(DateTime(1995, 5, 7)), '07/05/1995');
    });
  });

  group('DateInputFormatter', () {
    final formatter = DateInputFormatter();

    String format(String typed) {
      return formatter.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: typed)).text;
    }

    test('adds slashes while typing', () {
      expect(format('1'), '1');
      expect(format('170'), '17/0');
      expect(format('17051995'), '17/05/1995');
    });

    test('drops non-digits and anything past eight digits', () {
      expect(format('17/05/1995'), '17/05/1995');
      expect(format('1a7b0c5'), '17/05');
      expect(format('170519951'), '17/05/1995');
    });
  });

  group('avatars', () {
    test('defaults follow gender, neutral when not chosen yet', () {
      expect(AvatarCatalog.defaultFor(Gender.male), 'avatar-01');
      expect(AvatarCatalog.defaultFor(Gender.female), 'avatar-05');
      expect(AvatarCatalog.defaultFor(Gender.others), 'avatar-09');
      expect(AvatarCatalog.defaultFor(null), 'avatar-09');
    });

    test('the catalog has twelve avatars in three groups of four', () {
      expect(AvatarCatalog.groups.values.expand((ids) => ids), hasLength(12));
      expect(AvatarCatalog.groups.values.every((ids) => ids.length == 4), isTrue);
      expect(AvatarCatalog.groupOf('avatar-06'), AvatarGroup.female);
      expect(AvatarCatalog.groupOf('avatar-12'), AvatarGroup.neutral);
    });
  });

  test('the state list matches the backend: 36 unique names', () {
    expect(IndianStates.names, hasLength(36));
    expect(IndianStates.names.toSet(), hasLength(36));
    expect(IndianStates.names, contains('Karnataka'));
  });
}
