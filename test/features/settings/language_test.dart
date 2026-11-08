import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valuex_mobile/core/constants/storage_keys.dart';
import 'package:valuex_mobile/core/routing/app_router.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/core/utils/formatters.dart';
import 'package:valuex_mobile/core/widgets/square_back_button.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/logout_outcome.dart';
import 'package:valuex_mobile/features/profile/data/profile_repository.dart';
import 'package:valuex_mobile/features/profile/domain/profile_menu_badges.dart';
import 'package:valuex_mobile/features/profile/presentation/profile_screen.dart';
import 'package:valuex_mobile/features/profile/presentation/providers/logout_action.dart';
import 'package:valuex_mobile/features/settings/presentation/language_screen.dart';
import 'package:valuex_mobile/features/settings/presentation/providers/locale_controller.dart';
import 'package:valuex_mobile/features/settings/presentation/widgets/language_chip.dart';
import 'package:valuex_mobile/l10n/app_localizations_en.dart';
import 'package:valuex_mobile/l10n/app_localizations_hi.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/app_harness.dart';
import '../../helpers/fonts.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

final _en = AppLocalizationsEn();
final _hi = AppLocalizationsHi();

void main() {
  setUpAll(loadBrandFonts);

  Future<AppHarness> launchSignedIn(
    WidgetTester tester, {
    bool deviceLanguageSaved = true,
    String? location,
  }) async {
    final repository = _MockProfileRepository();
    when(() => repository.menuBadges()).thenAnswer((_) async => const ProfileMenuBadges());
    final harness = AppHarness(
      tester,
      deviceLanguageSaved: deviceLanguageSaved,
      extraOverrides: [profileRepositoryProvider.overrideWithValue(repository)],
    )..signedInAs(AccountStatus.active);
    await harness.launch(location: location);
    return harness;
  }

  Future<AppHarness> openLanguageFromProfile(WidgetTester tester) async {
    final harness = await launchSignedIn(tester);
    await tester.tap(find.text(_en.navProfile));
    await harness.settle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    await tester.ensureVisible(find.text(_en.profileLanguage));
    await tester.tap(find.text(_en.profileLanguage));
    await harness.settle();
    expect(find.byType(LanguageScreen), findsOneWidget);
    return harness;
  }

  Locale currentLocale(AppHarness harness) => harness.container.read(localeControllerProvider);

  group('default language', () {
    testWidgets('a new install is English even on a Hindi phone', (tester) async {
      tester.platformDispatcher.localesTestValue = [const Locale('hi')];
      tester.platformDispatcher.localeTestValue = const Locale('hi');
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final harness = AppHarness(tester, deviceLanguageSaved: false);
      await harness.launch();

      expect(find.text(_en.commonSkip), findsOneWidget);
      expect(find.text(_hi.commonSkip), findsNothing);
      expect(currentLocale(harness), const Locale('en'));
      await harness.dispose();
    });

    testWidgets('a saved Hindi choice is used from the first frame', (tester) async {
      final harness = AppHarness(
        tester,
        deviceLanguageSaved: false,
        extraOverrides: [savedLanguageCodeProvider.overrideWithValue('hi')],
      );
      await harness.launch(waitOutSplash: false);

      expect(currentLocale(harness), const Locale('hi'));
      await tester.pump(const Duration(milliseconds: 2300));
      await harness.settle();
      expect(find.text(_hi.commonSkip), findsOneWidget);
      await harness.dispose();
    });
  });

  group('Language screen', () {
    testWidgets('the Profile Language row opens it with English and Hindi', (tester) async {
      final harness = await openLanguageFromProfile(tester);

      expect(find.text(_en.languageTitle), findsOneWidget);
      expect(find.text(_en.languageSubtitle), findsOneWidget);
      expect(find.text(_en.languageNameHindi), findsOneWidget);
      expect(find.text('English'), findsNWidgets(2));
      expect(find.text('हिन्दी'), findsOneWidget);
      expect(find.text(_en.languageSave), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('the current language is marked as selected', (tester) async {
      final handle = tester.ensureSemantics();
      final harness = await openLanguageFromProfile(tester);

      expect(find.bySemanticsLabel(_en.languageSelected(_en.languageNameEnglish)), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      handle.dispose();
      await harness.dispose();
    });

    testWidgets('choosing a row does not change the language until Save', (tester) async {
      final harness = await openLanguageFromProfile(tester);

      await tester.tap(find.text('हिन्दी'));
      await harness.settle();

      expect(find.text(_en.languageTitle), findsOneWidget);
      expect(currentLocale(harness), const Locale('en'));
      expect(
        (await SharedPreferences.getInstance()).getString(StorageKeys.appLanguage),
        isNull,
      );
      await harness.dispose();
    });

    testWidgets('Save switches the whole app to Hindi, remembers it and goes back', (tester) async {
      final harness = await openLanguageFromProfile(tester);

      await tester.tap(find.text('हिन्दी'));
      await harness.settle();
      await tester.tap(find.text(_en.languageSave));
      await harness.settle();

      expect(currentLocale(harness), const Locale('hi'));
      expect(find.byType(LanguageScreen), findsNothing);
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text(_hi.profileLanguage), findsOneWidget);
      expect(find.text(_en.profileLanguage), findsNothing);
      expect(
        (await SharedPreferences.getInstance()).getString(StorageKeys.appLanguage),
        'hi',
      );
      await harness.dispose();
    });

    testWidgets('going back without Save keeps the language and drops the choice', (tester) async {
      final harness = await openLanguageFromProfile(tester);

      await tester.tap(find.text('हिन्दी'));
      await harness.settle();
      await tester.tap(find.byType(SquareBackButton));
      await harness.settle();

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(currentLocale(harness), const Locale('en'));
      await tester.tap(find.text(_en.profileLanguage));
      await harness.settle();
      expect(find.byIcon(Icons.check), findsOneWidget);
      await tester.tap(find.byType(SquareBackButton));
      await harness.settle();
      await harness.dispose();
    });

    testWidgets('Save with no change just goes back', (tester) async {
      final harness = await openLanguageFromProfile(tester);

      await tester.tap(find.text(_en.languageSave));
      await harness.settle();

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(currentLocale(harness), const Locale('en'));
      await harness.dispose();
    });

    testWidgets('opened directly, Back returns to Profile', (tester) async {
      final harness = await launchSignedIn(tester, location: RouteNames.language);
      expect(find.byType(LanguageScreen), findsOneWidget);

      await tester.tap(find.byType(SquareBackButton));
      await harness.settle();

      expect(find.byType(ProfileScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a signed-out user cannot open it', (tester) async {
      final harness = AppHarness(tester);
      await harness.launch();
      harness.container.read(appRouterProvider).go(RouteNames.language);
      await harness.settle();

      expect(find.byType(LanguageScreen), findsNothing);
      await harness.dispose();
    });

    testWidgets('Hindi at 200% text on a small phone does not overflow', (tester) async {
      final harness = await launchSignedIn(tester, location: RouteNames.language);
      tester.view.physicalSize = const Size(720, 1280);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await harness.container.read(localeControllerProvider.notifier).select(const Locale('hi'));
      await harness.settle();

      expect(tester.takeException(), isNull);
      expect(find.text(_hi.languageSave), findsOneWidget);
      await tester.ensureVisible(find.text('हिन्दी').first);
      expect(tester.takeException(), isNull);
      await harness.dispose();
    });

    testWidgets('passes the tap target and label guidelines in both languages', (tester) async {
      final handle = tester.ensureSemantics();
      final harness = await launchSignedIn(tester, location: RouteNames.language);

      for (final locale in const [Locale('en'), Locale('hi')]) {
        await harness.container.read(localeControllerProvider.notifier).select(locale);
        await harness.settle();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrast));
      }
      handle.dispose();
      await harness.dispose();
    });
  });

  group('language chip before sign-in', () {
    Future<AppHarness> open(WidgetTester tester, String? location) async {
      final harness = AppHarness(tester);
      await harness.launch(location: location);
      return harness;
    }

    for (final location in [null, RouteNames.createAccount, RouteNames.signIn]) {
      testWidgets('is shown on ${location ?? 'onboarding'} and opens the sheet', (tester) async {
        final harness = await open(tester, location);

        expect(find.byType(LanguageChip), findsOneWidget);
        await tester.tap(find.byType(LanguageChip));
        await harness.settle();

        expect(find.text(_en.languageSheetTitle), findsOneWidget);
        expect(find.text('हिन्दी'), findsWidgets);
        expect(find.text(_en.languageSave), findsOneWidget);
        await harness.dispose();
      });
    }

    testWidgets('Save in the sheet switches the screen to Hindi at once', (tester) async {
      final harness = await open(tester, RouteNames.createAccount);

      await tester.tap(find.byType(LanguageChip));
      await harness.settle();
      await tester.tap(find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('हिन्दी'),
      ));
      await harness.settle();
      await tester.tap(find.text(_en.languageSave));
      await harness.settle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text(_hi.createAccountCreate), findsOneWidget);
      expect(find.text(_en.createAccountCreate), findsNothing);
      expect(currentLocale(harness), const Locale('hi'));
      await harness.dispose();
    });

    testWidgets('closing the sheet without Save changes nothing', (tester) async {
      final harness = await open(tester, RouteNames.createAccount);

      await tester.tap(find.byType(LanguageChip));
      await harness.settle();
      await tester.tap(find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('हिन्दी'),
      ));
      await harness.settle();
      await tester.tapAt(const Offset(10, 10));
      await harness.settle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text(_en.createAccountCreate), findsOneWidget);
      expect(currentLocale(harness), const Locale('en'));
      await harness.dispose();
    });

    testWidgets('the choice made before sign-in is the one Profile shows', (tester) async {
      final harness = AppHarness(tester)..signedInAs(AccountStatus.active);
      await harness.launch(location: RouteNames.createAccount);
      await tester.tap(find.byType(LanguageChip));
      await harness.settle();
      await tester.tap(find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('हिन्दी'),
      ));
      await harness.settle();
      await tester.tap(find.text(_en.languageSave));
      await harness.settle();

      harness.container.read(appRouterProvider).go(RouteNames.language);
      await harness.settle();

      expect(find.byType(LanguageScreen), findsOneWidget);
      expect(find.text(_hi.languageTitle), findsWidgets);
      expect(find.byIcon(Icons.check), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('switching language keeps what the user typed', (tester) async {
      final harness = await open(tester, RouteNames.signIn);
      await tester.enterText(find.byType(TextField).first, '9876543210');
      await harness.settle();

      await tester.tap(find.byType(LanguageChip));
      await harness.settle();
      await tester.tap(find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('हिन्दी'),
      ));
      await harness.settle();
      await tester.tap(find.text(_en.languageSave));
      await harness.settle();

      expect(find.text(_hi.signInTitle), findsOneWidget);
      expect(find.text('9876543210'), findsWidgets);
      expect(harness.container.read(appRouterProvider).state.matchedLocation, RouteNames.signIn);
      await harness.dispose();
    });

    testWidgets('does not overlap the Skip button on onboarding at 200% text in Hindi',
        (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final harness = await open(tester, null);
      await harness.container.read(localeControllerProvider.notifier).select(const Locale('hi'));
      await harness.settle();

      expect(tester.takeException(), isNull);
      final chip = tester.getRect(find.byType(LanguageChip));
      final skip = tester.getRect(find.text(_hi.commonSkip));
      expect(chip.overlaps(skip), isFalse);
      await harness.dispose();
    });

    testWidgets('has an accessible name that includes the current language', (tester) async {
      final handle = tester.ensureSemantics();
      final harness = await open(tester, RouteNames.signIn);

      expect(find.bySemanticsLabel(_en.languageChipLabel(_en.languageNameEnglish)), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
      await harness.dispose();
    });
  });

  group('the choice stays', () {
    testWidgets('signing out keeps the language', (tester) async {
      final harness = await launchSignedIn(tester);
      await harness.container.read(localeControllerProvider.notifier).select(const Locale('hi'));
      when(() => harness.repository.logout()).thenAnswer((_) async => LogoutOutcome.revoked);

      await harness.container.read(logoutActionProvider)();
      await harness.settle();

      expect(currentLocale(harness), const Locale('hi'));
      expect(
        (await SharedPreferences.getInstance()).getString(StorageKeys.appLanguage),
        'hi',
      );
      await harness.dispose();
    });

    testWidgets('switching language in the middle of a flow keeps the place', (tester) async {
      final harness = await launchSignedIn(tester);
      final router = harness.container.read(appRouterProvider);
      router.go(RouteNames.categories);
      await harness.settle();
      final before = router.state.matchedLocation;

      await harness.container.read(localeControllerProvider.notifier).select(const Locale('hi'));
      await harness.settle();

      expect(router.state.matchedLocation, before);
      expect(find.text(_hi.categoriesTitle), findsWidgets);
      await harness.dispose();
    });
  });

  test('Hindi amounts and dates use Latin digits and Hindi month names', () async {
    await initializeDateFormatting('hi');
    final text = DateFormat.yMMMd('hi').format(DateTime(2026, 11, 7));

    expect(text, contains('2026'));
    expect(text, contains('7'));
    expect(RegExp('[०-९]').hasMatch(text), isFalse);
    expect(RegExp('[ऀ-ॿ]').hasMatch(text), isTrue);
    expect(Formatters.money(1234), '₹1,234');
  });
}
