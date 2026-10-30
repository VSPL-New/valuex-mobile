import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/features/listing/domain/restricted_check.dart';
import 'package:valuex_mobile/features/listing/presentation/widgets/restricted_item_dialogs.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../helpers/fonts.dart';

const _drones = RestrictionPolicy(
  code: 'DRONES',
  title: 'Drones',
  titleHi: 'ड्रोन',
  message: 'Confirm the drone is legal to sell',
  messageHi: 'पुष्टि करें कि ड्रोन बेचना कानूनी है',
);

const _compliance = RestrictedCheck(
  checkId: 'c1',
  result: RestrictedResult.complianceRequired,
  policies: [_drones],
);

const _blocked = RestrictedCheck(
  checkId: 'c2',
  result: RestrictedResult.restricted,
  policies: [_drones],
);

void main() {
  setUpAll(loadBrandFonts);

  Future<void> open(
    WidgetTester tester,
    Future<Object?> Function(BuildContext context) show, {
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) async {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(onPressed: () => show(context), child: const Text('open')),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('compliance dialog', () {
    testWidgets('shows the Hindi text to a Hindi reader', (tester) async {
      await open(tester, (context) => showComplianceDialog(context, _compliance),
          locale: const Locale('hi'));

      expect(find.text('ड्रोन'), findsOneWidget);
      expect(find.text('पुष्टि करें कि ड्रोन बेचना कानूनी है'), findsOneWidget);
      expect(find.text('सहमत हों और आगे बढ़ें'), findsOneWidget);
      expect(find.text('रद्द करें'), findsOneWidget);
      expect(find.text('Drones'), findsNothing);
    });

    testWidgets('meets the tap target and label guidelines and marks its titles as headers',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await open(tester, (context) => showComplianceDialog(context, _compliance));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      expect(tester.getSemantics(find.text('Before you continue')), isSemantics(isHeader: true));
      expect(tester.getSemantics(find.text('Drones')), isSemantics(isHeader: true));
      semantics.dispose();
    });

    testWidgets('lays out without overflow at 2x text size', (tester) async {
      await open(tester, (context) => showComplianceDialog(context, _compliance), textScale: 2);

      expect(tester.takeException(), isNull);
      expect(find.text('Agree & Continue'), findsOneWidget);
    });

    testWidgets('returns true for Agree & Continue and false for Cancel or a tap outside',
        (tester) async {
      bool? answer;
      await open(
          tester, (context) async => answer = await showComplianceDialog(context, _compliance));
      await tester.tap(find.text('Agree & Continue'));
      await tester.pumpAndSettle();
      expect(answer, isTrue);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(answer, isFalse);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();
      expect(answer, isFalse);
    });
  });

  group('blocked dialog', () {
    testWidgets('shows the Hindi text and the suspension notice for a severe violation',
        (tester) async {
      const severe = RestrictedCheck(
        checkId: 'c3',
        result: RestrictedResult.severeViolation,
        policies: [_drones],
      );
      await open(
        tester,
        (context) => showBlockedDialog(context, severe, onAppeal: (_) async => null),
        locale: const Locale('hi'),
      );

      expect(find.text('इस वस्तु को लिस्ट नहीं किया जा सकता'), findsOneWidget);
      expect(find.text('नीति उल्लंघन के कारण आपका खाता निलंबित है'), findsOneWidget);
      expect(find.text('ड्रोन'), findsOneWidget);
      expect(find.text('अपील करें'), findsOneWidget);
      expect(find.text('वापस जाएँ'), findsOneWidget);
    });

    testWidgets('meets the tap target and label guidelines in both of its steps', (tester) async {
      final semantics = tester.ensureSemantics();
      await open(
          tester, (context) => showBlockedDialog(context, _blocked, onAppeal: (_) async => null));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await tester.tap(find.text('Appeal'));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });

    testWidgets('Go Back from the appeal step returns to the policy text', (tester) async {
      await open(
          tester, (context) => showBlockedDialog(context, _blocked, onAppeal: (_) async => null));

      await tester.tap(find.text('Appeal'));
      await tester.pumpAndSettle();
      expect(find.text('Appeal this decision'), findsOneWidget);
      await tester.tap(find.text('Go Back'));
      await tester.pumpAndSettle();

      expect(find.text('This item cannot be listed'), findsOneWidget);
      expect(find.text('Confirm the drone is legal to sell'), findsOneWidget);
    });

    testWidgets('returns true once the appeal was sent and false for Go Back', (tester) async {
      bool? answer;
      final reasons = <String>[];
      await open(
        tester,
        (context) async => answer = await showBlockedDialog(
          context,
          _blocked,
          onAppeal: (reason) async {
            reasons.add(reason);
            return null;
          },
        ),
      );
      await tester.tap(find.text('Go Back'));
      await tester.pumpAndSettle();
      expect(answer, isFalse);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Appeal'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '  Decorative bottles  ');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send appeal'));
      await tester.pumpAndSettle();

      expect(answer, isTrue);
      expect(reasons, ['Decorative bottles']);
    });
  });
}
