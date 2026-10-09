// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entry_controllers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MobileInput)
const mobileInputProvider = MobileInputProvider._();

final class MobileInputProvider extends $NotifierProvider<MobileInput, String> {
  const MobileInputProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'mobileInputProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$mobileInputHash();

  @$internal
  @override
  MobileInput create() => MobileInput();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$mobileInputHash() => r'4e6d88978a51ae44f06cc7cf064bc1186ef5fc7a';

abstract class _$MobileInput extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<String, String>, String, Object?, Object?>;
    element.handleValue(ref, created);
  }
}

/// Number typed on the Sign In screen; separate from the sign-up number so the two never mix.

@ProviderFor(SignInMobileInput)
const signInMobileInputProvider = SignInMobileInputProvider._();

/// Number typed on the Sign In screen; separate from the sign-up number so the two never mix.
final class SignInMobileInputProvider extends $NotifierProvider<SignInMobileInput, String> {
  /// Number typed on the Sign In screen; separate from the sign-up number so the two never mix.
  const SignInMobileInputProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'signInMobileInputProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$signInMobileInputHash();

  @$internal
  @override
  SignInMobileInput create() => SignInMobileInput();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$signInMobileInputHash() => r'5b8e4071b63f7c57757104c3eb830e9481fbdbd3';

/// Number typed on the Sign In screen; separate from the sign-up number so the two never mix.

abstract class _$SignInMobileInput extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<String, String>, String, Object?, Object?>;
    element.handleValue(ref, created);
  }
}

@ProviderFor(EmailInput)
const emailInputProvider = EmailInputProvider._();

final class EmailInputProvider extends $NotifierProvider<EmailInput, String> {
  const EmailInputProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'emailInputProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$emailInputHash();

  @$internal
  @override
  EmailInput create() => EmailInput();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$emailInputHash() => r'f8d8310abc8216bbc81f43c3b7f0a65cd9316098';

abstract class _$EmailInput extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<String, String>, String, Object?, Object?>;
    element.handleValue(ref, created);
  }
}

/// Sends the registration OTP to the typed mobile number.

@ProviderFor(MobileEntryController)
const mobileEntryControllerProvider = MobileEntryControllerProvider._();

/// Sends the registration OTP to the typed mobile number.
final class MobileEntryControllerProvider
    extends $AsyncNotifierProvider<MobileEntryController, void> {
  /// Sends the registration OTP to the typed mobile number.
  const MobileEntryControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'mobileEntryControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$mobileEntryControllerHash();

  @$internal
  @override
  MobileEntryController create() => MobileEntryController();
}

String _$mobileEntryControllerHash() => r'f7d65e1310443c8dfaa7c57227363f2e2a34eec1';

/// Sends the registration OTP to the typed mobile number.

abstract class _$MobileEntryController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<AsyncValue<void>, void>,
        AsyncValue<void>, Object?, Object?>;
    element.handleValue(ref, null);
  }
}

/// Sends the sign-in OTP to the typed mobile number of an existing account.

@ProviderFor(SignInEntryController)
const signInEntryControllerProvider = SignInEntryControllerProvider._();

/// Sends the sign-in OTP to the typed mobile number of an existing account.
final class SignInEntryControllerProvider
    extends $AsyncNotifierProvider<SignInEntryController, void> {
  /// Sends the sign-in OTP to the typed mobile number of an existing account.
  const SignInEntryControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'signInEntryControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$signInEntryControllerHash();

  @$internal
  @override
  SignInEntryController create() => SignInEntryController();
}

String _$signInEntryControllerHash() => r'8afdedadcec0bb4e0ce375676dd4bd7652fcfbaf';

/// Sends the sign-in OTP to the typed mobile number of an existing account.

abstract class _$SignInEntryController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<AsyncValue<void>, void>,
        AsyncValue<void>, Object?, Object?>;
    element.handleValue(ref, null);
  }
}

/// Sends the verification OTP to the typed email address.

@ProviderFor(EmailEntryController)
const emailEntryControllerProvider = EmailEntryControllerProvider._();

/// Sends the verification OTP to the typed email address.
final class EmailEntryControllerProvider
    extends $AsyncNotifierProvider<EmailEntryController, void> {
  /// Sends the verification OTP to the typed email address.
  const EmailEntryControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'emailEntryControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$emailEntryControllerHash();

  @$internal
  @override
  EmailEntryController create() => EmailEntryController();
}

String _$emailEntryControllerHash() => r'eb312e5592c98e508097ae59670ca3411d5071b3';

/// Sends the verification OTP to the typed email address.

abstract class _$EmailEntryController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<AsyncValue<void>, void>,
        AsyncValue<void>, Object?, Object?>;
    element.handleValue(ref, null);
  }
}
