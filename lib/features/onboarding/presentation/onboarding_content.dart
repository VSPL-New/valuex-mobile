/// Static copy and image placement for the 4-screen onboarding carousel
/// (Figma: Just Qlic). Vertical values are in the 428x926 design frame.
class OnboardingContent {
  final String backgroundAsset;
  final String title;
  final String subtitle;
  final double imageTop;
  final double imageHeight;

  /// Where the white fade over the bottom of the image starts.
  final double fadeTop;

  const OnboardingContent({
    required this.backgroundAsset,
    required this.title,
    required this.subtitle,
    required this.fadeTop,
    this.imageTop = -4,
    this.imageHeight = 655,
  });
}

const List<OnboardingContent> onboardingPages = [
  OnboardingContent(
    backgroundAsset: 'assets/images/onboarding_bg_1.png',
    title: 'JustQlic Makes Selling Simple',
    subtitle:
        'Snap your item and let AI create the listing, suggest details, '
        'and help you sell faster.',
    fadeTop: 514,
  ),
  OnboardingContent(
    backgroundAsset: 'assets/images/onboarding_bg_2.png',
    title: 'JustQlic Helps You\nFind',
    subtitle:
        'Upload or snap a photo to instantly discover the same or '
        'similar products available to buy.',
    fadeTop: 519,
  ),
  OnboardingContent(
    backgroundAsset: 'assets/images/onboarding_bg_3.png',
    title: 'Real People, Safer & Smarter Deals',
    subtitle:
        'Verified users, ratings, and smart fraud protection help make '
        'every deal safer and more reliable.',
    fadeTop: 513,
  ),
  OnboardingContent(
    backgroundAsset: 'assets/images/onboarding_bg_4.png',
    title: 'Pay Safe, Sell Safe & Secure',
    subtitle:
        'Your payment stays protected while you complete the transaction\n'
        'with confidence.',
    imageTop: 0,
    imageHeight: 605,
    fadeTop: 512,
  ),
];
