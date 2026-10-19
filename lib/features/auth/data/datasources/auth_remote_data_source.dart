import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/otp/otp_provider.dart';
import '../../domain/entities/signup_details.dart';
import '../models/auth_models.dart';

class AuthRemoteDataSource {
  final ApiClient _client;
  final OtpProvider _otp;

  AuthRemoteDataSource(this._client, [this._otp = const BackendOtpProvider()]);

  // Terms and consent are collected at Sign Up, so they are not sent here.
  Future<MessageResponseModel> initiateRegistration(String mobile) async {
    final sent = await _client.post(
      ApiConstants.registerInitiate,
      data: {'mobile': mobile},
      authenticated: false,
      parse: MessageResponseModel.fromJson,
    );
    await _otp.send(mobile);
    return sent;
  }

  Future<AuthResponseModel> verifyMobileOtp({required String mobile, required String otp}) async {
    return _client.post(
      ApiConstants.registerVerifyMobile,
      data: {'mobile': mobile, _otp.credentialKey: await _otp.credential(otp)},
      authenticated: false,
      parse: AuthResponseModel.fromJson,
    );
  }

  Future<MessageResponseModel> initiateLogin(String mobile) async {
    final sent = await _client.post(
      ApiConstants.loginInitiate,
      data: {'mobile': mobile},
      authenticated: false,
      parse: MessageResponseModel.fromJson,
    );
    await _otp.send(mobile);
    return sent;
  }

  Future<AuthResponseModel> verifyLogin({required String mobile, required String otp}) async {
    return _client.post(
      ApiConstants.loginVerifyMobile,
      data: {'mobile': mobile, _otp.credentialKey: await _otp.credential(otp)},
      authenticated: false,
      parse: AuthResponseModel.fromJson,
    );
  }

  /// Ends the session of the stored access token, or of [bearerToken] when given.
  Future<void> logout({String? bearerToken}) {
    return _client.post<void>(ApiConstants.logout, bearerToken: bearerToken);
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
  }) async {
    final sent = await _client.post(
      ApiConstants.googleInitiateMobile,
      data: {'socialSessionToken': socialSessionToken, 'mobile': mobile},
      authenticated: false,
      parse: MessageResponseModel.fromJson,
    );
    await _otp.send(mobile);
    return sent;
  }

  Future<AuthResponseModel> verifyGoogleMobile({
    required String socialSessionToken,
    required String mobile,
    required String otp,
  }) async {
    return _client.post(
      ApiConstants.googleVerifyMobile,
      data: {
        'socialSessionToken': socialSessionToken,
        'mobile': mobile,
        _otp.credentialKey: await _otp.credential(otp),
      },
      authenticated: false,
      parse: AuthResponseModel.fromJson,
    );
  }

  Future<MessageResponseModel> sendEmailOtp(String email) async {
    final sent = await _client.post(
      ApiConstants.emailSendOtp,
      data: {'email': email},
      parse: MessageResponseModel.fromJson,
    );
    await _otp.send(email);
    return sent;
  }

  Future<void> verifyEmailOtp({required String email, required String otp}) async {
    await _client.post<Object?>(
      ApiConstants.emailVerifyOtp,
      data: {'email': email, _otp.credentialKey: await _otp.credential(otp)},
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
        if (details.gender != null) 'gender': details.gender!.apiValue,
        'avatarId': details.avatarId,
        'termsAccepted': details.termsAccepted,
        'consentGiven': details.consentGiven,
        'termsVersion': details.termsVersion,
      },
      parse: AuthResponseModel.fromJson,
    );
  }

  Future<UserProfileModel> fetchProfile() {
    return _client.get(ApiConstants.currentUser, parse: UserProfileModel.fromJson);
  }
}
