import 'account_status.dart';

/// Where an account belongs in the registration flow.
enum RegistrationStep { mobile, email, aadhaar, signup, home, blocked }

RegistrationStep registrationStepFor(AccountStatus status) {
  return switch (status) {
    AccountStatus.newAccount || AccountStatus.otpPending => RegistrationStep.mobile,
    AccountStatus.emailVerificationPending => RegistrationStep.email,
    AccountStatus.identityVerificationPending => RegistrationStep.aadhaar,
    AccountStatus.signupPending => RegistrationStep.signup,
    AccountStatus.active ||
    AccountStatus.underReview ||
    AccountStatus.restricted =>
      RegistrationStep.home,
    AccountStatus.suspended ||
    AccountStatus.banned ||
    AccountStatus.closed ||
    AccountStatus.unknown =>
      RegistrationStep.blocked,
  };
}
