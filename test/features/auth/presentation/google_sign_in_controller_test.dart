import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:valuex_mobile/features/auth/domain/entities/google_sign_in_result.dart';
import 'package:valuex_mobile/features/auth/domain/services/google_id_token_source.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/google_sign_in_controller.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/registration_flow.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_controller.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_state.dart';

import '../../../helpers/mocks.dart';

class _FakeTokenSource implements GoogleIdTokenSource {
  String? token = 'native-token';
  Object? failure;
  int calls = 0;

  @override
  Future<String?> idToken() async {
    calls++;
    if (failure != null) throw failure!;
    return token;
  }
}

void main() {
  late MockAuthRepository repository;
  late _FakeTokenSource tokenSource;
  late ProviderContainer container;

  setUp(() {
    repository = MockAuthRepository();
    tokenSource = _FakeTokenSource();
    final apiClient = MockApiClient();
    when(() => apiClient.onSessionExpired).thenAnswer((_) => const Stream<void>.empty());
    when(() => repository.hasSession()).thenAnswer((_) async => false);
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        googleIdTokenSourceProvider.overrideWithValue(tokenSource),
        apiClientProvider.overrideWithValue(apiClient),
      ],
    );
    addTearDown(container.dispose);
  });

  GoogleSignInController controller() => container.read(googleSignInControllerProvider.notifier);

  test('the token from the Google account chooser is sent to the server', () async {
    when(() => repository.signInWithGoogle('native-token')).thenAnswer(
      (_) async => const GoogleNeedsMobile(socialSessionToken: 'social-1', email: 'a@gmail.com'),
    );

    final outcome = await controller().signIn();

    expect(outcome, GoogleSignInOutcome.needsMobile);
    final flow = container.read(registrationFlowProvider);
    expect(flow.socialSessionToken, 'social-1');
    expect(flow.googleEmail, 'a@gmail.com');
  });

  test('a mock token skips the Google account chooser', () async {
    when(() => repository.signInWithGoogle('mock-alice')).thenAnswer(
      (_) async => const GoogleNeedsMobile(socialSessionToken: 'social-1', email: 'a@gmail.com'),
    );

    await controller().signIn(mockIdToken: 'mock-alice');

    expect(tokenSource.calls, 0);
  });

  test('closing the chooser is not an error and sends nothing', () async {
    tokenSource.token = null;

    final outcome = await controller().signIn();

    expect(outcome, GoogleSignInOutcome.cancelled);
    expect(container.read(googleSignInControllerProvider).hasError, isFalse);
    verifyNever(() => repository.signInWithGoogle(any()));
  });

  test('a linked account signs the user in with the returned status', () async {
    when(() => repository.signInWithGoogle(any())).thenAnswer(
      (_) async => const GoogleSignedIn(
        AuthResult(
          session: AuthSession(accessToken: 'a', refreshToken: 'r', userId: 'user-1'),
          status: AccountStatus.active,
          aadhaarVerified: true,
        ),
      ),
    );
    await container.read(sessionControllerProvider.future);

    final outcome = await controller().signIn();

    expect(outcome, GoogleSignInOutcome.signedIn);
    final session = container.read(sessionControllerProvider).value as Authenticated;
    expect(session.status, AccountStatus.active);
  });

  test('Google being unavailable on the device is reported as an error', () async {
    tokenSource.failure = const GoogleSignInUnavailable();

    final outcome = await controller().signIn();

    expect(outcome, isNull);
    expect(container.read(googleSignInControllerProvider).error, isA<GoogleSignInUnavailable>());
    verifyNever(() => repository.signInWithGoogle(any()));
  });

  test('a server error is kept as the state and cleared on request', () async {
    when(() => repository.signInWithGoogle(any())).thenThrow(
      const ApiError(
        type: ApiErrorType.business,
        message: 'x',
        code: 'ERROR_INVALID_GOOGLE_TOKEN',
        statusCode: 400,
      ),
    );

    final outcome = await controller().signIn();

    expect(outcome, isNull);
    expect((container.read(googleSignInControllerProvider).error as ApiError).code,
        'ERROR_INVALID_GOOGLE_TOKEN');

    controller().clearError();
    expect(container.read(googleSignInControllerProvider).hasError, isFalse);
  });
}
