import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/app.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/session_event.dart';
import 'package:valuex_mobile/core/routing/app_router.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/core/security/screen_protection_service.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:valuex_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:valuex_mobile/features/listing/data/listing_repository.dart';
import 'package:valuex_mobile/features/listing/domain/listing_preview.dart';
import 'package:valuex_mobile/features/listing/presentation/listing_preview_screen.dart';
import 'package:valuex_mobile/features/listing/presentation/listing_submitted_screen.dart';
import 'package:valuex_mobile/features/notifications/data/notifications_repository.dart';

import '../test/helpers/app_harness.dart' show FakeScreenProtection;
import '../test/helpers/fake_auth_repository.dart';
import '../test/helpers/mocks.dart';

class _MockListings extends Mock implements ListingRepository {}

class _MockNotifications extends Mock implements NotificationsRepository {}

class _FakeLocation extends HomeLocationController {
  @override
  Future<HomeLocationState> build() async => const LocationNeeded(LocationNeed.notAsked);
}

/// A seller who has just submitted a listing opens its preview, reads both tabs, finds the buyer
/// actions switched off, and comes back, through the real screens and router with in-memory data.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.parse(
    env: 'dev',
    apiBaseUrl: 'http://localhost:8080/api/v1',
    aadhaarFlow: 'sandbox',
  );

  const listing = {
    'listingId': 'l1',
    'status': 'TRUST_SAFETY_REVIEW',
    'images': [],
    'title': 'Apple Watch',
    'category': {
      'code': 'CAT-1',
      'name': 'Smartwatches',
      'path': [
        {'code': 'L1', 'name': 'Electronics', 'level': 1},
        {'code': 'CAT-1', 'name': 'Smartwatches', 'level': 3},
      ],
    },
    'condition': 'LIKE_NEW',
    'conditionNotes': 'No scratches',
    'description': 'Lightly used, with the original box.',
    'price': 14500,
    'negotiable': true,
    'quantity': 1,
    'attributes': {'brand': 'Apple', 'has_box': false},
    'location': 'Bengaluru',
    'listingSchema': {
      'category': {'code': 'CAT-1', 'name': 'Smartwatches', 'path': []},
      'profileCode': 'WATCH',
      'group': 'GOODS',
      'common': {
        'conditionVisible': true,
        'quantityVisible': true,
        'negotiableVisible': true,
        'priceDerived': false,
      },
      'transactionIntents': [],
      'fields': [
        {'key': 'brand', 'label': 'Brand', 'type': 'TEXT', 'required': true, 'section': 'CATEGORY'},
        {'key': 'has_box', 'label': 'Original box', 'type': 'BOOLEAN', 'section': 'CATEGORY'},
      ],
    },
  };

  testWidgets('submitted page to preview and back', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final server = FakeAuthRepository(status: AccountStatus.active)..aadhaarVerified = true;
    final apiClient = MockApiClient();
    when(() => apiClient.sessionEvents).thenAnswer((_) => const Stream<SessionEvent>.empty());
    final listings = _MockListings();
    when(() => listings.getListingPreview('l1'))
        .thenAnswer((_) async => ListingPreviewData.fromJson(listing));
    final notifications = _MockNotifications();
    when(notifications.unreadCount).thenAnswer((_) async => 0);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          authRepositoryProvider.overrideWithValue(server),
          apiClientProvider.overrideWithValue(apiClient),
          screenProtectionServiceProvider.overrideWithValue(FakeScreenProtection()),
          listingRepositoryProvider.overrideWithValue(listings),
          notificationsRepositoryProvider.overrideWithValue(notifications),
          homeLocationControllerProvider.overrideWith(_FakeLocation.new),
        ],
        child: const ValueXApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2300));
    await _settle(tester);

    final container = ProviderScope.containerOf(tester.element(find.byType(ValueXApp)));
    container.read(appRouterProvider).go(RouteNames.sellSubmitted, extra: 'l1');
    await _settle(tester);
    expect(find.byType(ListingSubmittedScreen), findsOneWidget);

    await tester.tap(find.text('Preview your listing'));
    await _settle(tester);
    expect(find.byType(ListingPreviewScreen), findsOneWidget);
    expect(find.text('Apple Watch'), findsOneWidget);
    expect(find.text('Under review'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);

    await tester.ensureVisible(find.text('Details'));
    await tester.tap(find.text('Details'));
    await _settle(tester);
    expect(find.text('Original box'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);

    await tester.tap(find.text('Buy Now'), warnIfMissed: false);
    await _settle(tester);
    expect(find.byType(ListingPreviewScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.byType(ListingSubmittedScreen), findsOneWidget);
    verify(() => listings.getListingPreview('l1')).called(1);
  });
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
}
