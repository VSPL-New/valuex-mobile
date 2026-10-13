import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/constants/storage_keys.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/route_guard.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/core/storage/preferences_service.dart';
import 'package:valuex_mobile/core/widgets/loading_indicator.dart';
import 'package:valuex_mobile/features/auth/data/models/auth_models.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/logout_outcome.dart';
import 'package:valuex_mobile/features/auth/domain/entities/user_profile.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_state.dart';
import 'package:valuex_mobile/features/auth/presentation/widgets/avatar_image.dart';
import 'package:valuex_mobile/features/profile/data/mock_profile_summary.dart';
import 'package:valuex_mobile/features/profile/data/profile_repository.dart';
import 'package:valuex_mobile/features/profile/domain/profile_menu_badges.dart';
import 'package:valuex_mobile/features/profile/domain/profile_summary.dart';
import 'package:valuex_mobile/features/profile/presentation/profile_details_screen.dart';
import 'package:valuex_mobile/features/profile/presentation/profile_screen.dart';
import 'package:valuex_mobile/features/profile/presentation/widgets/profile_menu_section.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_secure_storage.dart';
import '../../helpers/fonts.dart';
import '../../helpers/accessibility.dart';

const _json = {
  'userId': 'user-1',
  'status': 'ACTIVE',
  'aadhaarVerified': true,
  'displayName': 'Abhay Kumar',
  'city': 'Pune',
  'mobile': '90XXXX0010',
  'email': 'a***@gmail.com',
  'avatarId': 'avatar-02',
  'aadhaarName': 'Verified Person',
  'memberSince': '2026-08-07T12:00:00Z',
  'gender': 'MALE',
  'dateOfBirth': '1990-01-02',
  'state': 'Maharashtra',
  'address': 'Example Road 123',
  'pincode': '411001',
};

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  setUpAll(loadBrandFonts);

  group('repository', () {
    late FakeHttpAdapter adapter;
    late ProfileRepository repository;
    late FakeSecureStorage storage;

    setUp(() {
      adapter = FakeHttpAdapter((request) async => switch (request.path) {
            '/avatars' => FakeHttpAdapter.ok({
                'avatarIds': ['avatar-02'],
                'defaultAvatarId': 'avatar-02'
              }),
            '/users/me/menu-summary' => FakeHttpAdapter.ok({
                'avatarId': 'avatar-02',
                'aadhaarVerified': true,
                'memberSince': '2026-08-07T12:00:00Z',
                'badges': {'MY_ORDERS': 3, 'OFFERS': 0, 'SAVED_ITEMS': 'x'},
              }),
            _ => FakeHttpAdapter.ok(_json),
          });
      storage = FakeSecureStorage(accessToken: 'access', refreshToken: 'refresh');
      final client = ApiClient(
        storage,
        AppConfig.parse(env: 'dev', apiBaseUrl: 'http://localhost/api/v1', aadhaarFlow: 'sandbox'),
        adapter: adapter,
      );
      addTearDown(client.dispose);
      repository = ProfileRepository(client);
    });

    test('fetch preserves masked contacts, verified identity and joined date', () async {
      final profile = await repository.fetch();
      expect(profile.mobile, '90XXXX0010');
      expect(profile.aadhaarName, 'Verified Person');
      expect(profile.memberSince, DateTime.utc(2026, 8, 7, 12));
      expect(profile.dateOfBirth, '1990-01-02');
      expect(profile.address, 'Example Road 123');
      expect(profile.state, 'Maharashtra');
      expect(profile.pincode, '411001');
    });

    test('PATCH sends only changed fields and leaves tokens untouched', () async {
      await repository.update(displayName: 'New Name');
      final request = adapter.requests.single;
      expect(request.method, 'PATCH');
      expect(request.path, '/users/me');
      expect(request.data, {'displayName': 'New Name'});
      expect(request.headers['Authorization'], 'Bearer access');
      expect(storage.accessToken, 'access');
      expect(storage.refreshToken, 'refresh');
    });

    test('city-only update does not include identity or name', () async {
      await repository.update(city: 'Mumbai');
      expect(adapter.requests.single.data, {'city': 'Mumbai'});
    });

    test('catalog comes from backend and avatar uses PUT', () async {
      final catalog = await repository.avatars();
      expect(catalog.ids, ['avatar-02']);
      await repository.selectAvatar('avatar-02');
      expect(adapter.requests.last.method, 'PUT');
      expect(adapter.requests.last.path, '/users/me/avatar');
      expect(adapter.requests.last.data, {'avatarId': 'avatar-02'});
    });

    test('menu badges come from GET /users/me/menu-summary and keep only positive counts',
        () async {
      final badges = await repository.menuBadges();
      expect(adapter.requests.single.path, '/users/me/menu-summary');
      expect(badges.count(ProfileMenuKeys.myOrders), 3);
      expect(badges.count('OFFERS'), 0);
      expect(badges.count('SAVED_ITEMS'), 0);
      expect(badges.count(ProfileMenuKeys.notifications), 0);
    });

    test('an empty or missing badges map means no badges', () {
      expect(const ProfileMenuBadges().count(ProfileMenuKeys.myOrders), 0);
    });

    test('missing optional profile fields remain null', () {
      final profile = UserProfileModel.fromJson({'userId': 'x', 'status': 'ACTIVE'}).toEntity();
      expect(profile.aadhaarName, isNull);
      expect(profile.memberSince, isNull);
      expect(profile.gender, isNull);
    });
  });

  test('profile is unavailable to guests and blocked accounts', () {
    expect(
      redirectFor(session: const AsyncData(Unauthenticated()), location: RouteNames.profile),
      RouteNames.signIn,
    );
    expect(
      redirectFor(
        session:
            const AsyncData(Authenticated(status: AccountStatus.suspended, aadhaarVerified: true)),
        location: RouteNames.profile,
      ),
      RouteNames.accountBlocked,
    );
    expect(
      redirectFor(session: const AsyncData(Unauthenticated()), location: RouteNames.profileDetails),
      RouteNames.signIn,
    );
  });

  group('screen', () {
    late AppHarness harness;
    late _MockProfileRepository repository;
    late UserProfile profile;

    Future<void> launch(
      WidgetTester tester, {
      bool premium = false,
      ProfileMenuBadges badges = const ProfileMenuBadges(),
    }) async {
      profile = UserProfileModel.fromJson(_json).toEntity();
      repository = _MockProfileRepository();
      when(() => repository.fetch()).thenAnswer((_) async => profile);
      when(() => repository.menuBadges()).thenAnswer((_) async => badges);
      harness = AppHarness(
        tester,
        extraOverrides: [
          profileRepositoryProvider.overrideWithValue(repository),
          if (premium)
            profileSummaryProvider.overrideWithValue(const ProfileSummary(
              rating: 4.8,
              transactions: 32,
              listings: 8,
              sold: 24,
              isPremium: true,
              planName: 'Vision Plan',
            )),
        ],
      )..signedInAs(AccountStatus.active);
      await harness.launch();
    }

    Future<void> showProfile(WidgetTester tester) async {
      await launch(tester);
      await tester.tap(find.text('Profile'));
      await harness.settle();
      expect(find.byType(ProfileScreen), findsOneWidget);
    }

    Future<void> showDetails(WidgetTester tester) async {
      await showProfile(tester);
      await tester.tap(find.byTooltip('Edit profile'));
      await harness.settle();
      expect(find.byType(ProfileDetailsScreen), findsOneWidget);
    }

    testWidgets('Profile tab shows the header and every menu section', (tester) async {
      await showProfile(tester);
      expect(find.text('Abhay Kumar'), findsOneWidget);
      expect(find.text('90XXXX0010'), findsOneWidget);
      expect(find.text('Pune'), findsOneWidget);
      expect(find.text('32 transactions'), findsOneWidget);
      expect(find.text('4.8'), findsNWidgets(2));
      for (final label in ['Listings', 'Sold', 'Reviews']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Upgrade to Premium \u2192'), findsOneWidget);
      expect(find.bySemanticsLabel('Verified'), findsOneWidget);
      for (final text in [
        'Buying',
        'Selling',
        'Account',
        'My Orders',
        'Incoming Orders',
        'Payout Details'
      ]) {
        expect(find.text(text), findsOneWidget);
      }
      await tester.scrollUntilVisible(find.text('Sign Out'), 200);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.textContaining('v0.1.0 · ValueQuo Solutions'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('menu rows show the counts from the menu summary', (tester) async {
      final semantics = tester.ensureSemantics();
      await launch(
        tester,
        badges: const ProfileMenuBadges({
          ProfileMenuKeys.myOrders: 3,
          ProfileMenuKeys.incomingOrders: 120,
        }),
      );
      await tester.tap(find.text('Profile'));
      await harness.settle();
      expect(find.text('3'), findsOneWidget);
      expect(find.text('99+'), findsOneWidget);
      expect(find.bySemanticsLabel('My Orders, 3 new'), findsOneWidget);
      expect(find.bySemanticsLabel('Incoming Orders, 120 new'), findsOneWidget);
      expect(find.bySemanticsLabel('Saved Items'), findsOneWidget);
      for (final guideline in [
        androidTapTargetGuideline,
        labeledTapTargetGuideline,
        textContrast
      ]) {
        await expectLater(tester, meetsGuideline(guideline));
      }
      semantics.dispose();
      await harness.dispose();
    });

    testWidgets('a failed menu summary leaves every row usable without badges', (tester) async {
      await launch(tester);
      when(() => repository.menuBadges())
          .thenThrow(const ApiError(type: ApiErrorType.network, message: 'offline'));
      await tester.tap(find.text('Profile'));
      await harness.settle();
      expect(find.text('Abhay Kumar'), findsOneWidget);
      await tester.tap(find.text('My Orders'));
      await harness.settle();
      expect(find.text('This is coming soon'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('pull down refreshes the badges', (tester) async {
      await showProfile(tester);
      verify(() => repository.menuBadges()).called(1);
      await tester.fling(find.byType(SingleChildScrollView), const Offset(0, 400), 1000);
      await harness.settle();
      verify(() => repository.menuBadges()).called(1);
      await harness.dispose();
    });

    testWidgets('header shows the joined month', (tester) async {
      await showProfile(tester);
      expect(find.text('Joined Aug 2026'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('upgrade invite answers with a message', (tester) async {
      await showProfile(tester);
      await tester.tap(find.text('Upgrade to Premium \u2192'));
      await harness.settle();
      expect(find.text('This is coming soon'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a premium user sees the active plan instead of the invite', (tester) async {
      await launch(tester, premium: true);
      await tester.tap(find.text('Profile'));
      await harness.settle();
      expect(find.text('Vision Plan \u2014 Active'), findsOneWidget);
      expect(find.text('Upgrade to Premium \u2192'), findsNothing);
      await harness.dispose();
    });

    testWidgets('menu rows that are not built answer with a message', (tester) async {
      await showProfile(tester);
      await tester.tap(find.text('My Orders'));
      await harness.settle();
      expect(find.text('This is coming soon'), findsOneWidget);
      await harness.dispose();
    });

    group('sign out', () {
      Future<void> openConfirmation(WidgetTester tester) async {
        await showProfile(tester);
        await tester.scrollUntilVisible(find.text('Sign Out'), 200);
        await tester.tap(find.text('Sign Out'));
        await harness.settle();
      }

      testWidgets('asks for confirmation first', (tester) async {
        await openConfirmation(tester);

        expect(find.text('Are you sure you want to log out?'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        verifyNever(() => harness.repository.logout());
        await harness.dispose();
      });

      testWidgets('cancelling keeps the user signed in', (tester) async {
        await openConfirmation(tester);

        await tester.tap(find.text('Cancel'));
        await harness.settle();

        expect(find.text('Are you sure you want to log out?'), findsNothing);
        expect(find.byType(ProfileScreen), findsOneWidget);
        verifyNever(() => harness.repository.logout());
        await harness.dispose();
      });

      testWidgets('confirming logs out and returns to Sign In', (tester) async {
        await openConfirmation(tester);
        when(() => harness.repository.logout()).thenAnswer((_) async => LogoutOutcome.revoked);

        await tester.tap(find.widgetWithText(TextButton, 'Sign Out'));
        await harness.settle();

        verify(() => harness.repository.logout()).called(1);
        expect(find.byType(ProfileScreen), findsNothing);
        expect(find.text('Sign In'), findsWidgets);
        expect(find.textContaining('Logged out on this device'), findsNothing);
        await harness.dispose();
      });

      testWidgets('shows a progress indicator while the server is called', (tester) async {
        await openConfirmation(tester);
        final done = Completer<LogoutOutcome>();
        when(() => harness.repository.logout()).thenAnswer((_) => done.future);

        await tester.tap(find.widgetWithText(TextButton, 'Sign Out'));
        await harness.settle();

        expect(find.byType(LoadingIndicator), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);

        done.complete(LogoutOutcome.revoked);
        await harness.settle();
        expect(find.byType(LoadingIndicator), findsNothing);
        await harness.dispose();
      });

      testWidgets('tells the user when the server call is queued', (tester) async {
        await openConfirmation(tester);
        when(() => harness.repository.logout()).thenAnswer((_) async => LogoutOutcome.queued);

        await tester.tap(find.widgetWithText(TextButton, 'Sign Out'));
        await harness.settle();

        expect(find.byType(ProfileScreen), findsNothing);
        expect(find.textContaining('Logged out on this device'), findsOneWidget);
        await harness.dispose();
      });

      testWidgets('forgets the saved Home address and half-finished sign-up', (tester) async {
        await openConfirmation(tester);
        when(() => harness.repository.logout()).thenAnswer((_) async => LogoutOutcome.revoked);
        final prefs = harness.container.read(preferencesServiceProvider);
        await prefs.setString(StorageKeys.homeLocation, '{"city":"Pune"}');

        await tester.tap(find.widgetWithText(TextButton, 'Sign Out'));
        await harness.settle();

        expect(await prefs.getString(StorageKeys.homeLocation), isNull);
        await harness.dispose();
      });
    });

    testWidgets('Home tab leaves the profile page', (tester) async {
      await showProfile(tester);
      await tester.tap(find.text('Home'));
      await harness.settle();
      expect(find.byType(ProfileScreen), findsNothing);
      expect(find.text('Featured Deals Near You'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('details show masked read-only identity', (tester) async {
      await showDetails(tester);
      expect(find.text('Abhay Kumar'), findsOneWidget);
      expect(find.text('90XXXX0010'), findsOneWidget);
      expect(find.text('Verified Person'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      await harness.dispose();
    });

    testWidgets('profile loading failure offers a retry', (tester) async {
      await launch(tester);
      final waiting = Completer<UserProfile>();
      when(() => repository.fetch()).thenAnswer((_) => waiting.future);
      await tester.tap(find.text('Profile'));
      await harness.settle();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      waiting.completeError(const ApiError(type: ApiErrorType.network, message: 'offline'));
      await harness.settle();
      expect(find.text('Retry'), findsOneWidget);
      when(() => repository.fetch()).thenAnswer((_) async => profile);
      await tester.tap(find.text('Retry'));
      await harness.settle();
      expect(find.text('Abhay Kumar'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('unchanged edit cannot be saved', (tester) async {
      await showDetails(tester);
      await tester.tap(find.byTooltip('Edit profile'));
      await harness.settle();
      await tester.tap(find.text('Save changes'));
      await harness.settle();
      verifyNever(() =>
          repository.update(displayName: any(named: 'displayName'), city: any(named: 'city')));
      await harness.dispose();
    });

    testWidgets('profile, details and edit meet accessibility guidelines', (tester) async {
      final semantics = tester.ensureSemantics();
      await showProfile(tester);
      for (final guideline in [
        androidTapTargetGuideline,
        labeledTapTargetGuideline,
        textContrast
      ]) {
        await expectLater(tester, meetsGuideline(guideline));
      }
      await tester.tap(find.byTooltip('Edit profile'));
      await harness.settle();
      for (final guideline in [
        androidTapTargetGuideline,
        labeledTapTargetGuideline,
        textContrast
      ]) {
        await expectLater(tester, meetsGuideline(guideline));
      }
      await tester.tap(find.byTooltip('Edit profile'));
      await harness.settle();
      for (final guideline in [
        androidTapTargetGuideline,
        labeledTapTargetGuideline,
        textContrast
      ]) {
        await expectLater(tester, meetsGuideline(guideline));
      }
      semantics.dispose();
      await harness.dispose();
    });

    testWidgets('profile page at 200% text in Hindi does not overflow', (tester) async {
      await showProfile(tester);
      tester.view.physicalSize = const Size(960, 1920);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.platformDispatcher.localeTestValue = const Locale('hi');
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      await harness.settle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.byType(ProfileSignOutTile), 300);
      expect(tester.takeException(), isNull);
      await harness.dispose();
    });

    testWidgets('small viewport with large text remains scrollable', (tester) async {
      await showDetails(tester);
      tester.view.physicalSize = const Size(960, 1920);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.platformDispatcher.localeTestValue = const Locale('hi');
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      await harness.settle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('rejected avatar leaves current avatar unchanged', (tester) async {
      await showDetails(tester);
      when(() => repository.avatars()).thenAnswer((_) async =>
          const ProfileAvatarCatalog(ids: ['avatar-02', 'avatar-03'], defaultId: 'avatar-02'));
      when(() => repository.selectAvatar('avatar-03')).thenThrow(const ApiError(
        type: ApiErrorType.business,
        message: 'stale',
        code: 'ERROR_INVALID_AVATAR',
      ));
      await tester.tap(find.text('Change avatar'));
      await harness.settle();
      await tester.tap(find.byKey(const Key('avatar-avatar-03')));
      await harness.settle();
      await tester.tap(find.text('Save changes'));
      await harness.settle();
      expect(tester.widget<AvatarImage>(find.byType(AvatarImage)).avatarId, 'avatar-02');
      expect(find.text('Selected avatar is not available. Please choose another'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('edit saves only a changed name and shows server response', (tester) async {
      await showDetails(tester);
      when(() => repository.update(displayName: 'New Name', city: null)).thenAnswer((_) async {
        profile = UserProfileModel.fromJson({..._json, 'displayName': 'New Name'}).toEntity();
        return profile;
      });
      await tester.tap(find.byTooltip('Edit profile'));
      await harness.settle();
      await tester.enterText(find.byType(TextFormField).first, 'New Name');
      await tester.pump();
      await tester.tap(find.text('Save changes'));
      await harness.settle();
      verify(() => repository.update(displayName: 'New Name', city: null)).called(1);
      expect(find.text('New Name'), findsOneWidget);
      expect(find.text('Profile updated'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('blank name shows validation and sends nothing', (tester) async {
      await showDetails(tester);
      await tester.tap(find.byTooltip('Edit profile'));
      await harness.settle();
      await tester.enterText(find.byType(TextFormField).first, ' ');
      await tester.pump();
      await tester.tap(find.text('Save changes'));
      await harness.settle();
      expect(find.text('Enter 3 to 50 letters'), findsOneWidget);
      verifyNever(() =>
          repository.update(displayName: any(named: 'displayName'), city: any(named: 'city')));
      await harness.dispose();
    });

    testWidgets('failed save keeps draft and allows retry', (tester) async {
      await showDetails(tester);
      when(() => repository.update(displayName: 'New Name', city: null)).thenThrow(
        const ApiError(type: ApiErrorType.network, message: 'offline'),
      );
      await tester.tap(find.byTooltip('Edit profile'));
      await harness.settle();
      await tester.enterText(find.byType(TextFormField).first, 'New Name');
      await tester.pump();
      await tester.tap(find.text('Save changes'));
      await harness.settle();
      expect(tester.widget<TextFormField>(find.byType(TextFormField).first).controller!.text,
          'New Name');
      expect(find.byType(TextFormField), findsNWidgets(2));
      await harness.dispose();
    });

    testWidgets('cancel prompts before discarding a changed draft', (tester) async {
      await showDetails(tester);
      await tester.tap(find.byTooltip('Edit profile'));
      await harness.settle();
      await tester.enterText(find.byType(TextFormField).first, 'New Name');
      await tester.pump();
      await tester.tap(find.byTooltip('Cancel'));
      await harness.settle();
      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await harness.settle();
      expect(find.byType(TextFormField), findsNWidgets(2));
      await harness.dispose();
    });

    testWidgets('avatar picker lists server IDs and requires confirmation', (tester) async {
      await showDetails(tester);
      when(() => repository.avatars()).thenAnswer((_) async =>
          const ProfileAvatarCatalog(ids: ['avatar-02', 'avatar-03'], defaultId: 'avatar-02'));
      when(() => repository.selectAvatar('avatar-03')).thenAnswer((_) async {
        profile = UserProfileModel.fromJson({..._json, 'avatarId': 'avatar-03'}).toEntity();
        return profile;
      });
      await tester.tap(find.text('Change avatar'));
      await harness.settle();
      expect(find.byKey(const Key('avatar-avatar-01')), findsNothing);
      await tester.tap(find.byKey(const Key('avatar-avatar-03')));
      await harness.settle();
      verifyNever(() => repository.selectAvatar(any()));
      await tester.tap(find.text('Save changes'));
      await harness.settle();
      verify(() => repository.selectAvatar('avatar-03')).called(1);
      expect(tester.widget<AvatarImage>(find.byType(AvatarImage)).avatarId, 'avatar-03');
      await harness.dispose();
    });
  });
}
