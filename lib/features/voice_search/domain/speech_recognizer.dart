import 'speech_event.dart';

abstract interface class SpeechRecognizer {
  Future<bool> availability();
  Future<List<String>> languages();
  Stream<SpeechEvent> listen(String localeId);
  Future<void> stop();
  Future<void> cancel();
}
