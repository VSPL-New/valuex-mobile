import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/providers/session_controller.dart';
import '../../features/auth/presentation/screens/account_blocked_screen.dart';
import '../../features/auth/presentation/screens/create_account_screen.dart';
import '../../features/auth/presentation/screens/signup_mobile_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import 'route_guard.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final sessionChanged = ValueNotifier<int>(0);
  ref.listen(
      sessionControllerProvider, (previous, next) => sessionChanged.value++);
  ref.onDispose(sessionChanged.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: sessionChanged,
    redirect: (context, state) => redirectFor(
      session: ref.read(sessionControllerProvider),
      location: state.matchedLocation,
    ),
    routes: [
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
        path: RouteNames.signupMobile,
        name: 'signupMobile',
        builder: (context, state) => const SignupMobileScreen(),
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
    ],
  );
});
