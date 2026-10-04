import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../../shared/widgets/brand_logo.dart';

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
      backgroundColor: AppColors.brandBackground,
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
                _ProgressBar(animation: _progressController),
                const SizedBox(height: 10),
                const Text(
                  'Initializing A1 Engine...',
                  style: AppTextStyles.splashProgressLabel,
                ),
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
                widthFactor: animation.value,
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

