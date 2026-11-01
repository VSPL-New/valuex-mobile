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
    Size size = const Size(390, 844),
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
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
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
      expect(find.text('Under Trust & Safety review'), findsOneWidget);
      expect(find.text('This may take a few minutes.'), findsOneWidget);
      expect(find.text('Approved? You are live.'), findsOneWidget);
      expect(find.text('We publish your listing automatically.'), findsOneWidget);
      expect(find.text('Anything needed from you?'), findsOneWidget);
      expect(find.text('We will notify you if any action is required.'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
      expect(find.byIcon(Icons.verified_user_outlined), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.text('Preview your listing'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('promises a notification only for what needs action, not that it is live',
        (tester) async {
      final harness = await open(tester);

      expect(find.textContaining('notify you if any action is required'), findsOneWidget);
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
      expect(find.text('ट्रस्ट एंड सेफ्टी समीक्षा जारी है'), findsOneWidget);
      expect(find.text('इसमें कुछ मिनट लग सकते हैं।'), findsOneWidget);
      expect(find.text('मंज़ूरी मिलते ही लाइव।'), findsOneWidget);
      expect(find.text('आपकी लिस्टिंग अपने आप प्रकाशित हो जाएगी।'), findsOneWidget);
      expect(find.text('आपसे कोई कार्रवाई चाहिए?'), findsOneWidget);
      expect(
          find.text('आपसे किसी कार्रवाई की ज़रूरत होने पर हम आपको सूचित करेंगे।'), findsOneWidget);
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

    for (final language in ['en', 'hi']) {
      testWidgets('scrolls without overflow on a narrow phone at 2x text size in $language',
          (tester) async {
        tester.platformDispatcher.localesTestValue = [Locale(language)];
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final harness = await open(tester, textScale: 2, size: const Size(320, 640));

        expect(tester.takeException(), isNull);
        final preview = find
            .text(language == 'en' ? 'Preview your listing' : 'अपनी लिस्टिंग का पूर्वावलोकन देखें');
        await tester.ensureVisible(preview);
        await harness.settle();
        await tester.tap(preview);
        await harness.settle();
        expect(find.text(language == 'en' ? 'Preview is coming soon' : 'पूर्वावलोकन जल्द आ रहा है'),
            findsOneWidget);
        expect(tester.takeException(), isNull);
        await harness.dispose();
      });
    }
  });
}
