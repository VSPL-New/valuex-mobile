import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text_platform_interface/speech_to_text_platform_interface.dart';
import 'package:valuex_mobile/features/voice_search/data/speech_to_text_recognizer.dart';
import 'package:valuex_mobile/features/voice_search/domain/speech_event.dart';
import 'package:valuex_mobile/features/voice_search/domain/voice_error.dart';

class _FakeSpeechPlatform extends SpeechToTextPlatform {
  bool initializeResult = true;
  bool throwLocales = false;
  bool throwListen = false;
  bool supportsOnDevice = false;
  bool throwOnDeviceQuery = false;
  int onDeviceQueries = 0;
  SpeechListenOptions? listenOptions;
  String? localeId;

  @override
  Future<bool> initialize({debugLogging = false, List<SpeechConfigOption>? options}) async =>
      initializeResult;

  @override
  Future<List<dynamic>> locales() async {
    if (throwLocales) throw StateError('locales unavailable');
    return ['en_IN:English India', 'hi_IN:Hindi India'];
  }

  @override
  Future<bool> hasOnDeviceSupport({String? localeId}) async {
    onDeviceQueries++;
    if (throwOnDeviceQuery) throw StateError('not supported');
    return supportsOnDevice;
  }

  @override
  Future<bool> listen({
    String? localeId,
    partialResults = true,
    onDevice = false,
    int listenMode = 0,
    sampleRate = 0,
    SpeechListenOptions? options,
  }) async {
    if (throwListen) throw StateError('error_network');
    this.localeId = localeId;
    listenOptions = options;
    return true;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SpeechToTextRecognizer freshRecognizer() =>
      SpeechToTextRecognizer(speech: SpeechToText.withMethodChannel());

  test('maps platform errors to the user-facing voice error categories', () {
    expect(mapSpeechError('error_no_match'), VoiceError.noSpeech);
    expect(mapSpeechError('error_speech_timeout'), VoiceError.noSpeech);
    expect(mapSpeechError('error_network_timeout'), VoiceError.networkRequired);
    expect(mapSpeechError('error_language_not_supported'), VoiceError.languageUnavailable);
    expect(mapSpeechError('error_language_unavailable'), VoiceError.languageUnavailable);
    expect(mapSpeechError('error_insufficient_permissions'), VoiceError.permissionDenied);
    expect(mapSpeechError('error_recognizer_busy'), VoiceError.busy);
    expect(mapSpeechError('unrecognized_error'), VoiceError.unavailable);
  });

  test('uses supported locales, requests on-device when available, and emits partial/final events',
      () async {
    final previous = SpeechToTextPlatform.instance;
    final platform = _FakeSpeechPlatform()..supportsOnDevice = true;
    SpeechToTextPlatform.instance = platform;
    addTearDown(() => SpeechToTextPlatform.instance = previous);
    final recognizer = freshRecognizer();
    expect(await recognizer.availability(), isTrue);
    expect(await recognizer.languages(), ['en_IN', 'hi_IN']);

    final events = <SpeechEvent>[];
    final subscription = recognizer.listen('en_IN').listen(events.add);
    await Future<void>.delayed(Duration.zero);
    expect(platform.onDeviceQueries, 1);
    expect(platform.localeId, 'en_IN');
    expect(platform.listenOptions?.onDevice, isTrue);
    expect(platform.listenOptions?.partialResults, isTrue);
    expect(platform.listenOptions?.pauseFor, const Duration(seconds: 3));
    expect(platform.listenOptions?.listenFor, const Duration(seconds: 20));

    platform.onTextRecognition!(
      jsonEncode({
        'alternates': [
          {'recognizedWords': 'phones', 'confidence': 0.9},
        ],
        'resultType': 0,
      }),
    );
    platform.onTextRecognition!(
      jsonEncode({
        'alternates': [
          {'recognizedWords': 'phones', 'confidence': 0.9},
        ],
        'resultType': 2,
      }),
    );
    await Future<void>.delayed(Duration.zero);
    expect(events[0], isA<SpeechPartial>());
    expect((events[0] as SpeechPartial).text, 'phones');
    expect(events[1], isA<SpeechFinal>());
    expect((events[1] as SpeechFinal).text, 'phones');
    await recognizer.stop();
    await subscription.cancel();
    await recognizer.cancel();
  });

  test('falls back to the phone speech service when on-device support is unavailable', () async {
    final previous = SpeechToTextPlatform.instance;
    final platform = _FakeSpeechPlatform();
    SpeechToTextPlatform.instance = platform;
    addTearDown(() => SpeechToTextPlatform.instance = previous);
    final recognizer = freshRecognizer();
    await recognizer.availability();
    final subscription = recognizer.listen('hi_IN').listen((_) {});
    await Future<void>.delayed(Duration.zero);
    expect(platform.listenOptions?.onDevice, isFalse);
    await subscription.cancel();
    await recognizer.cancel();
  });

  test('retries failed initialization and returns an empty locale list on error', () async {
    final previous = SpeechToTextPlatform.instance;
    final platform = _FakeSpeechPlatform()..initializeResult = false;
    SpeechToTextPlatform.instance = platform;
    addTearDown(() => SpeechToTextPlatform.instance = previous);
    final recognizer = freshRecognizer();

    expect(await recognizer.availability(), isFalse);
    platform.initializeResult = true;
    expect(await recognizer.availability(), isTrue);
    platform.throwLocales = true;
    expect(await recognizer.languages(), isEmpty);
  });

  test('reports plugin errors and ends on the platform done status', () async {
    final previous = SpeechToTextPlatform.instance;
    final platform = _FakeSpeechPlatform();
    SpeechToTextPlatform.instance = platform;
    addTearDown(() => SpeechToTextPlatform.instance = previous);
    final recognizer = freshRecognizer();
    await recognizer.availability();
    final events = <SpeechEvent>[];
    final subscription = recognizer.listen('en_IN').listen(events.add);
    await Future<void>.delayed(Duration.zero);

    platform.onError!(
      jsonEncode({'errorMsg': 'error_network', 'permanent': false}),
    );
    platform.onTextRecognition!(
      jsonEncode({
        'alternates': [
          {'recognizedWords': 'phones', 'confidence': 0.9},
        ],
        'resultType': 2,
      }),
    );
    platform.onStatus!('done');
    await Future<void>.delayed(Duration.zero);

    expect(events.whereType<SpeechFailed>().single.error, VoiceError.networkRequired);
    expect(events.whereType<SpeechEnded>(), hasLength(1));
    await subscription.cancel();
    await recognizer.cancel();
  });

  test('maps listen failures and falls back when on-device capability query throws', () async {
    final previous = SpeechToTextPlatform.instance;
    final platform = _FakeSpeechPlatform()
      ..throwOnDeviceQuery = true
      ..throwListen = true;
    SpeechToTextPlatform.instance = platform;
    addTearDown(() => SpeechToTextPlatform.instance = previous);
    final recognizer = freshRecognizer();
    await recognizer.availability();
    final events = <SpeechEvent>[];
    final subscription = recognizer.listen('en_IN').listen(events.add);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(platform.onDeviceQueries, 1);
    expect(events.whereType<SpeechFailed>().single.error, VoiceError.networkRequired);
    expect(events.whereType<SpeechEnded>(), hasLength(1));
    await subscription.cancel();
    await recognizer.cancel();
  });
}
