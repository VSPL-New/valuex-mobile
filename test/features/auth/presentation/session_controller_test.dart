import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:valuex_mobile/features/auth/domain/entities/user_profile.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_controller.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_state.dart';

import '../../../helpers/mocks.dart';

UserProfile _profile(AccountStatus status, {bool aadhaarVerified = false}) {
  return UserProfile(userId: 'user-1', status: status, aadhaarVerified: aadhaarVerified);
}

void main() {
  late MockAuthRepository repository;
  late MockApiClient apiClient;
  late StreamController<void> sessionExpired;
  late ProviderContainer container;

  setUp(() {
    repository = MockAuthRepository();
    apiClient = MockApiClient();
    sessionExpired = StreamController<void>.broadcast();
    when(() => apiClient.onSessionExpired).thenAnswer((_) => sessionExpired.stream);
    when(() => repository.clearSession()).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        apiClientProvider.overrideWithValue(apiClient),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(sessionExpired.close);
  });

  Future<SessionState> resolve() => container.read(sessionControllerProvider.future);

  test('signed out when no session is stored', () async {
    when(() => repository.hasSession()).thenAnswer((_) async => false);

    final state = await resolve();

    expect(state, isA<Unauthenticated>());
    expect((state as Unauthenticated).sessionExpired, isFalse);
  });

  test('takes the status from the server profile', () async {
    when(() => repository.hasSession()).thenAnswer((_) async => true);
    when(() => repository.fetchProfile()).thenAnswer(
      (_) async => _profile(AccountStatus.identityVerificationPending),
    );

    final state = await resolve() as Authenticated;

    expect(state.status, AccountStatus.identityVerificationPending);
  });

  test('a network failure surfaces as an error without automatic retries', () async {
    when(() => repository.hasSession()).thenAnswer((_) async => true);
    when(() => repository.fetchProfile()).thenThrow(
      const ApiError(type: ApiErrorType.network, message: 'offline'),
    );

    await expectLater(resolve(), throwsA(isA<ApiError>()));
    verify(() => repository.fetchProfile()).called(1);
  });

  test('the session ending later signs the user out with a notice', () async {
    when(() => repository.hasSession()).thenAnswer((_) async => true);
    when(() => repository.fetchProfile()).thenAnswer((_) async => _profile(AccountStatus.active));
    await resolve();

    sessionExpired.add(null);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(sessionControllerProvider).value as Unauthenticated;
    expect(state.sessionExpired, isTrue);
  });

  test('signedIn publishes the status issued with the tokens', () async {
    when(() => repository.hasSession()).thenAnswer((_) async => false);
    await resolve();

    container.read(sessionControllerProvider.notifier).signedIn(
          const AuthResult(
            session: AuthSession(accessToken: 'a', refreshToken: 'r', userId: 'user-1'),
            status: AccountStatus.emailVerificationPending,
            aadhaarVerified: false,
          ),
        );

    final state = container.read(sessionControllerProvider).value as Authenticated;
    expect(state.status, AccountStatus.emailVerificationPending);
  });

  test('refreshStatus re-reads the server status', () async {
    when(() => repository.hasSession()).thenAnswer((_) async => true);
    var status = AccountStatus.emailVerificationPending;
    when(() => repository.fetchProfile()).thenAnswer((_) async => _profile(status));
    await resolve();

    status = AccountStatus.identityVerificationPending;
    await container.read(sessionControllerProvider.notifier).refreshStatus();

    final state = container.read(sessionControllerProvider).value as Authenticated;
    expect(state.status, AccountStatus.identityVerificationPending);
  });

  test('signOutLocally clears the stored session', () async {
    when(() => repository.hasSession()).thenAnswer((_) async => true);
    when(() => repository.fetchProfile()).thenAnswer((_) async => _profile(AccountStatus.banned));
    await resolve();

    await container.read(sessionControllerProvider.notifier).signOutLocally();

    verify(() => repository.clearSession()).called(1);
    expect(container.read(sessionControllerProvider).value, isA<Unauthenticated>());
  });
}
