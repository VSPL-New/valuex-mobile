import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import 'onboarding_content.dart';
import 'widgets/onboarding_slide.dart';

/// 4-screen onboarding carousel shown after the splash screen.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() => context.go(RouteNames.home);

  void _next() {
    if (_currentPage == onboardingPages.length - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _back() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        itemCount: onboardingPages.length,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemBuilder: (context, index) {
          final isLastPage = index == onboardingPages.length - 1;
          return OnboardingSlide(
            content: onboardingPages[index],
            dotIndex: index < 2 ? index : 2,
            highlightAllDots: isLastPage,
            showBackButton: index > 0,
            isLastPage: isLastPage,
            onSkip: _finish,
            onBack: _back,
            onNext: _next,
          );
        },
      ),
    );
  }
}
