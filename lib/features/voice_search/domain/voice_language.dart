import 'package:flutter/widgets.dart';

enum VoiceLanguage {
  english('en_IN'),
  hindi('hi_IN');

  const VoiceLanguage(this.localeId);

  final String localeId;

  static VoiceLanguage fromAppLocale(Locale locale) =>
      locale.languageCode == 'hi' ? VoiceLanguage.hindi : VoiceLanguage.english;
}
