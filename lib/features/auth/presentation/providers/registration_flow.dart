import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'registration_flow.g.dart';

/// Values carried between the registration and sign-in screens (never persisted; the server
/// status is the truth).
class RegistrationFlowState {
  final String? mobile;
  final String? email;
  final int? otpExpiresInSeconds;
  final String? aadhaarTransactionId;

  /// Google sign-in in progress: the server session that the mobile OTP completes.
  final String? socialSessionToken;
  final String? googleEmail;

  const RegistrationFlowState({
    this.mobile,
    this.email,
    this.otpExpiresInSeconds,
    this.aadhaarTransactionId,
    this.socialSessionToken,
    this.googleEmail,
  });
}

@Riverpod(keepAlive: true)
class RegistrationFlow extends _$RegistrationFlow {
  @override
  RegistrationFlowState build() => const RegistrationFlowState();

  void mobileOtpSent(String mobile, int? expiresInSeconds) {
    state = RegistrationFlowState(mobile: mobile, otpExpiresInSeconds: expiresInSeconds);
  }

  void emailOtpSent(String email, int? expiresInSeconds) {
    state = RegistrationFlowState(
      mobile: state.mobile,
      email: email,
      otpExpiresInSeconds: expiresInSeconds,
    );
  }

  void aadhaarTransactionStarted(String transactionId) {
    state = RegistrationFlowState(
      mobile: state.mobile,
      email: state.email,
      aadhaarTransactionId: transactionId,
    );
  }

  void googleSessionStarted({required String socialSessionToken, required String email}) {
    state = RegistrationFlowState(socialSessionToken: socialSessionToken, googleEmail: email);
  }

  void googleMobileOtpSent(String mobile, int? expiresInSeconds) {
    state = RegistrationFlowState(
      mobile: mobile,
      otpExpiresInSeconds: expiresInSeconds,
      socialSessionToken: state.socialSessionToken,
      googleEmail: state.googleEmail,
    );
  }

  void reset() => state = const RegistrationFlowState();
}
