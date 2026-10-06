/// Server-side account state; the single source of truth for registration progress.
enum AccountStatus {
  newAccount,
  otpPending,
  emailVerificationPending,
  identityVerificationPending,
  signupPending,
  active,
  underReview,
  restricted,
  suspended,
  banned,
  closed,
  unknown;

  static AccountStatus fromApi(String? value) {
    return switch (value) {
      'NEW' => newAccount,
      'OTP_PENDING' => otpPending,
      'EMAIL_VERIFICATION_PENDING' => emailVerificationPending,
      'IDENTITY_VERIFICATION_PENDING' => identityVerificationPending,
      'SIGNUP_PENDING' => signupPending,
      'ACTIVE' => active,
      'UNDER_REVIEW' => underReview,
      'RESTRICTED' => restricted,
      'SUSPENDED' => suspended,
      'BANNED' => banned,
      'CLOSED' => closed,
      _ => unknown,
    };
  }
}
