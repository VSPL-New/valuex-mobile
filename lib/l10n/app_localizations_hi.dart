// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'JustQlic';

  @override
  String get commonBack => 'वापस';

  @override
  String get commonRetry => 'पुनः प्रयास करें';

  @override
  String get commonSkip => 'छोड़ें';

  @override
  String get commonNext => 'आगे';

  @override
  String onboardingPageOf(int current, int total) {
    return '$total में से पृष्ठ $current';
  }

  @override
  String get splashInitializing => 'A1 इंजन शुरू हो रहा है...';

  @override
  String get homeComingSoon => 'होम — जल्द आ रहा है';

  @override
  String get onboardingTitle1 => 'JustQlic से बेचना हुआ आसान';

  @override
  String get onboardingSubtitle1 =>
      'अपने सामान की फ़ोटो लें और AI को लिस्टिंग बनाने, विवरण सुझाने और जल्दी बेचने में मदद करने दें।';

  @override
  String get onboardingTitle2 => 'JustQlic से पाएँ\nअपनी पसंद';

  @override
  String get onboardingSubtitle2 =>
      'फ़ोटो अपलोड करें या खींचें और खरीदने के लिए वही या मिलते-जुलते उत्पाद तुरंत खोजें।';

  @override
  String get onboardingTitle3 => 'असली लोग, सुरक्षित और स्मार्ट डील';

  @override
  String get onboardingSubtitle3 =>
      'सत्यापित उपयोगकर्ता, रेटिंग और स्मार्ट धोखाधड़ी सुरक्षा हर डील को ज़्यादा सुरक्षित और भरोसेमंद बनाते हैं।';

  @override
  String get onboardingTitle4 => 'सुरक्षित भुगतान, सुरक्षित बिक्री';

  @override
  String get onboardingSubtitle4 =>
      'लेन-देन पूरा करते समय आपका भुगतान सुरक्षित रहता है,\nपूरे भरोसे के साथ।';

  @override
  String get createAccountCreate => 'खाता बनाएँ';

  @override
  String get createAccountSignIn => 'साइन इन';

  @override
  String get createAccountOrLoginWith => 'या इससे लॉगिन करें';

  @override
  String get createAccountContinueGoogle => 'Google के साथ जारी रखें';

  @override
  String get createAccountContinueGuest => 'अतिथि के रूप में जारी रखें';

  @override
  String get createAccountSignInComingSoon => 'साइन इन जल्द उपलब्ध होगा';

  @override
  String get createAccountGoogleComingSoon => 'Google साइन-इन जल्द उपलब्ध होगा';

  @override
  String get signupMobileTitle => 'खाता बनाएँ';

  @override
  String get signupMobileSubtitle => 'JustQlic पर 10 लाख+ उपयोगकर्ताओं से जुड़ें';

  @override
  String get signupMobileLabel => 'मोबाइल नंबर';

  @override
  String get signupMobileHint => 'हम आपका नंबर सत्यापित करने के लिए OTP भेजेंगे';

  @override
  String get signupMobileSendOtp => 'OTP भेजें';

  @override
  String get signupMobileInvalid => '10 अंकों का मान्य मोबाइल नंबर दर्ज करें';

  @override
  String get signupMobileOtpComingSoon => 'OTP सत्यापन जल्द उपलब्ध होगा';

  @override
  String get errorUnableToConnect => 'कनेक्ट नहीं हो पा रहा — पुनः प्रयास करें';

  @override
  String get errorSomethingWentWrong => 'कुछ गलत हो गया — फिर से कोशिश करें';

  @override
  String get errorSessionExpired => 'सत्र समाप्त हो गया — फिर से लॉगिन करें';

  @override
  String get accountBlockedTitle => 'खाता उपलब्ध नहीं है';

  @override
  String get accountBlockedMessage =>
      'यह खाता अभी उपयोग नहीं किया जा सकता। कृपया सहायता के लिए सपोर्ट से संपर्क करें।';

  @override
  String get accountBlockedAction => 'शुरुआत पर वापस जाएँ';

  @override
  String get authErrorMobileRegistered => 'यह मोबाइल नंबर पहले से पंजीकृत है';

  @override
  String get authErrorEmailRegistered => 'यह ईमेल पहले से किसी अन्य खाते से जुड़ा है';

  @override
  String get authErrorInvalidOtp => 'OTP गलत है या समाप्त हो गया है';

  @override
  String get authErrorOtpExpired => 'OTP समाप्त हो गया है। कृपया नया OTP मँगवाएँ';

  @override
  String get authErrorOtpRateLimit => 'बहुत अधिक OTP अनुरोध। कृपया 10 मिनट बाद फिर कोशिश करें';

  @override
  String get authErrorOtpMaxAttempts => 'बहुत अधिक गलत प्रयास। कृपया नया OTP मँगवाएँ';

  @override
  String get authErrorInvalidState => 'यह चरण अभी उपलब्ध नहीं है';

  @override
  String get authErrorUserNotFound => 'आपका खाता नहीं मिला। कृपया दोबारा शुरू करें';

  @override
  String get authErrorValidation => 'कृपया दर्ज की गई जानकारी जाँच लें';

  @override
  String get emailEntryTitle => 'ईमेल सत्यापित करें';

  @override
  String get emailEntrySubtitle => 'अपने खाते को सुरक्षित रखने के लिए ईमेल जोड़ें';

  @override
  String get emailEntryLabel => 'ईमेल पता';

  @override
  String get emailEntryFieldHint => 'name@example.com';

  @override
  String get emailEntryHint => 'हम आपका ईमेल सत्यापित करने के लिए OTP भेजेंगे';

  @override
  String get emailEntrySendOtp => 'OTP भेजें';

  @override
  String get otpMobileTitle => 'अपना नंबर सत्यापित करें';

  @override
  String get otpEmailTitle => 'अपना ईमेल सत्यापित करें';

  @override
  String otpSubtitle(String target) {
    return '$target पर भेजा गया 6 अंकों का कोड दर्ज करें';
  }

  @override
  String get otpFieldLabel => '6 अंकों का वन-टाइम कोड';

  @override
  String get otpVerify => 'सत्यापित करें';

  @override
  String get otpIncomplete => '6 अंकों का कोड दर्ज करें';

  @override
  String get otpResend => 'कोड फिर से भेजें';

  @override
  String otpResendIn(int seconds) {
    return '$seconds सेकंड में कोड फिर से भेजें';
  }

  @override
  String otpExpiresIn(String time) {
    return 'कोड $time में समाप्त होगा';
  }

  @override
  String get otpExpired => 'कोड समाप्त हो गया है। नया कोड मँगवाएँ।';

  @override
  String get otpResendLimit => 'दोबारा भेजने की सीमा पूरी हो गई। कृपया बाद में कोशिश करें।';

  @override
  String get otpResent => 'नया कोड भेज दिया गया है';

  @override
  String get otpChangeNumber => 'नंबर बदलें';

  @override
  String get otpChangeEmail => 'ईमेल बदलें';

  @override
  String get aadhaarTitle => 'आधार सत्यापित करें';

  @override
  String get aadhaarSubtitle => 'अपने आधार नंबर से अपनी पहचान सत्यापित करें';

  @override
  String get aadhaarNote =>
      'आप ‘अभी छोड़ें’ चुन सकते हैं, लेकिन किसी भी लेन-देन (खरीदना/बेचना/विक्रेता या खरीदार से संपर्क) से पहले आधार सत्यापन ज़रूरी है। इसलिए अपने पहले लेन-देन से पहले आपको यह एक बार का आधार सत्यापन पूरा करना होगा।';

  @override
  String get aadhaarNumberLabel => 'आधार नंबर';

  @override
  String get aadhaarNumberHint => '12 अंकों का आधार नंबर';

  @override
  String get aadhaarShowNumber => 'आधार नंबर दिखाएँ';

  @override
  String get aadhaarHideNumber => 'आधार नंबर छिपाएँ';

  @override
  String get aadhaarConsent =>
      'मैं अपनी पहचान सत्यापित करने के लिए ValueX को अपना आधार नंबर उपयोग करने की सहमति देता/देती हूँ';

  @override
  String get aadhaarVerifyButton => 'आधार सत्यापित करें';

  @override
  String get aadhaarSkip => 'अभी छोड़ें';

  @override
  String get aadhaarNotNow => 'अभी नहीं';

  @override
  String get aadhaarComingSoon =>
      'आधार सत्यापन जल्द उपलब्ध होगा। आप अभी छोड़ सकते हैं और अपने पहले लेन-देन से पहले इसे पूरा कर सकते हैं।';

  @override
  String get aadhaarDevBanner =>
      'केवल डेवलपमेंट के लिए — इसे तृतीय-पक्ष आधार सत्यापन सेवा प्रदाता से बदला जाएगा';

  @override
  String get aadhaarOtpTitle => 'आधार OTP दर्ज करें';

  @override
  String get aadhaarOtpSubtitle =>
      'आपके आधार से जुड़े मोबाइल नंबर पर भेजा गया 6 अंकों का कोड दर्ज करें';

  @override
  String get aadhaarChangeNumber => 'आधार नंबर बदलें';

  @override
  String get authErrorAadhaarUsed => 'यह आधार पहले से किसी खाते से जुड़ा है';

  @override
  String get authErrorAadhaarRecovery =>
      'यह आधार एक बंद खाते से जुड़ा है। कृपया सपोर्ट से संपर्क करें';

  @override
  String get authErrorAadhaarUnavailable => 'सत्यापन सेवा अभी उपलब्ध नहीं है। कृपया फिर कोशिश करें';

  @override
  String get authErrorAadhaarSessionExpired =>
      'आधार सत्र समाप्त हो गया। कृपया आधार नंबर दोबारा दर्ज करें';

  @override
  String get authErrorAadhaarFailed => 'आधार सत्यापित नहीं हो सका। कृपया फिर कोशिश करें';

  @override
  String get commonClose => 'बंद करें';

  @override
  String get signupProfileTitle => 'अपनी प्रोफ़ाइल बनाएँ';

  @override
  String get signupProfileSubtitle => 'बस थोड़ा और! हमें अपने बारे में कुछ बताएँ';

  @override
  String get signupAvatarEdit => 'अवतार बदलें';

  @override
  String get signupAvatarSheetTitle => 'अपना अवतार चुनें';

  @override
  String get avatarGroupMale => 'पुरुष';

  @override
  String get avatarGroupFemale => 'महिला';

  @override
  String get avatarGroupNeutral => 'सामान्य';

  @override
  String avatarLabel(int number) {
    return 'अवतार $number';
  }

  @override
  String get signupNameLabel => 'नाम';

  @override
  String get signupNameHint => 'आपका पूरा नाम';

  @override
  String get signupGenderLabel => 'लिंग';

  @override
  String get genderMale => 'पुरुष';

  @override
  String get genderFemale => 'महिला';

  @override
  String get genderOthers => 'अन्य';

  @override
  String get signupDobLabel => 'जन्म तिथि';

  @override
  String get signupDobHint => 'दिन/माह/वर्ष';

  @override
  String get signupDobPick => 'जन्म तिथि चुनें';

  @override
  String get signupEmailLabel => 'ईमेल';

  @override
  String get signupPhoneLabel => 'फ़ोन';

  @override
  String get signupVerifiedReadOnly => 'सत्यापित';

  @override
  String get signupStateLabel => 'राज्य';

  @override
  String get signupStateHint => 'अपना राज्य चुनें';

  @override
  String get signupStateSheetTitle => 'अपना राज्य चुनें';

  @override
  String get signupCityLabel => 'शहर';

  @override
  String get signupCityHint => 'आपका शहर';

  @override
  String get signupAddressLabel => 'पता';

  @override
  String get signupAddressHint => 'मकान नंबर, गली, इलाका';

  @override
  String get signupPincodeLabel => 'पिनकोड';

  @override
  String get signupPincodeHint => '6 अंकों का पिनकोड';

  @override
  String get signupTermsPrefix => 'मैं ';

  @override
  String get signupTermsLink => 'नियम और शर्तों';

  @override
  String get signupTermsSuffix => ' से सहमत हूँ और अपने डेटा के उपयोग की सहमति देता/देती हूँ';

  @override
  String get signupTermsHint => 'इसे चालू करने के लिए पहले नियम और शर्तें खोलें';

  @override
  String get signupSubmit => 'जमा करें';

  @override
  String get signupHaveAccount => 'क्या आपके पास पहले से खाता है?';

  @override
  String get signupSignIn => 'साइन इन';

  @override
  String get signupErrorName => '3 से 50 अक्षर दर्ज करें';

  @override
  String get signupErrorCity => '2 से 100 अक्षर दर्ज करें';

  @override
  String get signupErrorAddress => '10 से 255 अक्षर दर्ज करें';

  @override
  String get signupErrorPincode => '6 अंकों का सही पिनकोड दर्ज करें';

  @override
  String get signupErrorDobFormat => 'दिन/माह/वर्ष में सही तारीख दर्ज करें';

  @override
  String get signupErrorDobFuture => 'जन्म तिथि भविष्य की नहीं हो सकती';

  @override
  String get authErrorInvalidAddressState => 'कृपया सही राज्य चुनें';

  @override
  String get authErrorInvalidDob => 'कृपया सही जन्म तिथि दर्ज करें';

  @override
  String get authErrorTermsNotAccepted => 'आगे बढ़ने के लिए कृपया नियम और शर्तें स्वीकार करें';

  @override
  String get authErrorConsentRequired => 'डेटा के उपयोग की सहमति आवश्यक है';

  @override
  String get authErrorInvalidAvatar => 'चुना गया अवतार उपलब्ध नहीं है। कृपया दूसरा चुनें';

  @override
  String get termsTitle => 'नियम और शर्तें';

  @override
  String get termsLastUpdated => 'अंतिम अपडेट: [तारीख जोड़ी जाएगी]';

  @override
  String get termsPlaceholder => '[कानूनी पाठ जोड़ा जाएगा]';

  @override
  String get termsSection1 => '1. शर्तों की स्वीकृति';

  @override
  String get termsSection2 => '2. आपका खाता';

  @override
  String get termsSection3 => '3. ValueX का उपयोग';

  @override
  String get termsSection4 => '4. लिस्टिंग और खरीदारी';

  @override
  String get termsSection5 => '5. भुगतान और शुल्क';

  @override
  String get termsSection6 => '6. गोपनीयता और आपका डेटा';

  @override
  String get termsSection7 => '7. इन शर्तों में बदलाव';

  @override
  String get termsSection8 => '8. हमसे संपर्क करें';
}
