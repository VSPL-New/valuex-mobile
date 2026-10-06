import '../../domain/entities/account_status.dart';
import '../../domain/entities/registration_step.dart';

sealed class SessionState {
  const SessionState();
}

class Unauthenticated extends SessionState {
  /// True when the stored session could not be renewed, so the user should be told.
  final bool sessionExpired;

  const Unauthenticated({this.sessionExpired = false});
}

class Authenticated extends SessionState {
  final AccountStatus status;
  final bool aadhaarVerified;

  const Authenticated({required this.status, required this.aadhaarVerified});

  RegistrationStep get step => registrationStepFor(status);

  /// Registration is finished (the account is active, even if Aadhaar was skipped).
  bool get isPastRegistration => step == RegistrationStep.home;
}
