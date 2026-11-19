// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Account state of the signed-in user. Loading and error describe the startup
/// lookup; routing decisions come from the server status, not from cached screens.

@ProviderFor(SessionController)
final sessionControllerProvider = SessionControllerProvider._();

/// Account state of the signed-in user. Loading and error describe the startup
/// lookup; routing decisions come from the server status, not from cached screens.
final class SessionControllerProvider
    extends $AsyncNotifierProvider<SessionController, SessionState> {
  /// Account state of the signed-in user. Loading and error describe the startup
  /// lookup; routing decisions come from the server status, not from cached screens.
  SessionControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: noAutoRetry,
          name: r'sessionControllerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$sessionControllerHash();

  @$internal
  @override
  SessionController create() => SessionController();
}

String _$sessionControllerHash() => r'423010396db0a76940382d5ed8b0983429b2b361';

/// Account state of the signed-in user. Loading and error describe the startup
/// lookup; routing decisions come from the server status, not from cached screens.

abstract class _$SessionController extends $AsyncNotifier<SessionState> {
  FutureOr<SessionState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SessionState>, SessionState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<SessionState>, SessionState>,
        AsyncValue<SessionState>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
