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
  /// **'I consent to JustQlic using my Aadhaar number to verify my identity'**
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
  /// **'GENDER (OPTIONAL)'**
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

  /// No description provided for @authErrorInvalidAddressState.
  ///
  /// In en, this message translates to:
  /// **'Please choose a valid state'**
  String get authErrorInvalidAddressState;

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
  /// **'3. Using JustQlic'**
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
  /// **'No items near you yet. Try another location'**
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
  /// **'Use your current location or one of your saved locations to see items near you.'**
  String get homeLocationPromptBody;

  /// No description provided for @homeUseMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get homeUseMyLocation;

  /// No description provided for @homeUseSavedLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my saved location'**
  String get homeUseSavedLocation;

  /// No description provided for @homeOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get homeOpenSettings;

  /// No description provided for @homeLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access is off. Use a saved location to see items near you'**
  String get homeLocationDenied;

  /// No description provided for @homeLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to detect your location. Use a saved location instead'**
  String get homeLocationUnavailable;

  /// No description provided for @homeLocationServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off on this device. Turn it on or use a saved location'**
  String get homeLocationServiceOff;

  /// No description provided for @homeLocationSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your location'**
  String get homeLocationSheetTitle;

  /// No description provided for @homeSavedLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a saved location'**
  String get homeSavedLocationTitle;

  /// No description provided for @homeSavedLocationEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no saved locations yet. An address is saved when you buy or sell an item.'**
  String get homeSavedLocationEmpty;

  /// No description provided for @homeSavedLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your saved locations. Try again'**
  String get homeSavedLocationFailed;

  /// No description provided for @homeSavedLocationUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Saved address'**
  String get homeSavedLocationUnnamed;

  /// No description provided for @homeSavedLocationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Use this address'**
  String get homeSavedLocationConfirm;

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

  /// No description provided for @googleMobileTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your mobile number'**
  String get googleMobileTitle;

  /// No description provided for @googleMobileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You are signing in with {email}. JustQlic uses your mobile number to identify your account.'**
  String googleMobileSubtitle(String email);

  /// No description provided for @googleErrorFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again'**
  String get googleErrorFailed;

  /// No description provided for @googleErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In is temporarily unavailable'**
  String get googleErrorUnavailable;

  /// No description provided for @googleErrorAlreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'This Google account is already linked to another JustQlic account'**
  String get googleErrorAlreadyLinked;

  /// No description provided for @googleErrorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in session expired. Please sign in with Google again'**
  String get googleErrorSessionExpired;

  /// No description provided for @googleErrorIncompleteAccount.
  ///
  /// In en, this message translates to:
  /// **'This number has an unfinished registration. Sign in with your mobile number to finish it'**
  String get googleErrorIncompleteAccount;

  /// No description provided for @googleMockBanner.
  ///
  /// In en, this message translates to:
  /// **'DEVELOPMENT ONLY — mock Google account. The real Google account chooser replaces this once client IDs are configured'**
  String get googleMockBanner;

  /// No description provided for @googleMockTitle.
  ///
  /// In en, this message translates to:
  /// **'Mock Google account'**
  String get googleMockTitle;

  /// No description provided for @googleMockLabel.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get googleMockLabel;

  /// No description provided for @googleMockContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get googleMockContinue;

  /// No description provided for @googleMockCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get googleMockCancel;

  /// No description provided for @profileDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile details'**
  String get profileDetailsTitle;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEdit;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profileSave;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileSaved;

  /// No description provided for @profileAvatar.
  ///
  /// In en, this message translates to:
  /// **'Change avatar'**
  String get profileAvatar;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileName;

  /// No description provided for @profileMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get profileMobile;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileVerifiedName.
  ///
  /// In en, this message translates to:
  /// **'Verified name'**
  String get profileVerifiedName;

  /// No description provided for @profileJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get profileJoined;

  /// No description provided for @profileMissing.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get profileMissing;

  /// No description provided for @profileDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get profileDiscard;

  /// No description provided for @profileDiscardAction.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get profileDiscardAction;

  /// No description provided for @profileKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get profileKeepEditing;

  /// No description provided for @profileGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profileGender;

  /// No description provided for @profileCatalogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No avatars are available. Please try again later'**
  String get profileCatalogEmpty;

  /// No description provided for @profileVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get profileVerified;

  /// No description provided for @profileSectionBuying.
  ///
  /// In en, this message translates to:
  /// **'Buying'**
  String get profileSectionBuying;

  /// No description provided for @profileSectionSelling.
  ///
  /// In en, this message translates to:
  /// **'Selling'**
  String get profileSectionSelling;

  /// No description provided for @profileSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileSectionAccount;

  /// No description provided for @profileMyOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get profileMyOrders;

  /// No description provided for @profileSavedItems.
  ///
  /// In en, this message translates to:
  /// **'Saved Items'**
  String get profileSavedItems;

  /// No description provided for @profilePaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get profilePaymentHistory;

  /// No description provided for @profileMyListings.
  ///
  /// In en, this message translates to:
  /// **'My Listings'**
  String get profileMyListings;

  /// No description provided for @profilePayoutDetails.
  ///
  /// In en, this message translates to:
  /// **'Payout Details'**
  String get profilePayoutDetails;

  /// No description provided for @profileSellerAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Seller Analytics'**
  String get profileSellerAnalytics;

  /// No description provided for @profileNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotifications;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileDisputeCenter.
  ///
  /// In en, this message translates to:
  /// **'Dispute Center'**
  String get profileDisputeCenter;

  /// No description provided for @profileHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get profileHelpSupport;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profileSignOut;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmMessage;

  /// No description provided for @logoutQueued.
  ///
  /// In en, this message translates to:
  /// **'Logged out on this device. We will finish signing you out on our servers when you are back online'**
  String get logoutQueued;

  /// No description provided for @profileIncomingOrders.
  ///
  /// In en, this message translates to:
  /// **'Incoming Orders'**
  String get profileIncomingOrders;

  /// No description provided for @profileFooter.
  ///
  /// In en, this message translates to:
  /// **'JustQlic v{version} · ValueQuo Solutions Pvt. Ltd.'**
  String profileFooter(String version);

  /// No description provided for @profileRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Rating {rating} out of 5'**
  String profileRatingLabel(String rating);

  /// No description provided for @profileTransactions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transaction} other{{count} transactions}}'**
  String profileTransactions(int count);

  /// No description provided for @profilePlanActive.
  ///
  /// In en, this message translates to:
  /// **'{plan} — Active'**
  String profilePlanActive(String plan);

  /// No description provided for @profileUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium →'**
  String get profileUpgrade;

  /// No description provided for @profileStatListings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get profileStatListings;

  /// No description provided for @profileStatSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get profileStatSold;

  /// No description provided for @profileStatReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get profileStatReviews;

  /// No description provided for @profileMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String profileMemberSince(String date);

  /// No description provided for @profileMenuBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'{label}, {count, plural, =1{1 new} other{{count} new}}'**
  String profileMenuBadgeLabel(String label, int count);

  /// No description provided for @profileAccountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account Security'**
  String get profileAccountSecurity;

  /// No description provided for @profileMyAddresses.
  ///
  /// In en, this message translates to:
  /// **'My Addresses'**
  String get profileMyAddresses;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Security'**
  String get securityTitle;

  /// No description provided for @securitySectionSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign-in details'**
  String get securitySectionSignIn;

  /// No description provided for @securityMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get securityMobileLabel;

  /// No description provided for @securityEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get securityEmailLabel;

  /// No description provided for @securityChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get securityChange;

  /// No description provided for @securityChangeMobileA11y.
  ///
  /// In en, this message translates to:
  /// **'Change mobile number'**
  String get securityChangeMobileA11y;

  /// No description provided for @securityChangeEmailA11y.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get securityChangeEmailA11y;

  /// No description provided for @securityAadhaarLabel.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar verification'**
  String get securityAadhaarLabel;

  /// No description provided for @securityAadhaarVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get securityAadhaarVerified;

  /// No description provided for @securityAadhaarPending.
  ///
  /// In en, this message translates to:
  /// **'Not verified yet'**
  String get securityAadhaarPending;

  /// No description provided for @securityAadhaarHint.
  ///
  /// In en, this message translates to:
  /// **'Required before your first buy or sell'**
  String get securityAadhaarHint;

  /// No description provided for @securityAadhaarVerifyNow.
  ///
  /// In en, this message translates to:
  /// **'Verify now'**
  String get securityAadhaarVerifyNow;

  /// No description provided for @securitySessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Active sessions'**
  String get securitySessionsTitle;

  /// No description provided for @securitySessionsHint.
  ///
  /// In en, this message translates to:
  /// **'Devices signed in to your account'**
  String get securitySessionsHint;

  /// No description provided for @securityThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get securityThisDevice;

  /// No description provided for @securityUnknownDevice.
  ///
  /// In en, this message translates to:
  /// **'Unknown device'**
  String get securityUnknownDevice;

  /// No description provided for @securityLastActive.
  ///
  /// In en, this message translates to:
  /// **'Last active {date}'**
  String securityLastActive(String date);

  /// No description provided for @securitySessionsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your sessions'**
  String get securitySessionsLoadFailed;

  /// No description provided for @securityOnlyThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This is the only device signed in'**
  String get securityOnlyThisDevice;

  /// No description provided for @securityLogoutOthers.
  ///
  /// In en, this message translates to:
  /// **'Log out of all other devices'**
  String get securityLogoutOthers;

  /// No description provided for @securityLogoutOthersTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out of other devices?'**
  String get securityLogoutOthersTitle;

  /// No description provided for @securityLogoutOthersMessage.
  ///
  /// In en, this message translates to:
  /// **'Every other device will be signed out. This device stays signed in.'**
  String get securityLogoutOthersMessage;

  /// No description provided for @securityLogoutOthersConfirm.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get securityLogoutOthersConfirm;

  /// No description provided for @securityLogoutOthersDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Logged out of 1 other device} other{Logged out of {count} other devices}}'**
  String securityLogoutOthersDone(int count);

  /// No description provided for @securityNoOtherSessions.
  ///
  /// In en, this message translates to:
  /// **'No other active sessions found'**
  String get securityNoOtherSessions;

  /// No description provided for @securityDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get securityDeleteAccount;

  /// No description provided for @securityChangeMobileTitle.
  ///
  /// In en, this message translates to:
  /// **'Change mobile number'**
  String get securityChangeMobileTitle;

  /// No description provided for @securityChangeMobileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your new number. We will send a code to confirm it.'**
  String get securityChangeMobileSubtitle;

  /// No description provided for @securityChangeEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get securityChangeEmailTitle;

  /// No description provided for @securityChangeEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your new email address. We will send a code to confirm it.'**
  String get securityChangeEmailSubtitle;

  /// No description provided for @securityNewMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'New mobile number'**
  String get securityNewMobileLabel;

  /// No description provided for @securityNewEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'New email address'**
  String get securityNewEmailLabel;

  /// No description provided for @securitySendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get securitySendCode;

  /// No description provided for @securityMobileStaysActive.
  ///
  /// In en, this message translates to:
  /// **'Your current number stays active until you confirm the new one.'**
  String get securityMobileStaysActive;

  /// No description provided for @securityEmailStaysActive.
  ///
  /// In en, this message translates to:
  /// **'Your current email stays active until you confirm the new one.'**
  String get securityEmailStaysActive;

  /// No description provided for @securityConfirmMobileTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm new number'**
  String get securityConfirmMobileTitle;

  /// No description provided for @securityConfirmEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm new email'**
  String get securityConfirmEmailTitle;

  /// No description provided for @securityMobileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Mobile number updated'**
  String get securityMobileUpdated;

  /// No description provided for @securityEmailUpdated.
  ///
  /// In en, this message translates to:
  /// **'Email updated'**
  String get securityEmailUpdated;

  /// No description provided for @securitySameMobile.
  ///
  /// In en, this message translates to:
  /// **'This is already your mobile number. Enter a different number.'**
  String get securitySameMobile;

  /// No description provided for @securitySameEmail.
  ///
  /// In en, this message translates to:
  /// **'This is already your email address. Enter a different address.'**
  String get securitySameEmail;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{You\'re all caught up} =1{1 unread} other{{count} unread}}'**
  String notificationsUnreadCount(int count);

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsMarkAllFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to mark all as read. Try again'**
  String get notificationsMarkAllFailed;

  /// No description provided for @notificationsTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notificationsTabAll;

  /// No description provided for @notificationsTabAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get notificationsTabAccount;

  /// No description provided for @notificationsTabOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get notificationsTabOrders;

  /// No description provided for @notificationsTabMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get notificationsTabMessages;

  /// No description provided for @notificationsTabListings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get notificationsTabListings;

  /// No description provided for @notificationsTabOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get notificationsTabOthers;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Updates about your account will appear here'**
  String get notificationsEmptyBody;

  /// No description provided for @notificationsLoadMoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load more notifications'**
  String get notificationsLoadMoreFailed;

  /// No description provided for @notificationUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationUnread;

  /// No description provided for @notificationJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notificationJustNow;

  /// No description provided for @notificationMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String notificationMinutesAgo(int count);

  /// No description provided for @notificationHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String notificationHoursAgo(int count);

  /// No description provided for @notificationDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String notificationDaysAgo(int count);

  /// No description provided for @addressSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search your address'**
  String get addressSearchLabel;

  /// No description provided for @addressSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Type your street, area or landmark'**
  String get addressSearchHint;

  /// No description provided for @addressSearchSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get addressSearchSearching;

  /// No description provided for @addressSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching address found. Enter it below'**
  String get addressSearchNoResults;

  /// No description provided for @addressSearchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Address search is unavailable. Enter your address below'**
  String get addressSearchUnavailable;

  /// No description provided for @addressSearchPoweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered by Google'**
  String get addressSearchPoweredBy;

  /// No description provided for @addressLandmarkLabel.
  ///
  /// In en, this message translates to:
  /// **'House or flat number, landmark (optional)'**
  String get addressLandmarkLabel;

  /// No description provided for @addressLandmarkHint.
  ///
  /// In en, this message translates to:
  /// **'Flat 4, near the metro station'**
  String get addressLandmarkHint;

  /// No description provided for @addressCheckChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking your address…'**
  String get addressCheckChecking;

  /// No description provided for @addressCheckVerified.
  ///
  /// In en, this message translates to:
  /// **'Address verified'**
  String get addressCheckVerified;

  /// No description provided for @addressCheckNotVerified.
  ///
  /// In en, this message translates to:
  /// **'We could not verify this address. Please check and try again'**
  String get addressCheckNotVerified;

  /// No description provided for @addressCheckMismatch.
  ///
  /// In en, this message translates to:
  /// **'The pincode does not match the selected city or state'**
  String get addressCheckMismatch;

  /// No description provided for @addressCheckInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a complete address'**
  String get addressCheckInvalid;

  /// No description provided for @addressCheckUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Address verification is unavailable right now. You can still continue'**
  String get addressCheckUnavailable;

  /// No description provided for @sellAddPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get sellAddPhotosTitle;

  /// No description provided for @sellAddPhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear photos sell faster (min 1, max 10)'**
  String get sellAddPhotosSubtitle;

  /// No description provided for @sellPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/10 photos added'**
  String sellPhotoCount(int count);

  /// No description provided for @sellAiTitle.
  ///
  /// In en, this message translates to:
  /// **'Let AI do the work for you'**
  String get sellAiTitle;

  /// No description provided for @sellAiBody.
  ///
  /// In en, this message translates to:
  /// **'Take a few clear photos and our AI will identify the item, suggest a category, describe its condition and estimate the best selling price.'**
  String get sellAiBody;

  /// No description provided for @sellEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Take or upload photos'**
  String get sellEmptyTitle;

  /// No description provided for @sellEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'AI will auto-fill item details from your photos'**
  String get sellEmptyBody;

  /// No description provided for @sellAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get sellAddPhotos;

  /// No description provided for @sellAddPhotoTile.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get sellAddPhotoTile;

  /// No description provided for @sellTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo tips for best results'**
  String get sellTipsTitle;

  /// No description provided for @sellTipLighting.
  ///
  /// In en, this message translates to:
  /// **'Take clear, well-lit photos'**
  String get sellTipLighting;

  /// No description provided for @sellTipAngles.
  ///
  /// In en, this message translates to:
  /// **'Capture from multiple angles'**
  String get sellTipAngles;

  /// No description provided for @sellTipDetails.
  ///
  /// In en, this message translates to:
  /// **'Include close-ups of important details (e.g. edges, scratches)'**
  String get sellTipDetails;

  /// No description provided for @sellTipAccessories.
  ///
  /// In en, this message translates to:
  /// **'Include all accessories (if available)'**
  String get sellTipAccessories;

  /// No description provided for @sellSubmitToAi.
  ///
  /// In en, this message translates to:
  /// **'Submit to AI'**
  String get sellSubmitToAi;

  /// No description provided for @sellMainPhoto.
  ///
  /// In en, this message translates to:
  /// **'MAIN'**
  String get sellMainPhoto;

  /// No description provided for @sellPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Photo {index}'**
  String sellPhotoLabel(int index);

  /// No description provided for @sellRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo {index}'**
  String sellRemovePhoto(int index);

  /// No description provided for @sellRetryPhoto.
  ///
  /// In en, this message translates to:
  /// **'Retry photo {index}'**
  String sellRetryPhoto(int index);

  /// No description provided for @sellPhotoUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get sellPhotoUploading;

  /// No description provided for @sellPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get sellPhotoFailed;

  /// No description provided for @sellTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get sellTakePhoto;

  /// No description provided for @sellChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get sellChooseFromGallery;

  /// No description provided for @sellErrorMaxPhotos.
  ///
  /// In en, this message translates to:
  /// **'Maximum 10 photos allowed'**
  String get sellErrorMaxPhotos;

  /// No description provided for @sellErrorInvalidPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo quality too low or invalid format'**
  String get sellErrorInvalidPhoto;

  /// No description provided for @sellErrorPhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Photo exceeds 10MB limit'**
  String get sellErrorPhotoTooLarge;

  /// No description provided for @sellErrorUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo. Check your connection'**
  String get sellErrorUploadFailed;

  /// No description provided for @sellErrorCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access required to capture photos'**
  String get sellErrorCameraDenied;

  /// No description provided for @sellErrorGalleryDenied.
  ///
  /// In en, this message translates to:
  /// **'Photo library access required to choose photos'**
  String get sellErrorGalleryDenied;

  /// No description provided for @sellErrorNotActive.
  ///
  /// In en, this message translates to:
  /// **'Only active accounts can create listings'**
  String get sellErrorNotActive;

  /// No description provided for @sellMinPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 photos to continue'**
  String get sellMinPhotosHint;

  /// No description provided for @sellErrorMinPhotos.
  ///
  /// In en, this message translates to:
  /// **'At least 2 photos required'**
  String get sellErrorMinPhotos;

  /// No description provided for @sellErrorNotEditable.
  ///
  /// In en, this message translates to:
  /// **'This listing can no longer be edited'**
  String get sellErrorNotEditable;

  /// No description provided for @itemDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Item Details'**
  String get itemDetailsTitle;

  /// No description provided for @itemDetailsSubtitleManual.
  ///
  /// In en, this message translates to:
  /// **'Fill in the details'**
  String get itemDetailsSubtitleManual;

  /// No description provided for @itemDetailsAiBanner.
  ///
  /// In en, this message translates to:
  /// **'AI filled these from your photos. Review and edit as needed.'**
  String get itemDetailsAiBanner;

  /// No description provided for @itemTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get itemTitleLabel;

  /// No description provided for @itemTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. iPhone 13 128GB'**
  String get itemTitleHint;

  /// No description provided for @itemCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get itemCategoryLabel;

  /// No description provided for @itemCategoryOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get itemCategoryOthers;

  /// No description provided for @itemConditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get itemConditionLabel;

  /// No description provided for @itemConditionNew.
  ///
  /// In en, this message translates to:
  /// **'Brand New'**
  String get itemConditionNew;

  /// No description provided for @itemConditionLikeNew.
  ///
  /// In en, this message translates to:
  /// **'Like New'**
  String get itemConditionLikeNew;

  /// No description provided for @itemConditionGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get itemConditionGood;

  /// No description provided for @itemConditionFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get itemConditionFair;

  /// No description provided for @itemConditionPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get itemConditionPoor;

  /// No description provided for @itemDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get itemDescriptionLabel;

  /// No description provided for @itemDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Age, how it was used, accessories included'**
  String get itemDescriptionHint;

  /// No description provided for @itemLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get itemLocationLabel;

  /// No description provided for @itemLocationChange.
  ///
  /// In en, this message translates to:
  /// **'Change location'**
  String get itemLocationChange;

  /// No description provided for @itemPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get itemPriceLabel;

  /// No description provided for @itemPriceNote.
  ///
  /// In en, this message translates to:
  /// **'Buyers can negotiate. You can accept, counter, or reject any offer.'**
  String get itemPriceNote;

  /// No description provided for @itemChooseListingPlan.
  ///
  /// In en, this message translates to:
  /// **'Choose Listing Plan'**
  String get itemChooseListingPlan;

  /// No description provided for @itemFillMissing.
  ///
  /// In en, this message translates to:
  /// **'Fill in the required fields to continue'**
  String get itemFillMissing;

  /// No description provided for @itemTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a title for your item'**
  String get itemTitleRequired;

  /// No description provided for @itemCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get itemCategoryRequired;

  /// No description provided for @itemConditionRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose the condition of your item'**
  String get itemConditionRequired;

  /// No description provided for @itemDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Describe your item'**
  String get itemDescriptionRequired;

  /// No description provided for @itemPriceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get itemPriceInvalid;

  /// No description provided for @planScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Boost your visibility and sell faster'**
  String get planScreenSubtitle;

  /// No description provided for @planValidityDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String planValidityDays(int count);

  /// No description provided for @planValidityMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String planValidityMonths(int count);

  /// No description provided for @planValidityLabel.
  ///
  /// In en, this message translates to:
  /// **'{validity} validity'**
  String planValidityLabel(String validity);

  /// No description provided for @planSupportAiEmail.
  ///
  /// In en, this message translates to:
  /// **'AI + Email support'**
  String get planSupportAiEmail;

  /// No description provided for @planSupportAiEmailChat.
  ///
  /// In en, this message translates to:
  /// **'AI + Email + Chat (Human) support'**
  String get planSupportAiEmailChat;

  /// No description provided for @planSupportAiEmailChatCall.
  ///
  /// In en, this message translates to:
  /// **'AI + Email + Chat + On-call support'**
  String get planSupportAiEmailChatCall;

  /// No description provided for @planBadgePopular.
  ///
  /// In en, this message translates to:
  /// **'POPULAR'**
  String get planBadgePopular;

  /// No description provided for @planBadgeBestValue.
  ///
  /// In en, this message translates to:
  /// **'BEST VALUE'**
  String get planBadgeBestValue;

  /// No description provided for @planSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get planSelected;

  /// No description provided for @planFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get planFree;

  /// No description provided for @planOriginalPriceSemantics.
  ///
  /// In en, this message translates to:
  /// **'Original price {price}'**
  String planOriginalPriceSemantics(String price);

  /// No description provided for @planBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment breakdown'**
  String get planBreakdownTitle;

  /// No description provided for @planBreakdownOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original price'**
  String get planBreakdownOriginal;

  /// No description provided for @planBreakdownDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount ({percent}% off)'**
  String planBreakdownDiscount(int percent);

  /// No description provided for @planBreakdownGstIncluded.
  ///
  /// In en, this message translates to:
  /// **'GST included'**
  String get planBreakdownGstIncluded;

  /// No description provided for @planBreakdownGstAdded.
  ///
  /// In en, this message translates to:
  /// **'GST ({rate}%)'**
  String planBreakdownGstAdded(String rate);

  /// No description provided for @planBreakdownTotal.
  ///
  /// In en, this message translates to:
  /// **'Total to pay'**
  String get planBreakdownTotal;

  /// No description provided for @planInclusiveOfGst.
  ///
  /// In en, this message translates to:
  /// **'Inclusive of GST'**
  String get planInclusiveOfGst;

  /// No description provided for @planFreeNote.
  ///
  /// In en, this message translates to:
  /// **'No payment is needed for this plan.'**
  String get planFreeNote;

  /// No description provided for @planNoPlans.
  ///
  /// In en, this message translates to:
  /// **'No plans are available right now.'**
  String get planNoPlans;

  /// No description provided for @planReviewListing.
  ///
  /// In en, this message translates to:
  /// **'Review Listing'**
  String get planReviewListing;

  /// No description provided for @planReviewSoon.
  ///
  /// In en, this message translates to:
  /// **'Reviewing your listing is coming soon.'**
  String get planReviewSoon;
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
