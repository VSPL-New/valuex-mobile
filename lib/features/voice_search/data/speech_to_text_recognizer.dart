import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text_platform_interface/speech_to_text_platform_interface.dart';

import '../domain/speech_event.dart';
import '../domain/speech_recognizer.dart';
import '../domain/voice_error.dart';

/// The plugin boundary for voice search. No other feature imports speech_to_text.
class SpeechToTextRecognizer implements SpeechRecognizer {
  SpeechToTextRecognizer({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  StreamController<SpeechEvent>? _events;
  bool? _available;

  @override
  Future<bool> availability() async {
    if (_available == true) return true;
    try {
      _available = await _speech.initialize(
        onError: (error) {
          _events?.add(SpeechFailed(mapSpeechError(error.errorMsg)));
        },
        onStatus: (status) {
          if (status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) {
            _events?.add(const SpeechEnded());
          }
        },
        debugLogging: false,
      );
    } on Object {
      _available = false;
    }
    return _available!;
  }

  @override
  Future<List<String>> languages() async {
    try {
      return (await _speech.locales()).map((locale) => locale.localeId).toList(growable: false);
    } on Object {
      return const [];
    }
  }

  @override
  Stream<SpeechEvent> listen(String localeId) {
    final events = StreamController<SpeechEvent>();
    _events = events;
    unawaited(_listen(localeId, events));
    return events.stream;
  }

  Future<void> _listen(String localeId, StreamController<SpeechEvent> events) async {
    var onDevice = false;
    try {
      onDevice = await SpeechToTextPlatform.instance.hasOnDeviceSupport(localeId: localeId);
    } on Object {
      // Older OS versions and unsupported platforms use the phone's speech service.
    }
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          if (result.finalResult) {
            events.add(SpeechFinal(result.recognizedWords));
          } else {
            events.add(SpeechPartial(result.recognizedWords));
          }
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 20),
          localeId: localeId,
          listenMode: ListenMode.confirmation,
          onDevice: onDevice,
        ),
      );
    } on Object catch (error) {
      events.add(SpeechFailed(mapSpeechError(error.toString())));
      events.add(const SpeechEnded());
    }
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() async {
    await _speech.cancel();
    final events = _events;
    _events = null;
    if (events != null && !events.isClosed) await events.close();
  }
}

VoiceError mapSpeechError(String message) {
  final name = message.toLowerCase();
  if (name.contains('no_match') || name.contains('speech_timeout')) return VoiceError.noSpeech;
  if (name.contains('network')) return VoiceError.networkRequired;
  if (name.contains('language_not_supported') || name.contains('language_unavailable')) {
    return VoiceError.languageUnavailable;
  }
  if (name.contains('permission') || name.contains('insufficient_permissions')) {
    return VoiceError.permissionDenied;
  }
  if (name.contains('busy') || name.contains('audio_error') || name.contains('recognizer_busy')) {
    return VoiceError.busy;
  }
  return VoiceError.unavailable;
}
