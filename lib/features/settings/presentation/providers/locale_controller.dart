import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../domain/supported_languages.dart';

part 'locale_controller.g.dart';

/// The language code saved on the device, read in `main()` before the first frame so a
/// returning Hindi user never sees an English frame. Null means nothing saved yet.
final savedLanguageCodeProvider = Provider<String?>((ref) => null);

/// The language the app UI is shown in: the saved choice, otherwise English. The phone's own
/// language is not used.
@Riverpod(keepAlive: true)
class LocaleController extends _$LocaleController {
  @override
  Locale build() => localeFromCode(ref.read(savedLanguageCodeProvider));

  /// Switches the UI at once, then saves the choice. Unsupported languages are ignored.
  Future<void> select(Locale locale) async {
    if (!isSupportedLocale(locale)) return;
    final chosen = localeFromCode(locale.languageCode);
    state = chosen;
    try {
      await ref.read(preferencesServiceProvider).setAppLanguage(chosen.languageCode);
    } on Object catch (error) {
      // The language still applies for this session; it just won't be remembered.
      developer.log('Could not save the app language: $error', name: 'locale');
    }
  }
}

/// The row chosen on the Language screen or sheet but not saved yet; going back drops it.
@riverpod
class PendingLanguage extends _$PendingLanguage {
  @override
  Locale build() => ref.read(localeControllerProvider);

  void choose(Locale locale) => state = locale;
}
