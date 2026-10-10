import '../../../../core/security/secure_storage_service.dart';
import '../../domain/entities/aadhaar_transaction.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/otp_sent.dart';
import '../../domain/entities/signup_details.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_models.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final SecureStorageService _storage;

  AuthRepositoryImpl(this._remote, this._storage);

  @override
  Future<bool> hasSession() async {
    final refreshToken = await _storage.getRefreshToken();
    return refreshToken != null;
  }

  @override
  Future<UserProfile> fetchProfile() async {
    return (await _remote.fetchProfile()).toEntity();
  }

  @override
  Future<void> clearSession() => _storage.clearSession();

  @override
  Future<OtpSent> initiateRegistration(String mobile) async {
    return (await _remote.initiateRegistration(mobile)).toOtpSent();
  }

  @override
  Future<AuthResult> verifyMobileOtp({required String mobile, required String otp}) {
    return _store(_remote.verifyMobileOtp(mobile: mobile, otp: otp));
  }

  @override
  Future<OtpSent> initiateLogin(String mobile) async {
    return (await _remote.initiateLogin(mobile)).toOtpSent();
  }

  @override
  Future<AuthResult> verifyLogin({required String mobile, required String otp}) {
    return _store(_remote.verifyLogin(mobile: mobile, otp: otp));
  }

  @override
  Future<OtpSent> sendEmailOtp(String email) async {
    return (await _remote.sendEmailOtp(email)).toOtpSent();
  }

  @override
  Future<void> verifyEmailOtp({required String email, required String otp}) {
    return _remote.verifyEmailOtp(email: email, otp: otp);
  }

  @override
  Future<AuthResult> skipAadhaar() => _store(_remote.skipAadhaar());

  @override
  Future<AadhaarTransaction> initiateAadhaar({
    required String aadhaarNumber,
    required String consentToken,
  }) async {
    final model = await _remote.initiateAadhaar(
      aadhaarNumber: aadhaarNumber,
      consentToken: consentToken,
    );
    return model.toEntity();
  }

  @override
  Future<AuthResult> verifyAadhaar({required String transactionId, required String otp}) {
    return _store(_remote.verifyAadhaar(transactionId: transactionId, otp: otp));
  }

  @override
  Future<AuthResult> completeSignup(SignupDetails details) {
    return _store(_remote.completeSignup(details));
  }

  Future<AuthResult> _store(Future<AuthResponseModel> call) async {
    final result = (await call).toEntity();
    await _storage.saveAccessToken(result.session.accessToken);
    await _storage.saveRefreshToken(result.session.refreshToken);
    await _storage.saveUserId(result.session.userId);
    return result;
  }
}
