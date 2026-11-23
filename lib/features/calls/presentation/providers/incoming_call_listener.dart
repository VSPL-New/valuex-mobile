import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/realtime_event.dart';
import '../../../../core/realtime/realtime_providers.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/route_names.dart';

/// Opens the incoming call screen when the server rings this phone over the live connection (US-014,
/// US-015). A call the phone already shows, or one it saw before, is not opened twice. When the app is
/// closed the push does the same through its deep link. Watched once, by the app.
final incomingCallProvider = Provider<void>((ref) {
  final seen = <String>{};
  final subscription = ref.watch(callEventsProvider).listen((event) {
    if (event.type != RealtimeTypes.callIncoming) return;
    final callId = event.data['callId'];
    if (callId is! String || !seen.add(callId)) return;
    final router = ref.read(appRouterProvider);
    final open = router.routerDelegate.currentConfiguration.uri.path;
    if (open == RouteNames.call(callId)) return;
    unawaited(router.push<void>(RouteNames.call(callId)));
  });
  ref.onDispose(subscription.cancel);
});
