import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/utils/validators.dart';
import 'auth_providers.dart';
import 'registration_flow.dart';
import 'session_controller.dart';

part 'otp_verification_controller.g.dart';

enum OtpChannel { mobile, email }

class OtpVerificationState {
  final String code;
  final int secondsUntilExpiry;
  final int secondsUntilResend;
  final int sendCount;
  final bool isVerifying;
  final bool isResending;
  final ApiError? error;

  /// The user tapped Verify before entering all six digits.
  final bool codeIncomplete;

  const OtpVerificationState({
    required this.secondsUntilExpiry,
    required this.secondsUntilResend,
    this.code = '',
    this.sendCount = 1,
    this.isVerifying = false,
    this.isResending = false,
    this.error,
    this.codeIncomplete = false,
  });

  bool get isExpired => secondsUntilExpiry <= 0;
  bool get isLocked => error?.code == 'ERROR_OTP_MAX_ATTEMPTS';
  bool get canResend =>
      secondsUntilResend <= 0 &&
      sendCount < OtpVerificationController.maxSends &&
      !isResending &&
      !isVerifying;

  /// Verify is tappable unless something visible already explains why not.
  bool get canSubmit => !isExpired && !isLocked && !isVerifying && !isResending;
  bool get canVerify =>
      Validators.isValidOtp(code) && !isExpired && !isLocked && !isVerifying && !isResending;

  OtpVerificationState copyWith({
    String? code,
    int? secondsUntilExpiry,
    int? secondsUntilResend,
    int? sendCount,
    bool? isVerifying,
    bool? isResending,
    ApiError? error,
    bool? codeIncomplete,
    bool clearError = false,
  }) {
    return OtpVerificationState(
      code: code ?? this.code,
      secondsUntilExpiry: secondsUntilExpiry ?? this.secondsUntilExpiry,
      secondsUntilResend: secondsUntilResend ?? this.secondsUntilResend,
      sendCount: sendCount ?? this.sendCount,
      isVerifying: isVerifying ?? this.isVerifying,
      isResending: isResending ?? this.isResending,
      error: clearError ? null : (error ?? this.error),
      codeIncomplete: codeIncomplete ?? this.codeIncomplete,
    );
  }
}

/// Code entry, countdowns, resend limits and verification for one OTP step.
@riverpod
class OtpVerificationController extends _$OtpVerificationController {
  static const resendCooldownSeconds = 30;
  static const defaultExpirySeconds = 300;
  static const maxSends = 3;

  @override
  OtpVerificationState build(OtpChannel channel) {
    final timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    ref.onDispose(timer.cancel);

    final expiry = ref.read(registrationFlowProvider).otpExpiresInSeconds;
    return OtpVerificationState(
      secondsUntilExpiry: expiry ?? defaultExpirySeconds,
      secondsUntilResend: resendCooldownSeconds,
    );
  }

  void _tick() {
    final current = state;
    if (current.secondsUntilExpiry <= 0 && current.secondsUntilResend <= 0) {
      return;
    }
    state = current.copyWith(
      secondsUntilExpiry: current.secondsUntilExpiry > 0 ? current.secondsUntilExpiry - 1 : 0,
      secondsUntilResend: current.secondsUntilResend > 0 ? current.secondsUntilResend - 1 : 0,
    );
  }

  void setCode(String code) {
    state = state.copyWith(
      code: code,
      clearError: state.error != null && !state.isLocked,
      codeIncomplete: Validators.isValidOtp(code) ? false : state.codeIncomplete,
    );
  }

  /// Returns true when the step succeeded and the session now reflects the new status.
  Future<bool> verify() async {
    if (!state.canSubmit) return false;
    if (!Validators.isValidOtp(state.code)) {
      state = state.copyWith(codeIncomplete: true);
      return false;
    }
    final code = state.code;
    final flow = ref.read(registrationFlowProvider);
    final repository = ref.read(authRepositoryProvider);
    final session = ref.read(sessionControllerProvider.notifier);

    state = state.copyWith(isVerifying: true, clearError: true);
    try {
      switch (channel) {
        case OtpChannel.mobile:
          final result = await repository.verifyMobileOtp(mobile: flow.mobile!, otp: code);
          session.signedIn(result);
        case OtpChannel.email:
          await repository.verifyEmailOtp(email: flow.email!, otp: code);
          await session.refreshStatus();
      }
    } on ApiError catch (error) {
      if (ref.mounted) {
        state = state.copyWith(isVerifying: false, error: error);
      }
      return false;
    }
    if (ref.mounted) {
      state = state.copyWith(isVerifying: false);
    }
    return true;
  }

  Future<void> resend() async {
    if (!state.canResend) return;
    final flow = ref.read(registrationFlowProvider);
    final repository = ref.read(authRepositoryProvider);

    state = state.copyWith(isResending: true, clearError: true);
    try {
      final sent = channel == OtpChannel.mobile
          ? await repository.initiateRegistration(flow.mobile!)
          : await repository.sendEmailOtp(flow.email!);
      if (!ref.mounted) return;
      state = state.copyWith(
        isResending: false,
        code: '',
        secondsUntilExpiry: sent.expiresInSeconds ?? defaultExpirySeconds,
        secondsUntilResend: resendCooldownSeconds,
        sendCount: state.sendCount + 1,
      );
    } on ApiError catch (error) {
      if (ref.mounted) {
        state = state.copyWith(isResending: false, error: error);
      }
    }
  }
}
