import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../onboarding_content.dart';
import 'onboarding_dots.dart';
import 'onboarding_nav_button.dart';

/// Single onboarding slide: full-bleed illustration with the skip action,
/// copy, page dots, and back/next controls laid over it.
class OnboardingSlide extends StatelessWidget {
  final OnboardingContent content;
  final int dotIndex;
  final bool highlightAllDots;
  final bool showBackButton;
  final bool isLastPage;
  final VoidCallback onSkip;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const OnboardingSlide({
    super.key,
    required this.content,
    required this.dotIndex,
    required this.showBackButton,
    required this.isLastPage,
    required this.onSkip,
    required this.onBack,
    required this.onNext,
    this.highlightAllDots = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(content.backgroundAsset, fit: BoxFit.cover),
        SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20, top: 8),
                  child: _SkipButton(onTap: onSkip),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      content.title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.onboardingTitle,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      content.subtitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.onboardingSubtitle,
                    ),
                    const SizedBox(height: 24),
                    OnboardingDots(
                      activeDot: dotIndex,
                      highlightAll: highlightAllDots,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (showBackButton)
                          OnboardingNavButton(
                            icon: Icons.arrow_back,
                            backgroundColor: AppColors.onboardingBackButton,
                            onPressed: onBack,
                          )
                        else
                          const SizedBox(width: 45),
                        const Spacer(),
                        OnboardingNavButton(
                          icon: isLastPage
                              ? Icons.check
                              : Icons.arrow_forward,
                          backgroundColor: AppColors.onboardingNextButton,
                          onPressed: onNext,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkipButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SkipButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.onboardingSkipBackground,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('Skip', style: AppTextStyles.skipLabel),
        ),
      ),
    );
  }
}
