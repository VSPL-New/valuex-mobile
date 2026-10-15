import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/app_config.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/providers/session_controller.dart';
import '../../features/auth/presentation/screens/aadhaar_dev_otp_screen.dart';
import '../../features/auth/presentation/screens/aadhaar_screen.dart';
import '../../features/auth/presentation/screens/account_blocked_screen.dart';
import '../../features/auth/presentation/screens/create_account_screen.dart';
import '../../features/auth/presentation/screens/google_mobile_screen.dart';
import '../../features/auth/presentation/screens/google_otp_screen.dart';
import '../../features/auth/presentation/screens/sign_in_mobile_screen.dart';
import '../../features/auth/presentation/screens/sign_in_otp_screen.dart';
import '../../features/auth/presentation/screens/signup_email_screen.dart';
import '../../features/auth/presentation/screens/signup_mobile_screen.dart';
import '../../features/auth/presentation/screens/signup_profile_screen.dart';
import '../../features/auth/presentation/screens/terms_screen.dart';
import '../../features/auth/presentation/screens/verify_email_otp_screen.dart';
import '../../features/auth/presentation/screens/verify_mobile_otp_screen.dart';
import '../../features/home/presentation/category_selection_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/account_security/domain/account_security.dart';
import '../../features/account_security/presentation/account_security_screen.dart';
import '../../features/account_security/presentation/change_contact_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/listing/presentation/create_listing_screen.dart';
import '../../features/profile/presentation/profile_details_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import 'route_guard.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final sessionChanged = ValueNotifier<int>(0);
  ref.listen(sessionControllerProvider, (previous, next) => sessionChanged.value++);
  ref.onDispose(sessionChanged.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: sessionChanged,
    redirect: (context, state) => redirectFor(
      session: ref.read(sessionControllerProvider),
      location: state.matchedLocation,
      aadhaarSandbox: ref.read(appConfigProvider).useAadhaarSandbox,
    ),
    routes: [
      GoRoute(
        path: RouteNames.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'details',
            name: 'profileDetails',
            builder: (context, state) => const ProfileDetailsScreen(),
          ),
          GoRoute(
            path: 'security',
            name: 'accountSecurity',
            builder: (context, state) => const AccountSecurityScreen(),
            routes: [
              GoRoute(
                path: 'mobile',
                name: 'changeMobile',
                builder: (context, state) => const ChangeContactScreen(kind: ContactKind.mobile),
              ),
              GoRoute(
                path: 'email',
                name: 'changeEmail',
                builder: (context, state) => const ChangeContactScreen(kind: ContactKind.email),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.createAccount,
        name: 'createAccount',
        builder: (context, state) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: RouteNames.signIn,
        name: 'signIn',
        builder: (context, state) => const SignInMobileScreen(),
      ),
      GoRoute(
        path: RouteNames.signInVerify,
        name: 'signInVerify',
        builder: (context, state) => const SignInOtpScreen(),
      ),
      GoRoute(
        path: RouteNames.googleMobile,
        name: 'googleMobile',
        builder: (context, state) => const GoogleMobileScreen(),
      ),
      GoRoute(
        path: RouteNames.googleVerify,
        name: 'googleVerify',
        builder: (context, state) => const GoogleOtpScreen(),
      ),
      GoRoute(
        path: RouteNames.signupMobile,
        name: 'signupMobile',
        // Sign In passes the typed number as `extra` when the account does not exist yet.
        builder: (context, state) => SignupMobileScreen(initialMobile: state.extra as String?),
      ),
      GoRoute(
        path: RouteNames.signupMobileVerify,
        name: 'signupMobileVerify',
        builder: (context, state) => const VerifyMobileOtpScreen(),
      ),
      GoRoute(
        path: RouteNames.signupEmail,
        name: 'signupEmail',
        builder: (context, state) => const SignupEmailScreen(),
      ),
      GoRoute(
        path: RouteNames.signupEmailVerify,
        name: 'signupEmailVerify',
        builder: (context, state) => const VerifyEmailOtpScreen(),
      ),
      GoRoute(
        path: RouteNames.signupAadhaar,
        name: 'signupAadhaar',
        builder: (context, state) => const AadhaarScreen(),
      ),
      GoRoute(
        path: RouteNames.devAadhaarOtp,
        name: 'devAadhaarOtp',
        builder: (context, state) => const AadhaarDevOtpScreen(),
      ),
      GoRoute(
        path: RouteNames.signupProfile,
        name: 'signupProfile',
        builder: (context, state) => const SignupProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.terms,
        name: 'terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: RouteNames.accountBlocked,
        name: 'accountBlocked',
        builder: (context, state) => const AccountBlockedScreen(),
      ),
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.categories,
        name: 'categories',
        builder: (context, state) => const CategorySelectionScreen(),
      ),
      GoRoute(
        path: RouteNames.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RouteNames.sell,
        name: 'sell',
        builder: (context, state) => const CreateListingScreen(),
      ),
    ],
  );
});
