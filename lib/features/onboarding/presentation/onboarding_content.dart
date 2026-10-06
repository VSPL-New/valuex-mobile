/// Image placement for the 4-screen onboarding carousel (Figma: Just Qlic).
/// Vertical values are in the 428x926 design frame; copy lives in the ARB files.
class OnboardingContent {
  final String backgroundAsset;
  final double imageTop;
  final double imageHeight;

  /// Where the white fade over the bottom of the image starts.
  final double fadeTop;

  const OnboardingContent({
    required this.backgroundAsset,
    required this.fadeTop,
    this.imageTop = -4,
    this.imageHeight = 655,
  });
}

const List<OnboardingContent> onboardingPages = [
  OnboardingContent(
    backgroundAsset: 'assets/images/onboarding_bg_1.png',
    fadeTop: 514,
  ),
  OnboardingContent(
    backgroundAsset: 'assets/images/onboarding_bg_2.png',
    fadeTop: 519,
  ),
  OnboardingContent(
    backgroundAsset: 'assets/images/onboarding_bg_3.png',
    fadeTop: 513,
  ),
  OnboardingContent(
    backgroundAsset: 'assets/images/onboarding_bg_4.png',
    imageTop: 0,
    imageHeight: 605,
    fadeTop: 512,
  ),
];
