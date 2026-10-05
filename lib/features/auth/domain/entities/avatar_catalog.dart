import 'gender.dart';

enum AvatarGroup { male, female, neutral }

/// Avatar ids published by the backend (`GET /avatars`), grouped for the picker.
class AvatarCatalog {
  AvatarCatalog._();

  static const Map<AvatarGroup, List<String>> groups = {
    AvatarGroup.male: ['avatar-01', 'avatar-02', 'avatar-03', 'avatar-04'],
    AvatarGroup.female: ['avatar-05', 'avatar-06', 'avatar-07', 'avatar-08'],
    AvatarGroup.neutral: ['avatar-09', 'avatar-10', 'avatar-11', 'avatar-12'],
  };

  static const String defaultMale = 'avatar-01';
  static const String defaultFemale = 'avatar-05';
  static const String defaultNeutral = 'avatar-09';

  /// The avatar shown until the user picks one: by gender, neutral when not chosen yet.
  static String defaultFor(Gender? gender) {
    return switch (gender) {
      Gender.male => defaultMale,
      Gender.female => defaultFemale,
      Gender.others || null => defaultNeutral,
    };
  }

  static AvatarGroup groupOf(String avatarId) {
    return groups.entries
        .firstWhere(
          (entry) => entry.value.contains(avatarId),
          orElse: () => const MapEntry(AvatarGroup.neutral, <String>[]),
        )
        .key;
  }
}
