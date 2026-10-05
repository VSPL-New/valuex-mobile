import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
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

  Future<AuthResponseModel> verifyMobileOtp(
      {required String mobile, required String otp}) {
    return _client.post(
      ApiConstants.registerVerifyMobile,
      data: {'mobile': mobile, 'otp': otp},
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
    return _client.post(ApiConstants.skipAadhaar,
        parse: AuthResponseModel.fromJson);
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

  Future<UserProfileModel> fetchProfile() {
    return _client.get(ApiConstants.currentUser,
        parse: UserProfileModel.fromJson);
  }
}
