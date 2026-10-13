import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/utils/validators.dart';
import '../../../profile/data/profile_repository.dart';
import '../../data/account_security_repository.dart';
import '../../domain/account_security.dart';

part 'contact_change_controller.g.dart';

enum ContactChangeStep { entry, code }

class ContactChangeState {
  final ContactChangeStep step;
  final String value;
  final String code;
  final int secondsUntilExpiry;
  final int secondsUntilResend;
  final int sendCount;
  final bool isBusy;
  final ApiError? error;

  /// Send was tapped with an invalid value, or Verify before six digits.
  final bool showInvalid;

  const ContactChangeState({
    this.step = ContactChangeStep.entry,
    this.value = '',
    this.code = '',
    this.secondsUntilExpiry = 0,
    this.secondsUntilResend = 0,
    this.sendCount = 0,
    this.isBusy = false,
    this.error,
    this.showInvalid = false,
  });

  bool get isExpired => step == ContactChangeStep.code && secondsUntilExpiry <= 0;
  bool get isLocked => error?.code == 'ERROR_OTP_MAX_ATTEMPTS';
  bool get canResend =>
      secondsUntilResend <= 0 && sendCount < ContactChangeController.maxSends && !isBusy;
  bool get canVerify => !isExpired && !isLocked && !isBusy;

  ContactChangeState copyWith({
    ContactChangeStep? step,
    String? value,
    String? code,
    int? secondsUntilExpiry,
    int? secondsUntilResend,
    int? sendCount,
    bool? isBusy,
    ApiError? error,
    bool? showInvalid,
    bool clearError = false,
  }) {
    return ContactChangeState(
      step: step ?? this.step,
      value: value ?? this.value,
      code: code ?? this.code,
      secondsUntilExpiry: secondsUntilExpiry ?? this.secondsUntilExpiry,
      secondsUntilResend: secondsUntilResend ?? this.secondsUntilResend,
      sendCount: sendCount ?? this.sendCount,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      showInvalid: showInvalid ?? this.showInvalid,
    );
  }
}

/// Two-step change of the mobile number or email: enter the new value, then confirm the code
/// sent to it. The current value stays active on the server until the code is confirmed.
@riverpod
class ContactChangeController extends _$ContactChangeController {
  static const resendCooldownSeconds = 30;
  static const defaultExpirySeconds = 300;
  static const maxSends = 3;

  @override
  ContactChangeState build(ContactKind kind) {
    final timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    ref.onDispose(timer.cancel);
    return const ContactChangeState();
  }

  void _tick() {
    final current = state;
    if (current.step != ContactChangeStep.code ||
        (current.secondsUntilExpiry <= 0 && current.secondsUntilResend <= 0)) {
      return;
    }
    state = current.copyWith(
      secondsUntilExpiry: current.secondsUntilExpiry > 0 ? current.secondsUntilExpiry - 1 : 0,
      secondsUntilResend: current.secondsUntilResend > 0 ? current.secondsUntilResend - 1 : 0,
    );
  }

  bool _isValidValue(String value) =>
      kind == ContactKind.mobile ? Validators.isValidMobile(value) : Validators.isValidEmail(value);

  void setValue(String value) {
    state = state.copyWith(value: value, clearError: true, showInvalid: false);
  }

  /// Back to the entry step to type a different value.
  void editValue() {
    state = state.copyWith(
      step: ContactChangeStep.entry,
      code: '',
      clearError: true,
      showInvalid: false,
    );
  }

  Future<bool> sendCode() async {
    if (state.isBusy) return false;
    final value = state.value.trim();
    if (!_isValidValue(value)) {
      state = state.copyWith(showInvalid: true);
      return false;
    }
    state = state.copyWith(value: value, isBusy: true, clearError: true);
    try {
      final sent = await ref.read(accountSecurityRepositoryProvider).startChange(kind, value);
      if (!ref.mounted) return false;
      state = state.copyWith(
        step: ContactChangeStep.code,
        code: '',
        isBusy: false,
        sendCount: 1,
        secondsUntilExpiry: sent.expiresInSeconds ?? defaultExpirySeconds,
        secondsUntilResend: resendCooldownSeconds,
      );
      return true;
    } on ApiError catch (error) {
      if (ref.mounted) state = state.copyWith(isBusy: false, error: error);
      return false;
    }
  }

  void setCode(String code) {
    state = state.copyWith(
      code: code,
      clearError: state.error != null && !state.isLocked,
      showInvalid: Validators.isValidOtp(code) ? false : state.showInvalid,
    );
  }

  /// True once the new value is confirmed and active.
  Future<bool> verify() async {
    if (!state.canVerify) return false;
    if (!Validators.isValidOtp(state.code)) {
      state = state.copyWith(showInvalid: true);
      return false;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await ref
          .read(accountSecurityRepositoryProvider)
          .confirmChange(kind, state.value, state.code);
      ref
        ..invalidate(accountSecurityProvider)
        ..invalidate(userProfileProvider);
      if (ref.mounted) state = state.copyWith(isBusy: false);
      return true;
    } on ApiError catch (error) {
      if (ref.mounted) state = state.copyWith(isBusy: false, error: error);
      return false;
    }
  }

  Future<void> resend() async {
    if (!state.canResend) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final sent = await ref.read(accountSecurityRepositoryProvider).startChange(kind, state.value);
      if (!ref.mounted) return;
      state = state.copyWith(
        isBusy: false,
        code: '',
        secondsUntilExpiry: sent.expiresInSeconds ?? defaultExpirySeconds,
        secondsUntilResend: resendCooldownSeconds,
        sendCount: state.sendCount + 1,
      );
    } on ApiError catch (error) {
      if (ref.mounted) state = state.copyWith(isBusy: false, error: error);
    }
  }
}
