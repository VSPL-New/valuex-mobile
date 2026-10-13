import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../auth/domain/entities/logout_outcome.dart';
import '../../../auth/presentation/providers/registration_flow.dart';
import '../../../auth/presentation/providers/session_controller.dart';
import '../../../home/presentation/providers/home_providers.dart';

/// Logs out and clears what the next person on a shared device should not see: the Home
/// address and the half-finished registration state. It outlives the Profile page, which
/// is torn down as soon as the session ends.
class LogoutAction {
  final Ref _ref;

  LogoutAction(this._ref);

  Future<LogoutOutcome> call() async {
    final outcome = await _ref.read(sessionControllerProvider.notifier).logOut();
    await _ref.read(preferencesServiceProvider).remove(StorageKeys.homeLocation);
    _ref
      ..invalidate(homeLocationControllerProvider)
      ..invalidate(registrationFlowProvider);
    return outcome;
  }
}

final logoutActionProvider = Provider<LogoutAction>(LogoutAction.new);
