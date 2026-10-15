import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/theme/colors.dart';
import 'package:valuex_mobile/core/widgets/brand_gradient_button.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:valuex_mobile/features/auth/domain/entities/gender.dart';
import 'package:valuex_mobile/features/auth/domain/entities/signup_details.dart';
import 'package:valuex_mobile/features/auth/domain/entities/user_profile.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_controller.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_state.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/signup_profile_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/terms_screen.dart';
import 'package:valuex_mobile/features/auth/presentation/widgets/avatar_image.dart';
import 'package:valuex_mobile/features/auth/presentation/widgets/gender_selector.dart';
import 'package:valuex_mobile/features/home/presentation/home_screen.dart';

import '../../../helpers/app_harness.dart';

class _FakeSignupDetails extends Fake implements SignupDetails {}

const _activeResult = AuthResult(
  session: AuthSession(accessToken: 'a', refreshToken: 'r', userId: 'user-1'),
  status: AccountStatus.active,
  aadhaarVerified: false,
);

Finder _field(String hint) {
  return find
      .byWidgetPredicate((widget) => widget is TextField && widget.decoration?.hintText == hint);
}

Future<void> _enter(WidgetTester tester, String hint, String text) async {
  await tester.ensureVisible(_field(hint));
  await tester.enterText(_field(hint), text);
  await tester.pump();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 400));
}

BrandGradientButton _submit(WidgetTester tester) {
  return tester.widget<BrandGradientButton>(find.widgetWithText(BrandGradientButton, 'Submit'));
}

