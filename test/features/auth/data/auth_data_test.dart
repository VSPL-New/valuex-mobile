import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/otp/otp_provider.dart';
import 'package:valuex_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:valuex_mobile/features/auth/data/models/auth_models.dart';
import 'package:valuex_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/gender.dart';
import 'package:valuex_mobile/features/auth/domain/entities/google_sign_in_result.dart';
import 'package:valuex_mobile/features/auth/domain/entities/logout_outcome.dart';
import 'package:valuex_mobile/features/auth/domain/entities/signup_details.dart';

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

    test('GoogleSignInModel for a linked account carries the issued session and status', () {
      final result = GoogleSignInModel.fromJson({
        'requiresMobileVerification': false,
        'accessToken': 'access-1',
        'refreshToken': 'refresh-1',
        'userId': 'user-1',
        'status': 'ACTIVE',
        'aadhaarVerified': true,
      }).toResult();

      expect(result, isA<GoogleSignedIn>());
      final auth = (result as GoogleSignedIn).auth;
      expect(auth.session.refreshToken, 'refresh-1');
      expect(auth.status, AccountStatus.active);
      expect(auth.aadhaarVerified, isTrue);
    });

    test('GoogleSignInModel for a new Google account carries the session and email', () {
      final result = GoogleSignInModel.fromJson({
        'requiresMobileVerification': true,
        'socialSessionToken': 'social-1',
        'googleEmail': 'a@gmail.com',
      }).toResult();

      expect(result, isA<GoogleNeedsMobile>());
      expect((result as GoogleNeedsMobile).socialSessionToken, 'social-1');
      expect(result.email, 'a@gmail.com');
    });

    test('MessageResponseModel reads the OTP lifetime', () {
      expect(
        MessageResponseModel.fromJson({'message': 'sent', 'otpExpiresInSeconds': 300})
            .toOtpSent()
            .expiresInSeconds,
        300,
      );
      expect(MessageResponseModel.fromJson({'message': 'ok'}).toOtpSent().expiresInSeconds, isNull);
    });
  });

  group('AuthRemoteDataSource', () {
    late FakeHttpAdapter adapter;
    late AuthRemoteDataSource dataSource;

    setUp(() {
      adapter = FakeHttpAdapter((options) async {
        return switch (options.path) {
          '/auth/register/initiate' || '/auth/login/initiate' => FakeHttpAdapter.ok({
              'message': 'OTP sent',
              'otpExpiresInSeconds': 300,
            }),
          '/auth/social/google/initiate-mobile' => FakeHttpAdapter.ok({
              'message': 'OTP sent',
              'otpExpiresInSeconds': 300,
            }),
          '/auth/social/google' => FakeHttpAdapter.ok({
              'requiresMobileVerification': true,
              'socialSessionToken': 'social-1',
              'googleEmail': 'a@gmail.com',
            }),
          '/auth/register/verify-mobile' ||
          '/auth/login/verify-mobile' ||
          '/auth/social/google/verify-mobile' ||
          '/auth/register/skip-aadhaar' ||
          '/auth/register/complete' ||
          '/auth/aadhaar/verify' =>
            FakeHttpAdapter.ok(_authJson),
          '/users/me' => FakeHttpAdapter.ok({'userId': 'user-1', 'status': 'ACTIVE'}),
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

    test('logout posts without a body, with the stored bearer token', () async {
      await dataSource.logout();

      final request = adapter.requests.single;
      expect(request.path, '/auth/logout');
      expect(request.data, isNull);
      expect(request.headers['Authorization'], 'Bearer access-1');
    });

    test('logout can revoke a given access token instead', () async {
      await dataSource.logout(bearerToken: 'pending-1');

      expect(adapter.requests.single.headers['Authorization'], 'Bearer pending-1');
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

    test(
        'with MSG91 the number goes to MSG91 after the backend accepts it and the proof is its token',
        () async {
      final calls = <String>[];
      final msg91 = Msg91OtpProvider(
        widgetId: 'widget-1',
        authToken: 'token-1',
        sendOtp: (body) async {
          calls.add('send ${body['identifier']}');
          return {'type': 'success', 'message': 'req-1'};
        },
        verifyOtp: (body) async {
          calls.add('verify ${body['otp']}');
          return {'type': 'success', 'message': 'jwt-1'};
        },
      );
      final source = AuthRemoteDataSource(
        ApiClient(
          FakeSecureStorage(accessToken: 'access-1', refreshToken: 'refresh-1'),
          _config,
          adapter: adapter,
        ),
        msg91,
      );

      await source.initiateRegistration('9876543210');
      await source.verifyMobileOtp(mobile: '9876543210', otp: '123456');

      expect(adapter.requests[0].data, {'mobile': '9876543210'});
      expect(adapter.requests[1].data, {'mobile': '9876543210', 'accessToken': 'jwt-1'});
      expect(calls, ['send 919876543210', 'verify 123456']);
    });

    test('with MSG91 a rejected code never reaches the backend', () async {
      final msg91 = Msg91OtpProvider(
        widgetId: 'widget-1',
        authToken: 'token-1',
        sendOtp: (_) async => {'type': 'success', 'message': 'req-1'},
        verifyOtp: (_) async => {'type': 'error', 'message': 'otp not match'},
      );
      final source = AuthRemoteDataSource(
        ApiClient(
          FakeSecureStorage(accessToken: 'access-1', refreshToken: 'refresh-1'),
          _config,
          adapter: adapter,
        ),
        msg91,
      );
      await source.initiateLogin('9876543210');

      await expectLater(
        source.verifyLogin(mobile: '9876543210', otp: '000000'),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'ERROR_INVALID_OTP')),
      );
      expect(adapter.requests.map((r) => r.path), ['/auth/login/initiate']);
    });

    test('sign in sends the number and verifies the code without a bearer token', () async {
      final sent = await dataSource.initiateLogin('9876543210');
      final result = await dataSource.verifyLogin(mobile: '9876543210', otp: '123456');

      expect(adapter.requests[0].path, '/auth/login/initiate');
      expect(adapter.requests[0].data, {'mobile': '9876543210'});
      expect(adapter.requests[1].path, '/auth/login/verify-mobile');
      expect(adapter.requests[1].data, {'mobile': '9876543210', 'otp': '123456'});
      for (final request in adapter.requests) {
        expect(request.headers.containsKey('Authorization'), isFalse);
      }
      expect(sent.otpExpiresInSeconds, 300);
      expect(result.status, 'EMAIL_VERIFICATION_PENDING');
    });

    test('Google calls send the ID token, session token and number without a bearer token',
        () async {
      final started = await dataSource.signInWithGoogle('id-token-1');
      final sent = await dataSource.initiateGoogleMobile(
        socialSessionToken: 'social-1',
        mobile: '9876543210',
      );
      final verified = await dataSource.verifyGoogleMobile(
        socialSessionToken: 'social-1',
        mobile: '9876543210',
        otp: '123456',
      );

      expect(adapter.requests[0].path, '/auth/social/google');
      expect(adapter.requests[0].data, {'idToken': 'id-token-1'});
      expect(adapter.requests[1].path, '/auth/social/google/initiate-mobile');
      expect(adapter.requests[1].data, {'socialSessionToken': 'social-1', 'mobile': '9876543210'});
      expect(adapter.requests[2].path, '/auth/social/google/verify-mobile');
      expect(adapter.requests[2].data, {
        'socialSessionToken': 'social-1',
        'mobile': '9876543210',
        'otp': '123456',
      });
      for (final request in adapter.requests) {
        expect(request.headers.containsKey('Authorization'), isFalse);
      }
      expect(started.requiresMobileVerification, isTrue);
      expect(sent.otpExpiresInSeconds, 300);
      expect(verified.status, 'EMAIL_VERIFICATION_PENDING');
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

    test('complete sign up posts the profile', () async {
      await dataSource.completeSignup(
        const SignupDetails(
          displayName: 'Asha Verma',
          gender: Gender.female,
          avatarId: 'avatar-05',
          termsAccepted: true,
          consentGiven: true,
          termsVersion: 'template-0',
        ),
      );

      final request = adapter.requests.single;
      expect(request.path, '/auth/register/complete');
      expect(request.headers['Authorization'], 'Bearer access-1');
      expect(request.data, {
        'displayName': 'Asha Verma',
        'gender': 'FEMALE',
        'avatarId': 'avatar-05',
        'termsAccepted': true,
        'consentGiven': true,
        'termsVersion': 'template-0',
      });
    });

    test('complete sign up leaves the gender out when none was chosen', () async {
      await dataSource.completeSignup(
        const SignupDetails(
          displayName: 'Asha Verma',
          avatarId: 'avatar-09',
          termsAccepted: true,
          consentGiven: true,
          termsVersion: 'template-0',
        ),
      );

      final body = adapter.requests.single.data as Map<String, dynamic>;
      expect(body.containsKey('gender'), isFalse);
      expect(body.containsKey('dateOfBirth'), isFalse);
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

    group('logout', () {
      const offline = ApiError(type: ApiErrorType.network, message: 'offline');

      setUp(() {
        storage
          ..accessToken = 'access-1'
          ..refreshToken = 'refresh-1'
          ..userId = 'user-1';
      });

      test('clears the stored session once the server confirmed', () async {
        when(() => remote.logout()).thenAnswer((_) async {});

        final outcome = await repository.logout();

        expect(outcome, LogoutOutcome.revoked);
        expect(storage.accessToken, isNull);
        expect(storage.refreshToken, isNull);
        expect(storage.userId, isNull);
        expect(storage.pendingLogoutToken, isNull);
      });

      test('queues the revocation and still signs out when offline', () async {
        when(() => remote.logout()).thenThrow(offline);

        final outcome = await repository.logout();

        expect(outcome, LogoutOutcome.queued);
        expect(storage.pendingLogoutToken, 'access-1');
        expect(storage.accessToken, isNull);
        expect(storage.refreshToken, isNull);
      });

      test('queues the revocation after a server error', () async {
        when(() => remote.logout()).thenThrow(
          const ApiError(type: ApiErrorType.server, message: 'down', statusCode: 503),
        );

        expect(await repository.logout(), LogoutOutcome.queued);
      });

      test('has nothing to queue when the session had no access token', () async {
        storage.accessToken = null;
        when(() => remote.logout()).thenThrow(offline);

        final outcome = await repository.logout();

        expect(outcome, LogoutOutcome.revoked);
        expect(storage.pendingLogoutToken, isNull);
        expect(storage.refreshToken, isNull);
      });

      test('treats an expired session as already logged out', () async {
        when(() => remote.logout()).thenThrow(const ApiError.sessionExpired());

        final outcome = await repository.logout();

        expect(outcome, LogoutOutcome.revoked);
        expect(storage.pendingLogoutToken, isNull);
        expect(storage.refreshToken, isNull);
      });

      test('revokePendingSession does nothing without a queued token', () async {
        await repository.revokePendingSession();

        verifyNever(() => remote.logout(bearerToken: any(named: 'bearerToken')));
      });

      test('revokePendingSession revokes the queued token and forgets it', () async {
        storage.pendingLogoutToken = 'pending-1';
        when(() => remote.logout(bearerToken: 'pending-1')).thenAnswer((_) async {});

        await repository.revokePendingSession();

        verify(() => remote.logout(bearerToken: 'pending-1')).called(1);
        expect(storage.pendingLogoutToken, isNull);
      });

      test('revokePendingSession keeps the token while still offline', () async {
        storage.pendingLogoutToken = 'pending-1';
        when(() => remote.logout(bearerToken: 'pending-1')).thenThrow(offline);

        await repository.revokePendingSession();

        expect(storage.pendingLogoutToken, 'pending-1');
      });

      test('revokePendingSession drops a token the server no longer accepts', () async {
        storage.pendingLogoutToken = 'pending-1';
        when(() => remote.logout(bearerToken: 'pending-1')).thenThrow(
          const ApiError(type: ApiErrorType.unauthorized, message: 'revoked', statusCode: 401),
        );

        await repository.revokePendingSession();

        expect(storage.pendingLogoutToken, isNull);
      });

      test('revokePendingSession leaves the signed-in session alone', () async {
        storage.pendingLogoutToken = 'pending-1';
        when(() => remote.logout(bearerToken: 'pending-1')).thenAnswer((_) async {});

        await repository.revokePendingSession();

        expect(storage.accessToken, 'access-1');
        expect(storage.refreshToken, 'refresh-1');
      });
    });

    test('verifying the mobile OTP stores the issued session', () async {
      when(
        () => remote.verifyMobileOtp(mobile: '9876543210', otp: '123456'),
      ).thenAnswer((_) async => AuthResponseModel.fromJson(_authJson));

      final result = await repository.verifyMobileOtp(mobile: '9876543210', otp: '123456');

      expect(result.status, AccountStatus.emailVerificationPending);
      expect(storage.accessToken, 'access-1');
      expect(storage.refreshToken, 'refresh-1');
      expect(storage.userId, 'user-1');
    });

    test('signing in stores the issued session and reports the current status', () async {
      storage.accessToken = 'stale';
      when(() => remote.verifyLogin(mobile: '9876543210', otp: '123456')).thenAnswer(
        (_) async => AuthResponseModel.fromJson({
          ..._authJson,
          'status': 'ACTIVE',
          'aadhaarVerified': true,
        }),
      );

      final result = await repository.verifyLogin(mobile: '9876543210', otp: '123456');

      expect(result.status, AccountStatus.active);
      expect(result.aadhaarVerified, isTrue);
      expect(storage.accessToken, 'access-1');
      expect(storage.refreshToken, 'refresh-1');
      expect(storage.userId, 'user-1');
    });

    test('Google sign-in of a linked account stores the issued session', () async {
      when(() => remote.signInWithGoogle('id-token-1')).thenAnswer(
        (_) async => GoogleSignInModel.fromJson({
          'requiresMobileVerification': false,
          'accessToken': 'access-1',
          'refreshToken': 'refresh-1',
          'userId': 'user-1',
          'status': 'ACTIVE',
          'aadhaarVerified': true,
        }),
      );

      final result = await repository.signInWithGoogle('id-token-1');

      expect(result, isA<GoogleSignedIn>());
      expect(storage.accessToken, 'access-1');
      expect(storage.refreshToken, 'refresh-1');
      expect(storage.userId, 'user-1');
    });

    test('Google sign-in of a new account stores nothing until the mobile is verified', () async {
      when(() => remote.signInWithGoogle('id-token-1')).thenAnswer(
        (_) async => GoogleSignInModel.fromJson({
          'requiresMobileVerification': true,
          'socialSessionToken': 'social-1',
          'googleEmail': 'a@gmail.com',
        }),
      );

      final result = await repository.signInWithGoogle('id-token-1');

      expect(result, isA<GoogleNeedsMobile>());
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
    });

    test('requesting the Google mobile OTP leaves the stored session alone', () async {
      when(
        () => remote.initiateGoogleMobile(socialSessionToken: 'social-1', mobile: '9876543210'),
      ).thenAnswer((_) async => const MessageResponseModel(otpExpiresInSeconds: 300));

      final sent = await repository.initiateGoogleMobile(
        socialSessionToken: 'social-1',
        mobile: '9876543210',
      );

      expect(sent.expiresInSeconds, 300);
      expect(storage.accessToken, isNull);
    });

    test('verifying the Google mobile OTP stores the issued session', () async {
      when(
        () => remote.verifyGoogleMobile(
          socialSessionToken: 'social-1',
          mobile: '9876543210',
          otp: '123456',
        ),
      ).thenAnswer((_) async => AuthResponseModel.fromJson({..._authJson, 'status': 'ACTIVE'}));

      final result = await repository.verifyGoogleMobile(
        socialSessionToken: 'social-1',
        mobile: '9876543210',
        otp: '123456',
      );

      expect(result.status, AccountStatus.active);
      expect(storage.refreshToken, 'refresh-1');
      expect(storage.userId, 'user-1');
    });

    test('requesting a sign-in OTP does not touch the stored session', () async {
      when(() => remote.initiateLogin('9876543210')).thenAnswer(
        (_) async => const MessageResponseModel(otpExpiresInSeconds: 300),
      );

      final sent = await repository.initiateLogin('9876543210');

      expect(sent.expiresInSeconds, 300);
      expect(storage.accessToken, isNull);
    });

    test('completing sign up stores the activated session', () async {
      const details = SignupDetails(
        displayName: 'Asha Verma',
        gender: Gender.female,
        avatarId: 'avatar-05',
        termsAccepted: true,
        consentGiven: true,
        termsVersion: 'template-0',
      );
      when(() => remote.completeSignup(details)).thenAnswer(
        (_) async => AuthResponseModel.fromJson({..._authJson, 'status': 'ACTIVE'}),
      );

      final result = await repository.completeSignup(details);

      expect(result.status, AccountStatus.active);
      expect(storage.accessToken, 'access-1');
      expect(storage.userId, 'user-1');
    });

    test('skipping Aadhaar replaces the stored tokens', () async {
      storage.accessToken = 'old';
      storage.refreshToken = 'old-refresh';
      when(() => remote.skipAadhaar()).thenAnswer(
        (_) async => AuthResponseModel.fromJson({..._authJson, 'status': 'SIGNUP_PENDING'}),
      );

      final result = await repository.skipAadhaar();

      expect(result.status, AccountStatus.signupPending);
      expect(storage.accessToken, 'access-1');
    });

    test('verifying Aadhaar stores the session', () async {
      when(() => remote.verifyAadhaar(transactionId: 'txn-1', otp: '123456')).thenAnswer(
        (_) async => AuthResponseModel.fromJson({..._authJson, 'aadhaarVerified': true}),
      );

      final result = await repository.verifyAadhaar(transactionId: 'txn-1', otp: '123456');

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
