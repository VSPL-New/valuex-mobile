import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../onboarding_content.dart';
import 'onboarding_dots.dart';
import 'onboarding_nav_button.dart';

/// Single onboarding slide: illustration with a white fade, then skip, copy,
/// page dots and back/next controls anchored to the bottom (Figma 428x926).
class OnboardingSlide extends StatelessWidget {
  static const _designWidth = 428.0;

  final OnboardingContent content;
  final String title;
  final String subtitle;
  final int dotIndex;
  final bool showBackButton;
  final VoidCallback onSkip;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const OnboardingSlide({
    super.key,
    required this.content,
    required this.title,
    required this.subtitle,
    required this.dotIndex,
    required this.showBackButton,
    required this.onSkip,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = media.size.width / _designWidth;
    // Design leaves 62px below the controls (includes the home indicator).
    final bottomPadding = math.max(62.0, media.padding.bottom + 24);
    final enlarged = media.textScaler.scale(16) > 16 * 1.15;

    return ColoredBox(
      color: AppColors.brandBackground,
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
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.brandBackground.withValues(alpha: 0),
                    AppColors.brandBackground.withValues(alpha: 0.27),
                    AppColors.brandBackground,
                    AppColors.brandBackground,
                  ],
                  stops: const [0, 0.120192, 0.269231, 1],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _TextBackdrop(
                  enlarged: enlarged,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 15),
                          child: _SkipButton(onTap: onSkip),
                        ),
                      ),
                      const SizedBox(height: 26),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(minHeight: 76, maxWidth: 342),
                                child: Center(
                                  child: Semantics(
                                    header: true,
                                    child: Text(
                                      title,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.heading1,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              ConstrainedBox(
                                constraints: const BoxConstraints(minHeight: 69, maxWidth: 322),
                                child: Center(
                                  child: Text(
                                    subtitle,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.onboardingSubtitle,
                                  ),
                                ),
                              ),
                            ],
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
                                label: AppLocalizations.of(context).commonBack,
                                radius: AppRadius.lg,
                                backgroundColor: AppColors.onboardingBackButton,
                                onPressed: onBack,
                              )
                            else
                              const SizedBox(width: AppSizes.minTouchTarget),
                            Expanded(
                              child: Center(
                                child: OnboardingDots(
                                  count: onboardingPages.length,
                                  activeDot: dotIndex,
                                ),
                              ),
                            ),
                            OnboardingNavButton(
                              label: AppLocalizations.of(context).commonNext,
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
            ),
          ),
        ],
      ),
    );
  }
}

/// Behind enlarged text the copy gets a solid backing that fades into the picture, so it never
/// sits on the illustration.
class _TextBackdrop extends StatelessWidget {
  static const _fade = 64.0;

  final bool enlarged;
  final Widget child;

  const _TextBackdrop({required this.enlarged, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!enlarged) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: -_fade,
          height: _fade,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.brandBackground.withValues(alpha: 0),
                    AppColors.brandBackground,
                  ],
                ),
              ),
            ),
          ),
        ),
        const Positioned.fill(child: ColoredBox(color: AppColors.brandBackground)),
        child,
      ],
    );
  }
}

class _SkipButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SkipButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    // The tinted pill is the drawing; the tap area is the full 48 dp height.
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).commonSkip,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSizes.minTouchTarget,
            minHeight: AppSizes.minTouchTarget,
          ),
          child: Center(
            widthFactor: 1,
            child: Material(
              color: AppColors.onboardingSkipBackground,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 64, minHeight: 31),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        AppLocalizations.of(context).commonSkip,
                        style: AppTextStyles.skipLabel,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
