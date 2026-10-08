// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signup_form_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Sign Up form: values, validation and submission.

@ProviderFor(SignupForm)
const signupFormProvider = SignupFormProvider._();

/// The Sign Up form: values, validation and submission.
final class SignupFormProvider extends $NotifierProvider<SignupForm, SignupFormState> {
  /// The Sign Up form: values, validation and submission.
  const SignupFormProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'signupFormProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$signupFormHash();

  @$internal
  @override
  SignupForm create() => SignupForm();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignupFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignupFormState>(value),
    );
  }
}

String _$signupFormHash() => r'b1caefb6754af10ba008063af83bcb4b8ce4913d';

/// The Sign Up form: values, validation and submission.

abstract class _$SignupForm extends $Notifier<SignupFormState> {
  SignupFormState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<SignupFormState, SignupFormState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<SignupFormState, SignupFormState>, SignupFormState, Object?, Object?>;
    element.handleValue(ref, created);
  }
}

/// The signed-in user's profile (contact details arrive masked from the server).

@ProviderFor(currentUserProfile)
const currentUserProfileProvider = CurrentUserProfileProvider._();

/// The signed-in user's profile (contact details arrive masked from the server).

final class CurrentUserProfileProvider
    extends $FunctionalProvider<AsyncValue<UserProfile>, UserProfile, FutureOr<UserProfile>>
    with $FutureModifier<UserProfile>, $FutureProvider<UserProfile> {
  /// The signed-in user's profile (contact details arrive masked from the server).
  const CurrentUserProfileProvider._()
      : super(
          from: null,
          argument: null,
          retry: noAutoRetry,
          name: r'currentUserProfileProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentUserProfileHash();

  @$internal
  @override
  $FutureProviderElement<UserProfile> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<UserProfile> create(Ref ref) {
    return currentUserProfile(ref);
  }
}

String _$currentUserProfileHash() => r'db0d479e80593bb8e5a48050db483286e43dc3e7';
