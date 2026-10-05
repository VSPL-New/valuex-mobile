import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/auth/domain/entities/aadhaar_transaction.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:valuex_mobile/features/auth/domain/entities/otp_sent.dart';
import 'package:valuex_mobile/features/auth/domain/entities/signup_details.dart';
import 'package:valuex_mobile/features/auth/domain/entities/user_profile.dart';
import 'package:valuex_mobile/features/auth/domain/repositories/auth_repository.dart';

/// In-memory backend for whole-flow tests: it enforces the same state order as the server
/// (OTP code is always 123456) and keeps the session between app launches.
class FakeAuthRepository implements AuthRepository {
  AccountStatus? status;
  bool aadhaarVerified = false;
  String? mobile;
  String? email;
  SignupDetails? signup;
  final List<String> calls = [];

  FakeAuthRepository({this.status});

  static ApiError _business(String code) {
    return ApiError(type: ApiErrorType.business, message: code, code: code, statusCode: 400);
  }

  AuthResult _result(AccountStatus next) {
    status = next;
    return AuthResult(
      session: const AuthSession(accessToken: 'access', refreshToken: 'refresh', userId: 'user-1'),
      status: next,
      aadhaarVerified: aadhaarVerified,
    );
  }

  void _require(AccountStatus expected) {
    if (status != expected) throw _business('ERROR_INVALID_STATE');
  }

  @override
  Future<bool> hasSession() async => status != null;

  @override
  Future<void> clearSession() async => status = null;

  @override
  Future<UserProfile> fetchProfile() async {
    calls.add('fetchProfile');
    return UserProfile(
      userId: 'user-1',
      status: status ?? AccountStatus.newAccount,
      aadhaarVerified: aadhaarVerified,
      mobile: '98****3210',
      email: 'a***@example.com',
    );
  }

  @override
  Future<OtpSent> initiateRegistration(String mobile) async {
    calls.add('initiateRegistration');
    this.mobile = mobile;
    return const OtpSent(expiresInSeconds: 300);
  }

  @override
  Future<AuthResult> verifyMobileOtp({required String mobile, required String otp}) async {
    calls.add('verifyMobileOtp');
    if (otp != '123456') throw _business('ERROR_INVALID_OTP');
    return _result(AccountStatus.emailVerificationPending);
  }

  @override
  Future<OtpSent> sendEmailOtp(String email) async {
    calls.add('sendEmailOtp');
    _require(AccountStatus.emailVerificationPending);
    this.email = email;
    return const OtpSent(expiresInSeconds: 300);
  }

  @override
  Future<void> verifyEmailOtp({required String email, required String otp}) async {
    calls.add('verifyEmailOtp');
    _require(AccountStatus.emailVerificationPending);
    if (otp != '123456') throw _business('ERROR_INVALID_OTP');
    status = AccountStatus.identityVerificationPending;
  }

  @override
  Future<AuthResult> skipAadhaar() async {
    calls.add('skipAadhaar');
    _require(AccountStatus.identityVerificationPending);
    return _result(AccountStatus.signupPending);
  }

  @override
  Future<AadhaarTransaction> initiateAadhaar({
    required String aadhaarNumber,
    required String consentToken,
  }) async {
    calls.add('initiateAadhaar');
    if (status != AccountStatus.identityVerificationPending &&
        status != AccountStatus.signupPending &&
        status != AccountStatus.active) {
      throw _business('ERROR_INVALID_STATE');
    }
    return const AadhaarTransaction(transactionId: 'txn-1');
  }

  @override
  Future<AuthResult> verifyAadhaar({required String transactionId, required String otp}) async {
    calls.add('verifyAadhaar');
    if (otp != '123456') throw _business('ERROR_AADHAAR_VERIFICATION_FAILED');
    aadhaarVerified = true;
    final current = status;
    return _result(
      current == AccountStatus.identityVerificationPending ? AccountStatus.signupPending : current!,
    );
  }

  @override
  Future<AuthResult> completeSignup(SignupDetails details) async {
    calls.add('completeSignup');
    _require(AccountStatus.signupPending);
    signup = details;
    return _result(AccountStatus.active);
  }
}
