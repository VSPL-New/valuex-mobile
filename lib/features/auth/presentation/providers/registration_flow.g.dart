// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registration_flow.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RegistrationFlow)
const registrationFlowProvider = RegistrationFlowProvider._();

final class RegistrationFlowProvider
    extends $NotifierProvider<RegistrationFlow, RegistrationFlowState> {
  const RegistrationFlowProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'registrationFlowProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$registrationFlowHash();

  @$internal
  @override
  RegistrationFlow create() => RegistrationFlow();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RegistrationFlowState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RegistrationFlowState>(value),
    );
  }
}

String _$registrationFlowHash() => r'd5bf2de51732e01d8f247a7b71c694e1a67719b3';

abstract class _$RegistrationFlow extends $Notifier<RegistrationFlowState> {
  RegistrationFlowState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<RegistrationFlowState, RegistrationFlowState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<RegistrationFlowState, RegistrationFlowState>,
        RegistrationFlowState,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
