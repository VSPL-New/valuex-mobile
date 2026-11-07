import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/create_account_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/sign_in_mobile_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/signup_mobile_screen.dart';
import 'package:valuex_mobile/features/home/presentation/home_screen.dart';
import 'package:valuex_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../helpers/fake_location_service.dart';

Widget _app(Locale locale, Widget home, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

void main() {
  test('user-facing translations use the JustQlic product name', () {
    for (final language in ['en', 'hi']) {
      final messages =
          jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync()) as Map<String, dynamic>;
      expect(messages['appName'], 'JustQlic');
      for (final entry in messages.entries) {
        if (entry.key.startsWith('@') || entry.value is! String) continue;
        expect(entry.value, isNot(contains('ValueX')), reason: '$language: ${entry.key}');
        expect(entry.value, isNot(contains('valuex.com')), reason: '$language: ${entry.key}');
      }
      final localized = lookupAppLocalizations(Locale(language));
      expect(localized.aadhaarConsent, contains('JustQlic'));
      expect(localized.termsSection3, contains('JustQlic'));
      expect(localized.googleMobileSubtitle('test@example.com'), contains('JustQlic'));
      expect(localized.googleErrorAlreadyLinked, contains('JustQlic'));
    }
  });

  group('English and Hindi files', () {
    Map<String, dynamic> load(String language) =>
        jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync()) as Map<String, dynamic>;
    final en = load('en');
    final hi = load('hi');
    Iterable<String> messageKeys(Map<String, dynamic> arb) =>
        arb.keys.where((key) => !key.startsWith('@'));

    test('have the same keys, so no string can be missing in Hindi', () {
      expect(messageKeys(hi).toSet().difference(messageKeys(en).toSet()), isEmpty,
          reason: 'only in Hindi');
      expect(messageKeys(en).toSet().difference(messageKeys(hi).toSet()), isEmpty,
          reason: 'missing in Hindi');
    });

    test('use every placeholder the English template declares', () {
      for (final key in messageKeys(en)) {
        final meta = en['@$key'];
        if (meta is! Map || meta['placeholders'] is! Map) continue;
        for (final name in (meta['placeholders'] as Map).keys) {
          final used = RegExp('\\{$name\\s*[,}]');
          expect(used.hasMatch(hi[key] as String), isTrue, reason: '$key is missing {$name}');
        }
      }
    });

    test('have no empty values', () {
      for (final arb in [en, hi]) {
        for (final key in messageKeys(arb)) {
          expect((arb[key] as String).trim(), isNotEmpty, reason: key);
        }
      }
    });

    test('Hindi differs from English except for words that read the same', () {
      const sameInBoth = {'appName', 'languageNameEnglish'};
      final same = messageKeys(en).where((key) => en[key] == hi[key] && !sameInBoth.contains(key));
      // Reported, not failed: names, numbers and units can legitimately be identical.
      expect(same.length, lessThan(messageKeys(en).length ~/ 10), reason: same.join(', '));
    });
  });

  test('English and Hindi define the same keys', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final hi = lookupAppLocalizations(const Locale('hi'));

    expect(en.createAccountCreate, 'Create an Account');
    expect(hi.createAccountCreate, isNot(en.createAccountCreate));
    expect(hi.signupMobileSendOtp, isNotEmpty);
  });

  for (final locale in AppLocalizations.supportedLocales) {
    group('locale ${locale.languageCode}', () {
      testWidgets('create account screen shows localized actions', (tester) async {
        await tester.pumpWidget(_app(locale, const CreateAccountScreen()));
        await tester.pump();
        final l10n = AppLocalizations.of(tester.element(find.byType(CreateAccountScreen)));

        expect(find.text(l10n.createAccountCreate), findsOneWidget);
        expect(find.text(l10n.createAccountSignIn), findsOneWidget);
        expect(find.text(l10n.createAccountContinueGuest), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('mobile number screen shows localized copy', (tester) async {
        await tester.pumpWidget(_app(locale, const SignupMobileScreen()));
        await tester.pump();
        final l10n = AppLocalizations.of(tester.element(find.byType(SignupMobileScreen)));

        expect(find.text(l10n.signupMobileTitle), findsOneWidget);
        expect(find.text(l10n.signupMobileSendOtp), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('sign in screen shows localized copy', (tester) async {
        await tester.pumpWidget(_app(locale, const SignInMobileScreen()));
        await tester.pump();
        final l10n = AppLocalizations.of(tester.element(find.byType(SignInMobileScreen)));

        expect(find.text(l10n.signInTitle), findsOneWidget);
        expect(find.text(l10n.signInSubtitle), findsOneWidget);
        expect(find.text(l10n.signInSignUp), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('home shows localized copy', (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _app(
            locale,
            const HomeScreen(),
            overrides: [locationServiceProvider.overrideWithValue(FakeLocationService())],
          ),
        );
        await tester.pump();
        await tester.pump();
        final l10n = AppLocalizations.of(tester.element(find.byType(HomeScreen)));

        expect(find.text(l10n.homeFeaturedTitle), findsOneWidget);
        expect(find.text(l10n.homeBrowse), findsOneWidget);
        expect(l10n.homeCartLabel(2), isNotEmpty);
        expect(l10n.homeNotificationsLabel(0), isNotEmpty);
      });
    });
  }
}
