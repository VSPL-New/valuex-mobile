import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../onboarding_content.dart';
import 'onboarding_dots.dart';
import 'onboarding_nav_button.dart';

/// Single onboarding slide: illustration with a white fade, then skip, copy,
/// page dots and back/next controls anchored to the bottom (Figma 428x926).
class OnboardingSlide extends StatelessWidget {
  static const _designWidth = 428.0;

  final OnboardingContent content;
  final int dotIndex;
  final bool highlightAllDots;
  final bool showBackButton;
  final VoidCallback onSkip;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const OnboardingSlide({
    super.key,
    required this.content,
    required this.dotIndex,
    required this.showBackButton,
    required this.onSkip,
    required this.onBack,
    required this.onNext,
    this.highlightAllDots = false,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = media.size.width / _designWidth;
    // Design leaves 62px below the controls (includes the home indicator).
    final bottomPadding = math.max(62.0, media.padding.bottom + 24);

    return ColoredBox(
      color: Colors.white,
      child: Stack(
        children: [
          Positioned(
            top: content.imageTop * scale,
            left: 0,
            right: 0,
            height: content.imageHeight * scale,
            child: Image.asset(
              content.backgroundAsset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned(
            top: content.fadeTop * scale,
            left: 0,
            right: 0,
            bottom: 0,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00FFFFFF),
                    Color(0x45FEFEFF),
                    Color(0xFFFDFEFF),
                    Color(0xFFFAFBFF),
                  ],
                  stops: [0, 0.120192, 0.269231, 1],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: _SkipButton(onTap: onSkip),
                    ),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: 342,
                    height: 76,
                    child: Center(
                      child: Text(
                        content.title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.onboardingTitle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: 322,
                    height: 69,
                    child: Center(
                      child: Text(
                        content.subtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.onboardingSubtitle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 17),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Row(
                      children: [
                        if (showBackButton)
                          OnboardingNavButton(
                            pointsBack: true,
                            radius: 12,
                            backgroundColor: AppColors.onboardingBackButton,
                            onPressed: onBack,
                          )
                        else
                          const SizedBox(width: 45),
                        Expanded(
                          child: Center(
                            child: OnboardingDots(
                              activeDot: dotIndex,
                              highlightAll: highlightAllDots,
                            ),
                          ),
                        ),
                        OnboardingNavButton(
                          backgroundColor: AppColors.onboardingNextButton,
                          onPressed: onNext,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
        child: const SizedBox(
          width: 64,
          height: 31,
          child: Center(child: Text('Skip', style: AppTextStyles.skipLabel)),
        ),
      ),
    );
  }
}
