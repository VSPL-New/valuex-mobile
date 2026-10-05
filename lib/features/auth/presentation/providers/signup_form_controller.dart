import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/utils/provider_retry.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/avatar_catalog.dart';
import '../../domain/entities/gender.dart';
import '../../domain/entities/signup_details.dart';
import '../../domain/entities/user_profile.dart';
import 'auth_providers.dart';
import 'session_controller.dart';

part 'signup_form_controller.g.dart';

enum SignupFieldError { name, city, address, pincode, dobFormat, dobFuture }

class SignupFormState {
  final String? chosenAvatarId;
  final String displayName;
  final Gender? gender;
  final String dobText;
  final String? state;
  final String city;
  final String address;
  final String pincode;
  final bool termsViewed;
  final bool termsAccepted;
  final bool isSubmitting;
  final ApiError? error;

  const SignupFormState({
    this.chosenAvatarId,
    this.displayName = '',
    this.gender,
    this.dobText = '',
    this.state,
    this.city = '',
    this.address = '',
    this.pincode = '',
    this.termsViewed = false,
    this.termsAccepted = false,
    this.isSubmitting = false,
    this.error,
  });

  String get avatarId => chosenAvatarId ?? AvatarCatalog.defaultFor(gender);

  DateTime? get dateOfBirth => Validators.parseDateOfBirth(dobText);

  /// Errors are shown only once the user has typed something invalid.
  SignupFieldError? get nameError =>
      displayName.isNotEmpty && !Validators.isValidName(displayName) ? SignupFieldError.name : null;

  SignupFieldError? get cityError =>
      city.isNotEmpty && !Validators.isValidCity(city) ? SignupFieldError.city : null;

  SignupFieldError? get addressError =>
      address.isNotEmpty && !Validators.isValidAddress(address) ? SignupFieldError.address : null;

  SignupFieldError? get pincodeError =>
      pincode.isNotEmpty && !Validators.isValidPincode(pincode) ? SignupFieldError.pincode : null;

  SignupFieldError? get dobError {
    if (dobText.length < 10) return null;
    if (Validators.isFutureDate(dobText)) return SignupFieldError.dobFuture;
    return dateOfBirth == null ? SignupFieldError.dobFormat : null;
  }

  bool get isValid =>
      Validators.isValidName(displayName) &&
      gender != null &&
      dateOfBirth != null &&
      state != null &&
      Validators.isValidCity(city) &&
      Validators.isValidAddress(address) &&
      Validators.isValidPincode(pincode) &&
      termsAccepted;

  bool get canSubmit => isValid && !isSubmitting;

  SignupFormState copyWith({
    String? chosenAvatarId,
    String? displayName,
    Gender? gender,
    String? dobText,
    String? state,
    String? city,
    String? address,
    String? pincode,
    bool? termsViewed,
    bool? termsAccepted,
    bool? isSubmitting,
    ApiError? error,
    bool clearError = false,
  }) {
    return SignupFormState(
      chosenAvatarId: chosenAvatarId ?? this.chosenAvatarId,
      displayName: displayName ?? this.displayName,
      gender: gender ?? this.gender,
      dobText: dobText ?? this.dobText,
      state: state ?? this.state,
      city: city ?? this.city,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
      termsViewed: termsViewed ?? this.termsViewed,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// The Sign Up form: values, validation and submission.
@riverpod
class SignupForm extends _$SignupForm {
  @override
  SignupFormState build() => const SignupFormState();

  void setDisplayName(String value) => state = state.copyWith(displayName: value);

  void setGender(Gender value) => state = state.copyWith(gender: value);

  void setDobText(String value) => state = state.copyWith(dobText: value);

  void setDateOfBirth(DateTime date) =>
      state = state.copyWith(dobText: Validators.formatDate(date));

  void setState(String value) => state = state.copyWith(state: value);

  void setCity(String value) => state = state.copyWith(city: value);

  void setAddress(String value) => state = state.copyWith(address: value);

  void setPincode(String value) => state = state.copyWith(pincode: value);

  void chooseAvatar(String avatarId) => state = state.copyWith(chosenAvatarId: avatarId);

  /// The consent switch unlocks once the Terms and Conditions page has been opened and closed.
  void markTermsViewed() => state = state.copyWith(termsViewed: true);

  void setTermsAccepted(bool value) {
    if (!state.termsViewed) return;
    state = state.copyWith(termsAccepted: value);
  }

  /// Returns true when registration completed and the session now shows the new status.
  Future<bool> submit() async {
    final current = state;
    final dateOfBirth = current.dateOfBirth;
    if (!current.canSubmit || dateOfBirth == null) return false;

    final repository = ref.read(authRepositoryProvider);
    final session = ref.read(sessionControllerProvider.notifier);
    state = current.copyWith(isSubmitting: true, clearError: true);
    try {
      final result = await repository.completeSignup(
        SignupDetails(
          displayName: current.displayName.trim(),
          gender: current.gender!,
          dateOfBirth: dateOfBirth,
          state: current.state!,
          city: current.city.trim(),
          address: current.address.trim(),
          pincode: current.pincode,
          avatarId: current.avatarId,
          termsAccepted: current.termsAccepted,
          consentGiven: current.termsAccepted,
          termsVersion: AppConstants.termsVersion,
        ),
      );
      session.signedIn(result);
    } on ApiError catch (error) {
      if (ref.mounted) {
        state = state.copyWith(isSubmitting: false, error: error);
      }
      return false;
    }
    if (ref.mounted) {
      state = state.copyWith(isSubmitting: false);
    }
    return true;
  }
}

/// The signed-in user's profile (contact details arrive masked from the server).
@Riverpod(retry: noAutoRetry)
Future<UserProfile> currentUserProfile(Ref ref) {
  return ref.watch(authRepositoryProvider).fetchProfile();
}
