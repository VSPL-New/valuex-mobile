// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_search_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VoiceSearchController)
final voiceSearchControllerProvider = VoiceSearchControllerProvider._();

final class VoiceSearchControllerProvider
    extends $NotifierProvider<VoiceSearchController, VoiceSearchState> {
  VoiceSearchControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'voiceSearchControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$voiceSearchControllerHash();

  @$internal
  @override
  VoiceSearchController create() => VoiceSearchController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoiceSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoiceSearchState>(value),
    );
  }
}

String _$voiceSearchControllerHash() => r'22dc9d01499d1113bf2c8217722a8a06ede75fbb';

abstract class _$VoiceSearchController extends $Notifier<VoiceSearchState> {
  VoiceSearchState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VoiceSearchState, VoiceSearchState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<VoiceSearchState, VoiceSearchState>, VoiceSearchState, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
