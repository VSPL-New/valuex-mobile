import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:valuex_mobile/features/auth/data/models/auth_models.dart';
import 'package:valuex_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';

import '../../../helpers/fake_http_adapter.dart';
import '../../../helpers/fake_secure_storage.dart';
import '../../../helpers/mocks.dart';

final _config = AppConfig.parse(
  env: 'dev',
  apiBaseUrl: 'http://localhost:8080/api/v1',
  aadhaarFlow: 'sandbox',
);

const _authJson = {
  'accessToken': 'access-1',
  'refreshToken': 'refresh-1',
  'userId': 'user-1',
  'status': 'EMAIL_VERIFICATION_PENDING',
  'aadhaarVerified': false,
};

void main() {
  group('models', () {
    test('AuthResponseModel maps to an AuthResult', () {
      final result = AuthResponseModel.fromJson(_authJson).toEntity();

      expect(result.session.accessToken, 'access-1');
      expect(result.session.refreshToken, 'refresh-1');
      expect(result.session.userId, 'user-1');
      expect(result.status, AccountStatus.emailVerificationPending);
      expect(result.aadhaarVerified, isFalse);
    });

    test('UserProfileModel tolerates missing optional fields', () {
      final profile = UserProfileModel.fromJson({
        'userId': 'user-1',
        'status': 'SIGNUP_PENDING',
      }).toEntity();

      expect(profile.status, AccountStatus.signupPending);
      expect(profile.aadhaarVerified, isFalse);
      expect(profile.displayName, isNull);
    });

    test('MessageResponseModel reads the OTP lifetime', () {
      expect(
        MessageResponseModel.fromJson(
                {'message': 'sent', 'otpExpiresInSeconds': 300})
            .toOtpSent()
            .expiresInSeconds,
        300,
      );
      expect(
          MessageResponseModel.fromJson({'message': 'ok'})
              .toOtpSent()
              .expiresInSeconds,
          isNull);
    });
  });

  group('AuthRemoteDataSource', () {
    late FakeHttpAdapter adapter;
    late AuthRemoteDataSource dataSource;

    setUp(() {
      adapter = FakeHttpAdapter((options) async {
        return switch (options.path) {
          '/auth/register/initiate' => FakeHttpAdapter.ok({
              'message': 'OTP sent',
              'otpExpiresInSeconds': 300,
            }),
          '/auth/register/verify-mobile' ||
          '/auth/register/skip-aadhaar' ||
          '/auth/aadhaar/verify' =>
            FakeHttpAdapter.ok(_authJson),
          '/users/me' =>
            FakeHttpAdapter.ok({'userId': 'user-1', 'status': 'ACTIVE'}),
          _ => FakeHttpAdapter.ok({'message': 'ok', 'transactionId': 'txn-1'}),
        };
      });
      final client = ApiClient(
        FakeSecureStorage(accessToken: 'access-1', refreshToken: 'refresh-1'),
        _config,
        adapter: adapter,
      );
      dataSource = AuthRemoteDataSource(client);
    });

    test('initiate sends only the mobile number and no bearer token', () async {
      final result = await dataSource.initiateRegistration('9876543210');

      final request = adapter.requests.single;
      expect(request.path, '/auth/register/initiate');
      expect(request.data, {'mobile': '9876543210'});
      expect(request.headers.containsKey('Authorization'), isFalse);
      expect(result.otpExpiresInSeconds, 300);
    });

    test('verify mobile posts mobile and otp without a bearer token', () async {
      await dataSource.verifyMobileOtp(mobile: '9876543210', otp: '123456');

      final request = adapter.requests.single;
      expect(request.path, '/auth/register/verify-mobile');
      expect(request.data, {'mobile': '9876543210', 'otp': '123456'});
      expect(request.headers.containsKey('Authorization'), isFalse);
    });

    test('email calls carry the bearer token', () async {
      await dataSource.sendEmailOtp('a@b.com');
      await dataSource.verifyEmailOtp(email: 'a@b.com', otp: '123456');

      expect(adapter.requests[0].path, '/auth/email/send-otp');
      expect(adapter.requests[0].data, {'email': 'a@b.com'});
      expect(adapter.requests[1].path, '/auth/email/verify-otp');
      expect(adapter.requests[1].data, {'email': 'a@b.com', 'otp': '123456'});
      expect(adapter.requests[1].headers['Authorization'], 'Bearer access-1');
    });

    test('Aadhaar calls post the documented fields', () async {
      final started = await dataSource.initiateAadhaar(
        aadhaarNumber: '123412341234',
        consentToken: '2026-10-06T10:00:00Z',
      );
      await dataSource.verifyAadhaar(transactionId: 'txn-1', otp: '123456');

      expect(started.transactionId, 'txn-1');
      expect(adapter.requests[0].path, '/auth/aadhaar/initiate');
      expect(adapter.requests[0].data, {
        'aadhaarNumber': '123412341234',
        'consentToken': '2026-10-06T10:00:00Z',
      });
      expect(adapter.requests[1].path, '/auth/aadhaar/verify');
    });

    test('skip Aadhaar and profile use their endpoints', () async {
      await dataSource.skipAadhaar();
      final profile = await dataSource.fetchProfile();

      expect(adapter.requests[0].path, '/auth/register/skip-aadhaar');
      expect(adapter.requests[1].path, '/users/me');
      expect(profile.status, 'ACTIVE');
    });
  });

  group('AuthRepositoryImpl', () {
    late MockAuthRemoteDataSource remote;
    late FakeSecureStorage storage;
    late AuthRepositoryImpl repository;

    setUp(() {
      remote = MockAuthRemoteDataSource();
      storage = FakeSecureStorage();
      repository = AuthRepositoryImpl(remote, storage);
    });

    test('verifying the mobile OTP stores the issued session', () async {
      when(
        () => remote.verifyMobileOtp(mobile: '9876543210', otp: '123456'),
      ).thenAnswer((_) async => AuthResponseModel.fromJson(_authJson));

      final result =
          await repository.verifyMobileOtp(mobile: '9876543210', otp: '123456');

      expect(result.status, AccountStatus.emailVerificationPending);
      expect(storage.accessToken, 'access-1');
      expect(storage.refreshToken, 'refresh-1');
      expect(storage.userId, 'user-1');
    });

    test('skipping Aadhaar replaces the stored tokens', () async {
      storage.accessToken = 'old';
      storage.refreshToken = 'old-refresh';
      when(() => remote.skipAadhaar()).thenAnswer(
        (_) async => AuthResponseModel.fromJson(
            {..._authJson, 'status': 'SIGNUP_PENDING'}),
      );

      final result = await repository.skipAadhaar();

      expect(result.status, AccountStatus.signupPending);
      expect(storage.accessToken, 'access-1');
    });

    test('verifying Aadhaar stores the session', () async {
      when(() => remote.verifyAadhaar(transactionId: 'txn-1', otp: '123456'))
          .thenAnswer(
        (_) async =>
            AuthResponseModel.fromJson({..._authJson, 'aadhaarVerified': true}),
      );

      final result =
          await repository.verifyAadhaar(transactionId: 'txn-1', otp: '123456');

      expect(result.aadhaarVerified, isTrue);
      expect(storage.refreshToken, 'refresh-1');
    });

    test('hasSession depends on the stored refresh token', () async {
      expect(await repository.hasSession(), isFalse);
      storage.refreshToken = 'refresh-1';
      expect(await repository.hasSession(), isTrue);
    });

    test('clearSession removes tokens and user id', () async {
      storage
        ..accessToken = 'a'
        ..refreshToken = 'r'
        ..userId = 'u';

      await repository.clearSession();

      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(storage.userId, isNull);
    });

    test('OTP sends do not touch the stored session', () async {
      when(() => remote.initiateRegistration('9876543210')).thenAnswer(
        (_) async => const MessageResponseModel(otpExpiresInSeconds: 300),
      );

      final sent = await repository.initiateRegistration('9876543210');

      expect(sent.expiresInSeconds, 300);
      expect(storage.accessToken, isNull);
    });
  });
}
