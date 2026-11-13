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

String _$voiceSearchControllerHash() => r'04675ad57a5cb6c81807073b3855598b6a1186fe';

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
