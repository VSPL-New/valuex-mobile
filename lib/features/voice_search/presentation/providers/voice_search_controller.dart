import 'dart:io';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../features/settings/presentation/providers/locale_controller.dart';
import '../../data/speech_to_text_recognizer.dart';
import '../../data/voice_preferences.dart';
import '../../domain/speech_event.dart';
import '../../domain/speech_recognizer.dart';
import '../../domain/voice_error.dart';
import '../../domain/voice_language.dart';
import '../../domain/voice_query_normalizer.dart';

part 'voice_search_controller.g.dart';

enum VoiceSearchPhase { idle, starting, listening, finishing, done, failed }

@immutable
class VoiceSearchState {
  const VoiceSearchState({
    this.phase = VoiceSearchPhase.idle,
    this.partialText = '',
    this.language = VoiceLanguage.english,
    this.error,
    this.result,
  });

  final VoiceSearchPhase phase;
  final String partialText;
  final VoiceLanguage language;
  final VoiceError? error;
  final String? result;

  VoiceSearchState copyWith({
    VoiceSearchPhase? phase,
    String? partialText,
    VoiceLanguage? language,
    Object? error = _unchanged,
    Object? result = _unchanged,
  }) =>
      VoiceSearchState(
        phase: phase ?? this.phase,
        partialText: partialText ?? this.partialText,
        language: language ?? this.language,
        error: identical(error, _unchanged) ? this.error : error as VoiceError?,
        result: identical(result, _unchanged) ? this.result : result as String?,
      );
}

const Object _unchanged = Object();

final speechRecognizerProvider = Provider<SpeechRecognizer>(
  (ref) => SpeechToTextRecognizer(),
);

@riverpod
class VoiceSearchController extends _$VoiceSearchController with WidgetsBindingObserver {
  StreamSubscription<SpeechEvent>? _subscription;
  int _session = 0;
  bool _observerAdded = false;

  SpeechRecognizer get _recognizer => ref.read(speechRecognizerProvider);
  VoicePreferences get _preferences => ref.read(voicePreferencesProvider);

  @override
  VoiceSearchState build() {
    final locale = ref.read(localeControllerProvider);
    final recognizer = _recognizer;
    if (!_observerAdded) {
      WidgetsBinding.instance.addObserver(this);
      _observerAdded = true;
    }
    ref.onDispose(() {
      if (_observerAdded) WidgetsBinding.instance.removeObserver(this);
      unawaited(_subscription?.cancel());
      unawaited(recognizer.cancel());
    });
    return VoiceSearchState(language: VoiceLanguage.fromAppLocale(locale));
  }

  Future<void> start({Future<bool> Function()? showNotice}) async {
    if (state.phase != VoiceSearchPhase.idle && state.phase != VoiceSearchPhase.failed) return;
    final session = ++_session;
    state = state.copyWith(
      phase: VoiceSearchPhase.starting,
      partialText: '',
      error: null,
      result: null,
    );
    try {
      final savedLanguage = await _preferences.getLanguage();
      if (!_isCurrent(session)) return;
      if (savedLanguage != null) state = state.copyWith(language: savedLanguage);

      if (!await _preferences.noticeShown()) {
        final accepted = await (showNotice?.call() ?? Future<bool>.value(false));
        if (!_isCurrent(session)) return;
        if (!accepted) {
          state = state.copyWith(phase: VoiceSearchPhase.idle);
          return;
        }
        await _preferences.setNoticeShown();
      }

      final available = await _recognizer.availability();
      if (!_isCurrent(session)) return;
      if (!available) {
        state = state.copyWith(phase: VoiceSearchPhase.failed, error: await _permissionError());
        return;
      }

      final localeId = _resolveLocale(state.language, await _recognizer.languages());
      if (!_isCurrent(session)) return;
      if (localeId == null) {
        state = state.copyWith(
          phase: VoiceSearchPhase.failed,
          error: VoiceError.languageUnavailable,
        );
        return;
      }

      state = state.copyWith(phase: VoiceSearchPhase.listening);
      _subscription = _recognizer.listen(localeId).listen(
            (event) => _onEvent(session, event),
            onError: (_) => _fail(session, VoiceError.unavailable),
          );
    } on Object {
      if (_isCurrent(session)) {
        state = state.copyWith(phase: VoiceSearchPhase.failed, error: VoiceError.unavailable);
      }
    }
  }

