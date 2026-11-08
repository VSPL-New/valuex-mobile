import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/provider_retry.dart';
import '../../data/listing_repository.dart';
import '../../domain/listing_preview.dart';

/// The owner's preview of one listing (US-123). It reads only; auto-dispose drops the private
/// content as soon as the screen is left. A failure shows a Retry button, not a silent retry.
final listingPreviewProvider = FutureProvider.autoDispose.family<ListingPreviewData, String>(
  (ref, listingId) => ref.watch(listingRepositoryProvider).getListingPreview(listingId),
  retry: noAutoRetry,
);

/// A short-lived link to one photo of the preview, fetched when the photo is shown.
final listingPhotoLinkProvider = FutureProvider.autoDispose.family<PhotoLink, String>(
  (ref, mediaId) => ref.watch(listingRepositoryProvider).photoLink(mediaId),
  retry: noAutoRetry,
);
