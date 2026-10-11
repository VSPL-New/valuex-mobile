import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/app.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/session_event.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:valuex_mobile/features/splash/presentation/splash_screen.dart';

import 'helpers/mocks.dart';

void main() {
  testWidgets('ValueXApp builds and shows the splash screen', (tester) async {
    final repository = MockAuthRepository();
    final apiClient = MockApiClient();
    when(() => apiClient.sessionEvents).thenAnswer((_) => const Stream<SessionEvent>.empty());
    when(() => repository.hasSession()).thenAnswer((_) async => false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.parse(
              env: 'dev',
              apiBaseUrl: 'http://localhost:8080/api/v1',
              aadhaarFlow: 'sandbox',
            ),
          ),
          authRepositoryProvider.overrideWithValue(repository),
          apiClientProvider.overrideWithValue(apiClient),
        ],
        child: const ValueXApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);

    // Let the splash timer finish so no timer is left pending.
    await tester.pump(const Duration(seconds: 3));
  });
}
