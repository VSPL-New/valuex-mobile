import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/session_controller.dart';
import '../providers/session_state.dart';

/// Tells the user their session ended and returns them to the start of sign-in.
class SessionExpiryListener extends ConsumerWidget {
  final Widget child;

  const SessionExpiryListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sessionControllerProvider, (previous, next) {
      final state = next.value;
      if (state is! Unauthenticated || !state.sessionExpired) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).errorSessionExpired)),
        );
      ref.read(appRouterProvider).go(RouteNames.signIn);
    });
    return child;
  }
}
