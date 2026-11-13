import 'voice_error.dart';

sealed class SpeechEvent {
  const SpeechEvent();
}

final class SpeechPartial extends SpeechEvent {
  const SpeechPartial(this.text);
  final String text;
}

final class SpeechFinal extends SpeechEvent {
  const SpeechFinal(this.text);
  final String text;
}

final class SpeechFailed extends SpeechEvent {
  const SpeechFailed(this.error);
  final VoiceError error;
}

final class SpeechEnded extends SpeechEvent {
  const SpeechEnded();
}
