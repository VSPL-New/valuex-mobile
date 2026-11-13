import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valuex_mobile/features/settings/presentation/providers/locale_controller.dart';
import 'package:valuex_mobile/features/voice_search/data/voice_preferences.dart';
import 'package:valuex_mobile/features/voice_search/domain/speech_event.dart';
import 'package:valuex_mobile/features/voice_search/domain/speech_recognizer.dart';
import 'package:valuex_mobile/features/voice_search/domain/voice_error.dart';
import 'package:valuex_mobile/features/voice_search/domain/voice_language.dart';
import 'package:valuex_mobile/features/voice_search/presentation/providers/voice_search_controller.dart';

class _FakeRecognizer implements SpeechRecognizer {
  bool available = true;
  bool throwAvailability = false;
  List<String> installedLanguages = ['en_IN', 'en_US', 'en_GB', 'hi_IN'];
  int listenCount = 0;
  int stopCount = 0;
  int cancelCount = 0;
  final List<String> requestedLocales = [];
  final List<StreamController<SpeechEvent>> sessions = [];

  @override
  Future<bool> availability() async {
    if (throwAvailability) throw StateError('plugin initialization failed');
    return available;
  }

  @override
  Future<List<String>> languages() async => installedLanguages;

  @override
  Stream<SpeechEvent> listen(String localeId) {
    listenCount++;
    requestedLocales.add(localeId);
    final events = StreamController<SpeechEvent>.broadcast(sync: true);
    sessions.add(events);
    return events.stream;
  }

  @override
  Future<void> stop() async => stopCount++;

