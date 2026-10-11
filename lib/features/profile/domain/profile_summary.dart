/// Seller and plan figures shown on the Profile page. Backed by mock data until the ratings,
/// orders, listings and subscription stories supply real values.
class ProfileSummary {
  final double rating;
  final int transactions;
  final int listings;
  final int sold;
  final bool isPremium;
  final String planName;

  const ProfileSummary({
    required this.rating,
    required this.transactions,
    required this.listings,
    required this.sold,
    required this.isPremium,
    required this.planName,
  });
}
