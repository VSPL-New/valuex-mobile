import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';

import 'helpers/app_harness.dart';

/// Screen readers jump between headings, so every screen title must be marked as one.
void main() {
  final titles = <String, (String, AccountStatus?)>{
    RouteNames.terms: ('Terms and Conditions', AccountStatus.signupPending),
    RouteNames.accountBlocked: ('Account unavailable', AccountStatus.suspended),
    RouteNames.home: ('Featured Deals Near You', AccountStatus.active),
    RouteNames.categories: ('All categories', AccountStatus.active),
    RouteNames.signupProfile: ('Create your profile', AccountStatus.signupPending),
    RouteNames.signupAadhaar: ('Verify Aadhaar', AccountStatus.identityVerificationPending),
    RouteNames.signupEmail: ('Verify Email', AccountStatus.emailVerificationPending),
    RouteNames.signupMobile: ('Create Account', null),
  };

  for (final entry in titles.entries) {
    testWidgets('${entry.key} marks its title as a heading', (tester) async {
      final handle = tester.ensureSemantics();
      final harness = AppHarness(tester);
      if (entry.value.$2 != null) harness.signedInAs(entry.value.$2!);
      await harness.launch(location: entry.key);

      expect(tester.getSemantics(find.text(entry.value.$1).first), isSemantics(isHeader: true));
      handle.dispose();
      await harness.dispose();
    });
  }
}