  @override
  Future<void> cancel() async => cancelCount++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeRecognizer recognizer;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    recognizer = _FakeRecognizer();
  });

  ProviderContainer containerFor({String? appLanguage}) => ProviderContainer(
        overrides: [
          speechRecognizerProvider.overrideWithValue(recognizer),
          if (appLanguage != null) savedLanguageCodeProvider.overrideWithValue(appLanguage),
        ],
      );

  test('shows the notice once and does not start when the buyer declines', () async {
    final container = containerFor();
    addTearDown(container.dispose);
    container.listen(voiceSearchControllerProvider, (previous, next) {});
    final controller = container.read(voiceSearchControllerProvider.notifier);
    var noticeCount = 0;

    await controller.start(showNotice: () async {
      noticeCount++;
      return false;
    });

    expect(noticeCount, 1);
    expect(container.read(voiceSearchControllerProvider).phase, VoiceSearchPhase.idle);
    expect(recognizer.listenCount, 0);
  });

  test('starts in the app language, shows partials and finishes with tidied text', () async {
    final container = containerFor(appLanguage: 'hi');
    addTearDown(container.dispose);
    container.listen(voiceSearchControllerProvider, (previous, next) {});
    final controller = container.read(voiceSearchControllerProvider.notifier);

    await controller.start(showNotice: () async => true);

    expect(recognizer.requestedLocales.single, 'hi_IN');
    recognizer.sessions.single.add(const SpeechPartial('मुझे सैमसंग फोन'));
    expect(container.read(voiceSearchControllerProvider).partialText, 'मुझे सैमसंग फोन');
    recognizer.sessions.single.add(const SpeechFinal('मुझे सैमसंग फोन चाहिए'));

    final state = container.read(voiceSearchControllerProvider);
    expect(state.phase, VoiceSearchPhase.done);
    expect(state.result, 'सैमसंग फोन');
  });

  test('falls back through the installed English locale list', () async {
    recognizer.installedLanguages = ['en_GB'];
    final container = containerFor();
    addTearDown(container.dispose);
    container.listen(voiceSearchControllerProvider, (previous, next) {});
    await container
        .read(voiceSearchControllerProvider.notifier)
        .start(showNotice: () async => true);
    expect(recognizer.requestedLocales.single, 'en_GB');
  });

  test('uses any installed English locale after the preferred locales', () async {
    recognizer.installedLanguages = ['en_AU'];
    final container = containerFor();
    addTearDown(container.dispose);
    container.listen(voiceSearchControllerProvider, (previous, next) {});
    await container
        .read(voiceSearchControllerProvider.notifier)
        .start(showNotice: () async => true);
    expect(recognizer.requestedLocales.single, 'en_AU');
  });

  test('reports Hindi unavailable when hi_IN is not installed', () async {
    SharedPreferences.setMockInitialValues({VoicePreferences.languageKey: 'hi_IN'});
    recognizer.installedLanguages = ['en_IN'];
    final container = containerFor();
    addTearDown(container.dispose);
    container.listen(voiceSearchControllerProvider, (previous, next) {});
    await container
        .read(voiceSearchControllerProvider.notifier)
        .start(showNotice: () async => true);
    final state = container.read(voiceSearchControllerProvider);
    expect(state.error, VoiceError.languageUnavailable);
    expect(recognizer.listenCount, 0);
  });

  for (final entry in {
    'en-IN': 'en',
    'en-US': 'en',
    'en-GB': 'en',
    'en-AU': 'en',
    'hi-IN': 'hi',
    'EN-in': 'en',
  }.entries) {
    test('recognizes ${entry.key} and preserves the platform locale identifier', () async {
      recognizer.installedLanguages = [entry.key];
      final container = containerFor(appLanguage: entry.value);
      addTearDown(container.dispose);
      container.listen(voiceSearchControllerProvider, (previous, next) {});
      await container
          .read(voiceSearchControllerProvider.notifier)
          .start(showNotice: () async => true);
      expect(recognizer.requestedLocales.single, entry.key);
      expect(container.read(voiceSearchControllerProvider).phase, VoiceSearchPhase.listening);
    });
  }

  test('uses the last partial if the recognizer ends without a final result', () async {
    final container = containerFor();
    addTearDown(container.dispose);
    container.listen(voiceSearchControllerProvider, (previous, next) {});
    await container
        .read(voiceSearchControllerProvider.notifier)
        .start(showNotice: () async => true);
    recognizer.sessions.single.add(const SpeechPartial('find me a phone'));
    recognizer.sessions.single.add(const SpeechEnded());
    expect(container.read(voiceSearchControllerProvider).result, 'a phone');
  });

  test('empty recognition shows no-speech and makes no completed query', () async {
    final container = containerFor();
    addTearDown(container.dispose);
    container.listen(voiceSearchControllerProvider, (previous, next) {});
    await container
        .read(voiceSearchControllerProvider.notifier)
        .start(showNotice: () async => true);
    recognizer.sessions.single.add(const SpeechEnded());
    final state = container.read(voiceSearchControllerProvider);
    expect(state.phase, VoiceSearchPhase.failed);
    expect(state.error, VoiceError.noSpeech);
    expect(state.result, isNull);
  });

  test('maps recognition errors and allows retry', () async {
    final container = containerFor();
    addTearDown(container.dispose);
    container.listen(voiceSearchControllerProvider, (previous, next) {});
    final controller = container.read(voiceSearchControllerProvider.notifier);
    await controller.start(showNotice: () async => true);
    recognizer.sessions.single.add(const SpeechFailed(VoiceError.busy));
    expect(container.read(voiceSearchControllerProvider).error, VoiceError.busy);
    await controller.start();
    expect(recognizer.listenCount, 2);
  });

  test('a stream error becomes an unavailable state', () async {
    final container = containerFor();
    addTearDown(container.dispose);
    container.listen(voiceSearchControllerProvider, (previous, next) {});
    await container
        .read(voiceSearchControllerProvider.notifier)
        .start(showNotice: () async => true);
    recognizer.sessions.single.addError(StateError('plugin'));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(voiceSearchControllerProvider).error, VoiceError.unavailable);
  });

  test('an initialization exception becomes an unavailable state', () async {
    recognizer.throwAvailability = true;
    final container = containerFor();
    addTearDown(container.dispose);
    container.listen(voiceSearchControllerProvider, (previous, next) {});
    await container
        .read(voiceSearchControllerProvider.notifier)
        .start(showNotice: () async => true);
    expect(container.read(voiceSearchControllerProvider).error, VoiceError.unavailable);
  });

  test('only one session starts and Stop asks the recognizer to finish', () async {
    final container = containerFor();
    addTearDown(container.dispose);
    container.listen(voiceSearchControllerProvider, (previous, next) {});
    final controller = container.read(voiceSearchControllerProvider.notifier);
    await Future.wait([
      controller.start(showNotice: () async => true),
      controller.start(showNotice: () async => true),
    ]);

    expect(recognizer.listenCount, 1);
    await controller.stop();
    expect(recognizer.stopCount, 1);
    expect(container.read(voiceSearchControllerProvider).phase, VoiceSearchPhase.finishing);
  });

  test('switching language while listening saves it and restarts the session', () async {
    final container = containerFor();
    addTearDown(container.dispose);
    container.listen(voiceSearchControllerProvider, (previous, next) {});
    final controller = container.read(voiceSearchControllerProvider.notifier);
    await controller.start(showNotice: () async => true);

    await controller.switchLanguage(VoiceLanguage.hindi);

    expect(recognizer.requestedLocales.last, 'hi_IN');
    expect(await container.read(voicePreferencesProvider).getLanguage(), VoiceLanguage.hindi);
  });

  test('backgrounding cancels and stale session events do not change state', () async {
    final container = containerFor();
    addTearDown(container.dispose);
    container.listen(voiceSearchControllerProvider, (previous, next) {});
    final controller = container.read(voiceSearchControllerProvider.notifier);
    await controller.start(showNotice: () async => true);
    final oldEvents = recognizer.sessions.single;

    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    await Future<void>.delayed(Duration.zero);
    oldEvents.add(const SpeechFinal('stale result'));

    expect(container.read(voiceSearchControllerProvider).phase, VoiceSearchPhase.idle);
    expect(container.read(voiceSearchControllerProvider).result, isNull);
    expect(recognizer.cancelCount, 1);
  });

  test('an inactive app only cancels an active listening session', () async {
    final container = containerFor();
    addTearDown(container.dispose);
    container.listen(voiceSearchControllerProvider, (previous, next) {});
    final controller = container.read(voiceSearchControllerProvider.notifier);
    controller.didChangeAppLifecycleState(AppLifecycleState.inactive);
    expect(container.read(voiceSearchControllerProvider).phase, VoiceSearchPhase.idle);
    expect(recognizer.cancelCount, 0);

    await controller.start(showNotice: () async => true);
    controller.didChangeAppLifecycleState(AppLifecycleState.inactive);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(voiceSearchControllerProvider).phase, VoiceSearchPhase.idle);
    expect(recognizer.cancelCount, 1);
  });

  test('maps denied and permanently denied microphone permissions', () async {
    const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    Future<void> testStatus(int status, VoiceError expected) async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => call.method == 'checkPermissionStatus' ? status : false,
      );
      recognizer.available = false;
      final container = containerFor();
      addTearDown(container.dispose);
      container.listen(voiceSearchControllerProvider, (previous, next) {});
      await container
          .read(voiceSearchControllerProvider.notifier)
          .start(showNotice: () async => true);
      expect(container.read(voiceSearchControllerProvider).error, expected);
    }

    await testStatus(0, VoiceError.permissionDenied);
    await testStatus(4, VoiceError.permissionBlocked);
    messenger.setMockMethodCallHandler(channel, null);
  });
}
