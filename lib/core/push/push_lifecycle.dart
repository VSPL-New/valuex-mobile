import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/account_active_provider.dart';
import '../../features/notifications/domain/notification_deep_links.dart';
import '../../features/settings/presentation/providers/locale_controller.dart';
import '../routing/app_router.dart';
import 'push_providers.dart';
import 'push_service.dart';

/// Opens the screen of a tapped notification. A repeated tap on the same event is ignored, and a
/// link the app cannot open (unknown, or needing a listing to load first) does nothing.
class PushTapHandler {
  static const int _remembered = 20;

  final void Function(NotificationTarget target) _open;
  final List<String> _seen = [];

  PushTapHandler(this._open);

  void handle(PushTap tap) {
    final id = tap.eventId;
    if (id != null) {
      if (_seen.contains(id)) return;
      _seen.add(id);
      if (_seen.length > _remembered) _seen.removeAt(0);
    }
    final target = notificationTargetFor(tap.deepLink);
    if (target == null || target.needsListing) return;
    _open(target);
  }
}

/// Registers the phone while the account is active, follows token and language changes, routes taps
/// on notifications, and drops the token when the person signs out. Watched once, by the app.
final pushLifecycleProvider = Provider<void>((ref) {
  final service = ref.watch(pushServiceProvider);
  final registration = ref.watch(pushRegistrationProvider);
  final handler = PushTapHandler((target) {
    final router = ref.read(appRouterProvider);
    if (target.isTab) {
      router.go(target.route);
    } else {
      unawaited(router.push<void>(target.route));
    }
  });

  final subscriptions = [
    service.tokenChanges.listen((_) {
      if (ref.read(accountActiveProvider)) unawaited(registration.sync());
    }),
    service.taps.listen(handler.handle),
  ];
  ref.onDispose(() {
    for (final subscription in subscriptions) {
      unawaited(subscription.cancel());
    }
  });

  ref.listen<bool>(accountActiveProvider, (previous, active) {
    if (active) {
      unawaited(registration.sync());
      unawaited(_openInitialTap(service, handler));
    } else if (previous == true) {
      unawaited(registration.forget());
    }
  }, fireImmediately: true);

  ref.listen(localeControllerProvider, (previous, next) {
    if (ref.read(accountActiveProvider)) unawaited(registration.sync());
  });
});

/// The notification that started the app from a closed state, opened once the account is active.
Future<void> _openInitialTap(PushService service, PushTapHandler handler) async {
  final tap = await service.initialTap();
  if (tap != null) handler.handle(tap);
}
