import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/realtime/realtime_event.dart';
import '../../../../core/realtime/realtime_providers.dart';
import '../../../../core/utils/provider_retry.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/domain/profile_menu_badges.dart';

/// The number on the Offers row of the Profile (US-076): offers waiting for the person's answer, as
/// seller and as buyer. It starts from the profile menu summary and follows `badge.updated` events,
/// so an open Profile page changes without a refresh. The summary is read again after a reconnect.
class OffersBadgeController extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    ref.listen<int>(realtimeResyncProvider, (previous, next) => unawaited(_reread()));
    final events = ref.watch(badgeEventsProvider).listen(_onEvent);
    ref.onDispose(events.cancel);
    final badges = await ref.watch(profileMenuBadgesProvider.future);
    return badges.count(ProfileMenuKeys.offers);
  }

  void _onEvent(RealtimeEvent event) {
    if (event.type != RealtimeTypes.badgeUpdated) return;
    final count = event.data['offersAwaiting'];
    if (count is num) state = AsyncData(count.toInt());
  }

  Future<void> _reread() async {
    try {
      final badges = await ref.refresh(profileMenuBadgesProvider.future);
      if (ref.mounted) state = AsyncData(badges.count(ProfileMenuKeys.offers));
    } on Object {
      // The count on screen stays until the next event.
    }
  }
}

final offersBadgeProvider = AsyncNotifierProvider.autoDispose<OffersBadgeController, int>(
  OffersBadgeController.new,
  retry: noAutoRetry,
);
