import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valuex_mobile/core/constants/storage_keys.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/home/domain/entities/home_location.dart';
import 'package:valuex_mobile/features/home/domain/services/location_service.dart';
import 'package:valuex_mobile/features/notifications/data/notifications_repository.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fonts.dart';

class _MockNotifications extends Mock implements NotificationsRepository {}

void main() {
  setUpAll(loadBrandFonts);

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text).first;
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
  }

  Future<AppHarness> openHome(
    WidgetTester tester, {
    bool aadhaarVerified = true,
    LocationAccess access = LocationAccess.granted,
    LocationAccess afterRequest = LocationAccess.granted,
  }) async {
    final notifications = _MockNotifications();
    when(notifications.unreadCount).thenAnswer((_) async => 3);
    final harness = AppHarness(
      tester,
      extraOverrides: [notificationsRepositoryProvider.overrideWithValue(notifications)],
    );
    harness.signedInAs(AccountStatus.active, aadhaarVerified: aadhaarVerified);
    harness.locationService
      ..state = access
      ..afterRequest = afterRequest;
    await harness.launch(location: RouteNames.home);
    return harness;
  }

  testWidgets('shows the header, promo, categories and featured deals', (tester) async {
    final harness = await openHome(tester);

    expect(find.text('Andheri (East)'), findsOneWidget);
    expect(find.text('Mumbai, Maharashtra'), findsOneWidget);
    expect(find.text('Search here ...'), findsOneWidget);
    expect(find.text('Unlock AI Photo Search'), findsOneWidget);
    expect(find.text('Claim Voucher'), findsOneWidget);
    expect(find.text('Browse'), findsOneWidget);
    expect(find.text('Electronic'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(find.text('Featured Deals Near You'), findsOneWidget);
    expect(find.text('Sony A7 IV Camera'), findsOneWidget);
    expect(find.text('\u20b91,85,000'), findsOneWidget);
    expect(find.text('BOOSTED'), findsWidgets);
    expect(tester.takeException(), isNull);
    await harness.dispose();
  });

  testWidgets('the cart and the bell tell a screen reader their counts', (tester) async {
    final handle = tester.ensureSemantics();
    final harness = await openHome(tester);

    expect(find.bySemanticsLabel('Cart, 2 items'), findsOneWidget);
    expect(find.bySemanticsLabel('Notifications, 3 unread'), findsOneWidget);
    handle.dispose();
    await harness.dispose();
  });

  testWidgets('a listing card is announced as one button with its facts', (tester) async {
    final handle = tester.ensureSemantics();
    final harness = await openHome(tester);

    expect(
      find.bySemanticsLabel(
        'Sony A7 IV Camera, \u20b91,85,000, Delhi, Rated 4.7 out of 5, Good, BOOSTED',
      ),
      findsOneWidget,
    );
    handle.dispose();
    await harness.dispose();
  });

  group('location', () {
    testWidgets('without permission Home explains and offers an address', (tester) async {
      final harness = await openHome(tester, access: LocationAccess.denied);

      expect(find.text('See items near you'), findsOneWidget);
      expect(find.text('Use my location'), findsOneWidget);
      expect(find.text('Enter address'), findsOneWidget);
      expect(find.text('Set your location'), findsOneWidget);
      expect(find.text('Sony A7 IV Camera'), findsNothing);
      await harness.dispose();
    });

    testWidgets('allowing location shows the place and the listings', (tester) async {
      final harness = await openHome(tester, access: LocationAccess.denied);

      await tapText(tester, 'Use my location');
      await harness.settle();

      expect(harness.locationService.requests, 1);
      expect(find.text('Andheri (East)'), findsOneWidget);
      expect(find.text('Sony A7 IV Camera'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('refusing the request says why and keeps the address option', (tester) async {
      final harness = await openHome(
        tester,
        access: LocationAccess.denied,
        afterRequest: LocationAccess.denied,
      );

      await tapText(tester, 'Use my location');
      await harness.settle();

      expect(
        find.text('Location access is off. Enter your address to see items near you'),
        findsOneWidget,
      );
      expect(find.text('Enter address'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a permanent refusal sends the user to the settings', (tester) async {
      final harness = await openHome(tester, access: LocationAccess.deniedForever);

      await tapText(tester, 'Open settings');
      await tester.pump();

      expect(harness.locationService.settingsOpened, 1);
      await harness.dispose();
    });

    testWidgets('an address is checked, saved and used', (tester) async {
      final harness = await openHome(tester, access: LocationAccess.denied);

      await tapText(tester, 'Enter address');
      await harness.settle();
      await tapText(tester, 'Save location');
      await tester.pump();
      expect(find.text('Enter a valid city'), findsOneWidget);
      expect(find.text('Select your state'), findsWidgets);

      await tester.enterText(find.widgetWithText(TextField, 'Your city'), 'Pune');
      await tapText(tester, 'Select your state');
      await harness.settle();
      await tester.scrollUntilVisible(
        find.text('Maharashtra'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Maharashtra'));
      await harness.settle();
      await tapText(tester, 'Save location');
      await harness.settle();

      expect(find.text('Pune, Maharashtra'), findsOneWidget);
      expect(find.text('Sony A7 IV Camera'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(HomeLocation.tryParse(prefs.getString(StorageKeys.homeLocation))?.city, 'Pune');
      await harness.dispose();
    });
  });

  group('navigation', () {
    testWidgets('More opens every category and Back returns to Home', (tester) async {
      final harness = await openHome(tester);

      await tester.tap(find.text('More'));
      await harness.settle();
      expect(find.text('All categories'), findsOneWidget);
      expect(find.text('Furniture'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Back'));
      await harness.settle();
      expect(find.text('Featured Deals Near You'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('Sell without Aadhaar explains what is needed', (tester) async {
      final harness = await openHome(tester, aadhaarVerified: false);

      await tester.tap(find.text('Sell'));
      await tester.pump();

      expect(find.text('Please complete Aadhaar verification to proceed'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a screen that is not built yet says it is coming soon', (tester) async {
      final harness = await openHome(tester);

      await tester.tap(find.text('Chats'));
      await tester.pump();

      expect(find.text('This is coming soon'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a signed-out visitor who taps Sell is sent to create an account', (tester) async {
      final harness = AppHarness(tester);
      await harness.launch(location: RouteNames.home);

      await tester.tap(find.text('Sell'));
      await harness.settle();

      expect(find.text('Create an Account'), findsWidgets);
      await harness.dispose();
    });
  });
}
