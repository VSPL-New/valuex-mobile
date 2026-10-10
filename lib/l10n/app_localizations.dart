import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('hi')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'JustQlic'**
  String get appName;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @onboardingPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String onboardingPageOf(int current, int total);

  /// No description provided for @splashInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing A1 Engine...'**
  String get splashInitializing;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'JustQlic Makes Selling Simple'**
  String get onboardingTitle1;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In en, this message translates to:
  /// **'Snap your item and let AI create the listing, suggest details, and help you sell faster.'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'JustQlic Helps You\nFind'**
  String get onboardingTitle2;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Upload or snap a photo to instantly discover the same or similar products available to buy.'**
  String get onboardingSubtitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Real People, Safer & Smarter Deals'**
  String get onboardingTitle3;

  /// No description provided for @onboardingSubtitle3.
  ///
  /// In en, this message translates to:
  /// **'Verified users, ratings, and smart fraud protection help make every deal safer and more reliable.'**
  String get onboardingSubtitle3;

  /// No description provided for @onboardingTitle4.
  ///
  /// In en, this message translates to:
  /// **'Pay Safe, Sell Safe & Secure'**
  String get onboardingTitle4;

  /// No description provided for @onboardingSubtitle4.
  ///
  /// In en, this message translates to:
  /// **'Your payment stays protected while you complete the transaction\nwith confidence.'**
  String get onboardingSubtitle4;

  /// No description provided for @createAccountCreate.
  ///
  /// In en, this message translates to:
  /// **'Create an Account'**
  String get createAccountCreate;

  /// No description provided for @createAccountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get createAccountSignIn;

  /// No description provided for @createAccountOrLoginWith.
  ///
  /// In en, this message translates to:
  /// **'Or login with'**
  String get createAccountOrLoginWith;

  /// No description provided for @createAccountContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get createAccountContinueGoogle;

  /// No description provided for @createAccountContinueGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get createAccountContinueGuest;

  /// No description provided for @createAccountGoogleComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is coming soon'**
  String get createAccountGoogleComingSoon;

  /// No description provided for @signupMobileTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupMobileTitle;

  /// No description provided for @signupMobileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join 10L+ users on JustQlic'**
  String get signupMobileSubtitle;

  /// No description provided for @signupMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'MOBILE NUMBER'**
  String get signupMobileLabel;

  /// No description provided for @signupMobileHint.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send an OTP to verify your number'**
  String get signupMobileHint;

  /// No description provided for @signupMobileSendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get signupMobileSendOtp;

  /// No description provided for @signupMobileInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit mobile number'**
  String get signupMobileInvalid;

  /// No description provided for @signupMobileOtpComingSoon.
  ///
  /// In en, this message translates to:
  /// **'OTP verification is coming soon'**
  String get signupMobileOtpComingSoon;

  /// No description provided for @errorUnableToConnect.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect — Retry'**
  String get errorUnableToConnect;

  /// No description provided for @errorSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong — Try Again'**
  String get errorSomethingWentWrong;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired — Login again'**
  String get errorSessionExpired;

  /// No description provided for @accountBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account unavailable'**
  String get accountBlockedTitle;

  /// No description provided for @accountBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'This account cannot be used right now. Please contact support for help.'**
  String get accountBlockedMessage;

  /// No description provided for @accountBlockedAction.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get accountBlockedAction;

  /// No description provided for @authErrorMobileRegistered.
  ///
  /// In en, this message translates to:
  /// **'This mobile number is already registered'**
  String get authErrorMobileRegistered;

  /// No description provided for @authErrorEmailRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already linked to another account'**
  String get authErrorEmailRegistered;

  /// No description provided for @authErrorInvalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired OTP'**
  String get authErrorInvalidOtp;

  /// No description provided for @authErrorOtpExpired.
  ///
  /// In en, this message translates to:
  /// **'OTP has expired. Please request a new one'**
  String get authErrorOtpExpired;

  /// No description provided for @authErrorOtpRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many OTP requests. Please try again in 10 minutes'**
  String get authErrorOtpRateLimit;

  /// No description provided for @authErrorOtpMaxAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Please request a new OTP'**
  String get authErrorOtpMaxAttempts;

  /// No description provided for @authErrorInvalidState.
  ///
  /// In en, this message translates to:
  /// **'This step is not available right now'**
  String get authErrorInvalidState;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'We could not find your account. Please start again'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorValidation.
  ///
  /// In en, this message translates to:
  /// **'Please check the details you entered'**
  String get authErrorValidation;

  /// No description provided for @emailEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get emailEntryTitle;

  /// No description provided for @emailEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your email to keep your account secure'**
  String get emailEntrySubtitle;

  /// No description provided for @emailEntryLabel.
  ///
  /// In en, this message translates to:
  /// **'EMAIL ADDRESS'**
  String get emailEntryLabel;

  /// No description provided for @emailEntryFieldHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get emailEntryFieldHint;

  /// No description provided for @emailEntryHint.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send an OTP to verify your email'**
  String get emailEntryHint;

  /// No description provided for @emailEntrySendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get emailEntrySendOtp;

  /// No description provided for @emailEntryInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get emailEntryInvalid;

  /// No description provided for @otpMobileTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your number'**
  String get otpMobileTitle;

  /// No description provided for @otpEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get otpEmailTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {target}'**
  String otpSubtitle(String target);

  /// No description provided for @otpFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit one-time code'**
  String get otpFieldLabel;

  /// No description provided for @otpVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get otpVerify;

  /// No description provided for @otpIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get otpIncomplete;

  /// No description provided for @otpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResend;

  /// No description provided for @otpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String otpResendIn(int seconds);

  /// No description provided for @otpExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Code expires in {time}'**
  String otpExpiresIn(String time);

  /// No description provided for @otpExpired.
  ///
  /// In en, this message translates to:
  /// **'The code has expired. Request a new one.'**
  String get otpExpired;

  /// No description provided for @otpResendLimit.
  ///
  /// In en, this message translates to:
  /// **'Resend limit reached. Please try again later.'**
  String get otpResendLimit;

  /// No description provided for @otpResent.
  ///
  /// In en, this message translates to:
  /// **'A new code has been sent'**
  String get otpResent;

  /// No description provided for @otpChangeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get otpChangeNumber;

  /// No description provided for @otpChangeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get otpChangeEmail;

  /// No description provided for @aadhaarTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Aadhaar'**
  String get aadhaarTitle;

  /// No description provided for @aadhaarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity with your Aadhaar number'**
  String get aadhaarSubtitle;

  /// No description provided for @aadhaarNote.
  ///
  /// In en, this message translates to:
  /// **'You can ‘Skip for now’ but Aadhaar Verification is must before any transactions (Buy/Sell/Contact seller/buyer). So, before your first transaction, you must complete this one time Aadhaar Verification.'**
  String get aadhaarNote;

  /// No description provided for @aadhaarNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'AADHAAR NUMBER'**
  String get aadhaarNumberLabel;

  /// No description provided for @aadhaarNumberHint.
  ///
  /// In en, this message translates to:
  /// **'12-digit Aadhaar number'**
  String get aadhaarNumberHint;

  /// No description provided for @aadhaarShowNumber.
  ///
  /// In en, this message translates to:
  /// **'Show Aadhaar number'**
  String get aadhaarShowNumber;

  /// No description provided for @aadhaarHideNumber.
  ///
  /// In en, this message translates to:
  /// **'Hide Aadhaar number'**
  String get aadhaarHideNumber;

  /// No description provided for @aadhaarConsent.
  ///
  /// In en, this message translates to:
  /// **'I consent to ValueX using my Aadhaar number to verify my identity'**
  String get aadhaarConsent;

  /// No description provided for @aadhaarVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify Aadhaar'**
  String get aadhaarVerifyButton;

  /// No description provided for @aadhaarNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter your 12-digit Aadhaar number'**
  String get aadhaarNumberInvalid;

  /// No description provided for @aadhaarConsentRequired.
  ///
  /// In en, this message translates to:
  /// **'Please accept to continue'**
  String get aadhaarConsentRequired;

  /// No description provided for @aadhaarSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get aadhaarSkip;

  /// No description provided for @aadhaarNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get aadhaarNotNow;

  /// No description provided for @aadhaarComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar verification is coming soon. You can skip for now and complete it before your first transaction.'**
  String get aadhaarComingSoon;

  /// No description provided for @aadhaarDevBanner.
  ///
  /// In en, this message translates to:
  /// **'DEVELOPMENT ONLY — to be replaced with the third-party Aadhaar verification service provider'**
  String get aadhaarDevBanner;

  /// No description provided for @aadhaarOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Aadhaar OTP'**
  String get aadhaarOtpTitle;

  /// No description provided for @aadhaarOtpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to your Aadhaar-linked mobile number'**
  String get aadhaarOtpSubtitle;

  /// No description provided for @aadhaarChangeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change Aadhaar number'**
  String get aadhaarChangeNumber;

  /// No description provided for @authErrorAadhaarUsed.
  ///
  /// In en, this message translates to:
  /// **'This Aadhaar is already linked to an account'**
  String get authErrorAadhaarUsed;

  /// No description provided for @authErrorAadhaarRecovery.
  ///
  /// In en, this message translates to:
  /// **'This Aadhaar is linked to a closed account. Please contact support'**
  String get authErrorAadhaarRecovery;

  /// No description provided for @authErrorAadhaarUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Verification service temporarily unavailable. Please try again'**
  String get authErrorAadhaarUnavailable;

  /// No description provided for @authErrorAadhaarSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar session expired. Please enter your Aadhaar number again'**
  String get authErrorAadhaarSessionExpired;

  /// No description provided for @authErrorAadhaarFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify Aadhaar. Please try again'**
  String get authErrorAadhaarFailed;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @signupProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your profile'**
  String get signupProfileTitle;

  /// No description provided for @signupProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Almost there! Tell me a bit about yourself'**
  String get signupProfileSubtitle;

  /// No description provided for @signupAvatarEdit.
  ///
  /// In en, this message translates to:
  /// **'Change avatar'**
  String get signupAvatarEdit;

  /// No description provided for @signupAvatarSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your avatar'**
  String get signupAvatarSheetTitle;

  /// No description provided for @avatarGroupMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get avatarGroupMale;

  /// No description provided for @avatarGroupFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get avatarGroupFemale;

  /// No description provided for @avatarGroupNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get avatarGroupNeutral;

  /// No description provided for @avatarLabel.
  ///
  /// In en, this message translates to:
  /// **'Avatar {number}'**
  String avatarLabel(int number);

  /// No description provided for @signupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get signupNameLabel;

  /// No description provided for @signupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your full name'**
  String get signupNameHint;

  /// No description provided for @signupGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'GENDER'**
  String get signupGenderLabel;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get genderOthers;

  /// No description provided for @signupDobLabel.
  ///
  /// In en, this message translates to:
  /// **'DATE OF BIRTH'**
  String get signupDobLabel;

  /// No description provided for @signupDobHint.
  ///
  /// In en, this message translates to:
  /// **'DD/MM/YYYY'**
  String get signupDobHint;

  /// No description provided for @signupDobPick.
  ///
  /// In en, this message translates to:
  /// **'Choose date of birth'**
  String get signupDobPick;

  /// No description provided for @signupEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'EMAIL'**
  String get signupEmailLabel;

  /// No description provided for @signupPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'PHONE'**
  String get signupPhoneLabel;

  /// No description provided for @signupVerifiedReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get signupVerifiedReadOnly;

  /// No description provided for @signupStateLabel.
  ///
  /// In en, this message translates to:
  /// **'STATE'**
  String get signupStateLabel;

  /// No description provided for @signupStateHint.
  ///
  /// In en, this message translates to:
  /// **'Select your state'**
  String get signupStateHint;

  /// No description provided for @signupStateSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Select your state'**
  String get signupStateSheetTitle;

  /// No description provided for @signupCityLabel.
  ///
  /// In en, this message translates to:
  /// **'CITY'**
  String get signupCityLabel;

  /// No description provided for @signupCityHint.
  ///
  /// In en, this message translates to:
  /// **'Your city'**
  String get signupCityHint;

  /// No description provided for @signupAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'ADDRESS'**
  String get signupAddressLabel;

  /// No description provided for @signupAddressHint.
  ///
  /// In en, this message translates to:
  /// **'House number, street, area'**
  String get signupAddressHint;

  /// No description provided for @signupPincodeLabel.
  ///
  /// In en, this message translates to:
  /// **'PINCODE'**
  String get signupPincodeLabel;

  /// No description provided for @signupPincodeHint.
  ///
  /// In en, this message translates to:
  /// **'6-digit pincode'**
  String get signupPincodeHint;

  /// No description provided for @signupTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get signupTermsPrefix;

  /// No description provided for @signupTermsLink.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get signupTermsLink;

  /// No description provided for @signupTermsSuffix.
  ///
  /// In en, this message translates to:
  /// **' and consent to the processing of my data'**
  String get signupTermsSuffix;

  /// No description provided for @signupTermsHint.
  ///
  /// In en, this message translates to:
  /// **'Open the Terms and Conditions first to turn this on'**
  String get signupTermsHint;

  /// No description provided for @signupSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get signupSubmit;

  /// No description provided for @signupHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get signupHaveAccount;

  /// No description provided for @signupSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signupSignIn;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Please sign in to continue.'**
  String get signInSubtitle;

  /// No description provided for @signInNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get signInNoAccount;

  /// No description provided for @signInSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signInSignUp;

  /// No description provided for @signInCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get signInCreateAccount;

  /// No description provided for @authErrorMobileNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'No account found with this mobile number. Please create an account'**
  String get authErrorMobileNotRegistered;

  /// No description provided for @authErrorSignInIncomplete.
  ///
  /// In en, this message translates to:
  /// **'This number isn\'t verified yet. Please create an account to finish setting it up'**
  String get authErrorSignInIncomplete;

  /// No description provided for @authErrorAccountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Your account is suspended. Please contact support'**
  String get authErrorAccountSuspended;

  /// No description provided for @authErrorAccountRecovery.
  ///
  /// In en, this message translates to:
  /// **'Your account requires recovery. Please contact support'**
  String get authErrorAccountRecovery;

  /// No description provided for @signupErrorGender.
  ///
  /// In en, this message translates to:
  /// **'Choose one option'**
  String get signupErrorGender;

  /// No description provided for @signupErrorState.
  ///
  /// In en, this message translates to:
  /// **'Choose your state'**
  String get signupErrorState;

  /// No description provided for @signupErrorTerms.
  ///
  /// In en, this message translates to:
  /// **'Accept the Terms and Conditions to continue'**
  String get signupErrorTerms;

  /// No description provided for @signupErrorName.
  ///
  /// In en, this message translates to:
  /// **'Enter 3 to 50 letters'**
  String get signupErrorName;

  /// No description provided for @signupErrorCity.
  ///
  /// In en, this message translates to:
  /// **'Enter 2 to 100 letters'**
  String get signupErrorCity;

  /// No description provided for @signupErrorAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter 10 to 255 characters'**
  String get signupErrorAddress;

  /// No description provided for @signupErrorPincode.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 6-digit pincode'**
  String get signupErrorPincode;

  /// No description provided for @signupErrorDobFormat.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid date as DD/MM/YYYY'**
  String get signupErrorDobFormat;

  /// No description provided for @signupErrorDobFuture.
  ///
  /// In en, this message translates to:
  /// **'Date of birth cannot be in the future'**
  String get signupErrorDobFuture;

  /// No description provided for @authErrorInvalidAddressState.
  ///
  /// In en, this message translates to:
  /// **'Please choose a valid state'**
  String get authErrorInvalidAddressState;

  /// No description provided for @authErrorInvalidDob.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid date of birth'**
  String get authErrorInvalidDob;

  /// No description provided for @authErrorTermsNotAccepted.
  ///
  /// In en, this message translates to:
  /// **'Please accept the terms and conditions to continue'**
  String get authErrorTermsNotAccepted;

  /// No description provided for @authErrorConsentRequired.
  ///
  /// In en, this message translates to:
  /// **'Consent for data processing is required'**
  String get authErrorConsentRequired;

  /// No description provided for @authErrorInvalidAvatar.
  ///
  /// In en, this message translates to:
  /// **'Selected avatar is not available. Please choose another'**
  String get authErrorInvalidAvatar;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsTitle;

  /// No description provided for @termsLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: [date to be added]'**
  String get termsLastUpdated;

  /// No description provided for @termsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'[Legal text to be added]'**
  String get termsPlaceholder;

  /// No description provided for @termsSection1.
  ///
  /// In en, this message translates to:
  /// **'1. Acceptance of terms'**
  String get termsSection1;

  /// No description provided for @termsSection2.
  ///
  /// In en, this message translates to:
  /// **'2. Your account'**
  String get termsSection2;

  /// No description provided for @termsSection3.
  ///
  /// In en, this message translates to:
  /// **'3. Using ValueX'**
  String get termsSection3;

  /// No description provided for @termsSection4.
  ///
  /// In en, this message translates to:
  /// **'4. Listings and purchases'**
  String get termsSection4;

  /// No description provided for @termsSection5.
  ///
  /// In en, this message translates to:
  /// **'5. Payments and fees'**
  String get termsSection5;

  /// No description provided for @termsSection6.
  ///
  /// In en, this message translates to:
  /// **'6. Privacy and your data'**
  String get termsSection6;

  /// No description provided for @termsSection7.
  ///
  /// In en, this message translates to:
  /// **'7. Changes to these terms'**
  String get termsSection7;

  /// No description provided for @termsSection8.
  ///
  /// In en, this message translates to:
  /// **'8. Contact us'**
  String get termsSection8;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navSell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get navSell;

  /// No description provided for @navChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get navChats;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search here ...'**
  String get homeSearchHint;

  /// No description provided for @homeSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get homeSearchLabel;

  /// No description provided for @homePhotoSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search with a photo'**
  String get homePhotoSearchLabel;

  /// No description provided for @homeCartLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Cart, empty} =1{Cart, 1 item} other{Cart, {count} items}}'**
  String homeCartLabel(int count);

  /// No description provided for @homeNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Notifications} =1{Notifications, 1 unread} other{Notifications, {count} unread}}'**
  String homeNotificationsLabel(int count);

  /// No description provided for @homeLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location: {place}. Change'**
  String homeLocationLabel(String place);

  /// No description provided for @homeLocating.
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get homeLocating;

  /// No description provided for @homeSetLocation.
  ///
  /// In en, this message translates to:
  /// **'Set your location'**
  String get homeSetLocation;

  /// No description provided for @homeSetLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose'**
  String get homeSetLocationHint;

  /// No description provided for @homePromoSection.
  ///
  /// In en, this message translates to:
  /// **'#SPECIAL FOR YOU'**
  String get homePromoSection;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get homeSeeAll;

  /// No description provided for @homeSeeAllCount.
  ///
  /// In en, this message translates to:
  /// **'See All ({count})'**
  String homeSeeAllCount(int count);

  /// No description provided for @homeBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get homeBrowse;

  /// No description provided for @homeMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get homeMore;

  /// No description provided for @homeFeaturedTitle.
  ///
  /// In en, this message translates to:
  /// **'Featured Deals Near You'**
  String get homeFeaturedTitle;

  /// No description provided for @homeBoosted.
  ///
  /// In en, this message translates to:
  /// **'BOOSTED'**
  String get homeBoosted;

  /// No description provided for @conditionNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get conditionNew;

  /// No description provided for @conditionLikeNew.
  ///
  /// In en, this message translates to:
  /// **'Like New'**
  String get conditionLikeNew;

  /// No description provided for @conditionExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get conditionExcellent;

  /// No description provided for @conditionGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get conditionGood;

  /// No description provided for @conditionFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get conditionFair;

  /// No description provided for @conditionPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get conditionPoor;

  /// No description provided for @homeRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Rated {rating} out of 5'**
  String homeRatingLabel(String rating);

  /// No description provided for @homeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load Home. Pull down or tap Retry'**
  String get homeLoadFailed;

  /// No description provided for @homeNoListings.
  ///
  /// In en, this message translates to:
  /// **'No items near you yet. Try another address'**
  String get homeNoListings;

  /// No description provided for @homeCategoriesFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load categories. Try again'**
  String get homeCategoriesFailed;

  /// No description provided for @homeLocationPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'See items near you'**
  String get homeLocationPromptTitle;

  /// No description provided for @homeLocationPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Allow location access to see items near you, or enter your address.'**
  String get homeLocationPromptBody;

  /// No description provided for @homeUseMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get homeUseMyLocation;

  /// No description provided for @homeEnterAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter address'**
  String get homeEnterAddress;

  /// No description provided for @homeOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get homeOpenSettings;

  /// No description provided for @homeLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access is off. Enter your address to see items near you'**
  String get homeLocationDenied;

  /// No description provided for @homeLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to detect your location. Enter your address instead'**
  String get homeLocationUnavailable;

  /// No description provided for @homeLocationServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off on this device. Turn it on or enter your address'**
  String get homeLocationServiceOff;

  /// No description provided for @homeLocationSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your location'**
  String get homeLocationSheetTitle;

  /// No description provided for @homeAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'AREA (OPTIONAL)'**
  String get homeAreaLabel;

  /// No description provided for @homeAreaHint.
  ///
  /// In en, this message translates to:
  /// **'For example, Andheri East'**
  String get homeAreaHint;

  /// No description provided for @homeCityLabel.
  ///
  /// In en, this message translates to:
  /// **'CITY'**
  String get homeCityLabel;

  /// No description provided for @homeCityHint.
  ///
  /// In en, this message translates to:
  /// **'Your city'**
  String get homeCityHint;

  /// No description provided for @homeSaveLocation.
  ///
  /// In en, this message translates to:
  /// **'Save location'**
  String get homeSaveLocation;

  /// No description provided for @homeCityError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid city'**
  String get homeCityError;

  /// No description provided for @homeStateError.
  ///
  /// In en, this message translates to:
  /// **'Select your state'**
  String get homeStateError;

  /// No description provided for @homeFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This is coming soon'**
  String get homeFeatureComingSoon;

  /// No description provided for @homeSellAadhaarRequired.
  ///
  /// In en, this message translates to:
  /// **'Please complete Aadhaar verification to proceed'**
  String get homeSellAadhaarRequired;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get categoriesTitle;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
