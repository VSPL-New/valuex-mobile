import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/features/voice_search/presentation/widgets/voice_notice_sheet.dart';
import 'package:valuex_mobile/features/voice_search/presentation/widgets/voice_search_button.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets('voice button is labelled, at least 48 dp, and responds to a tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(app(VoiceSearchButton(onPressed: () => tapped = true)));

    final button = find.byTooltip('Search by voice');
    expect(button, findsOneWidget);
    expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    await tester.tap(button);
    expect(tapped, isTrue);
  });

  testWidgets('first-use notice offers Continue and Not now', (tester) async {
    bool? accepted;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => accepted = await showVoiceNoticeSheet(context),
            child: const Text('Open notice'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open notice'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Your phone\'s speech service'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(accepted, isTrue);
  });
}
