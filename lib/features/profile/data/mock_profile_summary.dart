import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/profile_summary.dart';

/// MOCK: the figures from the Figma Make profile. Replace this provider with real data from
/// ratings (rating, transactions), My Listings and orders (listings, sold) and the
/// subscription story (isPremium, planName) when those exist; the screen needs no change.
final profileSummaryProvider = Provider<ProfileSummary>(
  (ref) => const ProfileSummary(
    rating: 4.8,
    transactions: 32,
    listings: 8,
    sold: 24,
    isPremium: false,
    planName: 'Vision Plan',
  ),
);
