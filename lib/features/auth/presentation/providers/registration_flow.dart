import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'registration_flow.g.dart';

/// Values carried between registration screens (never persisted; the server status is the truth).
class RegistrationFlowState {
  final String? mobile;
  final String? email;
  final int? otpExpiresInSeconds;
  final String? aadhaarTransactionId;

  const RegistrationFlowState({
    this.mobile,
    this.email,
    this.otpExpiresInSeconds,
    this.aadhaarTransactionId,
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

  void reset() => state = const RegistrationFlowState();
}
