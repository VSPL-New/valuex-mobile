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
  String get accountBlockedAction => 'Back to Sign In';

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
  String get emailEntryInvalid => 'Enter a valid email address';

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
  String get aadhaarConsent =>
      'I consent to JustQlic using my Aadhaar number to verify my identity';

  @override
  String get aadhaarVerifyButton => 'Verify Aadhaar';

  @override
  String get aadhaarNumberInvalid => 'Enter your 12-digit Aadhaar number';

  @override
  String get aadhaarConsentRequired => 'Please accept to continue';

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
  String get signupGenderLabel => 'GENDER (OPTIONAL)';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOthers => 'Others';

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
  String get signInTitle => 'Sign In';

  @override
  String get signInSubtitle => 'Welcome back! Please sign in to continue.';

  @override
  String get signInNoAccount => 'Don\'t have an account?';

  @override
  String get signInSignUp => 'Sign up';

  @override
  String get signInCreateAccount => 'Create an account';

  @override
  String get authErrorMobileNotRegistered =>
      'No account found with this mobile number. Please create an account';

  @override
  String get authErrorSignInIncomplete =>
      'This number isn\'t verified yet. Please create an account to finish setting it up';

  @override
  String get authErrorAccountSuspended => 'Your account is suspended. Please contact support';

  @override
  String get authErrorAccountRecovery => 'Your account requires recovery. Please contact support';

  @override
  String get signupErrorTerms => 'Accept the Terms and Conditions to continue';

  @override
  String get signupErrorName => 'Enter 3 to 50 letters';

  @override
  String get authErrorInvalidAddressState => 'Please choose a valid state';

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
  String get termsSection3 => '3. Using JustQlic';

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

  @override
  String get loading => 'Loading';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navSell => 'Sell';

  @override
  String get navChats => 'Chats';

  @override
  String get navProfile => 'Profile';

  @override
  String get homeSearchHint => 'Search here ...';

  @override
  String get homeSearchLabel => 'Search';

  @override
  String get homePhotoSearchLabel => 'Search with a photo';

  @override
  String homeCartLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cart, $count items',
      one: 'Cart, 1 item',
      zero: 'Cart, empty',
    );
    return '$_temp0';
  }

  @override
  String homeNotificationsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notifications, $count unread',
      one: 'Notifications, 1 unread',
      zero: 'Notifications',
    );
    return '$_temp0';
  }

  @override
  String homeLocationLabel(String place) {
    return 'Location: $place. Change';
  }

  @override
  String get homeLocating => 'Finding your location…';

  @override
  String get homeSetLocation => 'Set your location';

  @override
  String get homeSetLocationHint => 'Tap to choose';

  @override
  String get homePromoSection => '#SPECIAL FOR YOU';

  @override
  String get homeSeeAll => 'See All';

  @override
  String homeSeeAllCount(int count) {
    return 'See All ($count)';
  }

  @override
  String get homeBrowse => 'Browse';

  @override
  String get homeMore => 'More';

  @override
  String get homeFeaturedTitle => 'Featured Deals Near You';

  @override
  String get homeBoosted => 'BOOSTED';

  @override
  String get conditionNew => 'New';

  @override
  String get conditionLikeNew => 'Like New';

  @override
  String get conditionExcellent => 'Excellent';

  @override
  String get conditionGood => 'Good';

  @override
  String get conditionFair => 'Fair';

  @override
  String get conditionPoor => 'Poor';

  @override
  String homeRatingLabel(String rating) {
    return 'Rated $rating out of 5';
  }

  @override
  String get homeLoadFailed => 'Unable to load Home. Pull down or tap Retry';

  @override
  String get homeNoListings => 'No items near you yet. Try another location';

  @override
  String get homeCategoriesFailed => 'Unable to load categories. Try again';

  @override
  String get homeLocationPromptTitle => 'See items near you';

  @override
  String get homeLocationPromptBody =>
      'Use your current location or one of your saved locations to see items near you.';

  @override
  String get homeUseMyLocation => 'Use my current location';

  @override
  String get homeUseSavedLocation => 'Use my saved location';

  @override
  String get homeOpenSettings => 'Open settings';

  @override
  String get homeLocationDenied =>
      'Location access is off. Use a saved location to see items near you';

  @override
  String get homeLocationUnavailable =>
      'Unable to detect your location. Use a saved location instead';

  @override
  String get homeLocationServiceOff =>
      'Location is turned off on this device. Turn it on or use a saved location';

  @override
  String get homeLocationSheetTitle => 'Choose your location';

  @override
  String get homeSavedLocationTitle => 'Choose a saved location';

  @override
  String get homeSavedLocationEmpty =>
      'You have no saved locations yet. An address is saved when you buy or sell an item.';

  @override
  String get homeSavedLocationFailed => 'Unable to load your saved locations. Try again';

  @override
  String get homeSavedLocationUnnamed => 'Saved address';

  @override
  String get homeSavedLocationConfirm => 'Use this address';

  @override
  String get homeFeatureComingSoon => 'This is coming soon';

  @override
  String get homeSellAadhaarRequired => 'Please complete Aadhaar verification to proceed';

  @override
  String get categoriesTitle => 'All categories';

  @override
  String get googleMobileTitle => 'Add your mobile number';

  @override
  String googleMobileSubtitle(String email) {
    return 'You are signing in with $email. JustQlic uses your mobile number to identify your account.';
  }

  @override
  String get googleErrorFailed => 'Google sign-in failed. Please try again';

  @override
  String get googleErrorUnavailable => 'Google Sign-In is temporarily unavailable';

  @override
  String get googleErrorAlreadyLinked =>
      'This Google account is already linked to another JustQlic account';

  @override
  String get googleErrorSessionExpired =>
      'Google sign-in session expired. Please sign in with Google again';

  @override
  String get googleErrorIncompleteAccount =>
      'This number has an unfinished registration. Sign in with your mobile number to finish it';

  @override
  String get googleMockBanner =>
      'DEVELOPMENT ONLY — mock Google account. The real Google account chooser replaces this once client IDs are configured';

  @override
  String get googleMockTitle => 'Mock Google account';

  @override
  String get googleMockLabel => 'Account name';

  @override
  String get googleMockContinue => 'Continue';

  @override
  String get googleMockCancel => 'Cancel';

  @override
  String get profileDetailsTitle => 'Profile details';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileSave => 'Save changes';

  @override
  String get profileSaved => 'Profile updated';

  @override
  String get profileAvatar => 'Change avatar';

  @override
  String get profileName => 'Display name';

  @override
  String get profileMobile => 'Mobile number';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileVerifiedName => 'Verified name';

  @override
  String get profileJoined => 'Joined';

  @override
  String get profileMissing => 'Not provided';

  @override
  String get profileDiscard => 'Discard changes?';

  @override
  String get profileDiscardAction => 'Discard';

  @override
  String get profileKeepEditing => 'Keep editing';

  @override
  String get profileGender => 'Gender';

  @override
  String get profileCatalogEmpty => 'No avatars are available. Please try again later';

  @override
  String get profileVerified => 'Verified';

  @override
  String get profileSectionBuying => 'Buying';

  @override
  String get profileSectionSelling => 'Selling';

  @override
  String get profileSectionAccount => 'Account';

  @override
  String get profileMyOrders => 'My Orders';

  @override
  String get profileSavedItems => 'Saved Items';

  @override
  String get profilePaymentHistory => 'Payment History';

  @override
  String get profileMyListings => 'My Listings';

  @override
  String get profilePayoutDetails => 'Payout Details';

  @override
  String get profileSellerAnalytics => 'Seller Analytics';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileDisputeCenter => 'Dispute Center';

  @override
  String get profileHelpSupport => 'Help & Support';

  @override
  String get profileSignOut => 'Sign Out';

  @override
  String get logoutConfirmMessage => 'Are you sure you want to log out?';

  @override
  String get logoutQueued =>
      'Logged out on this device. We will finish signing you out on our servers when you are back online';

  @override
  String get profileIncomingOrders => 'Incoming Orders';

  @override
  String profileFooter(String version) {
    return 'JustQlic v$version · ValueQuo Solutions Pvt. Ltd.';
  }

  @override
  String profileRatingLabel(String rating) {
    return 'Rating $rating out of 5';
  }

  @override
  String profileTransactions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return '$_temp0';
  }

  @override
  String profilePlanActive(String plan) {
    return '$plan — Active';
  }

  @override
  String get profileUpgrade => 'Upgrade to Premium →';

  @override
  String get profileStatListings => 'Listings';

  @override
  String get profileStatSold => 'Sold';

  @override
  String get profileStatReviews => 'Reviews';

  @override
  String profileMemberSince(String date) {
    return 'Joined $date';
  }

  @override
  String profileMenuBadgeLabel(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new',
      one: '1 new',
    );
    return '$label, $_temp0';
  }

  @override
  String get profileAccountSecurity => 'Account Security';

  @override
  String get profileMyAddresses => 'My Addresses';

  @override
  String get securityTitle => 'Account Security';

  @override
  String get securitySectionSignIn => 'Sign-in details';

  @override
  String get securityMobileLabel => 'Mobile number';

  @override
  String get securityEmailLabel => 'Email';

  @override
  String get securityChange => 'Change';

  @override
  String get securityChangeMobileA11y => 'Change mobile number';

  @override
  String get securityChangeEmailA11y => 'Change email';

  @override
  String get securityAadhaarLabel => 'Aadhaar verification';

  @override
  String get securityAadhaarVerified => 'Verified';

  @override
  String get securityAadhaarPending => 'Not verified yet';

  @override
  String get securityAadhaarHint => 'Required before your first buy or sell';

  @override
  String get securityAadhaarVerifyNow => 'Verify now';

  @override
  String get securitySessionsTitle => 'Active sessions';

  @override
  String get securitySessionsHint => 'Devices signed in to your account';

  @override
  String get securityThisDevice => 'This device';

  @override
  String get securityUnknownDevice => 'Unknown device';

  @override
  String securityLastActive(String date) {
    return 'Last active $date';
  }

  @override
  String get securitySessionsLoadFailed => 'Unable to load your sessions';

  @override
  String get securityOnlyThisDevice => 'This is the only device signed in';

  @override
  String get securityLogoutOthers => 'Log out of all other devices';

  @override
  String get securityLogoutOthersTitle => 'Log out of other devices?';

  @override
  String get securityLogoutOthersMessage =>
      'Every other device will be signed out. This device stays signed in.';

  @override
  String get securityLogoutOthersConfirm => 'Log out';

  @override
  String securityLogoutOthersDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Logged out of $count other devices',
      one: 'Logged out of 1 other device',
    );
    return '$_temp0';
  }

  @override
  String get securityNoOtherSessions => 'No other active sessions found';

  @override
  String get securityDeleteAccount => 'Delete My Account';

  @override
  String get securityChangeMobileTitle => 'Change mobile number';

  @override
  String get securityChangeMobileSubtitle =>
      'Enter your new number. We will send a code to confirm it.';

  @override
  String get securityChangeEmailTitle => 'Change email';

  @override
  String get securityChangeEmailSubtitle =>
      'Enter your new email address. We will send a code to confirm it.';

  @override
  String get securityNewMobileLabel => 'New mobile number';

  @override
  String get securityNewEmailLabel => 'New email address';

  @override
  String get securitySendCode => 'Send code';

  @override
  String get securityMobileStaysActive =>
      'Your current number stays active until you confirm the new one.';

  @override
  String get securityEmailStaysActive =>
      'Your current email stays active until you confirm the new one.';

  @override
  String get securityConfirmMobileTitle => 'Confirm new number';

  @override
  String get securityConfirmEmailTitle => 'Confirm new email';

  @override
  String get securityMobileUpdated => 'Mobile number updated';

  @override
  String get securityEmailUpdated => 'Email updated';

  @override
  String get securitySameMobile => 'This is already your mobile number. Enter a different number.';

  @override
  String get securitySameEmail => 'This is already your email address. Enter a different address.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String notificationsUnreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread',
      one: '1 unread',
      zero: 'You\'re all caught up',
    );
    return '$_temp0';
  }

  @override
  String get notificationsMarkAllRead => 'Mark all read';

  @override
  String get notificationsMarkAllFailed => 'Unable to mark all as read. Try again';

  @override
  String get notificationsTabAll => 'All';

  @override
  String get notificationsTabAccount => 'Account';

  @override
  String get notificationsTabOrders => 'Orders';

  @override
  String get notificationsTabMessages => 'Messages';

  @override
  String get notificationsTabListings => 'Listings';

  @override
  String get notificationsTabOthers => 'Others';

  @override
  String get notificationsEmptyTitle => 'No notifications yet';

  @override
  String get notificationsEmptyBody => 'Updates about your account will appear here';

  @override
  String get notificationsLoadMoreFailed => 'Unable to load more notifications';

  @override
  String get notificationUnread => 'Unread';

  @override
  String get notificationJustNow => 'Just now';

  @override
  String notificationMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String notificationHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String notificationDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get addressSearchLabel => 'Search your address';

  @override
  String get addressSearchHint => 'Type your street, area or landmark';

  @override
  String get addressSearchSearching => 'Searching…';

  @override
  String get addressSearchNoResults => 'No matching address found. Enter it below';

  @override
  String get addressSearchUnavailable => 'Address search is unavailable. Enter your address below';

  @override
  String get addressSearchPoweredBy => 'Powered by Google';

  @override
  String get addressLandmarkLabel => 'House or flat number, landmark (optional)';

  @override
  String get addressLandmarkHint => 'Flat 4, near the metro station';

  @override
  String get addressCheckChecking => 'Checking your address…';

  @override
  String get addressCheckVerified => 'Address verified';

  @override
  String get addressCheckNotVerified =>
      'We could not verify this address. Please check and try again';

  @override
  String get addressCheckMismatch => 'The pincode does not match the selected city or state';

  @override
  String get addressCheckInvalid => 'Please enter a complete address';

  @override
  String get addressCheckUnavailable =>
      'Address verification is unavailable right now. You can still continue';

  @override
  String get sellAddPhotosTitle => 'Add Photos';

  @override
  String get sellAddPhotosSubtitle => 'Clear photos sell faster (min 2, max 10)';

  @override
  String sellPhotoCount(int count) {
    return '$count/10 photos added';
  }

  @override
  String get sellAiTitle => 'Let AI do the work for you';

  @override
  String get sellAiBody =>
      'Take a few clear photos and our AI will identify the item, suggest a category, describe its condition and estimate the best selling price.';

  @override
  String get sellEmptyTitle => 'Take or upload photos';

  @override
  String get sellEmptyBody => 'AI will auto-fill item details from your photos';

  @override
  String get sellAddPhotos => 'Add Photos';

  @override
  String get sellAddPhotoTile => 'Add';

  @override
  String get sellTipsTitle => 'Photo tips for best results';

  @override
  String get sellTipLighting => 'Take clear, well-lit photos';

  @override
  String get sellTipAngles => 'Capture from multiple angles';

  @override
  String get sellTipDetails => 'Include close-ups of important details (e.g. edges, scratches)';

  @override
  String get sellTipAccessories => 'Include all accessories (if available)';

  @override
  String get sellSubmitToAi => 'Submit to AI';

  @override
  String get sellMainPhoto => 'MAIN';

  @override
  String sellPhotoLabel(int index) {
    return 'Photo $index';
  }

  @override
  String sellRemovePhoto(int index) {
    return 'Remove photo $index';
  }

  @override
  String sellRetryPhoto(int index) {
    return 'Retry photo $index';
  }

  @override
  String get sellPhotoUploading => 'Uploading';

  @override
  String get sellPhotoFailed => 'Failed';

  @override
  String get sellTakePhoto => 'Take photo';

  @override
  String get sellChooseFromGallery => 'Choose from gallery';

  @override
  String get sellErrorMaxPhotos => 'Maximum 10 photos allowed';

  @override
  String get sellErrorInvalidPhoto => 'Photo quality too low or invalid format';

  @override
  String get sellErrorPhotoTooLarge => 'Photo exceeds 10MB limit';

  @override
  String get sellErrorUploadFailed => 'Failed to upload photo. Check your connection';

  @override
  String get sellErrorCameraDenied => 'Camera access required to capture photos';

  @override
  String get sellErrorGalleryDenied => 'Photo library access required to choose photos';

  @override
  String get sellErrorNotActive => 'Only active accounts can create listings';

  @override
  String get sellMinPhotosHint => 'Add at least 2 photos to continue';

  @override
  String get sellErrorMinPhotos => 'At least 2 photos required';

  @override
  String get sellErrorNotEditable => 'This listing can no longer be edited';

  @override
  String get itemDetailsTitle => 'Item Details';

  @override
  String get itemDetailsSubtitleManual => 'Fill in the details';

  @override
  String get itemDetailsAiBanner => 'AI filled these from your photos. Review and edit as needed.';

  @override
  String get itemTitleLabel => 'Title';

  @override
  String get itemTitleHint => 'e.g. iPhone 13 128GB';

  @override
  String get itemCategoryLabel => 'Category';

  @override
  String get itemCategoryOthers => 'Others';

  @override
  String get itemConditionLabel => 'Condition';

  @override
  String get itemConditionNew => 'Brand New';

  @override
  String get itemConditionLikeNew => 'Like New';

  @override
  String get itemConditionGood => 'Good';

  @override
  String get itemConditionFair => 'Fair';

  @override
  String get itemConditionPoor => 'Poor';

  @override
  String get itemDescriptionLabel => 'Description';

  @override
  String get itemDescriptionHint => 'Age, how it was used, accessories included';

  @override
  String get itemLocationLabel => 'Location';

  @override
  String get itemLocationChange => 'Change location';

  @override
  String get itemPriceLabel => 'Price';

  @override
  String get itemPriceNote => 'Buyers can negotiate. You can accept, counter, or reject any offer.';

  @override
  String get itemChooseListingPlan => 'Choose Listing Plan';

  @override
  String get itemFillMissing => 'Fill in the required fields to continue';

  @override
  String get itemTitleRequired => 'Enter a title for your item';

  @override
  String get itemCategoryRequired => 'Choose a category';

  @override
  String get itemConditionRequired => 'Choose the condition of your item';

  @override
  String get itemDescriptionRequired => 'Describe your item';

  @override
  String get itemPriceInvalid => 'Enter a valid price';

  @override
  String get itemCategoryChoose => 'Choose a category';

  @override
  String get itemCategoryChange => 'Change';

  @override
  String get itemCategoryPickerTitle => 'Choose category';

  @override
  String get itemCategorySearchHint => 'Search categories';

  @override
  String get itemCategorySearchMin => 'Type at least 2 letters to search';

  @override
  String get itemCategoryNoResults => 'No categories match';

  @override
  String get itemCategoryPopular => 'Popular';

  @override
  String get itemCategoryMore => 'More categories';

  @override
  String get itemCategoryAll => 'All categories';

  @override
  String get itemCategoryUnavailable => 'This category is not available. Choose another one.';

  @override
  String get itemSchemaFailed => 'Unable to load the details for this category. Try again';

  @override
  String get itemAboutTitle => 'About this item';

  @override
  String get itemMoreDetails => 'More details';

  @override
  String get itemMoreDetailsHint => 'Optional, but buyers like to know';

  @override
  String get itemConditionNotesLabel => 'Condition notes';

  @override
  String get itemConditionNotesHint =>
      'Scratches, repairs or missing parts. Write none if there are none.';

  @override
  String get itemConditionNotesRequired => 'Describe the condition, or write that there are none';

  @override
  String get itemNegotiableLabel => 'Price is negotiable';

  @override
  String get itemNegotiableRequired => 'Say whether the price can be negotiated';

  @override
  String get itemQuantityLabel => 'Quantity';

  @override
  String get itemQuantityInvalid => 'Enter a quantity from 1 to 1000';

  @override
  String get itemYes => 'Yes';

  @override
  String get itemNo => 'No';

  @override
  String get itemSelect => 'Select';

  @override
  String get itemSelectDate => 'Select date';

  @override
  String get itemSearch => 'Search';

  @override
  String get itemDone => 'Done';

  @override
  String get itemOtherValueHint => 'Or type your own';

  @override
  String get itemListHint => 'Separate with commas';

  @override
  String get itemDimLength => 'Length (cm)';

  @override
  String get itemDimWidth => 'Width (cm)';

  @override
  String get itemDimHeight => 'Height (cm)';

  @override
  String get itemAddDetail => 'Add detail';

  @override
  String get itemDetailName => 'Name';

  @override
  String get itemDetailValue => 'Value';

  @override
  String get itemRemoveDetail => 'Remove detail';

  @override
  String itemFieldRequired(String field) {
    return '$field is required';
  }

  @override
  String itemFieldInvalid(String field) {
    return 'Enter a valid $field';
  }

  @override
  String get itemAttributeError => 'Check the details you entered and try again';

  @override
  String get planDevBanner => 'Plan is under revision until US-119';

  @override
  String get planScreenSubtitle => 'Boost your visibility and sell faster';

  @override
  String planValidityDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String planValidityMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String planValidityLabel(String validity) {
    return '$validity validity';
  }

  @override
  String get planSupportAiEmail => 'AI + Email support';

  @override
  String get planSupportAiEmailChat => 'AI + Email + Chat (Human) support';

  @override
  String get planSupportAiEmailChatCall => 'AI + Email + Chat + On-call support';

  @override
  String get planBadgePopular => 'POPULAR';

  @override
  String get planBadgeBestValue => 'BEST VALUE';

  @override
  String get planSelected => 'Selected';

  @override
  String get planFree => 'Free';

  @override
  String planOriginalPriceSemantics(String price) {
    return 'Original price $price';
  }

  @override
  String get planBreakdownTitle => 'Payment breakdown';

  @override
  String get planBreakdownOriginal => 'Original price';

  @override
  String planBreakdownDiscount(int percent) {
    return 'Discount ($percent% off)';
  }

  @override
  String get planBreakdownGstIncluded => 'GST included';

  @override
  String planBreakdownGstAdded(String rate) {
    return 'GST ($rate%)';
  }

  @override
  String get planBreakdownTotal => 'Total to pay';

  @override
  String get planInclusiveOfGst => 'Inclusive of GST';

  @override
  String get planFreeNote => 'No payment is needed for this plan.';

  @override
  String get planNoPlans => 'No plans are available right now.';

  @override
  String get planReviewListing => 'Review Listing';

  @override
  String get planReviewSoon => 'Reviewing your listing is coming soon.';

  @override
  String get sellYourPhotos => 'Your photos';

  @override
  String get itemAiGenerated => 'AI generated';

  @override
  String get itemPleaseVerify => 'Please verify';

  @override
  String get sellAiAnalysing => 'Analysing your photos';

  @override
  String get sellAiUnavailable =>
      'AI Service is not available at this moment or your usage quota has exhausted, please do manual entry';

  @override
  String get sellAiNotRecognised =>
      'We could not recognise the item from your photos. Please fill in the details yourself.';
}
