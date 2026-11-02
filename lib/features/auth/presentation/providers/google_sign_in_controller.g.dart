// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_sign_in_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Turns a Google account into a ValueX session. The state carries the last error.

@ProviderFor(GoogleSignInController)
final googleSignInControllerProvider = GoogleSignInControllerProvider._();

/// Turns a Google account into a ValueX session. The state carries the last error.
final class GoogleSignInControllerProvider
    extends $AsyncNotifierProvider<GoogleSignInController, void> {
  /// Turns a Google account into a ValueX session. The state carries the last error.
  GoogleSignInControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'googleSignInControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$googleSignInControllerHash();

  @$internal
  @override
  GoogleSignInController create() => GoogleSignInController();
}

String _$googleSignInControllerHash() => r'6a9af100c229581e2d4d0499fd9f4e0698946050';

/// Turns a Google account into a ValueX session. The state carries the last error.

abstract class _$GoogleSignInController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<AsyncValue<void>, void>,
        AsyncValue<void>, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
