import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

/// App launch screen (Figma: Just Qlic) — logo, animated progress bar, and
/// an auto-advance to onboarding once the progress animation completes.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _splashDuration = Duration(milliseconds: 2200);

  late final AnimationController _progressController;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _splashDuration,
    )..forward();
    _navigationTimer = Timer(_splashDuration, () {
      if (mounted) context.go(RouteNames.onboarding);
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _GradientBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 5),
                  Image.asset('assets/images/splash_logo.png', width: 229),
                  const SizedBox(height: 16),
                  const Text(
                    'Initializing A1 Engine...',
                    style: AppTextStyles.splashProgressLabel,
                  ),
                  const SizedBox(height: 12),
                  _ProgressBar(animation: _progressController),
                  const Spacer(flex: 4),
                  const Text(
                    'An Ayurvedic Clinic for your Clothes',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.splashTagline,
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Diagonal navy-to-lime wash anchored to the bottom of the screen.
class _GradientBackdrop extends StatelessWidget {
  const _GradientBackdrop();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.45,
        widthFactor: 1,
        child: Transform.rotate(
          angle: -0.36,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.splashGradientStart,
                  AppColors.splashGradientStart,
                  AppColors.splashGradientEnd,
                ],
                stops: [0.0, 0.92, 1.0],
              ),
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
    return SizedBox(
      width: 242,
      height: 7,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Stack(
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(color: AppColors.progressTrack),
              ),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: animation.value,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.progressGradientStart,
                        AppColors.progressGradientEnd,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

