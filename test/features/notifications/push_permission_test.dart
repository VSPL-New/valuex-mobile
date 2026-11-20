import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valuex_mobile/core/constants/storage_keys.dart';
import 'package:valuex_mobile/core/push/push_providers.dart';
import 'package:valuex_mobile/core/push/push_token_repository.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/features/notifications/presentation/push_permission_sheet.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../core/push/push_fakes.dart';
import '../../helpers/fonts.dart';

class _MockRepository extends Mock implements PushTokenRepository {}

void main() {
  setUpAll(loadBrandFonts);

  late FakePushService service;
  late _MockRepository repository;
  var settingsOpened = 0;

  final grants = <bool>[];

  setUp(() {
    grants.clear();
    SharedPreferences.setMockInitialValues({});
    service = FakePushService()
      ..granted = false
      ..token_ = 'fcm-1';
    repository = _MockRepository();
    settingsOpened = 0;
    when(() => repository.register(
          deviceId: any(named: 'deviceId'),
          platform: any(named: 'platform'),
          token: any(named: 'token'),
          locale: any(named: 'locale'),
          appVersion: any(named: 'appVersion'),
          permissionGranted: any(named: 'permissionGranted'),
        )).thenAnswer((invocation) async {
      grants.add(invocation.namedArguments[#permissionGranted] as bool);
    });
  });

  Future<void> pump(
    WidgetTester tester,
    Widget body, {
    Locale locale = const Locale('en'),
    double textScale = 1,
    Size size = const Size(400, 800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        pushServiceProvider.overrideWithValue(service),
        pushTokenRepositoryProvider.overrideWithValue(repository),
        installIdProvider.overrideWith((ref) async => 'install-1'),
        appSettingsOpenerProvider.overrideWithValue(() async {
          settingsOpened++;
          return true;
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: body),
      ),
    ));
    await tester.pumpAndSettle();
  }

  int registrations({bool? granted}) =>
      granted == null ? grants.length : grants.where((value) => value == granted).length;

  Widget asker() => Consumer(
        builder: (context, ref, _) => TextButton(
          onPressed: () => maybeAskForPushPermission(context, ref),
          child: const Text('chat'),
        ),
      );

  Future<void> ask(WidgetTester tester) async {
    await tester.tap(find.text('chat'));
    await tester.pumpAndSettle();
  }

  group('asking for the permission', () {
    testWidgets('explains first, then asks, and tells the server the answer', (tester) async {
      await pump(tester, asker());

      await ask(tester);
      expect(find.text('Hear about messages and offers'), findsOneWidget);
      expect(service.requests, 0);

      await tester.tap(find.text('Turn on notifications'));
      await tester.pumpAndSettle();

      expect(service.requests, 1);
      expect(find.text('Hear about messages and offers'), findsNothing);
      expect(registrations(granted: true), 1);
      expect(
          (await SharedPreferences.getInstance()).getBool(StorageKeys.pushPermissionAsked), isTrue);
    });

    testWidgets('"Not now" is remembered, nothing is requested, and the refusal is registered',
        (tester) async {
      await pump(tester, asker());

      await ask(tester);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(service.requests, 0);
      expect(registrations(granted: false), 1);
      expect(
          (await SharedPreferences.getInstance()).getBool(StorageKeys.pushPermissionAsked), isTrue);
    });

    testWidgets('a refusal in the system prompt is registered as not granted', (tester) async {
      service.grantOnRequest = false;
      await pump(tester, asker());

      await ask(tester);
      await tester.tap(find.text('Turn on notifications'));
      await tester.pumpAndSettle();

      expect(service.requests, 1);
      expect(registrations(granted: false), 1);
    });

    testWidgets('is shown only once', (tester) async {
      await pump(tester, asker());
      await ask(tester);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      await ask(tester);

      expect(find.text('Hear about messages and offers'), findsNothing);
    });

    testWidgets('does not ask when notifications are already allowed', (tester) async {
      service.granted = true;
      await pump(tester, asker());

      await ask(tester);

      expect(find.text('Hear about messages and offers'), findsNothing);
    });

    testWidgets('does not ask where push is not available', (tester) async {
      service.available = false;
      await pump(tester, asker());

      await ask(tester);

      expect(find.text('Hear about messages and offers'), findsNothing);
    });

    testWidgets('speaks Hindi', (tester) async {
      await pump(tester, asker(), locale: const Locale('hi'));

      await tester.tap(find.text('chat'));
      await tester.pumpAndSettle();

      expect(find.text('संदेश और ऑफ़र की जानकारी पाएँ'), findsOneWidget);
      expect(find.text('अभी नहीं'), findsOneWidget);
    });

    testWidgets('works at 320 px wide and 200 percent text, with 48 dp actions', (tester) async {
      await pump(tester, asker(), textScale: 2, size: const Size(320, 640));

      await ask(tester);

      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });

  group('the off banner', () {
    testWidgets('offers the system settings when notifications are off', (tester) async {
      await pump(tester, const Column(children: [PushOffBanner()]));

      expect(find.text('Notifications are off on this phone'), findsOneWidget);
      await tester.tap(find.text('Open Settings'));
      await tester.pump();

      expect(settingsOpened, 1);
    });

    testWidgets('shows nothing when notifications are on', (tester) async {
      service.granted = true;
      await pump(tester, const Column(children: [PushOffBanner()]));

      expect(find.text('Notifications are off on this phone'), findsNothing);
    });

    testWidgets('shows nothing where push is not available', (tester) async {
      service.available = false;
      await pump(tester, const Column(children: [PushOffBanner()]));

      expect(find.text('Notifications are off on this phone'), findsNothing);
    });

    testWidgets('checks again and registers when the person returns from the settings',
        (tester) async {
      await pump(tester, const Column(children: [PushOffBanner()]));
      expect(find.text('Notifications are off on this phone'), findsOneWidget);

      service.granted = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('Notifications are off on this phone'), findsNothing);
      expect(registrations(granted: true), 1);
    });

    testWidgets('speaks Hindi and fits at 200 percent text', (tester) async {
      await pump(tester, const Column(children: [PushOffBanner()]),
          locale: const Locale('hi'), textScale: 2, size: const Size(320, 640));

      expect(find.text('इस फ़ोन पर सूचनाएँ बंद हैं'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
