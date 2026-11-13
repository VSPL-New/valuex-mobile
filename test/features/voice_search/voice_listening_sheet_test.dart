import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valuex_mobile/features/voice_search/data/voice_preferences.dart';
import 'package:valuex_mobile/features/voice_search/domain/speech_event.dart';
import 'package:valuex_mobile/features/voice_search/domain/speech_recognizer.dart';
import 'package:valuex_mobile/features/voice_search/domain/voice_error.dart';
import 'package:valuex_mobile/features/voice_search/presentation/providers/voice_search_controller.dart';
import 'package:valuex_mobile/features/voice_search/presentation/widgets/voice_listening_sheet.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

class _FakeRecognizer implements SpeechRecognizer {
  List<String> installed = ['en_IN', 'en_US', 'en_GB', 'hi_IN'];
  int stops = 0;
  int cancels = 0;
  final List<StreamController<SpeechEvent>> sessions = [];
  final List<String> requestedLocales = [];

  @override
  Future<bool> availability() async => true;

  @override
  Future<List<String>> languages() async => installed;

  @override
  Stream<SpeechEvent> listen(String localeId) {
    requestedLocales.add(localeId);
    final events = StreamController<SpeechEvent>.broadcast(sync: true);
    sessions.add(events);
    return events.stream;
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> cancel() async => cancels++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeRecognizer recognizer;
  String? result;

  Future<void> launch(
    WidgetTester tester, {
    String? language,
    List<String>? installed,
    Locale locale = const Locale('en'),
    double textScale = 1.0,
  }) async {
    SharedPreferences.setMockInitialValues({
      VoicePreferences.noticeKey: true,
      if (language != null) VoicePreferences.languageKey: language,
    });
    recognizer = _FakeRecognizer();
    if (installed != null) recognizer.installed = installed;
    result = null;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [speechRecognizerProvider.overrideWithValue(recognizer)],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async => result = await showVoiceListeningSheet(context),
                  child: const Text('Open voice panel'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open voice panel'));
    await tester.pumpAndSettle();
    await tester.pump();
  }

  testWidgets('shows live words and returns the normalized final query', (tester) async {
    await launch(tester);
    expect(find.text('Listening…'), findsOneWidget);
    recognizer.sessions.single.add(const SpeechPartial('find me phones'));
    await tester.pump();
    expect(find.text('find me phones'), findsOneWidget);

    await tester.tap(find.text('Stop'));
    await tester.pump();
    expect(recognizer.stops, 1);
    recognizer.sessions.single.add(const SpeechFinal('find me phones'));
    await tester.pumpAndSettle();

    expect(result, 'phones');
  });

  testWidgets('shows no-speech recovery and can retry', (tester) async {
    await launch(tester);
    recognizer.sessions.single.add(const SpeechFailed(VoiceError.noSpeech));
    await tester.pump();
    expect(find.text('Didn\'t catch that. Try again or type your search.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(recognizer.sessions, hasLength(2));
  });

  testWidgets('shows the corresponding recovery action for every voice error', (tester) async {
    const messages = {
      VoiceError.permissionDenied: 'Microphone or speech permission was not granted.',
      VoiceError.permissionBlocked: 'Microphone or speech access is blocked.',
      VoiceError.unavailable: 'Speech recognition is not available on this phone.',
      VoiceError.languageUnavailable: 'Speech recognition is not available in this language',
      VoiceError.noSpeech: 'Didn\'t catch that.',
      VoiceError.networkRequired: 'This language needs a network connection',
      VoiceError.busy: 'The microphone is busy.',
    };

    for (final entry in messages.entries) {
      await launch(tester);
      recognizer.sessions.single.add(SpeechFailed(entry.key));
      await tester.pump();
      expect(find.textContaining(entry.value), findsOneWidget);
      if (entry.key == VoiceError.permissionBlocked) {
        expect(find.text('Open Settings'), findsOneWidget);
        expect(find.text('Try again'), findsNothing);
      } else if (entry.key == VoiceError.languageUnavailable) {
        expect(find.text('Switch language'), findsOneWidget);
      } else if (entry.key == VoiceError.unavailable || entry.key == VoiceError.networkRequired) {
        expect(find.text('Type instead'), findsOneWidget);
      } else {
        expect(find.text('Try again'), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Type instead closes the panel with the typing result', (tester) async {
    await launch(tester);
    recognizer.sessions.single.add(const SpeechFailed(VoiceError.unavailable));
    await tester.pump();
    await tester.ensureVisible(find.text('Type instead'));
    await tester.tap(find.text('Type instead'));
    await tester.pumpAndSettle();
    expect(result, voiceTypeInsteadResult);
  });

  testWidgets('switches from unavailable Hindi to English and completes the query', (tester) async {
    await launch(tester, language: 'hi_IN', installed: ['en_IN']);
    expect(find.textContaining('not available in this language'), findsOneWidget);
    expect(recognizer.sessions, isEmpty);

    await tester.ensureVisible(find.text('Switch language'));
    await tester.tap(find.text('Switch language'));
    await tester.pumpAndSettle();
    expect(recognizer.requestedLocales, ['en_IN']);
    expect(find.text('Listening…'), findsOneWidget);

    recognizer.sessions.single.add(const SpeechFinal('find me phone'));
    await tester.pumpAndSettle();
    expect(result, 'phone');
  });

  testWidgets('panel remains scrollable at 200% text in English and Hindi', (tester) async {
    for (final language in ['en', 'hi']) {
      await launch(
        tester,
        language: language == 'hi' ? 'hi_IN' : 'en_IN',
        locale: Locale(language),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);

      final l10n = AppLocalizations.of(tester.element(find.byType(VoiceListeningSheet)));
      final cancel = find.text(l10n.voiceCancel);
      await tester.ensureVisible(cancel);
      expect(cancel, findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });
}
