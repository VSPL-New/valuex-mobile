import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How often the chat list and an open conversation ask the server for news while they are on
/// screen (LLD A.7 fallback; the realtime channel of US-130 will replace it). Null turns it off.
final chatPollIntervalProvider = Provider<Duration?>((ref) => const Duration(seconds: 15));
