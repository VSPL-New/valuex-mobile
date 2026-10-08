import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/utils/validators.dart';
import 'auth_providers.dart';
import 'registration_flow.dart';
import 'session_controller.dart';

part 'aadhaar_controllers.g.dart';

class AadhaarFormState {
  final String number;
  final bool obscured;
  final String? consentGivenAt;
  final bool isSubmitting;
  final ApiError? error;

  /// The user tapped Verify with something missing; show what is wrong.
  final bool showValidation;

  const AadhaarFormState({
    this.number = '',
    this.obscured = true,
    this.consentGivenAt,
    this.isSubmitting = false,
    this.error,
    this.showValidation = false,
  });

  bool get hasConsent => consentGivenAt != null;
  bool get isNumberValid => Validators.isValidAadhaar(number);
  bool get canVerify => isNumberValid && hasConsent && !isSubmitting;

  AadhaarFormState copyWith({
    String? number,
    bool? obscured,
    String? consentGivenAt,
    bool clearConsent = false,
    bool? isSubmitting,
    ApiError? error,
    bool? showValidation,
    bool clearError = false,
  }) {
    return AadhaarFormState(
      number: number ?? this.number,
      obscured: obscured ?? this.obscured,
      consentGivenAt: clearConsent ? null : (consentGivenAt ?? this.consentGivenAt),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      showValidation: showValidation ?? this.showValidation,
    );
  }
}

/// Aadhaar entry. The number lives only in this state, which is dropped when the screen
/// closes, and is never logged or stored.
@riverpod
class AadhaarForm extends _$AadhaarForm {
  @override
  AadhaarFormState build() => const AadhaarFormState();

  void setNumber(String value) => state = state.copyWith(number: value, clearError: true);

  /// Called when Verify is tapped with a missing number or consent.
  void showValidation() => state = state.copyWith(showValidation: true);

  void toggleObscured() => state = state.copyWith(obscured: !state.obscured);

  /// The consent time is recorded when the box is ticked and sent as the consent token.
  void setConsent(bool given) {
    state = given
        ? state.copyWith(consentGivenAt: DateTime.now().toUtc().toIso8601String())
        : state.copyWith(clearConsent: true);
  }

  /// Returns true when the Aadhaar OTP was sent.
  Future<bool> sendOtp() async {
    if (!state.canVerify) return false;
    final number = state.number;
    final consent = state.consentGivenAt!;
    final repository = ref.read(authRepositoryProvider);
    final flow = ref.read(registrationFlowProvider.notifier);

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final started = await repository.initiateAadhaar(
        aadhaarNumber: number,
        consentToken: consent,
      );
      flow.aadhaarTransactionStarted(started.transactionId);
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

  /// Skips Aadhaar for now; the account moves on to Sign Up.
  Future<bool> skip() async {
    if (state.isSubmitting) return false;
    final repository = ref.read(authRepositoryProvider);
    final session = ref.read(sessionControllerProvider.notifier);

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      session.signedIn(await repository.skipAadhaar());
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

class AadhaarOtpState {
  final String code;
  final bool isVerifying;
  final ApiError? error;

  /// The user tapped Verify before entering all six digits.
  final bool codeIncomplete;

  const AadhaarOtpState({
    this.code = '',
    this.isVerifying = false,
    this.error,
    this.codeIncomplete = false,
  });

  bool get canVerify => Validators.isValidOtp(code) && !isVerifying;
}

/// Development-only OTP step for the sandbox Aadhaar provider.
@riverpod
class AadhaarOtpController extends _$AadhaarOtpController {
  @override
  AadhaarOtpState build() => const AadhaarOtpState();

  void setCode(String code) {
    state = AadhaarOtpState(
      code: code,
      codeIncomplete: Validators.isValidOtp(code) ? false : state.codeIncomplete,
    );
  }

  Future<bool> verify() async {
    final transactionId = ref.read(registrationFlowProvider).aadhaarTransactionId;
    if (state.isVerifying || transactionId == null) return false;
    if (!Validators.isValidOtp(state.code)) {
      state = AadhaarOtpState(code: state.code, codeIncomplete: true);
      return false;
    }
    final code = state.code;
    final repository = ref.read(authRepositoryProvider);
    final session = ref.read(sessionControllerProvider.notifier);

    state = AadhaarOtpState(code: code, isVerifying: true);
    try {
      session.signedIn(await repository.verifyAadhaar(transactionId: transactionId, otp: code));
    } on ApiError catch (error) {
      if (ref.mounted) {
        state = AadhaarOtpState(code: code, error: error);
      }
      return false;
    }
    if (ref.mounted) {
      state = AadhaarOtpState(code: code);
    }
    return true;
  }
}
