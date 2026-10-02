/// Static copy for the 4-screen onboarding carousel (Figma: Just Qlic).
class OnboardingContent {
  final String backgroundAsset;
  final String title;
  final String subtitle;

  const OnboardingContent({
    required this.backgroundAsset,
    required this.title,
    required this.subtitle,
  });
}

const List<OnboardingContent> onboardingPages = [
  OnboardingContent(
    backgroundAsset: 'assets/images/onboarding_bg_1.png',
    title: 'JustQlic Makes Selling Simple',
    subtitle:
        'Snap your item and let AI create the listing, suggest details, '
        'and help you sell faster.',
  ),
  OnboardingContent(
    backgroundAsset: 'assets/images/onboarding_bg_2.png',
    title: 'JustQlic Helps You Find',
    subtitle:
        'Upload or snap a photo to instantly discover the same or '
        'similar products available to buy.',
  ),
  OnboardingContent(
    backgroundAsset: 'assets/images/onboarding_bg_3.png',
    title: 'Real People, Safer & Smarter Deals',
    subtitle:
        'Verified users, ratings, and smart fraud protection help make '
        'every deal safer and more reliable.',
  ),
  OnboardingContent(
    backgroundAsset: 'assets/images/onboarding_bg_4.png',
    title: 'Pay Safe, Sell Safe & Secure',
    subtitle:
        'Your payment stays protected while you complete the transaction '
        'with confidence.',
  ),
];
