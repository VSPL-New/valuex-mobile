import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/signup_details.dart';
import '../models/auth_models.dart';

class AuthRemoteDataSource {
  final ApiClient _client;

  AuthRemoteDataSource(this._client);

  // Terms and consent are collected at Sign Up, so they are not sent here.
  Future<MessageResponseModel> initiateRegistration(String mobile) {
    return _client.post(
      ApiConstants.registerInitiate,
      data: {'mobile': mobile},
      authenticated: false,
      parse: MessageResponseModel.fromJson,
    );
  }

  Future<AuthResponseModel> verifyMobileOtp({required String mobile, required String otp}) {
    return _client.post(
      ApiConstants.registerVerifyMobile,
      data: {'mobile': mobile, 'otp': otp},
      authenticated: false,
      parse: AuthResponseModel.fromJson,
    );
  }

  Future<MessageResponseModel> initiateLogin(String mobile) {
    return _client.post(
      ApiConstants.loginInitiate,
      data: {'mobile': mobile},
      authenticated: false,
      parse: MessageResponseModel.fromJson,
    );
  }

  Future<AuthResponseModel> verifyLogin({required String mobile, required String otp}) {
    return _client.post(
      ApiConstants.loginVerifyMobile,
      data: {'mobile': mobile, 'otp': otp},
      authenticated: false,
      parse: AuthResponseModel.fromJson,
    );
  }

  Future<GoogleSignInModel> signInWithGoogle(String idToken) {
    return _client.post(
      ApiConstants.googleSignIn,
      data: {'idToken': idToken},
      authenticated: false,
      parse: GoogleSignInModel.fromJson,
    );
  }

  Future<MessageResponseModel> initiateGoogleMobile({
    required String socialSessionToken,
    required String mobile,
  }) {
    return _client.post(
      ApiConstants.googleInitiateMobile,
      data: {'socialSessionToken': socialSessionToken, 'mobile': mobile},
      authenticated: false,
      parse: MessageResponseModel.fromJson,
    );
  }

  Future<AuthResponseModel> verifyGoogleMobile({
    required String socialSessionToken,
    required String mobile,
    required String otp,
  }) {
    return _client.post(
      ApiConstants.googleVerifyMobile,
      data: {'socialSessionToken': socialSessionToken, 'mobile': mobile, 'otp': otp},
      authenticated: false,
      parse: AuthResponseModel.fromJson,
    );
  }

  Future<MessageResponseModel> sendEmailOtp(String email) {
    return _client.post(
      ApiConstants.emailSendOtp,
      data: {'email': email},
      parse: MessageResponseModel.fromJson,
    );
  }

  Future<void> verifyEmailOtp({required String email, required String otp}) {
    return _client.post<Object?>(
      ApiConstants.emailVerifyOtp,
      data: {'email': email, 'otp': otp},
    );
  }

  Future<AuthResponseModel> skipAadhaar() {
    return _client.post(ApiConstants.skipAadhaar, parse: AuthResponseModel.fromJson);
  }

  Future<AadhaarInitiateModel> initiateAadhaar({
    required String aadhaarNumber,
    required String consentToken,
  }) {
    return _client.post(
      ApiConstants.aadhaarInitiate,
      data: {'aadhaarNumber': aadhaarNumber, 'consentToken': consentToken},
      parse: AadhaarInitiateModel.fromJson,
    );
  }

  Future<AuthResponseModel> verifyAadhaar({
    required String transactionId,
    required String otp,
  }) {
    return _client.post(
      ApiConstants.aadhaarVerify,
      data: {'transactionId': transactionId, 'otp': otp},
      parse: AuthResponseModel.fromJson,
    );
  }

  Future<AuthResponseModel> completeSignup(SignupDetails details) {
    return _client.post(
      ApiConstants.registerComplete,
      data: {
        'displayName': details.displayName,
        'gender': details.gender.apiValue,
        'dateOfBirth': _isoDate(details.dateOfBirth),
        'state': details.state,
        'city': details.city,
        'address': details.address,
        'pincode': details.pincode,
        'avatarId': details.avatarId,
        'termsAccepted': details.termsAccepted,
        'consentGiven': details.consentGiven,
        'termsVersion': details.termsVersion,
      },
      parse: AuthResponseModel.fromJson,
    );
  }

  static String _isoDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-${two(date.day)}';
  }

  Future<UserProfileModel> fetchProfile() {
    return _client.get(ApiConstants.currentUser, parse: UserProfileModel.fromJson);
  }
}
