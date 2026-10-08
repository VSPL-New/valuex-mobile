// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_verification_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Code entry, countdowns, resend limits and verification for one OTP step.

@ProviderFor(OtpVerificationController)
const otpVerificationControllerProvider = OtpVerificationControllerFamily._();

/// Code entry, countdowns, resend limits and verification for one OTP step.
final class OtpVerificationControllerProvider
    extends $NotifierProvider<OtpVerificationController, OtpVerificationState> {
  /// Code entry, countdowns, resend limits and verification for one OTP step.
  const OtpVerificationControllerProvider._(
      {required OtpVerificationControllerFamily super.from, required OtpChannel super.argument})
      : super(
          retry: null,
          name: r'otpVerificationControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$otpVerificationControllerHash();

  @override
  String toString() {
    return r'otpVerificationControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  OtpVerificationController create() => OtpVerificationController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OtpVerificationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OtpVerificationState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OtpVerificationControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$otpVerificationControllerHash() => r'0d2566d35d83598767f4840c359723fce671a80c';

/// Code entry, countdowns, resend limits and verification for one OTP step.

final class OtpVerificationControllerFamily extends $Family
    with
        $ClassFamilyOverride<OtpVerificationController, OtpVerificationState, OtpVerificationState,
            OtpVerificationState, OtpChannel> {
  const OtpVerificationControllerFamily._()
      : super(
          retry: null,
          name: r'otpVerificationControllerProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Code entry, countdowns, resend limits and verification for one OTP step.

  OtpVerificationControllerProvider call(
    OtpChannel channel,
  ) =>
      OtpVerificationControllerProvider._(argument: channel, from: this);

  @override
  String toString() => r'otpVerificationControllerProvider';
}

/// Code entry, countdowns, resend limits and verification for one OTP step.

abstract class _$OtpVerificationController extends $Notifier<OtpVerificationState> {
  late final _$args = ref.$arg as OtpChannel;
  OtpChannel get channel => _$args;

  OtpVerificationState build(
    OtpChannel channel,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(
      _$args,
    );
    final ref = this.ref as $Ref<OtpVerificationState, OtpVerificationState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<OtpVerificationState, OtpVerificationState>,
        OtpVerificationState,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
