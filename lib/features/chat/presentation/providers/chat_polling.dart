import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/realtime/realtime_event.dart';
import '../../../../core/realtime/realtime_providers.dart';

/// How often the chat list and an open conversation ask the server for news while they are on
/// screen: every 15 seconds while the live connection is down (LLD A.7 fallback), never while it is
/// connected, because events and the re-read after each reconnect cover it (US-130). Tests turn
/// polling off by overriding this with null.
final chatPollIntervalProvider = Provider<Duration?>((ref) {
  final connected = ref.watch(realtimeStatusProvider) == RealtimeStatus.connected;
  return connected ? null : const Duration(seconds: 15);
});