  Future<VoiceError> _permissionError() async {
    final microphone = await Permission.microphone.status;
    final speech = Platform.isIOS ? await Permission.speech.status : PermissionStatus.granted;
    if (microphone.isPermanentlyDenied ||
        microphone.isRestricted ||
        speech.isPermanentlyDenied ||
        speech.isRestricted) {
      return VoiceError.permissionBlocked;
    }
    if (microphone.isDenied || speech.isDenied) return VoiceError.permissionDenied;
    return VoiceError.unavailable;
  }

  String? _resolveLocale(VoiceLanguage language, List<String> installed) {
    String normalized(String locale) => locale.replaceAll('-', '_').toLowerCase();
    String? find(String preferred) =>
        installed.where((locale) => normalized(locale) == normalized(preferred)).firstOrNull;
    if (language == VoiceLanguage.hindi) {
      return find('hi_IN');
    }
    for (final preferred in ['en_IN', 'en_US', 'en_GB']) {
      final locale = find(preferred);
      if (locale != null) return locale;
    }
    return installed.where((locale) => normalized(locale).startsWith('en_')).firstOrNull;
  }

  void _onEvent(int session, SpeechEvent event) {
    if (!_isCurrent(session)) return;
    switch (event) {
      case SpeechPartial(:final text):
        state = state.copyWith(partialText: text);
      case SpeechFinal(:final text):
        _finish(session, text.isEmpty ? state.partialText : text);
      case SpeechFailed(:final error):
        _fail(session, error);
      case SpeechEnded():
        _finish(session, state.partialText);
    }
  }

  void _finish(int session, String text) {
    if (!_isCurrent(session) ||
        state.phase == VoiceSearchPhase.done ||
        state.phase == VoiceSearchPhase.failed) {
      return;
    }
    final normalized = normalizeVoiceQuery(text);
    unawaited(_subscription?.cancel());
    if (normalized.isEmpty) {
      state = state.copyWith(phase: VoiceSearchPhase.failed, error: VoiceError.noSpeech);
    } else {
      state = state.copyWith(
        phase: VoiceSearchPhase.done,
        result: normalized,
        partialText: normalized,
      );
    }
  }

  void _fail(int session, VoiceError error) {
    if (!_isCurrent(session) || state.phase == VoiceSearchPhase.done) return;
    state = state.copyWith(phase: VoiceSearchPhase.failed, error: error);
    unawaited(_subscription?.cancel());
  }

  bool _isCurrent(int session) => ref.mounted && session == _session;

  Future<void> stop() async {
    if (state.phase != VoiceSearchPhase.listening) return;
    state = state.copyWith(phase: VoiceSearchPhase.finishing);
    try {
      await _recognizer.stop();
    } on Object {
      _fail(_session, VoiceError.unavailable);
    }
  }

  Future<void> cancel() async {
    ++_session;
    final recognizer = _recognizer;
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
    await recognizer.cancel();
    if (ref.mounted) {
      state = state.copyWith(
        phase: VoiceSearchPhase.idle,
        partialText: '',
        error: null,
        result: null,
      );
    }
  }

  Future<void> switchLanguage(VoiceLanguage language) async {
    if (state.phase == VoiceSearchPhase.starting) return;
    final restart = state.phase != VoiceSearchPhase.idle && state.phase != VoiceSearchPhase.done;
    final preferences = _preferences;
    await cancel();
    if (!ref.mounted) return;
    await preferences.setLanguage(language);
    if (!ref.mounted) return;
    state = state.copyWith(language: language);
    if (restart) await start();
  }

  Future<void> openSettings() => openAppSettings();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final interrupted = state == AppLifecycleState.paused ||
        (state == AppLifecycleState.inactive &&
            (this.state.phase == VoiceSearchPhase.listening ||
                this.state.phase == VoiceSearchPhase.finishing));
    if (interrupted) {
      unawaited(cancel());
    }
  }
}
