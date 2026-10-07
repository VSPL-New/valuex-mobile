// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'JustQlic';

  @override
  String get commonBack => 'Back';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonNext => 'Next';

  @override
  String onboardingPageOf(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get splashInitializing => 'Initializing A1 Engine...';

  @override
  String get homeComingSoon => 'Home — coming soon';

  @override
  String get onboardingTitle1 => 'JustQlic Makes Selling Simple';

  @override
  String get onboardingSubtitle1 =>
      'Snap your item and let AI create the listing, suggest details, and help you sell faster.';

  @override
  String get onboardingTitle2 => 'JustQlic Helps You\nFind';

  @override
  String get onboardingSubtitle2 =>
      'Upload or snap a photo to instantly discover the same or similar products available to buy.';

  @override
  String get onboardingTitle3 => 'Real People, Safer & Smarter Deals';

  @override
  String get onboardingSubtitle3 =>
      'Verified users, ratings, and smart fraud protection help make every deal safer and more reliable.';

  @override
  String get onboardingTitle4 => 'Pay Safe, Sell Safe & Secure';

  @override
  String get onboardingSubtitle4 =>
      'Your payment stays protected while you complete the transaction\nwith confidence.';

  @override
  String get createAccountCreate => 'Create an Account';

  @override
  String get createAccountSignIn => 'Sign In';

  @override
  String get createAccountOrLoginWith => 'Or login with';

  @override
  String get createAccountContinueGoogle => 'Continue with Google';

  @override
  String get createAccountContinueGuest => 'Continue as Guest';

  @override
  String get createAccountSignInComingSoon => 'Sign in is coming soon';

  @override
  String get createAccountGoogleComingSoon => 'Google sign-in is coming soon';

  @override
  String get signupMobileTitle => 'Create Account';

  @override
  String get signupMobileSubtitle => 'Join 10L+ users on JustQlic';

  @override
  String get signupMobileLabel => 'MOBILE NUMBER';

  @override
  String get signupMobileHint => 'We\'ll send an OTP to verify your number';

  @override
  String get signupMobileSendOtp => 'Send OTP';

  @override
  String get signupMobileInvalid => 'Enter a valid 10-digit mobile number';

  @override
  String get signupMobileOtpComingSoon => 'OTP verification is coming soon';

  @override
  String get errorUnableToConnect => 'Unable to connect — Retry';

  @override
  String get errorSomethingWentWrong => 'Something went wrong — Try Again';

  @override
  String get errorSessionExpired => 'Session expired — Login again';

  @override
  String get accountBlockedTitle => 'Account unavailable';

  @override
  String get accountBlockedMessage =>
      'This account cannot be used right now. Please contact support for help.';

  @override
  String get accountBlockedAction => 'Back to start';

  @override
  String get authErrorMobileRegistered => 'This mobile number is already registered';

  @override
  String get authErrorEmailRegistered => 'This email is already linked to another account';

  @override
  String get authErrorInvalidOtp => 'Invalid or expired OTP';

  @override
  String get authErrorOtpExpired => 'OTP has expired. Please request a new one';

  @override
  String get authErrorOtpRateLimit => 'Too many OTP requests. Please try again in 10 minutes';

  @override
  String get authErrorOtpMaxAttempts => 'Too many failed attempts. Please request a new OTP';

  @override
  String get authErrorInvalidState => 'This step is not available right now';

  @override
  String get authErrorUserNotFound => 'We could not find your account. Please start again';

  @override
  String get authErrorValidation => 'Please check the details you entered';

  @override
  String get emailEntryTitle => 'Verify Email';

  @override
  String get emailEntrySubtitle => 'Add your email to keep your account secure';

  @override
  String get emailEntryLabel => 'EMAIL ADDRESS';

  @override
  String get emailEntryFieldHint => 'name@example.com';

  @override
  String get emailEntryHint => 'We\'ll send an OTP to verify your email';

  @override
  String get emailEntrySendOtp => 'Send OTP';

  @override
  String get otpMobileTitle => 'Verify your number';

  @override
  String get otpEmailTitle => 'Verify your email';

  @override
  String otpSubtitle(String target) {
    return 'Enter the 6-digit code sent to $target';
  }

  @override
  String get otpFieldLabel => '6-digit one-time code';

  @override
  String get otpVerify => 'Verify';

  @override
  String get otpIncomplete => 'Enter the 6-digit code';

  @override
  String get otpResend => 'Resend code';

  @override
  String otpResendIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String otpExpiresIn(String time) {
    return 'Code expires in $time';
  }

  @override
  String get otpExpired => 'The code has expired. Request a new one.';

  @override
  String get otpResendLimit => 'Resend limit reached. Please try again later.';

  @override
  String get otpResent => 'A new code has been sent';

  @override
  String get otpChangeNumber => 'Change number';

  @override
  String get otpChangeEmail => 'Change email';

  @override
  String get aadhaarTitle => 'Verify Aadhaar';

  @override
  String get aadhaarSubtitle => 'Verify your identity with your Aadhaar number';

  @override
  String get aadhaarNote =>
      'You can ‘Skip for now’ but Aadhaar Verification is must before any transactions (Buy/Sell/Contact seller/buyer). So, before your first transaction, you must complete this one time Aadhaar Verification.';

  @override
  String get aadhaarNumberLabel => 'AADHAAR NUMBER';

  @override
  String get aadhaarNumberHint => '12-digit Aadhaar number';

  @override
  String get aadhaarShowNumber => 'Show Aadhaar number';

  @override
  String get aadhaarHideNumber => 'Hide Aadhaar number';

  @override
  String get aadhaarConsent => 'I consent to ValueX using my Aadhaar number to verify my identity';

  @override
  String get aadhaarVerifyButton => 'Verify Aadhaar';

  @override
  String get aadhaarSkip => 'Skip for now';

  @override
  String get aadhaarNotNow => 'Not now';

  @override
  String get aadhaarComingSoon =>
      'Aadhaar verification is coming soon. You can skip for now and complete it before your first transaction.';

  @override
  String get aadhaarDevBanner =>
      'DEVELOPMENT ONLY — to be replaced with the third-party Aadhaar verification service provider';

  @override
  String get aadhaarOtpTitle => 'Enter Aadhaar OTP';

  @override
  String get aadhaarOtpSubtitle =>
      'Enter the 6-digit code sent to your Aadhaar-linked mobile number';

  @override
  String get aadhaarChangeNumber => 'Change Aadhaar number';

  @override
  String get authErrorAadhaarUsed => 'This Aadhaar is already linked to an account';

  @override
  String get authErrorAadhaarRecovery =>
      'This Aadhaar is linked to a closed account. Please contact support';

  @override
  String get authErrorAadhaarUnavailable =>
      'Verification service temporarily unavailable. Please try again';

  @override
  String get authErrorAadhaarSessionExpired =>
      'Aadhaar session expired. Please enter your Aadhaar number again';

  @override
  String get authErrorAadhaarFailed => 'Unable to verify Aadhaar. Please try again';

  @override
  String get commonClose => 'Close';

  @override
  String get signupProfileTitle => 'Create your profile';

  @override
  String get signupProfileSubtitle => 'Almost there! Tell me a bit about yourself';

  @override
  String get signupAvatarEdit => 'Change avatar';

  @override
  String get signupAvatarSheetTitle => 'Choose your avatar';

  @override
  String get avatarGroupMale => 'Male';

  @override
  String get avatarGroupFemale => 'Female';

  @override
  String get avatarGroupNeutral => 'Neutral';

  @override
  String avatarLabel(int number) {
    return 'Avatar $number';
  }

  @override
  String get signupNameLabel => 'NAME';

  @override
  String get signupNameHint => 'Your full name';

  @override
  String get signupGenderLabel => 'GENDER';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOthers => 'Others';

  @override
  String get signupDobLabel => 'DATE OF BIRTH';

  @override
  String get signupDobHint => 'DD/MM/YYYY';

  @override
  String get signupDobPick => 'Choose date of birth';

  @override
  String get signupEmailLabel => 'EMAIL';

  @override
  String get signupPhoneLabel => 'PHONE';

  @override
  String get signupVerifiedReadOnly => 'Verified';

  @override
  String get signupStateLabel => 'STATE';

  @override
  String get signupStateHint => 'Select your state';

  @override
  String get signupStateSheetTitle => 'Select your state';

  @override
  String get signupCityLabel => 'CITY';

  @override
  String get signupCityHint => 'Your city';

  @override
  String get signupAddressLabel => 'ADDRESS';

  @override
  String get signupAddressHint => 'House number, street, area';

  @override
  String get signupPincodeLabel => 'PINCODE';

  @override
  String get signupPincodeHint => '6-digit pincode';

  @override
  String get signupTermsPrefix => 'I agree to the ';

  @override
  String get signupTermsLink => 'Terms and Conditions';

  @override
  String get signupTermsSuffix => ' and consent to the processing of my data';

  @override
  String get signupTermsHint => 'Open the Terms and Conditions first to turn this on';

  @override
  String get signupSubmit => 'Submit';

  @override
  String get signupHaveAccount => 'Already have an account?';

  @override
  String get signupSignIn => 'Sign In';

  @override
  String get signupErrorName => 'Enter 3 to 50 letters';

  @override
  String get signupErrorCity => 'Enter 2 to 100 letters';

  @override
  String get signupErrorAddress => 'Enter 10 to 255 characters';

  @override
  String get signupErrorPincode => 'Enter a valid 6-digit pincode';

  @override
  String get signupErrorDobFormat => 'Enter a valid date as DD/MM/YYYY';

  @override
  String get signupErrorDobFuture => 'Date of birth cannot be in the future';

  @override
  String get authErrorInvalidAddressState => 'Please choose a valid state';

  @override
  String get authErrorInvalidDob => 'Please enter a valid date of birth';

  @override
  String get authErrorTermsNotAccepted => 'Please accept the terms and conditions to continue';

  @override
  String get authErrorConsentRequired => 'Consent for data processing is required';

  @override
  String get authErrorInvalidAvatar => 'Selected avatar is not available. Please choose another';

  @override
  String get termsTitle => 'Terms and Conditions';

  @override
  String get termsLastUpdated => 'Last updated: [date to be added]';

  @override
  String get termsPlaceholder => '[Legal text to be added]';

  @override
  String get termsSection1 => '1. Acceptance of terms';

  @override
  String get termsSection2 => '2. Your account';

  @override
  String get termsSection3 => '3. Using ValueX';

  @override
  String get termsSection4 => '4. Listings and purchases';

  @override
  String get termsSection5 => '5. Payments and fees';

  @override
  String get termsSection6 => '6. Privacy and your data';

  @override
  String get termsSection7 => '7. Changes to these terms';

  @override
  String get termsSection8 => '8. Contact us';
}
