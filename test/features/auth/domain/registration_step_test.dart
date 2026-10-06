import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/registration_step.dart';

void main() {
  group('AccountStatus.fromApi', () {
    test('parses every backend state', () {
      expect(AccountStatus.fromApi('NEW'), AccountStatus.newAccount);
      expect(AccountStatus.fromApi('OTP_PENDING'), AccountStatus.otpPending);
      expect(
        AccountStatus.fromApi('EMAIL_VERIFICATION_PENDING'),
        AccountStatus.emailVerificationPending,
      );
      expect(
        AccountStatus.fromApi('IDENTITY_VERIFICATION_PENDING'),
        AccountStatus.identityVerificationPending,
      );
      expect(AccountStatus.fromApi('SIGNUP_PENDING'), AccountStatus.signupPending);
      expect(AccountStatus.fromApi('ACTIVE'), AccountStatus.active);
      expect(AccountStatus.fromApi('UNDER_REVIEW'), AccountStatus.underReview);
      expect(AccountStatus.fromApi('RESTRICTED'), AccountStatus.restricted);
      expect(AccountStatus.fromApi('SUSPENDED'), AccountStatus.suspended);
      expect(AccountStatus.fromApi('BANNED'), AccountStatus.banned);
      expect(AccountStatus.fromApi('CLOSED'), AccountStatus.closed);
    });

    test('treats missing or new values as unknown', () {
      expect(AccountStatus.fromApi(null), AccountStatus.unknown);
      expect(AccountStatus.fromApi('SOMETHING_NEW'), AccountStatus.unknown);
    });
  });

  group('registrationStepFor (resume table)', () {
    const expected = {
      AccountStatus.newAccount: RegistrationStep.mobile,
      AccountStatus.otpPending: RegistrationStep.mobile,
      AccountStatus.emailVerificationPending: RegistrationStep.email,
      AccountStatus.identityVerificationPending: RegistrationStep.aadhaar,
      AccountStatus.signupPending: RegistrationStep.signup,
      AccountStatus.active: RegistrationStep.home,
      AccountStatus.underReview: RegistrationStep.home,
      AccountStatus.restricted: RegistrationStep.home,
      AccountStatus.suspended: RegistrationStep.blocked,
      AccountStatus.banned: RegistrationStep.blocked,
      AccountStatus.closed: RegistrationStep.blocked,
      AccountStatus.unknown: RegistrationStep.blocked,
    };

    for (final entry in expected.entries) {
      test('${entry.key.name} resumes at ${entry.value.name}', () {
        expect(registrationStepFor(entry.key), entry.value);
      });
    }

    test('covers every status', () {
      expect(expected.keys.toSet(), AccountStatus.values.toSet());
    });
  });
}
