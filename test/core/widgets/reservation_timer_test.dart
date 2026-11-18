import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/core/theme/colors.dart';
import 'package:valuex_mobile/core/widgets/reservation_timer.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../helpers/fonts.dart';

void main() {
  setUpAll(loadBrandFonts);

  final serverTime = DateTime.utc(2026, 11, 18, 10);
  late DateTime phone;

  setUp(() => phone = DateTime.utc(2030));

  Future<void> pump(
    WidgetTester tester, {
    required Duration left,
    VoidCallback? onEnded,
    Locale locale = const Locale('en'),
    double textScale = 1,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: ReservationTimer(
            validUntil: serverTime.add(left),
            serverTime: serverTime,
            onEnded: onEnded,
            now: () => phone,
          ),
        ),
      ),
    ));
  }

  Future<void> pass(WidgetTester tester, Duration time) async {
    phone = phone.add(time);
    await tester.pump(time);
  }

  Color colorOfText(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!.color!;

  testWidgets('counts down in minutes and seconds from the server clock', (tester) async {
    await pump(tester, left: const Duration(minutes: 14, seconds: 30));
    expect(find.text('14:30 left'), findsOneWidget);

    await pass(tester, const Duration(seconds: 5));

    expect(find.text('14:25 left'), findsOneWidget);
  });

  testWidgets('does not depend on the phone clock being right', (tester) async {
    phone = DateTime.utc(1999);

    await pump(tester, left: const Duration(minutes: 7));

    expect(find.text('07:00 left'), findsOneWidget);
  });

  testWidgets('is in the normal colour until the last minute and in the warning colour after',
      (tester) async {
    await pump(tester, left: const Duration(minutes: 1, seconds: 2));
    expect(colorOfText(tester, '01:02 left'), AppColors.brandForeground);

    await pass(tester, const Duration(seconds: 3));

    expect(find.text('00:59 left'), findsOneWidget);
    expect(colorOfText(tester, '00:59 left'), AppColors.brandError);
  });

  testWidgets('says the reservation ended and calls onEnded once when the time is up',
      (tester) async {
    var ended = 0;
    await pump(tester, left: const Duration(seconds: 2), onEnded: () => ended++);

    await pass(tester, const Duration(seconds: 3));
    await pass(tester, const Duration(seconds: 2));

    expect(find.text('Reservation ended'), findsOneWidget);
    expect(colorOfText(tester, 'Reservation ended'), AppColors.brandError);
    expect(ended, 1);
  });

  testWidgets('shows an already ended reservation without a callback', (tester) async {
    await pump(tester, left: const Duration(seconds: -30));

    expect(find.text('Reservation ended'), findsOneWidget);
  });

  testWidgets('speaks the minutes left, and not again for every second', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, left: const Duration(minutes: 5, seconds: 20));
    expect(find.bySemanticsLabel('5 minutes left to complete your purchase'), findsOneWidget);

    await pass(tester, const Duration(seconds: 1));

    expect(find.bySemanticsLabel('5 minutes left to complete your purchase'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('speaks seconds in tens in the last minute', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, left: const Duration(seconds: 44));

    expect(find.bySemanticsLabel('50 seconds left to complete your purchase'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('speaks a single minute in the singular', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, left: const Duration(minutes: 1, seconds: 30));

    expect(find.bySemanticsLabel('1 minute left to complete your purchase'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('counts again when the server answers with a new end', (tester) async {
    await pump(tester, left: const Duration(minutes: 10));
    expect(find.text('10:00 left'), findsOneWidget);

    await pump(tester, left: const Duration(minutes: 15));

    expect(find.text('15:00 left'), findsOneWidget);
  });

  testWidgets('reads in Hindi', (tester) async {
    await pump(tester, left: const Duration(minutes: 3), locale: const Locale('hi'));
    await tester.pumpAndSettle();

    expect(find.text('03:00 बाकी'), findsOneWidget);
  });

  testWidgets('does not overflow at 320 px and 200 percent text', (tester) async {
    await pump(
      tester,
      left: const Duration(minutes: 14, seconds: 59),
      textScale: 2,
      size: const Size(320, 640),
    );

    expect(tester.takeException(), isNull);
  });
}
