import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../chat/presentation/widgets/chat_avatar.dart';
import '../../data/rtc/rtc_client.dart';
import '../../domain/call.dart';
import '../../domain/call_time.dart';
import '../providers/call_controller.dart';
import 'call_controls.dart';

/// Who is on the other end: avatar, name, the listing and the information line that the call is not
/// recorded. Shared by the ringing, the voice and the ended views.
class CallIdentity extends StatelessWidget {
  final CallSession call;
  final String status;
  final String? timer;

  const CallIdentity({super.key, required this.call, required this.status, this.timer});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final initial = call.counterpartName.isEmpty ? '?' : call.counterpartName.characters.first;
    final title = call.listingTitle;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChatAvatar(initial: initial.toUpperCase(), size: 112, circle: true),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: Text(
            call.counterpartName,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading2.copyWith(color: AppColors.brandOnPrimary),
          ),
        ),
        if (title != null && title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              l10n.callAboutListing(title),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(color: AppColors.brandOnPrimary),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          liveRegion: true,
          child: Text(
            status,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.brandOnPrimary),
          ),
        ),
        if (timer != null)
          Semantics(
            label: l10n.callDuration(timer!),
            excludeSemantics: true,
            child: Text(
              timer!,
              style: AppTextStyles.heading1.copyWith(color: AppColors.brandOnPrimary),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        CallChip(label: l10n.callNotRecorded, icon: Icons.mic_none_rounded),
      ],
    );
  }
}

/// A row of controls that wraps on a narrow phone or a large text size instead of overflowing.
class CallControlRow extends StatelessWidget {
  final List<Widget> children;

  const CallControlRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: children,
      ),
    );
  }
}

String qualityLabel(AppLocalizations l10n, RtcQuality quality) => switch (quality) {
      RtcQuality.excellent => l10n.callQualityExcellent,
      RtcQuality.good => l10n.callQualityGood,
      RtcQuality.poor => l10n.callQualityPoor,
      RtcQuality.lost => l10n.callQualityLost,
      RtcQuality.unknown => '',
    };

/// The line under the name while the call is in progress, or the problem when there is one.
String inCallStatus(AppLocalizations l10n, CallUiState state) {
  final call = state.call!;
  if (state.problem == CallProblem.connectionLost) return l10n.callConnectionLost;
  return switch (state.phase) {
    CallPhase.reconnecting => l10n.callReconnecting,
    CallPhase.active when !state.remotePresent => l10n.callWaitingFor(call.counterpartName),
    CallPhase.active => '',
    _ => l10n.callConnecting,
  };
}

/// The timer, once the call is on.
String? callTimer(CallUiState state, DateTime now) {
  final call = state.call;
  if (call == null || call.connectedAt == null) return null;
  return formatCallDuration(call.elapsed(now));
}

/// The text that says how a call ended, from this person's side.
String endedText(AppLocalizations l10n, CallSession call) {
  final name = call.counterpartName;
  return switch (call.endReason) {
    CallEndReason.completed => l10n.callEndedCompleted,
    CallEndReason.noAnswer =>
      call.outgoing ? l10n.callEndedNoAnswerOut(name) : l10n.callEndedMissed(name),
    CallEndReason.cancelled => call.outgoing ? l10n.callEndedCancelled : l10n.callEndedMissed(name),
    CallEndReason.declined =>
      call.outgoing ? l10n.callEndedDeclined(name) : l10n.callEndedCancelled,
    CallEndReason.dropped => l10n.callEndedDropped,
    CallEndReason.maxDuration => l10n.callEndedMaxDuration,
    CallEndReason.blocked => l10n.callEndedBlocked,
    _ => l10n.callEndedFailed,
  };
}

/// The ringing view of both people: the caller can cancel, the person called can accept or decline.
class RingingView extends StatelessWidget {
  final CallUiState state;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onCancel;

