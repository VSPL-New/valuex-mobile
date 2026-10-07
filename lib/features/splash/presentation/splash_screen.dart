import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_guard.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/api_error_messages.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/presentation/providers/session_controller.dart';
import '../../../l10n/app_localizations.dart';

/// App launch screen (Figma: Just Qlic) — logo and animated progress bar. Once the
/// animation completes and the stored session is resolved, it opens the screen that
/// matches the account state (onboarding when signed out).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  static const _splashDuration = Duration(milliseconds: 2200);

  late final AnimationController _progressController;
  Timer? _navigationTimer;
  bool _animationDone = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _splashDuration,
    )..forward();
    _navigationTimer = Timer(_splashDuration, () {
      if (!mounted) return;
      setState(() => _animationDone = true);
      _openNextScreen();
    });
    ref.listenManual(sessionControllerProvider, (previous, next) => _openNextScreen());
  }

  void _openNextScreen() {
    if (!mounted || _navigated || !_animationDone) return;
    final session = ref.read(sessionControllerProvider).value;
    if (session == null) return;
    _navigated = true;
    context.go(startRouteFor(session));
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionError = ref.watch(sessionControllerProvider).error;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo size follows the Figma splash frame.
                const BrandLogo(width: 229, height: 92, fit: BoxFit.cover),
                const SizedBox(height: 23),
                if (sessionError != null && _animationDone)
                  ErrorView(
                    message: apiErrorMessage(
                      AppLocalizations.of(context),
                      sessionError is ApiError
                          ? sessionError
                          : const ApiError(type: ApiErrorType.unknown, message: ''),
                    ),
                    onRetry: () => ref.invalidate(sessionControllerProvider),
                  )
                else ...[
                  _ProgressBar(animation: _progressController),
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context).splashInitializing,
                    style: AppTextStyles.splashProgressLabel,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final Animation<double> animation;

  const _ProgressBar({required this.animation});

  @override
  Widget build(BuildContext context) {
    // With reduce motion on, show the bar full instead of animating it.
    final still = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      width: 242,
      height: 7,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(color: AppColors.brandMuted),
              ),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: still ? 1 : animation.value,
                child: const DecoratedBox(
                  decoration: BoxDecoration(gradient: AppGradients.brand),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
