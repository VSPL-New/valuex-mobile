import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/features/auth/data/models/auth_models.dart';
import 'package:valuex_mobile/features/communication_safety/data/communication_safety_repository.dart';
import 'package:valuex_mobile/features/communication_safety/domain/communication_safety.dart';
import 'package:valuex_mobile/features/communication_safety/presentation/blocked_users_screen.dart';
import 'package:valuex_mobile/features/communication_safety/presentation/widgets/report_sheet.dart';
import 'package:valuex_mobile/features/communication_safety/presentation/widgets/user_safety_menu.dart';
import 'package:valuex_mobile/features/profile/data/profile_repository.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/fonts.dart';
import 'communication_safety_fixtures.dart';

const _offline = ApiError(type: ApiErrorType.network, message: 'offline');

ApiError _status(int status) =>
    ApiError(type: ApiErrorType.business, message: 'x', code: 'X', statusCode: status);

void main() {
  setUpAll(loadBrandFonts);

  late FakeCommunicationSafetyRepository safety;

  setUp(() => safety = FakeCommunicationSafetyRepository());

  Future<void> pumpApp(
    WidgetTester tester,
    Widget home, {
    List<Override> overrides = const [],
    Locale locale = const Locale('en'),
    double textScale = 1,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [communicationSafetyRepositoryProvider.overrideWithValue(safety), ...overrides],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Blocked users screen', () {
    setUp(() {
      safety.onList = (page) async => blockedPage([
            blockedUserJson('u1', name: 'Asha K'),
            blockedUserJson('u2', name: 'Ravi S'),
          ]);
    });

    testWidgets('lists the blocked users with an Unblock action each', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const BlockedUsersScreen());

      expect(tester.getSemantics(find.text('Blocked users').first), isSemantics(isHeader: true));
      expect(find.text('Asha K'), findsOneWidget);
      expect(find.text('Ravi S'), findsOneWidget);
      expect(find.text('Unblock'), findsNWidgets(2));
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'Unblock Asha K',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('an empty list explains what blocking does', (tester) async {
      safety.onList = (page) async => blockedPage(const []);
      await pumpApp(tester, const BlockedUsersScreen());

      expect(find.text("You haven't blocked anyone"), findsOneWidget);
      expect(find.textContaining("can't contact you"), findsOneWidget);
    });

    testWidgets('a failed load shows an error with Retry', (tester) async {
      var fail = true;
      safety.onList = (page) async {
        if (fail) throw _offline;
        return blockedPage([blockedUserJson('u1', name: 'Asha K')]);
      };
      await pumpApp(tester, const BlockedUsersScreen());

      expect(find.text('Unable to load your blocked users. Try again'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Asha K'), findsOneWidget);
    });

    testWidgets('waits with a spinner while the list loads', (tester) async {
      final gate = Completer<BlockedUsersPage>();
      safety.onList = (page) => gate.future;
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [communicationSafetyRepositoryProvider.overrideWithValue(safety)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const BlockedUsersScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      gate.complete(blockedPage([blockedUserJson('u1', name: 'Asha K')]));
      await tester.pumpAndSettle();
      expect(find.text('Asha K'), findsOneWidget);
    });

    testWidgets('unblocking removes the user and says so', (tester) async {
      await pumpApp(tester, const BlockedUsersScreen());

      await tester.tap(find.text('Unblock').first);
      await tester.pumpAndSettle();

      expect(safety.unblocked, ['u1']);
      expect(find.text('Asha K'), findsNothing);
      expect(find.text('Ravi S'), findsOneWidget);
      expect(find.text('User unblocked'), findsOneWidget);
    });

    testWidgets('a refused unblock puts the user back and says so', (tester) async {
      safety.onUnblock = (id) async => throw _offline;
      await pumpApp(tester, const BlockedUsersScreen());

      await tester.tap(find.text('Unblock').first);
      await tester.pumpAndSettle();

      expect(find.text('Asha K'), findsOneWidget);
      expect(find.text('Unable to unblock this user. Try again'), findsOneWidget);
    });

    testWidgets('loads the next page when the user scrolls to the end', (tester) async {
      safety.onList = (page) async => page == 0
          ? blockedPage(
              [for (var i = 0; i < 20; i++) blockedUserJson('a$i', name: 'Person $i')],
              hasNext: true,
              total: 21,
            )
          : blockedPage([blockedUserJson('z1', name: 'Last person')], page: 1, total: 21);
      await pumpApp(tester, const BlockedUsersScreen());

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -20000));
      await tester.pumpAndSettle();

      expect(safety.listed, [0, 1]);
    });

    testWidgets('a page that fails to load says so', (tester) async {
      safety.onList = (page) async => page == 0
          ? blockedPage(
              [for (var i = 0; i < 20; i++) blockedUserJson('a$i', name: 'Person $i')],
              hasNext: true,
              total: 21,
            )
          : throw _offline;
      await pumpApp(tester, const BlockedUsersScreen());

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -20000));
      await tester.pumpAndSettle();

      expect(find.text('Unable to load more users. Try again'), findsOneWidget);
    });

    testWidgets('pull to refresh loads the list again', (tester) async {
      await pumpApp(tester, const BlockedUsersScreen());
      expect(safety.listed, [0]);

      await tester.fling(find.text('Asha K'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(safety.listed.length, 2);
    });

    testWidgets('reads in Hindi at 200 percent text on a narrow phone without overflow',
        (tester) async {
      await pumpApp(
        tester,
        const BlockedUsersScreen(),
        locale: const Locale('hi'),
        textScale: 2,
        size: const Size(320, 640),
      );

      expect(find.text('अनब्लॉक करें'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the touch target and contrast guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const BlockedUsersScreen());

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrast));
      handle.dispose();
    });
  });

  group('Report sheet', () {
    bool? sent;

    Future<void> openSheet(WidgetTester tester, {Locale locale = const Locale('en')}) async {
      sent = null;
      await pumpApp(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => sent = await showReportSheet(
                context,
                target: ReportTarget.user,
                targetId: 'u9',
              ),
              child: const Text('open'),
            ),
          ),
        ),
        locale: locale,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    ElevatedButton submit(WidgetTester tester) =>
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Submit report'));

    testWidgets('lists every reason and keeps Submit off until one is chosen', (tester) async {
      await openSheet(tester);

      expect(find.text('Report this user'), findsOneWidget);
      for (final reason in [
        'Spam',
        'Harassment',
        'Scam or fraud',
        'Inappropriate content',
        'Offensive behaviour',
        'Sharing contact details',
        'Other',
      ]) {
        expect(find.text(reason), findsOneWidget, reason: reason);
      }
      expect(submit(tester).onPressed, isNull);

      await tester.tap(find.text('Spam'));
      await tester.pump();
      expect(submit(tester).onPressed, isNotNull);
    });

    testWidgets('sends the reason and trimmed details, then closes with a yes', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Harassment'));
      await tester.enterText(find.byType(TextField), '  keeps sending rude messages  ');
      await tester.pump();
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();

      expect(safety.reports.single.target, ReportTarget.user);
      expect(safety.reports.single.targetId, 'u9');
      expect(safety.reports.single.reason, ReportReason.harassment);
      expect(safety.reports.single.details, '  keeps sending rude messages  ');
      expect(find.text('Report this user'), findsNothing);
      expect(sent, isTrue);
    });

    testWidgets('shows how many characters the details can still take', (tester) async {
      await openSheet(tester);

      expect(find.text('0/500'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();
      expect(find.text('3/500'), findsOneWidget);
    });

    testWidgets('the daily limit is explained and the sheet stays open', (tester) async {
      safety.onReport = (report) async => throw _status(429);
      await openSheet(tester);

      await tester.tap(find.text('Spam'));
      await tester.pump();
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();

      expect(find.text("You've reached today's report limit. Try again tomorrow"), findsOneWidget);
      expect(find.text('Report this user'), findsOneWidget);
      expect(submit(tester).onPressed, isNotNull);
    });

    testWidgets('a target that cannot be found is explained', (tester) async {
      safety.onReport = (report) async => throw _status(404);
      await openSheet(tester);

      await tester.tap(find.text('Spam'));
      await tester.pump();
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();

      expect(find.text("We couldn't find what you tried to report"), findsOneWidget);
    });

    testWidgets('any other failure says so and allows another try', (tester) async {
      var fail = true;
      safety.onReport = (report) async {
        if (fail) throw _offline;
      };
      await openSheet(tester);

      await tester.tap(find.text('Other'));
      await tester.pump();
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();
      expect(find.text('Unable to send your report. Try again'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();
      expect(find.text('Report this user'), findsNothing);
      expect(safety.reports.length, 2);
      expect(sent, isTrue);
    });

    testWidgets('dismissing the sheet sends nothing and answers no', (tester) async {
      await openSheet(tester);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(safety.reports, isEmpty);
      expect(sent, isFalse);
    });

    testWidgets('reads in Hindi', (tester) async {
      await openSheet(tester, locale: const Locale('hi'));

      expect(find.text('इस उपयोगकर्ता की रिपोर्ट करें'), findsOneWidget);
      expect(find.text('रिपोर्ट भेजें'), findsOneWidget);
    });
  });

  group('User safety menu', () {
    Override signedInAs(String userId) => userProfileProvider.overrideWith(
          (ref) async => UserProfileModel.fromJson({
            'userId': userId,
            'status': 'ACTIVE',
            'aadhaarVerified': true,
          }).toEntity(),
        );

    Future<void> showMenu(WidgetTester tester, {String me = 'me'}) async {
      await pumpApp(
        tester,
        Scaffold(
          appBar: AppBar(actions: const [UserSafetyMenu(userId: 'u2')]),
        ),
        overrides: [signedInAs(me)],
      );
    }

    testWidgets('offers Block user and Report user', (tester) async {
      await showMenu(tester);

      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();

      expect(find.text('Block user'), findsOneWidget);
      expect(find.text('Report user'), findsOneWidget);
    });

    testWidgets('is not shown on the signed-in user\'s own profile', (tester) async {
      await showMenu(tester, me: 'u2');

      expect(find.byTooltip('More options'), findsNothing);
    });

    testWidgets('blocks after the user confirms, and says so', (tester) async {
      await showMenu(tester);
      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block user'));
      await tester.pumpAndSettle();

      expect(find.text('Block this user?'), findsOneWidget);
      expect(find.textContaining('Existing orders and accepted prices stay'), findsOneWidget);
      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();

      expect(safety.blocked, ['u2']);
      expect(find.text('User blocked'), findsOneWidget);
    });

    testWidgets('does not block when the user cancels', (tester) async {
      await showMenu(tester);
      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block user'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(safety.blocked, isEmpty);
      expect(find.text('Block this user?'), findsNothing);
    });

    testWidgets('says so when the block fails', (tester) async {
      safety.onBlock = (id) async => throw _offline;
      await showMenu(tester);
      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block user'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();

      expect(find.text('Unable to block this user. Try again'), findsOneWidget);
    });

    testWidgets('reports the user and thanks them', (tester) async {
      await showMenu(tester);
      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Report user'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Spam'));
      await tester.pump();
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();

      expect(safety.reports.single.targetId, 'u2');
      expect(safety.reports.single.target, ReportTarget.user);
      expect(find.text("Thanks. We've received your report"), findsOneWidget);
    });

    testWidgets('a dismissed report sheet shows no thanks', (tester) async {
      await showMenu(tester);
      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Report user'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text("Thanks. We've received your report"), findsNothing);
      expect(safety.reports, isEmpty);
    });
  });
}
