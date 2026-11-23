import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../l10n/app_localizations.dart';
import '../../communication_safety/domain/communication_safety.dart';
import '../../communication_safety/presentation/widgets/report_sheet.dart';
import '../data/call_permissions.dart';
import '../domain/call.dart';
import 'call_starter.dart';
import 'providers/call_controller.dart';
import 'widgets/call_views.dart';
import 'widgets/video_call_view.dart';

/// One call: ringing, in progress and ended, on a single screen that follows the server's state
/// (US-014, US-015). The back button does nothing while the call is live: End, Cancel and Decline
/// are the ways out, so the server always knows.
class CallScreen extends ConsumerWidget {
  final String callId;

  const CallScreen({super.key, required this.callId});

  static bool _terminal(CallPhase phase) => phase == CallPhase.ended || phase == CallPhase.failed;

  /// A call the person ended themselves closes the screen at once; nothing more to say.
  static bool _closesItself(CallSession call) =>
      (call.endReason == CallEndReason.cancelled && call.outgoing) ||
      (call.endReason == CallEndReason.declined && !call.outgoing);

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.home);
    }
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(callControllerProvider(callId).notifier).accept();
    if (!context.mounted || result == CallPermissionResult.granted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(callPermissionMessage(l10n, result)),
          action: SnackBarAction(
            label: l10n.callOpenSettings,
            onPressed: ref.read(callPermissionsProvider).openSettings,
          ),
        ),
      );
  }

  Future<void> _report(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final sent = await showReportSheet(context, target: ReportTarget.call, targetId: callId);
    if (!sent) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.reportDone)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = callControllerProvider(callId);
    final controller = ref.read(provider.notifier);
    final state = ref.watch(provider);
    ref.listen(provider, (previous, next) {
      final call = next.call;
      if (next.phase == CallPhase.ended &&
          previous?.phase != CallPhase.ended &&
          call != null &&
          _closesItself(call)) {
        _close(context);
      }
    });
    final now = ref.watch(callTickProvider).value ?? DateTime.now();
    final call = state.call;
    final video = state.isVideo &&
        (state.phase == CallPhase.joining ||
            state.phase == CallPhase.active ||
            state.phase == CallPhase.reconnecting);

    final Widget body;
    if (call == null && state.phase == CallPhase.failed) {
      body = CallProblemView(message: l10n.callErrorLoad, onClose: () => _close(context));
    } else if (call == null) {
      body = const Center(child: LoadingIndicator());
    } else {
      body = switch (state.phase) {
        CallPhase.loading => const Center(child: LoadingIndicator()),
        CallPhase.ringingOut || CallPhase.ringingIn => RingingView(
            state: state,
            onAccept: () => _accept(context, ref),
            onDecline: controller.decline,
            onCancel: controller.cancel,
          ),
        CallPhase.joining || CallPhase.active || CallPhase.reconnecting when video => VideoCallView(
            state: state,
            now: now,
            remote: ref.watch(callRtcClientProvider(callId)).remoteVideo(),
            local: ref.watch(callRtcClientProvider(callId)).localVideo(),
            onMute: controller.toggleMute,
            onCamera: controller.toggleCamera,
            onFlip: controller.flipCamera,
            onSpeaker: controller.toggleSpeaker,
            onEnd: controller.hangUp,
            onReport: () => _report(context),
            onTurnOffVideo: controller.turnOffVideo,
          ),
        CallPhase.joining || CallPhase.active || CallPhase.reconnecting => VoiceCallView(
            state: state,
            now: now,
            onMute: controller.toggleMute,
            onSpeaker: controller.toggleSpeaker,
            onEnd: controller.hangUp,
            onReport: () => _report(context),
          ),
        CallPhase.ended => EndedView(
            call: call,
            onClose: () => _close(context),
            onReport: () => _report(context),
          ),
        CallPhase.failed => CallProblemView(
            message:
                state.error is ApiError ? callErrorMessage(l10n, state.error!) : l10n.callErrorJoin,
            onClose: () => _close(context),
          ),
      };
    }

    return PopScope(
      canPop: _terminal(state.phase) || call == null,
      child: Scaffold(
        backgroundColor: video ? AppColors.brandForeground : null,
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: video ? null : AppGradients.brand),
          child: SafeArea(child: body),
        ),
      ),
    );
  }
}
