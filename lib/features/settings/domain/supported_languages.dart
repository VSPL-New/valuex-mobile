import 'package:flutter/widgets.dart';

/// A language the app can show. [nativeName] is written in its own script and is the same in
/// every app language, so a user who lands in the wrong language can still find theirs.
class SupportedLanguage {
  final Locale locale;
  final String nativeName;

  const SupportedLanguage(this.locale, this.nativeName);

  String get code => locale.languageCode;
}

/// MVP languages: English (default) and Hindi. Adding a language means one ARB file and one entry.
const List<SupportedLanguage> supportedLanguages = [
  SupportedLanguage(Locale('en'), 'English'),
  SupportedLanguage(Locale('hi'), 'हिन्दी'),
];

const Locale defaultLocale = Locale('en');

/// The language for a saved code; anything missing or unsupported gives English.
Locale localeFromCode(String? code) {
  for (final language in supportedLanguages) {
    if (language.code == code) return language.locale;
  }
  return defaultLocale;
}

bool isSupportedLocale(Locale locale) =>
    supportedLanguages.any((language) => language.code == locale.languageCode);

SupportedLanguage languageFor(Locale locale) => supportedLanguages.firstWhere(
      (language) => language.code == locale.languageCode,
      orElse: () => supportedLanguages.first,
    );
