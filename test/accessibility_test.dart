import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/core/theme/spacing.dart';
import 'package:valuex_mobile/core/widgets/square_back_button.dart';
import 'package:valuex_mobile/features/auth/domain/entities/aadhaar_transaction.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/otp_sent.dart';
import 'package:valuex_mobile/features/auth/presentation/widgets/avatar_image.dart';
import 'package:valuex_mobile/features/auth/presentation/widgets/gender_selector.dart';
import 'package:valuex_mobile/features/auth/presentation/widgets/state_picker_field.dart';

import 'helpers/app_harness.dart';
import 'helpers/fonts.dart';

/// Every registration screen must lay out without overflow in English and Hindi, at the
/// system's largest text size, on a small phone.
void main() {
  setUpAll(loadBrandFonts);

  final screens = <String, AccountStatus?>{
    RouteNames.createAccount: null,
    RouteNames.signupMobile: null,
    RouteNames.signupEmail: AccountStatus.emailVerificationPending,
    RouteNames.signupAadhaar: AccountStatus.identityVerificationPending,
    RouteNames.signupProfile: AccountStatus.signupPending,
    RouteNames.terms: AccountStatus.signupPending,
    RouteNames.accountBlocked: AccountStatus.suspended,
  };

  for (final locale in const [Locale('en'), Locale('hi')]) {
    for (final scale in const [1.0, 2.0]) {
      for (final entry in screens.entries) {
        testWidgets('${entry.key} in ${locale.languageCode} at ${scale}x text', (tester) async {
          tester.platformDispatcher.localesTestValue = [locale];
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearAllTestValues);

          final harness = AppHarness(tester);
          if (entry.value != null) harness.signedInAs(entry.value!);
          await harness.launch(location: entry.key);
          tester.view.physicalSize = const Size(1080, 1920);
          await tester.pump();

          expect(tester.takeException(), isNull);
          await harness.dispose();
        });
      }
    }
  }

  group('OTP screens', () {
    for (final locale in const [Locale('en'), Locale('hi')]) {
      testWidgets('the mobile OTP screen in ${locale.languageCode} at 2x text', (tester) async {
        tester.platformDispatcher.localesTestValue = [locale];
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final harness = AppHarness(tester);
        when(
          () => harness.repository.initiateRegistration(any()),
        ).thenAnswer((_) async => const OtpSent(expiresInSeconds: 300));
        await harness.launch(location: RouteNames.signupMobile);
        await tester.enterText(find.byType(TextField), '9876543210');
        await tester.pump();
        await tester.tap(find.byType(InkWell).last);
        await harness.settle();

        expect(find.byType(TextField), findsOneWidget);
        expect(tester.takeException(), isNull);
        await harness.dispose();
      });

      testWidgets('the development Aadhaar OTP screen in ${locale.languageCode}', (tester) async {
        tester.platformDispatcher.localesTestValue = [locale];
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final harness = AppHarness(tester)..signedInAs(AccountStatus.identityVerificationPending);
        when(
          () => harness.repository.initiateAadhaar(
            aadhaarNumber: any(named: 'aadhaarNumber'),
            consentToken: any(named: 'consentToken'),
          ),
        ).thenAnswer((_) async => const AadhaarTransaction(transactionId: 'txn-1'));
        await harness.launch();
        await tester.enterText(find.byType(TextField), '123412341234');
        await tester.ensureVisible(find.byType(Checkbox));
        await tester.tap(find.byType(Checkbox));
        await tester.pump();
        await tester.tap(find.byType(InkWell).at(find.byType(InkWell).evaluate().length - 2));
        await harness.settle();

        expect(tester.takeException(), isNull);
        await harness.dispose();
      });
    }
  });

  group('touch targets', () {
    testWidgets('the back button has a 48 by 48 tap area', (tester) async {
      final harness = AppHarness(tester);
      await harness.launch(location: RouteNames.signupMobile);

      final size = tester.getSize(find.byType(SquareBackButton));

      expect(size.width, greaterThanOrEqualTo(AppSizes.minTouchTarget));
      expect(size.height, greaterThanOrEqualTo(AppSizes.minTouchTarget));
      await harness.dispose();
    });

    testWidgets('the Sign Up controls are at least 48 by 48', (tester) async {
      final harness = AppHarness(tester)..signedInAs(AccountStatus.signupPending);
      await harness.launch();

      for (final finder in [
        find.byType(GenderSelector),
        find.byType(StatePickerField),
        find.byTooltip('Choose date of birth'),
        find.byType(Switch),
      ]) {
        await tester.ensureVisible(finder);
        await tester.pump();
        final size = tester.getSize(finder.first);
        expect(size.height, greaterThanOrEqualTo(AppSizes.minTouchTarget), reason: '$finder');
      }
      expect(tester.getSize(find.byTooltip('Choose date of birth')).width,
          greaterThanOrEqualTo(AppSizes.minTouchTarget));
      expect(
        tester.getSize(find.byType(AvatarImage)).shortestSide,
        greaterThanOrEqualTo(AppSizes.minTouchTarget),
      );
      await harness.dispose();
    });
  });
}
