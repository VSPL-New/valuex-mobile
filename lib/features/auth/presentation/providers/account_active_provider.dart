import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/account_status.dart';
import 'session_controller.dart';
import 'session_state.dart';

/// True while the user is signed in with an active account: the only time the live connection and
/// push registration are wanted.
final accountActiveProvider = Provider<bool>((ref) {
  final state = ref.watch(sessionControllerProvider).value;
  return state is Authenticated && state.status == AccountStatus.active;
});
