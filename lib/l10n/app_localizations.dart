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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi')
  ];

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

  /// No description provided for @splashInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing A1 Engine...'**
  String get splashInitializing;

  /// No description provided for @homeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Home — coming soon'**
  String get homeComingSoon;

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

  /// No description provided for @createAccountSignInComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Sign in is coming soon'**
  String get createAccountSignInComingSoon;

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
  /// **'Back to start'**
  String get accountBlockedAction;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

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
