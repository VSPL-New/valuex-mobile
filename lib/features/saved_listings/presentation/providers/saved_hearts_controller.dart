import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/saved_listings_repository.dart';
import '../../domain/saved_listing.dart';
import 'saved_items_controller.dart';

/// What a tap on a heart did.
enum SaveHeartStatus { saved, removed, limitReached, unavailable, failed }

class SaveHeartOutcome {
  final SaveHeartStatus status;

  /// The allowed number of saved items, for [SaveHeartStatus.limitReached] when the server said.
  final int? max;

  const SaveHeartOutcome(this.status, {this.max});

  bool get failed => status != SaveHeartStatus.saved && status != SaveHeartStatus.removed;
}

/// The hearts on cards and on the listing page. The server's `saved` flag is where each heart
/// starts; a tap is shown at once and put back if the server refuses, and every heart of the same
/// listing follows it, so a card on Home and the listing page never disagree.
class SavedHeartsController extends Notifier<Map<String, bool>> {
  final Set<String> _busy = {};

  @override
  Map<String, bool> build() => const {};

  /// Flips the heart of [listingId], which is [currentlySaved] now. Null while a request for the
  /// same listing is still running, so rapid taps send one request.
  Future<SaveHeartOutcome?> toggle(String listingId, {required bool currentlySaved}) async {
    if (!_busy.add(listingId)) return null;
    _set(listingId, !currentlySaved);
    try {
      final repository = ref.read(savedListingsRepositoryProvider);
      if (currentlySaved) {
        await repository.remove(listingId);
      } else {
        await repository.save(listingId);
      }
      ref.invalidate(savedItemsControllerProvider);
      return SaveHeartOutcome(currentlySaved ? SaveHeartStatus.removed : SaveHeartStatus.saved);
    } on SavedListingLimitReached catch (limit) {
      _set(listingId, currentlySaved);
      return SaveHeartOutcome(SaveHeartStatus.limitReached, max: limit.max);
    } on SavedListingUnavailable {
      _set(listingId, false);
      return const SaveHeartOutcome(SaveHeartStatus.unavailable);
    } on Object {
      _set(listingId, currentlySaved);
      return const SaveHeartOutcome(SaveHeartStatus.failed);
    } finally {
      _busy.remove(listingId);
    }
  }

  /// Saved Items removed the listing: every heart for it shows not saved.
  void markRemoved(String listingId) => _set(listingId, false);

  void _set(String listingId, bool saved) {
    if (!ref.mounted) return;
    state = {...state, listingId: saved};
  }
}

final savedHeartsProvider = NotifierProvider<SavedHeartsController, Map<String, bool>>(
  SavedHeartsController.new,
);
