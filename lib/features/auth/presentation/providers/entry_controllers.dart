import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/utils/validators.dart';
import 'auth_providers.dart';
import 'registration_flow.dart';

part 'entry_controllers.g.dart';

@riverpod
class MobileInput extends _$MobileInput {
  @override
  String build() => '';

  void update(String value) => state = value;
}

/// Number typed on the Sign In screen; separate from the sign-up number so the two never mix.
@riverpod
class SignInMobileInput extends _$SignInMobileInput {
  @override
  String build() => '';

  void update(String value) => state = value;
}

@riverpod
class EmailInput extends _$EmailInput {
  @override
  String build() => '';

  void update(String value) => state = value;
}

/// Sends the registration OTP to the typed mobile number.
@riverpod
class MobileEntryController extends _$MobileEntryController {
  @override
  FutureOr<void> build() {}

  /// Removes the last send error once the user edits the number.
  void clearError() {
    if (state.hasError) state = const AsyncData(null);
  }

  /// Returns true when the OTP was sent.
  Future<bool> sendOtp() async {
    final mobile = ref.read(mobileInputProvider);
    if (!Validators.isValidMobile(mobile) || state.isLoading) return false;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final sent = await ref.read(authRepositoryProvider).initiateRegistration(mobile);
      ref.read(registrationFlowProvider.notifier).mobileOtpSent(mobile, sent.expiresInSeconds);
    });
    if (!ref.mounted) return !result.hasError;
    state = result;
    return !result.hasError;
  }
}

/// Sends the sign-in OTP to the typed mobile number of an existing account.
@riverpod
class SignInEntryController extends _$SignInEntryController {
  @override
  FutureOr<void> build() {}

  /// Removes the last send error once the user edits the number.
  void clearError() {
    if (state.hasError) state = const AsyncData(null);
  }

  /// Returns true when the OTP was sent.
  Future<bool> sendOtp() async {
    final mobile = ref.read(signInMobileInputProvider);
    if (!Validators.isValidMobile(mobile) || state.isLoading) return false;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final sent = await ref.read(authRepositoryProvider).initiateLogin(mobile);
      ref.read(registrationFlowProvider.notifier).mobileOtpSent(mobile, sent.expiresInSeconds);
    });
    if (!ref.mounted) return !result.hasError;
    state = result;
    return !result.hasError;
  }
}

/// Sends the verification OTP to the typed email address.
@riverpod
class EmailEntryController extends _$EmailEntryController {
  @override
  FutureOr<void> build() {}

  /// Removes the last send error once the user edits the address.
  void clearError() {
    if (state.hasError) state = const AsyncData(null);
  }

  Future<bool> sendOtp() async {
    final email = ref.read(emailInputProvider).trim();
    if (!Validators.isValidEmail(email) || state.isLoading) return false;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final sent = await ref.read(authRepositoryProvider).sendEmailOtp(email);
      ref.read(registrationFlowProvider.notifier).emailOtpSent(email, sent.expiresInSeconds);
    });
    if (!ref.mounted) return !result.hasError;
    state = result;
    return !result.hasError;
  }
}
