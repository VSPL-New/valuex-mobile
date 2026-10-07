import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';

import 'helpers/app_harness.dart';
import 'helpers/fonts.dart';

/// Every screen must pass Flutter's accessibility guidelines. Add a screen here when it is built:
/// a new screen that fails tap target size, labels or text contrast breaks this test.
void main() {
  setUpAll(loadBrandFonts);

  final screens = <String, AccountStatus?>{
    'onboarding': null,
    RouteNames.createAccount: null,
    RouteNames.signupMobile: null,
    RouteNames.signupEmail: AccountStatus.emailVerificationPending,
    RouteNames.signupAadhaar: AccountStatus.identityVerificationPending,
    RouteNames.signupProfile: AccountStatus.signupPending,
    RouteNames.terms: AccountStatus.signupPending,
    RouteNames.accountBlocked: AccountStatus.suspended,
    RouteNames.home: AccountStatus.active,
  };

  final guidelines = <String, AccessibilityGuideline>{
    'android tap target (48 dp)': androidTapTargetGuideline,
    'ios tap target (44 pt)': iOSTapTargetGuideline,
    'labelled tap targets': labeledTapTargetGuideline,
    'text contrast (4.5:1)': textContrastGuideline,
  };

  for (final entry in screens.entries) {
    for (final guideline in guidelines.entries) {
      testWidgets('${entry.key} passes ${guideline.key}', (tester) async {
        final handle = tester.ensureSemantics();
        final harness = AppHarness(tester);
        if (entry.value != null) harness.signedInAs(entry.value!);
        await harness.launch(location: entry.key == 'onboarding' ? null : entry.key);

        await expectLater(tester, meetsGuideline(guideline.value));
        handle.dispose();
        await harness.dispose();
      });
    }
  }

  testWidgets('the splash screen passes the text guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    final harness = AppHarness(tester);
    await harness.launch(waitOutSplash: false);

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await tester.pump(const Duration(seconds: 3));
    handle.dispose();
    await harness.dispose();
  });
}
