import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/provider_retry.dart';
import '../../data/listing_view_repository.dart';
import '../../domain/public_listing.dart';

/// A listing as a buyer sees it. Auto-dispose, so it is loaded again on every open and a failure
/// shows a Retry button instead of retrying silently.
final publicListingProvider = FutureProvider.autoDispose.family<PublicListing, String>(
  (ref, listingId) => ref.watch(listingViewRepositoryProvider).view(listingId),
  retry: noAutoRetry,
);

final sellerReviewsProvider = FutureProvider.autoDispose.family<SellerReviews, String>(
  (ref, sellerId) => ref.watch(listingViewRepositoryProvider).sellerReviews(sellerId),
  retry: noAutoRetry,
);
