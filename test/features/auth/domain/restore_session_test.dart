import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/user_profile.dart';
import 'package:valuex_mobile/features/auth/domain/usecases/restore_session.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository repository;
  late RestoreSession restoreSession;

  const profile = UserProfile(
    userId: 'user-1',
    status: AccountStatus.signupPending,
    aadhaarVerified: false,
  );

  setUp(() {
    repository = MockAuthRepository();
    restoreSession = RestoreSession(repository);
    when(() => repository.clearSession()).thenAnswer((_) async {});
  });

  test('returns null without calling the server when nobody is signed in',
      () async {
    when(() => repository.hasSession()).thenAnswer((_) async => false);

    expect(await restoreSession(), isNull);
    verifyNever(() => repository.fetchProfile());
  });

  test('returns the server profile when a session is stored', () async {
    when(() => repository.hasSession()).thenAnswer((_) async => true);
    when(() => repository.fetchProfile()).thenAnswer((_) async => profile);

    expect((await restoreSession())?.status, AccountStatus.signupPending);
  });

  test('an expired session is cleared and treated as signed out', () async {
    when(() => repository.hasSession()).thenAnswer((_) async => true);
    when(() => repository.fetchProfile())
        .thenThrow(const ApiError.sessionExpired());

    expect(await restoreSession(), isNull);
    verify(() => repository.clearSession()).called(1);
  });

  test('a deleted user is cleared and treated as signed out', () async {
    when(() => repository.hasSession()).thenAnswer((_) async => true);
    when(() => repository.fetchProfile()).thenThrow(
      const ApiError(
        type: ApiErrorType.business,
        message: 'not found',
        code: 'ERROR_USER_NOT_FOUND',
        statusCode: 400,
      ),
    );

    expect(await restoreSession(), isNull);
    verify(() => repository.clearSession()).called(1);
  });

  test('a network failure is rethrown and the session is kept', () async {
    when(() => repository.hasSession()).thenAnswer((_) async => true);
    when(() => repository.fetchProfile()).thenThrow(
      const ApiError(type: ApiErrorType.network, message: 'offline'),
    );

    await expectLater(restoreSession(), throwsA(isA<ApiError>()));
    verifyNever(() => repository.clearSession());
  });
}
