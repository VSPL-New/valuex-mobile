import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valuex_mobile/core/constants/storage_keys.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/address/domain/saved_address.dart';
import 'package:valuex_mobile/features/address/presentation/providers/address_providers.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/home/domain/entities/home_location.dart';
import 'package:valuex_mobile/features/listing/presentation/create_listing_screen.dart';
import 'package:valuex_mobile/features/home/domain/services/location_service.dart';
import 'package:valuex_mobile/features/notifications/data/notifications_repository.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fonts.dart';

class _MockNotifications extends Mock implements NotificationsRepository {}

const _home = SavedAddress(
  id: 'a-1',
  label: 'Home',
  address: '12 FC Road, Shivajinagar',
  landmark: 'Flat 4',
  city: 'Pune',
  state: 'Maharashtra',
  pincode: '411014',
  isDefault: true,
);

const _office = SavedAddress(
  id: 'a-2',
  label: 'Office',
  address: 'Cyber Park, Hinjewadi',
  city: 'Pune',
  state: 'Maharashtra',
  pincode: '411057',
);

void main() {
  setUpAll(loadBrandFonts);

  Finder inDialog(String text) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text).first;
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
  }

  /// Tapping a button lower on the page scrolls the header out of the list, where it is not built.
  Future<void> showHeaderThenListing(WidgetTester tester, AppHarness harness) async {
    final page = find.byType(Scrollable).first;
    tester.state<ScrollableState>(page).position.jumpTo(0);
    await harness.settle();
  }

  Future<void> scrollToListing(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Sony A7 IV Camera'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }

  Future<AppHarness> openHome(
    WidgetTester tester, {
    bool aadhaarVerified = true,
    LocationAccess access = LocationAccess.granted,
    LocationAccess afterRequest = LocationAccess.granted,
    List<SavedAddress> saved = const [],
    Future<List<SavedAddress>> Function()? savedLoader,
  }) async {
    final notifications = _MockNotifications();
    when(notifications.unreadCount).thenAnswer((_) async => 3);
    final harness = AppHarness(
      tester,
      extraOverrides: [
        notificationsRepositoryProvider.overrideWithValue(notifications),
        savedAddressesProvider.overrideWith((ref) => (savedLoader ?? () async => saved)()),
      ],
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
    testWidgets('without permission Home explains and offers the current or a saved location', (
      tester,
    ) async {
      final harness = await openHome(tester, access: LocationAccess.denied);

      expect(find.text('See items near you'), findsOneWidget);
      expect(find.text('Use my current location'), findsOneWidget);
      expect(find.text('Use my saved location'), findsOneWidget);
      expect(find.text('Enter address'), findsNothing);
      expect(find.text('Set your location'), findsOneWidget);
      expect(find.text('Sony A7 IV Camera'), findsNothing);
      await harness.dispose();
    });

    testWidgets('allowing location shows the place and the listings', (tester) async {
      final harness = await openHome(tester, access: LocationAccess.denied);

      await tapText(tester, 'Use my current location');
      await harness.settle();

      expect(harness.locationService.requests, 1);
      await showHeaderThenListing(tester, harness);
      expect(find.text('Andheri (East)'), findsOneWidget);
      await scrollToListing(tester);
      expect(find.text('Sony A7 IV Camera'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('refusing the request says why and keeps the saved location option', (
      tester,
    ) async {
      final harness = await openHome(
        tester,
        access: LocationAccess.denied,
        afterRequest: LocationAccess.denied,
      );

      await tapText(tester, 'Use my current location');
      await harness.settle();

      expect(
        find.text('Location access is off. Use a saved location to see items near you'),
        findsOneWidget,
      );
      expect(find.text('Use my saved location'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a permanent refusal sends the user to the settings', (tester) async {
      final harness = await openHome(tester, access: LocationAccess.deniedForever);

      await tapText(tester, 'Open settings');
      await tester.pump();

      expect(harness.locationService.settingsOpened, 1);
      await harness.dispose();
    });

    testWidgets('a saved location is chosen from a pop-up that shows the name and full address', (
      tester,
    ) async {
      final harness = await openHome(
        tester,
        access: LocationAccess.denied,
        saved: [_home, _office],
      );

      await tapText(tester, 'Use my saved location');
      await harness.settle();

      expect(find.text('Choose a saved location'), findsOneWidget);
      expect(inDialog('Home'), findsOneWidget);
      expect(
          find.text('Flat 4, 12 FC Road, Shivajinagar, Pune, Maharashtra 411014'), findsOneWidget);
      expect(find.text('Office'), findsOneWidget);
      expect(find.text('Cyber Park, Hinjewadi, Pune, Maharashtra 411057'), findsOneWidget);
      expect(find.byType(Radio<String>), findsNWidgets(2));

      await tester.tap(find.text('Office'));
      await harness.settle();
      expect(find.text('Choose a saved location'), findsOneWidget, reason: 'picking only selects');
      await tester.tap(find.text('Use this address'));
      await harness.settle();

      expect(find.text('Choose a saved location'), findsNothing);
      await showHeaderThenListing(tester, harness);
      expect(find.text('Pune, Maharashtra'), findsOneWidget);
      await scrollToListing(tester);
      expect(find.text('Sony A7 IV Camera'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      final kept = HomeLocation.tryParse(prefs.getString(StorageKeys.homeLocation));
      expect(kept?.city, 'Pune');
      expect(kept?.pincode, '411057');
      await harness.dispose();
    });

    testWidgets('the header opens a sheet with only the two choices and no address entry', (
      tester,
    ) async {
      final harness = await openHome(tester, saved: [_home]);

      await tester.tap(find.text('Andheri (East)'));
      await harness.settle();

      expect(find.text('Choose your location'), findsOneWidget);
      expect(find.text('Use my current location'), findsOneWidget);
      expect(find.text('Use my saved location'), findsOneWidget);
      expect(find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)),
          findsNothing);

      await tester.tap(find.text('Use my saved location'));
      await harness.settle();
      expect(find.text('Choose a saved location'), findsOneWidget);
      await tester.tap(inDialog('Home'));
      await harness.settle();
      await tester.tap(find.text('Use this address'));
      await harness.settle();

      expect(find.text('Pune, Maharashtra'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('with no saved address the pop-up says one is saved when the user buys or sells', (
      tester,
    ) async {
      final harness = await openHome(tester, access: LocationAccess.denied);

      await tapText(tester, 'Use my saved location');
      await harness.settle();

      expect(
        find.text(
            'You have no saved locations yet. An address is saved when you buy or sell an item.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await harness.settle();
      expect(find.text('Choose a saved location'), findsNothing);
      await harness.dispose();
    });

    testWidgets('a failed load of the saved addresses can be retried', (tester) async {
      var calls = 0;
      final harness = await openHome(
        tester,
        access: LocationAccess.denied,
        savedLoader: () async {
          calls++;
          if (calls == 1) throw Exception('offline');
          return [_home];
        },
      );

      await tapText(tester, 'Use my saved location');
      await harness.settle();
      expect(find.text('Unable to load your saved locations. Try again'), findsOneWidget);

      await tester.tap(inDialog('Retry'));
      await harness.settle();

      expect(inDialog('Home'), findsOneWidget);
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

    testWidgets('Sell is not blocked for a user who skipped Aadhaar', (tester) async {
      final harness = await openHome(tester, aadhaarVerified: false);

      await tester.tap(find.text('Sell'));
      await harness.settle();

      expect(find.text('Please complete Aadhaar verification to proceed'), findsNothing);
      expect(find.byType(CreateListingScreen), findsOneWidget);
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
