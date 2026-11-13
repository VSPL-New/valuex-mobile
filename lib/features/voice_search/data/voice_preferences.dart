import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/preferences_service.dart';
import '../domain/voice_language.dart';

class VoicePreferences {
  VoicePreferences(this._preferences);

  static const String languageKey = 'voice_search_language';
  static const String noticeKey = 'voice_search_notice_shown_v1';

  final PreferencesService _preferences;

  Future<VoiceLanguage?> getLanguage() async {
    final saved = await _preferences.getString(languageKey);
    return switch (saved) {
      'en_IN' => VoiceLanguage.english,
      'hi_IN' => VoiceLanguage.hindi,
      _ => null,
    };
  }

  Future<void> setLanguage(VoiceLanguage language) async {
    await _preferences.setString(languageKey, language.localeId);
  }

  Future<bool> noticeShown() async => await _preferences.getBool(noticeKey) ?? false;

  Future<void> setNoticeShown() async {
    await _preferences.setBool(noticeKey, true);
  }
}

final voicePreferencesProvider = Provider<VoicePreferences>(
  (ref) => VoicePreferences(ref.watch(preferencesServiceProvider)),
);
