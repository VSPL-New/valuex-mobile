import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../l10n/app_localizations.dart';
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

  void _finish() => context.go(RouteNames.createAccount);

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
    final l10n = AppLocalizations.of(context);
    final titles = [
      l10n.onboardingTitle1,
      l10n.onboardingTitle2,
      l10n.onboardingTitle3,
      l10n.onboardingTitle4,
    ];
    final subtitles = [
      l10n.onboardingSubtitle1,
      l10n.onboardingSubtitle2,
      l10n.onboardingSubtitle3,
      l10n.onboardingSubtitle4,
    ];

    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        itemCount: onboardingPages.length,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemBuilder: (context, index) {
          return OnboardingSlide(
            content: onboardingPages[index],
            title: titles[index],
            subtitle: subtitles[index],
            dotIndex: index,
            showBackButton: index > 0,
            onSkip: _finish,
            onBack: _back,
            onNext: _next,
          );
        },
      ),
    );
  }
}
