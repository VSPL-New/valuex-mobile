import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/routing/app_router.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/home/presentation/home_screen.dart';
import 'package:valuex_mobile/features/listing/presentation/listing_submitted_screen.dart';
import 'package:valuex_mobile/features/notifications/data/notifications_repository.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/app_harness.dart';
import '../../helpers/fonts.dart';

class _MockNotifications extends Mock implements NotificationsRepository {}

void main() {
  setUpAll(loadBrandFonts);

  Future<AppHarness> open(
    WidgetTester tester, {
    Object? extra = 'l1',
    double textScale = 1,
  }) async {
    final notifications = _MockNotifications();
    when(notifications.unreadCount).thenAnswer((_) async => 0);
    final harness = AppHarness(tester, extraOverrides: [
      notificationsRepositoryProvider.overrideWithValue(notifications),
    ])
      ..signedInAs(AccountStatus.active, aadhaarVerified: true);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await harness.launch(location: RouteNames.home);
    tester.view.physicalSize = Size(1080, 1800 * textScale * 3);
    harness.container.read(appRouterProvider).go(RouteNames.sellSubmitted, extra: extra);
    await harness.settle();
    return harness;
  }

  group('listing submitted page', () {
    testWidgets('says the listing is submitted and under review, and shows both buttons',
        (tester) async {
      final harness = await open(tester);

      expect(find.byType(ListingSubmittedScreen), findsOneWidget);
      expect(find.text('Your listing is submitted'), findsOneWidget);
      expect(find.textContaining('under Trust & Safety compliance review'), findsOneWidget);
      expect(find.textContaining('goes live automatically if it is compliant'), findsOneWidget);
      expect(find.text('Preview your listing'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('never promises a notification until the notifications exist', (tester) async {
      final harness = await open(tester);

      expect(find.textContaining('notify'), findsNothing);
      expect(find.textContaining('is live'), findsNothing);
      expect(find.textContaining('published'), findsNothing);
      await harness.dispose();
    });

    testWidgets('Preview your listing says the preview is coming soon and stays on the page',
        (tester) async {
      final harness = await open(tester);

      await tester.tap(find.text('Preview your listing'));
      await harness.settle();

      expect(find.text('Preview is coming soon'), findsOneWidget);
      expect(find.byType(ListingSubmittedScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('Back to Home leaves the page for Home', (tester) async {
      final harness = await open(tester);

      await tester.tap(find.text('Back to Home'));
      await harness.settle();

      expect(find.byType(ListingSubmittedScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('the system back button goes Home instead of leaving the app', (tester) async {
      final harness = await open(tester);

      await tester.binding.handlePopRoute();
      await harness.settle();

      expect(find.byType(ListingSubmittedScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('opening the page without a listing id goes back to the first sell step',
        (tester) async {
      final harness = await open(tester, extra: 42);

      expect(find.byType(ListingSubmittedScreen), findsNothing);
      await harness.dispose();
    });

    testWidgets('shows the page in Hindi', (tester) async {
      tester.platformDispatcher.localesTestValue = [const Locale('hi')];
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final harness = await open(tester);

      expect(find.text('आपकी लिस्टिंग जमा हो गई है'), findsOneWidget);
      expect(find.text('अपनी लिस्टिंग का पूर्वावलोकन देखें'), findsOneWidget);
      expect(find.text('होम पर वापस जाएँ'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('meets the tap target, label and contrast guidelines', (tester) async {
      final semantics = tester.ensureSemantics();
      final harness = await open(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrast));
      semantics.dispose();
      await harness.dispose();
    });

    testWidgets('lays out without overflow at 2x text size', (tester) async {
      final harness = await open(tester, textScale: 2);

      expect(tester.takeException(), isNull);
      expect(find.text('Preview your listing'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
      await harness.dispose();
    });
  });
}
