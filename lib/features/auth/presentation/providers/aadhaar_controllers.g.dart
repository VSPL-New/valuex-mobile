// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aadhaar_controllers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Aadhaar entry. The number lives only in this state, which is dropped when the screen
/// closes, and is never logged or stored.

@ProviderFor(AadhaarForm)
const aadhaarFormProvider = AadhaarFormProvider._();

/// Aadhaar entry. The number lives only in this state, which is dropped when the screen
/// closes, and is never logged or stored.
final class AadhaarFormProvider extends $NotifierProvider<AadhaarForm, AadhaarFormState> {
  /// Aadhaar entry. The number lives only in this state, which is dropped when the screen
  /// closes, and is never logged or stored.
  const AadhaarFormProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'aadhaarFormProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$aadhaarFormHash();

  @$internal
  @override
  AadhaarForm create() => AadhaarForm();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AadhaarFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AadhaarFormState>(value),
    );
  }
}

String _$aadhaarFormHash() => r'411d8a33696e9f49725a1c295ae53ca43d702f71';

/// Aadhaar entry. The number lives only in this state, which is dropped when the screen
/// closes, and is never logged or stored.

abstract class _$AadhaarForm extends $Notifier<AadhaarFormState> {
  AadhaarFormState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AadhaarFormState, AadhaarFormState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AadhaarFormState, AadhaarFormState>, AadhaarFormState, Object?, Object?>;
    element.handleValue(ref, created);
  }
}

/// Development-only OTP step for the sandbox Aadhaar provider.

@ProviderFor(AadhaarOtpController)
const aadhaarOtpControllerProvider = AadhaarOtpControllerProvider._();

/// Development-only OTP step for the sandbox Aadhaar provider.
final class AadhaarOtpControllerProvider
    extends $NotifierProvider<AadhaarOtpController, AadhaarOtpState> {
  /// Development-only OTP step for the sandbox Aadhaar provider.
  const AadhaarOtpControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'aadhaarOtpControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$aadhaarOtpControllerHash();

  @$internal
  @override
  AadhaarOtpController create() => AadhaarOtpController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AadhaarOtpState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AadhaarOtpState>(value),
    );
  }
}

String _$aadhaarOtpControllerHash() => r'43fd51aff9a98e5eb128efddf2fe919c08c73561';

/// Development-only OTP step for the sandbox Aadhaar provider.

abstract class _$AadhaarOtpController extends $Notifier<AadhaarOtpState> {
  AadhaarOtpState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AadhaarOtpState, AadhaarOtpState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AadhaarOtpState, AadhaarOtpState>, AadhaarOtpState, Object?, Object?>;
    element.handleValue(ref, created);
  }
}
