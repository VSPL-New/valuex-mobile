import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/widgets/brand_bottom_nav.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/providers/session_controller.dart';
import '../../auth/presentation/providers/session_state.dart';

/// Passing message for screens that are not built yet.
void showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).homeFeatureComingSoon)));
}

/// Handles a tap on the main navigation from the tab [current].
void onMainNavSelected(
  BuildContext context,
  WidgetRef ref, {
  required BottomNavItem current,
  required BottomNavItem item,
}) {
  if (item == current) return;
  switch (item) {
    case BottomNavItem.home:
      context.go(RouteNames.home);
    case BottomNavItem.profile:
      context.go(RouteNames.profile);
    case BottomNavItem.sell:
      final session = ref.read(sessionControllerProvider).value;
      if (session is! Authenticated) {
        context.go(RouteNames.createAccount);
        return;
      }
      unawaited(context.push(RouteNames.sell));
    case BottomNavItem.search || BottomNavItem.chats:
      showComingSoon(context);
  }
}
