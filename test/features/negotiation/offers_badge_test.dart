import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/realtime/realtime_event.dart';
import 'package:valuex_mobile/core/realtime/realtime_providers.dart';
import 'package:valuex_mobile/features/negotiation/presentation/providers/offers_badge_provider.dart';
import 'package:valuex_mobile/features/profile/data/profile_repository.dart';
import 'package:valuex_mobile/features/profile/domain/profile_menu_badges.dart';

import '../../core/realtime/realtime_fakes.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late _MockProfileRepository profile;
  late FakeRealtimeClient realtime;

  ProviderContainer container() {
    final value = ProviderContainer(overrides: [
      profileRepositoryProvider.overrideWithValue(profile),
      realtimeClientProvider.overrideWithValue(realtime),
    ]);
    addTearDown(value.dispose);
    return value;
  }

  Future<ProviderContainer> started() async {
    final c = container();
    c.listen(offersBadgeProvider, (previous, next) {});
    await c.read(offersBadgeProvider.future);
    return c;
  }

  setUp(() {
    profile = _MockProfileRepository();
    realtime = FakeRealtimeClient();
    when(() => profile.menuBadges())
        .thenAnswer((_) async => const ProfileMenuBadges({ProfileMenuKeys.offers: 3}));
  });

  test('starts from the offers count of the profile menu summary', () async {
    final c = await started();

    expect(c.read(offersBadgeProvider).value, 3);
  });

  test('is zero when the summary has no offers key', () async {
    when(() => profile.menuBadges()).thenAnswer((_) async => const ProfileMenuBadges());

    final c = await started();

    expect(c.read(offersBadgeProvider).value, 0);
  });

  test('follows badge.updated events, down to zero', () async {
    final c = await started();

    realtime.emit(RealtimeTypes.badgeUpdated, {'offersAwaiting': 5});
    await Future<void>.delayed(Duration.zero);
    expect(c.read(offersBadgeProvider).value, 5);

    realtime.emit(RealtimeTypes.badgeUpdated, {'offersAwaiting': 0});
    await Future<void>.delayed(Duration.zero);
    expect(c.read(offersBadgeProvider).value, 0);
  });

  test('ignores a badge event without a count and events of other types', () async {
    final c = await started();

    realtime.emit(RealtimeTypes.badgeUpdated, {'chatsUnread': 2});
    realtime.emit(RealtimeTypes.negotiationUpdated, {'offersAwaiting': 9});
    await Future<void>.delayed(Duration.zero);

    expect(c.read(offersBadgeProvider).value, 3);
  });

  test('reads the summary again after a reconnect and keeps the count when that fails', () async {
    final c = await started();
    when(() => profile.menuBadges())
        .thenAnswer((_) async => const ProfileMenuBadges({ProfileMenuKeys.offers: 7}));

    c.read(realtimeResyncProvider.notifier).bump();
    await Future<void>.delayed(Duration.zero);
    expect(c.read(offersBadgeProvider).value, 7);

    when(() => profile.menuBadges())
        .thenThrow(const ApiError(type: ApiErrorType.network, message: 'offline'));
    c.read(realtimeResyncProvider.notifier).bump();
    await Future<void>.delayed(Duration.zero);
    expect(c.read(offersBadgeProvider).value, 7);
  });
}
