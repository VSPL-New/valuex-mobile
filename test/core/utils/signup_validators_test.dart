import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/utils/validators.dart';
import 'package:valuex_mobile/features/auth/domain/entities/avatar_catalog.dart';
import 'package:valuex_mobile/features/auth/domain/entities/gender.dart';
import 'package:valuex_mobile/features/auth/domain/entities/indian_states.dart';

void main() {
  group('name', () {
    test('a name needs 3 to 50 letters, spaces and . \' -', () {
      for (final name in ['Asha', 'Asha Verma', "D'Souza-Rao", 'Dr. A K', 'आशा वर्मा']) {
        expect(Validators.isValidName(name), isTrue, reason: name);
      }
      for (final name in ['', 'Al', 'Asha123', 'Asha@Home', 'x' * 51]) {
        expect(Validators.isValidName(name), isFalse, reason: name);
      }
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
