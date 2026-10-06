import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/security/secure_storage_service.dart';

/// In-memory stand-in for the platform keystore.
class FakeSecureStorage extends Fake implements SecureStorageService {
  String? accessToken;
  String? refreshToken;
  String? userId;

  FakeSecureStorage({this.accessToken, this.refreshToken});

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> saveAccessToken(String token) async => accessToken = token;

  @override
  Future<void> saveRefreshToken(String token) async => refreshToken = token;

  @override
  Future<void> deleteAccessToken() async => accessToken = null;

  @override
  Future<void> deleteRefreshToken() async => refreshToken = null;

  @override
  Future<void> clearSession() async {
    accessToken = null;
    refreshToken = null;
    userId = null;
  }

  @override
  Future<String?> getUserId() async => userId;

  @override
  Future<void> saveUserId(String userId) async => this.userId = userId;
}