  const RingingView({
    super.key,
    required this.state,
    required this.onAccept,
    required this.onDecline,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final call = state.call!;
    final incoming = !call.outgoing;
    final status = incoming
        ? (call.type.hasVideo ? l10n.callIncomingVideo : l10n.callIncomingVoice)
        : l10n.callCalling;
    final onTap = state.busy ? null : (incoming ? onDecline : onCancel);
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: CallIdentity(call: call, status: status),
            ),
          ),
        ),
        CallControlRow(
          children: [
            CallControl(
              icon: Icons.call_end_rounded,
              label: incoming ? l10n.callDecline : l10n.callCancel,
              style: CallControlStyle.danger,
              onPressed: onTap,
            ),
            if (incoming)
              CallControl(
                icon: call.type.hasVideo ? Icons.videocam_rounded : Icons.call_rounded,
                label: l10n.callAccept,
                style: CallControlStyle.accept,
                onPressed: state.busy ? null : onAccept,
              ),
          ],
        ),
      ],
    );
  }
}

/// The voice call in progress.
class VoiceCallView extends StatelessWidget {
  final CallUiState state;
  final DateTime now;
  final VoidCallback onMute;
  final VoidCallback onSpeaker;
  final VoidCallback onEnd;
  final VoidCallback onReport;

  const VoiceCallView({
    super.key,
    required this.state,
    required this.now,
    required this.onMute,
    required this.onSpeaker,
    required this.onEnd,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final call = state.call!;
    final left = call.timeLeft(now);
    final warn =
        state.phase == CallPhase.active && left != null && left <= const Duration(minutes: 2);
    final quality = qualityLabel(l10n, state.quality);
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CallIdentity(
                    call: call,
                    status: inCallStatus(l10n, state),
                    timer: callTimer(state, now),
                  ),
                  if (quality.isNotEmpty && state.phase == CallPhase.active) ...[
                    const SizedBox(height: AppSpacing.sm),
                    CallChip(label: quality, icon: Icons.network_check_rounded),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (warn)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: CallBanner(message: l10n.callTimeLeft(formatCallDuration(left))),
          ),
        CallControlRow(
          children: [
            CallControl(
              icon: state.muted ? Icons.mic_off_rounded : Icons.mic_rounded,
              label: state.muted ? l10n.callUnmute : l10n.callMute,
              style: state.muted ? CallControlStyle.active : CallControlStyle.normal,
              onPressed: onMute,
            ),
            CallControl(
              icon: state.speakerOn ? Icons.volume_up_rounded : Icons.hearing_rounded,
              label: state.speakerOn ? l10n.callSpeaker : l10n.callEarpiece,
              style: state.speakerOn ? CallControlStyle.active : CallControlStyle.normal,
              onPressed: onSpeaker,
            ),
            CallControl(icon: Icons.flag_outlined, label: l10n.callReport, onPressed: onReport),
            CallControl(
              icon: Icons.call_end_rounded,
              label: l10n.callEnd,
              style: CallControlStyle.danger,
              onPressed: state.busy ? null : onEnd,
            ),
          ],
        ),
      ],
    );
  }
}

/// The ended call: how it ended and how long it lasted.
class EndedView extends StatelessWidget {
  final CallSession call;
  final VoidCallback onClose;
  final VoidCallback onReport;

  const EndedView({super.key, required this.call, required this.onClose, required this.onReport});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final seconds = call.durationSeconds ?? 0;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: CallIdentity(
                call: call,
                status: endedText(l10n, call),
                timer: seconds > 0 ? formatCallDuration(Duration(seconds: seconds)) : null,
              ),
            ),
          ),
        ),
        CallControlRow(
          children: [
            CallControl(icon: Icons.flag_outlined, label: l10n.callReport, onPressed: onReport),
            CallControl(
              icon: Icons.close_rounded,
              label: l10n.callClose,
              style: CallControlStyle.active,
              onPressed: onClose,
            ),
          ],
        ),
      ],
    );
  }
}
