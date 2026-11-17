import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/realtime/realtime_event.dart';
import 'package:valuex_mobile/core/realtime/realtime_providers.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/core/widgets/realtime_reconnecting_banner.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/fonts.dart';

class _Status extends RealtimeStatusController {
  final RealtimeStatus initial;

  _Status(this.initial);

  @override
  RealtimeStatus build() => initial;
}

void main() {
  setUpAll(loadBrandFonts);

  Future<void> pumpBanner(
    WidgetTester tester,
    RealtimeStatus status, {
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) async {
    final overrides = <Override>[realtimeStatusProvider.overrideWith(() => _Status(status))];
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Column(children: [RealtimeReconnectingBanner()])),
      ),
    ));
  }

  for (final status in [RealtimeStatus.reconnecting, RealtimeStatus.degraded]) {
    testWidgets('shows that the connection is being restored while $status', (tester) async {
      await pumpBanner(tester, status);

      expect(find.text('Reconnecting…'), findsOneWidget);
    });
  }

  for (final status in [
    RealtimeStatus.idle,
    RealtimeStatus.connecting,
    RealtimeStatus.connected,
    RealtimeStatus.stopped,
  ]) {
    testWidgets('takes no room while $status', (tester) async {
      await pumpBanner(tester, status);

      expect(find.text('Reconnecting…'), findsNothing);
      expect(tester.getSize(find.byType(RealtimeReconnectingBanner)).height, 0);
    });
  }

  testWidgets('is announced as a live region', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpBanner(tester, RealtimeStatus.reconnecting);

    expect(
      tester.getSemantics(find.byType(RealtimeReconnectingBanner)),
      matchesSemantics(label: 'Reconnecting…', isLiveRegion: true),
    );
    handle.dispose();
  });

  testWidgets('reads in Hindi', (tester) async {
    await pumpBanner(tester, RealtimeStatus.reconnecting, locale: const Locale('hi'));

    expect(find.text('फिर से कनेक्ट हो रहा है…'), findsOneWidget);
  });

  testWidgets('fits at 200 percent text on a narrow screen and meets the guidelines',
      (tester) async {
    final handle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpBanner(tester, RealtimeStatus.reconnecting, textScale: 2);

    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(textContrast));
    handle.dispose();
  });
}
