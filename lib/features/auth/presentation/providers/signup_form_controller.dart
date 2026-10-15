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

enum SignupFieldError { name, terms }

class SignupFormState {
  final String? chosenAvatarId;
  final String displayName;

  /// Optional: null until the user picks one, and again after they tap the chosen option.
  final Gender? gender;
  final bool termsViewed;
  final bool termsAccepted;
  final bool isSubmitting;
  final ApiError? error;

  /// The user tapped Submit with something missing; show what is wrong.
  final bool showValidation;

  const SignupFormState({
    this.chosenAvatarId,
    this.displayName = '',
    this.gender,
    this.termsViewed = false,
    this.termsAccepted = false,
    this.isSubmitting = false,
    this.error,
    this.showValidation = false,
  });

  String get avatarId => chosenAvatarId ?? AvatarCatalog.defaultFor(gender);

  /// A field shows its error once the user typed something invalid, or after Submit was tapped.
  SignupFieldError? get nameError =>
      (displayName.isNotEmpty || showValidation) && !Validators.isValidName(displayName)
          ? SignupFieldError.name
          : null;

  SignupFieldError? get termsError =>
      showValidation && !termsAccepted ? SignupFieldError.terms : null;

  /// The first field with an error, in screen order.
  SignupFieldError? get firstError => nameError ?? termsError;

  bool get isValid => Validators.isValidName(displayName) && termsAccepted;

  bool get canSubmit => isValid && !isSubmitting;

  SignupFormState copyWith({
    String? chosenAvatarId,
    String? displayName,
    Gender? gender,
    bool clearGender = false,
    bool? termsViewed,
    bool? termsAccepted,
    bool? isSubmitting,
    ApiError? error,
    bool? showValidation,
    bool clearError = false,
  }) {
    return SignupFormState(
      chosenAvatarId: chosenAvatarId ?? this.chosenAvatarId,
      displayName: displayName ?? this.displayName,
      gender: clearGender ? null : (gender ?? this.gender),
      termsViewed: termsViewed ?? this.termsViewed,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      showValidation: showValidation ?? this.showValidation,
    );
  }
}

/// The Sign Up form: values, validation and submission.
@riverpod
class SignupForm extends _$SignupForm {
  @override
  SignupFormState build() => const SignupFormState();

  /// Called when Submit is tapped while the form is incomplete.
  void showValidation() => state = state.copyWith(showValidation: true);

  void setDisplayName(String value) => state = state.copyWith(displayName: value);

  /// Choosing the selected option again clears it, since gender is optional.
  void setGender(Gender value) => state =
      state.gender == value ? state.copyWith(clearGender: true) : state.copyWith(gender: value);

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
    if (!current.canSubmit) return false;

    final repository = ref.read(authRepositoryProvider);
    final session = ref.read(sessionControllerProvider.notifier);
    state = current.copyWith(isSubmitting: true, clearError: true);
    try {
      final result = await repository.completeSignup(
        SignupDetails(
          displayName: current.displayName.trim(),
          gender: current.gender,
          avatarId: current.avatarId,
          termsAccepted: current.termsAccepted,
          consentGiven: current.termsAccepted,
          termsVersion: AppConstants.termsVersion,
        ),
      );
      session.signedIn(result);
    } on ApiError catch (error) {
      if (ref.mounted) state = state.copyWith(isSubmitting: false, error: error);
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
