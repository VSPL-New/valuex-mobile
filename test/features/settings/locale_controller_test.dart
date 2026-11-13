import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valuex_mobile/core/constants/storage_keys.dart';
import 'package:valuex_mobile/core/storage/preferences_service.dart';
import 'package:valuex_mobile/features/settings/domain/supported_languages.dart';
import 'package:valuex_mobile/features/settings/presentation/providers/locale_controller.dart';

class _FailingPreferences extends PreferencesService {
  @override
  Future<bool> setAppLanguage(String code) async => throw StateError('disk full');
}

void main() {
  group('supported languages', () {
    test('are exactly English then Hindi, with native names', () {
      expect(supportedLanguages.map((l) => l.code), ['en', 'hi']);
      expect(supportedLanguages.map((l) => l.nativeName), ['English', 'हिन्दी']);
    });

    test('localeFromCode gives English for anything missing or unsupported', () {
      expect(localeFromCode('en'), const Locale('en'));
      expect(localeFromCode('hi'), const Locale('hi'));
      for (final code in [null, '', 'fr', 'ta', 'HI', 'hi-IN']) {
        expect(localeFromCode(code), defaultLocale, reason: '$code');
      }
    });

    test('isSupportedLocale and languageFor', () {
      expect(isSupportedLocale(const Locale('hi', 'IN')), isTrue);
      expect(isSupportedLocale(const Locale('ta')), isFalse);
      expect(languageFor(const Locale('hi')).nativeName, 'हिन्दी');
      expect(languageFor(const Locale('ta')).code, 'en');
    });
  });

  group('PreferencesService', () {
    test('saves and reads the app language', () async {
      SharedPreferences.setMockInitialValues({});
      final service = PreferencesService();
      expect(await service.getAppLanguage(), isNull);

      await service.setAppLanguage('hi');

      expect(await service.getAppLanguage(), 'hi');
      expect((await SharedPreferences.getInstance()).getString(StorageKeys.appLanguage), 'hi');
    });

    test('reads and writes boolean preferences and supports removal and clearing', () async {
      SharedPreferences.setMockInitialValues({});
      final service = PreferencesService();

      expect(await service.isOnboardingComplete(), isFalse);
      expect(await service.setOnboardingComplete(true), isTrue);
      expect(await service.isOnboardingComplete(), isTrue);
      expect(await service.setOnboardingComplete(false), isTrue);
      expect(await service.isOnboardingComplete(), isFalse);

      expect(await service.getBool('voice_notice'), isNull);
      expect(await service.setBool('voice_notice', true), isTrue);
      expect(await service.getBool('voice_notice'), isTrue);
      expect(await service.setString('temporary', 'value'), isTrue);
      expect(await service.getString('temporary'), 'value');
      expect(await service.remove('temporary'), isTrue);
      expect(await service.getString('temporary'), isNull);
      expect(await service.clear(), isTrue);
      expect(await service.getBool('voice_notice'), isNull);
    });
  });

  group('LocaleController', () {
    ProviderContainer container({String? saved}) {
      final c = ProviderContainer(overrides: [savedLanguageCodeProvider.overrideWithValue(saved)]);
      addTearDown(c.dispose);
      return c;
    }

    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('starts in English when nothing is saved', () {
      expect(container().read(localeControllerProvider), const Locale('en'));
    });

    test('starts in Hindi when Hindi was saved', () {
      expect(container(saved: 'hi').read(localeControllerProvider), const Locale('hi'));
    });

    test('a saved code that is no longer supported falls back to English', () {
      expect(container(saved: 'fr').read(localeControllerProvider), const Locale('en'));
    });

    test('select changes the language and remembers it', () async {
      final c = container();

      await c.read(localeControllerProvider.notifier).select(const Locale('hi'));

      expect(c.read(localeControllerProvider), const Locale('hi'));
      expect(await PreferencesService().getAppLanguage(), 'hi');
    });

    test('a failed save still applies the language for this session', () async {
      final c = ProviderContainer(overrides: [
        preferencesServiceProvider.overrideWithValue(_FailingPreferences()),
      ]);
      addTearDown(c.dispose);

      await c.read(localeControllerProvider.notifier).select(const Locale('hi'));

      expect(c.read(localeControllerProvider), const Locale('hi'));
    });

    test('select ignores a language that is not supported', () async {
      final c = container(saved: 'hi');

      await c.read(localeControllerProvider.notifier).select(const Locale('fr'));

      expect(c.read(localeControllerProvider), const Locale('hi'));
      expect(await PreferencesService().getAppLanguage(), isNull);
    });
  });

  group('PendingLanguage', () {
    test('starts as the current language and changes only the pending choice', () {
      final c = ProviderContainer(overrides: [savedLanguageCodeProvider.overrideWithValue('hi')]);
      addTearDown(c.dispose);
      final sub = c.listen(pendingLanguageProvider, (_, __) {});
      addTearDown(sub.close);

      expect(c.read(pendingLanguageProvider), const Locale('hi'));
      c.read(pendingLanguageProvider.notifier).choose(const Locale('en'));

      expect(c.read(pendingLanguageProvider), const Locale('en'));
      expect(c.read(localeControllerProvider), const Locale('hi'));
    });
  });
}
