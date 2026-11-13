import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valuex_mobile/core/storage/preferences_service.dart';
import 'package:valuex_mobile/features/voice_search/data/voice_preferences.dart';
import 'package:valuex_mobile/features/voice_search/domain/voice_language.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('stores the selected voice language separately from search criteria', () async {
    final preferences = VoicePreferences(PreferencesService());

    expect(await preferences.getLanguage(), isNull);
    await preferences.setLanguage(VoiceLanguage.hindi);
    expect(await preferences.getLanguage(), VoiceLanguage.hindi);
    expect(
        await SharedPreferences.getInstance()
            .then((prefs) => prefs.getString('voice_search_language')),
        'hi_IN');
  });

  test('stores the versioned first-use notice flag', () async {
    final preferences = VoicePreferences(PreferencesService());

    expect(await preferences.noticeShown(), isFalse);
    await preferences.setNoticeShown();
    expect(await preferences.noticeShown(), isTrue);
    expect(
      await SharedPreferences.getInstance()
          .then((prefs) => prefs.getBool('voice_search_notice_shown_v1')),
      isTrue,
    );
  });
}
