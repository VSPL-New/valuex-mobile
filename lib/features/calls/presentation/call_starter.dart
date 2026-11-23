import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../../../core/routing/route_names.dart';
import '../../../l10n/app_localizations.dart';
import '../../chat/presentation/contact_error_messages.dart';
import '../data/call_permissions.dart';
import '../domain/call.dart';
import 'providers/call_launcher.dart';

/// The text for a call that could not start or go on (US-014, US-015 error scenarios). Codes shared
/// with chat (a block, an unavailable seller, the rate limit) use the chat text.
String callErrorMessage(AppLocalizations l10n, Object error) {
  if (error is ApiError) {
    return switch (error.code) {
      'ERROR_CALLS_UNAVAILABLE' => l10n.callErrorUnavailable,
      'ERROR_CALL_IN_PROGRESS' => l10n.callErrorInProgress,
      'ERROR_USER_BUSY' => l10n.callErrorBusy,
      'ERROR_CALL_FAILED' => l10n.callErrorJoin,
      _ => contactErrorMessage(l10n, error),
    };
  }
  return contactErrorMessage(l10n, error);
}

/// The text for a refused permission, and whether the phone's settings are the only way to change it.
String callPermissionMessage(AppLocalizations l10n, CallPermissionResult result) =>
    result == CallPermissionResult.cameraDenied ? l10n.callErrorCamera : l10n.callErrorMicrophone;

/// Starts a voice or video call about [listingId] and opens the call screen (US-014, US-015). The
/// permissions come first; a refusal or an error shows a message and nothing is created.
Future<void> startCall(
  BuildContext context,
  WidgetRef ref, {
  required String listingId,
  required CallType type,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final permissions = ref.read(callPermissionsProvider);
  final result = await ref.read(callLauncherProvider.notifier).start(listingId, type: type);
  if (!context.mounted) return;
  final callId = result.callId;
  if (callId != null) {
    await context.push(RouteNames.call(callId));
    return;
  }
  final refused = result.permission;
  final error = result.error;
  if (refused != null) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(callPermissionMessage(l10n, refused)),
          action: SnackBarAction(label: l10n.callOpenSettings, onPressed: permissions.openSettings),
        ),
      );
  } else if (error != null) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(callErrorMessage(l10n, error))));
  }
}