void main() {
  late AppHarness harness;

  setUpAll(() {
    registerFallbackValue(_FakeSignupDetails());
  });

  Future<void> openSignup(WidgetTester tester) async {
    harness = AppHarness(tester)..signedInAs(AccountStatus.signupPending);
    await harness.launch();
    expect(find.byType(SignupProfileScreen), findsOneWidget);
  }

  Future<void> openTermsAndClose(WidgetTester tester) async {
    await _tapVisible(tester, find.text('Terms and Conditions'));
    await harness.settle();
    expect(find.byType(TermsScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await harness.settle();
  }

  Future<void> fillEverything(WidgetTester tester, {Gender? gender = Gender.female}) async {
    await _enter(tester, 'Your full name', 'Asha Verma');
    if (gender != null) {
      await _tapVisible(
        tester,
        find.text(switch (gender) {
          Gender.male => 'Male',
          Gender.female => 'Female',
          Gender.others => 'Others',
        }),
      );
    }
    await openTermsAndClose(tester);
    await _tapVisible(tester, find.byType(Switch));
  }

  group('resume and layout', () {
    testWidgets('resumes at Sign Up and shows the verified contact details read-only', (
      tester,
    ) async {
      await openSignup(tester);

      expect(find.text('Create your profile'), findsOneWidget);
      expect(find.text('Almost there! Tell me a bit about yourself'), findsOneWidget);
      expect(find.text('a***@mail.com'), findsOneWidget);
      expect(find.text('98****3210'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('does not ask for an address or a date of birth', (tester) async {
      await openSignup(tester);

      for (final label in ['ADDRESS', 'CITY', 'STATE', 'PINCODE', 'DATE OF BIRTH']) {
        expect(find.text(label, skipOffstage: false), findsNothing, reason: label);
      }
      expect(find.text('GENDER (OPTIONAL)'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('Submit with nothing filled in shows the messages and sends nothing', (
      tester,
    ) async {
      await openSignup(tester);
      expect(_submit(tester).onPressed, isNotNull);

      await _tapVisible(tester, find.widgetWithText(BrandGradientButton, 'Submit'));
      await harness.settle();

      for (final message in [
        'Enter 3 to 50 letters',
        'Open the Terms and Conditions first to turn this on',
      ]) {
        await tester.ensureVisible(find.text(message, skipOffstage: false));
        expect(find.text(message), findsOneWidget, reason: message);
      }
      expect(find.byType(SnackBar), findsNothing);
      verifyNever(() => harness.repository.completeSignup(any()));
      await harness.dispose();
    });

    testWidgets('a profile that fails to load shows a retry', (tester) async {
      harness = AppHarness(tester)..signedInAs(AccountStatus.signupPending);
      var calls = 0;
      when(() => harness.repository.fetchProfile()).thenAnswer((_) async {
        calls++;
        // The first call restores the session; the second is the form's own profile load.
        if (calls == 2) {
          throw const ApiError(type: ApiErrorType.network, message: 'offline');
        }
        return const UserProfile(
          userId: 'user-1',
          status: AccountStatus.signupPending,
          aadhaarVerified: false,
          mobile: '98****3210',
          email: 'a***@mail.com',
        );
      });
      await harness.launch();

      expect(find.byType(SignupProfileScreen), findsOneWidget);
      expect(find.text('Unable to connect — Retry'), findsWidgets);

      await _tapVisible(tester, find.text('Retry').first);
      await harness.settle();

      expect(find.text('a***@mail.com'), findsOneWidget);
      await harness.dispose();
    });
  });

  group('avatar', () {
    testWidgets('starts neutral and follows the chosen gender', (tester) async {
      await openSignup(tester);
      expect(tester.widget<AvatarImage>(find.byType(AvatarImage)).avatarId, 'avatar-09');

      await _tapVisible(tester, find.text('Male'));
      expect(tester.widget<AvatarImage>(find.byType(AvatarImage)).avatarId, 'avatar-01');

      await _tapVisible(tester, find.text('Female'));
      expect(tester.widget<AvatarImage>(find.byType(AvatarImage)).avatarId, 'avatar-05');
      await harness.dispose();
    });

    testWidgets('a picked avatar stays when the gender changes', (tester) async {
      await openSignup(tester);

      await tester.tap(find.byKey(const Key('avatarEdit')));
      await tester.pumpAndSettle();
      expect(find.text('Choose your avatar'), findsOneWidget);
      await tester.tap(find.byKey(const Key('avatar-avatar-07')));
      await tester.pumpAndSettle();

      expect(tester.widget<AvatarImage>(find.byType(AvatarImage)).avatarId, 'avatar-07');

      await _tapVisible(tester, find.text('Male'));
      expect(tester.widget<AvatarImage>(find.byType(AvatarImage)).avatarId, 'avatar-07');
      await harness.dispose();
    });
  });

  group('gender', () {
    testWidgets('offers Male, Female and Others, with none selected at first', (tester) async {
      await openSignup(tester);

      expect(tester.widget<GenderSelector>(find.byType(GenderSelector)).value, isNull);
      await _tapVisible(tester, find.text('Others'));

      expect(tester.widget<GenderSelector>(find.byType(GenderSelector)).value, Gender.others);
      await harness.dispose();
    });

    testWidgets('choosing the selected option again clears it and the neutral avatar returns', (
      tester,
    ) async {
      await openSignup(tester);

      await _tapVisible(tester, find.text('Female'));
      expect(tester.widget<AvatarImage>(find.byType(AvatarImage)).avatarId, 'avatar-05');
      await _tapVisible(tester, find.text('Female'));

      expect(tester.widget<GenderSelector>(find.byType(GenderSelector)).value, isNull);
      expect(tester.widget<AvatarImage>(find.byType(AvatarImage)).avatarId, 'avatar-09');
      await harness.dispose();
    });
  });

  group('name validation', () {
    testWidgets('shows a message for a bad name', (tester) async {
      await openSignup(tester);

      await _enter(tester, 'Your full name', 'A1');

      expect(find.text('Enter 3 to 50 letters'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a Devanagari name is accepted', (tester) async {
      await openSignup(tester);

      await _enter(tester, 'Your full name', 'आशा वर्मा');

      expect(find.text('Enter 3 to 50 letters'), findsNothing);
      await harness.dispose();
    });
  });

  group('terms', () {
    testWidgets('the locked hint uses the instruction colour and blinks when the toggle is tapped',
        (
      tester,
    ) async {
      await openSignup(tester);
      const hint = 'Open the Terms and Conditions first to turn this on';
      await tester.ensureVisible(find.byType(Switch));
      await tester.pump();

      expect(tester.widget<Text>(find.text(hint)).style?.color, AppColors.brandInstruction);
      double opacity() => tester
          .widget<Opacity>(find.ancestor(of: find.text(hint), matching: find.byType(Opacity)).first)
          .opacity;
      expect(opacity(), 1);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(opacity(), lessThan(1));

      await tester.pump(const Duration(seconds: 1));
      expect(opacity(), 1);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      await harness.dispose();
    });

    testWidgets('the toggle is locked until the Terms and Conditions were opened and closed', (
      tester,
    ) async {
      await openSignup(tester);
      await tester.ensureVisible(find.byType(Switch));

      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
      expect(find.text('Open the Terms and Conditions first to turn this on'), findsOneWidget);

      await openTermsAndClose(tester);

      expect(find.byType(SignupProfileScreen), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNotNull);
      expect(find.text('Open the Terms and Conditions first to turn this on'), findsNothing);
      await harness.dispose();
    });

    testWidgets('the template page lists numbered sections with placeholder text', (tester) async {
      await openSignup(tester);

      await _tapVisible(tester, find.text('Terms and Conditions'));
      await harness.settle();

      expect(find.text('Terms and Conditions'), findsWidgets);
      expect(find.text('Last updated: [date to be added]'), findsOneWidget);
      expect(find.text('1. Acceptance of terms'), findsOneWidget);
      expect(find.text('[Legal text to be added]'), findsWidgets);
      await harness.dispose();
    });
  });

  group('submit', () {
    testWidgets('sends the profile, stores the session and lands on Home', (tester) async {
      await openSignup(tester);
      when(() => harness.repository.completeSignup(any())).thenAnswer((_) async => _activeResult);

      await fillEverything(tester);
      expect(_submit(tester).onPressed, isNotNull);
      await _tapVisible(tester, find.widgetWithText(BrandGradientButton, 'Submit'));
      await harness.settle();

      final details = verify(() => harness.repository.completeSignup(captureAny())).captured.single
          as SignupDetails;
      expect(details.displayName, 'Asha Verma');
      expect(details.gender, Gender.female);
      expect(details.avatarId, 'avatar-05');
      expect(details.termsAccepted, isTrue);
      expect(details.consentGiven, isTrue);
      expect(details.termsVersion, 'template-0');
      final session = harness.container.read(sessionControllerProvider).value as Authenticated;
      expect(session.status, AccountStatus.active);
      expect(find.byType(HomeScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a user who leaves gender empty can sign up with the neutral avatar', (
      tester,
    ) async {
      await openSignup(tester);
      when(() => harness.repository.completeSignup(any())).thenAnswer((_) async => _activeResult);

      await fillEverything(tester, gender: null);
      await _tapVisible(tester, find.widgetWithText(BrandGradientButton, 'Submit'));
      await harness.settle();

      final details = verify(() => harness.repository.completeSignup(captureAny())).captured.single
          as SignupDetails;
      expect(details.gender, isNull);
      expect(details.avatarId, 'avatar-09');
      expect(find.byType(HomeScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('turning the terms switch off makes Submit ask for the terms again', (
      tester,
    ) async {
      await openSignup(tester);
      await fillEverything(tester);

      await _tapVisible(tester, find.byType(Switch));
      await _tapVisible(tester, find.widgetWithText(BrandGradientButton, 'Submit'));
      await harness.settle();

      expect(find.text('Accept the Terms and Conditions to continue'), findsOneWidget);
      verifyNever(() => harness.repository.completeSignup(any()));
      await harness.dispose();
    });

    testWidgets('a network failure shows the connection message', (tester) async {
      await openSignup(tester);
      when(() => harness.repository.completeSignup(any())).thenThrow(
        const ApiError(type: ApiErrorType.network, message: 'offline'),
      );
      await fillEverything(tester);

      await _tapVisible(tester, find.widgetWithText(BrandGradientButton, 'Submit'));
      await harness.settle();

      expect(find.text('Unable to connect — Retry'), findsWidgets);
      expect(find.byType(SignupProfileScreen), findsOneWidget);
      await harness.dispose();
    });
  });
}
