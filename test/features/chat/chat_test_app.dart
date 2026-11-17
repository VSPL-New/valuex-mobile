import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/features/chat/data/chat_repository.dart';
import 'package:valuex_mobile/features/chat/presentation/providers/chat_polling.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import 'chat_fixtures.dart';

/// Pumps [home] at "/" inside a small router whose other routes only name where they lead, so a
/// tap that navigates can be checked.
Future<void> pumpChatApp(
  WidgetTester tester,
  Widget home, {
  required MockChatRepository repo,
  List<Override> overrides = const [],
  Locale locale = const Locale('en'),
  double textScale = 1,
  Size size = const Size(390, 844),
  Map<String, Object> preferences = const {},
}) async {
  SharedPreferences.setMockInitialValues(preferences);
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => home),
      GoRoute(
        path: '/chats/:threadId',
        builder: (context, state) =>
            Scaffold(body: Text('thread ${state.pathParameters['threadId']}')),
      ),
      GoRoute(
        path: '/listing/:listingId',
        builder: (context, state) =>
            Scaffold(body: Text('listing ${state.pathParameters['listingId']}')),
      ),
      GoRoute(path: '/chats', builder: (context, state) => const Scaffold(body: Text('chats tab'))),
      GoRoute(path: '/home', builder: (context, state) => const Scaffold(body: Text('home tab'))),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repo),
        chatPollIntervalProvider.overrideWithValue(null),
        ...overrides,
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
