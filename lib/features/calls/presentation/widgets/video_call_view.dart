import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/call_time.dart';
import '../providers/call_controller.dart';
import 'call_controls.dart';
import 'call_views.dart';

/// The video call in progress: the other person full screen, this phone's picture small and
/// draggable, and the controls (US-015). The pictures are drawn by the call SDK; this only places them.
class VideoCallView extends StatelessWidget {
  final CallUiState state;
  final DateTime now;
  final Widget remote;
  final Widget local;
  final VoidCallback onMute;
  final VoidCallback onCamera;
  final VoidCallback onFlip;
  final VoidCallback onSpeaker;
  final VoidCallback onEnd;
  final VoidCallback onReport;
  final VoidCallback onTurnOffVideo;

  const VideoCallView({
    super.key,
    required this.state,
    required this.now,
    required this.remote,
    required this.local,
    required this.onMute,
    required this.onCamera,
    required this.onFlip,
    required this.onSpeaker,
    required this.onEnd,
    required this.onReport,
    required this.onTurnOffVideo,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final call = state.call!;
    final left = call.timeLeft(now);
    final warn =
        state.phase == CallPhase.active && left != null && left <= const Duration(minutes: 2);
    final status = inCallStatus(l10n, state);
    final timer = callTimer(state, now);
    final quality = qualityLabel(l10n, state.quality);
    return Stack(
      fit: StackFit.expand,
      children: [
        Semantics(label: call.counterpartName, image: true, child: remote),
        if (!state.remotePresent)
          Center(
            child: SingleChildScrollView(
              child: CallIdentity(call: call, status: status, timer: timer),
            ),
          ),
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  CallChip(label: call.counterpartName, icon: Icons.person_outline_rounded),
                  if (timer != null) CallChip(label: timer, icon: Icons.timer_outlined),
                  if (quality.isNotEmpty && state.phase == CallPhase.active)
                    CallChip(label: quality, icon: Icons.network_check_rounded),
                  CallChip(label: l10n.callNotRecorded, icon: Icons.mic_none_rounded),
                ],
              ),
              if (state.remotePresent && status.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                CallChip(label: status),
              ],
            ],
          ),
        ),
        if (state.cameraOn) DraggablePreview(label: l10n.callYourCamera, child: local),
        Align(
          alignment: Alignment.bottomCenter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
              ),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
              child: SingleChildScrollView(
                reverse: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The banners sit above the controls, where the small picture is not dragged to.
                    if (state.lowBandwidth)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          0,
                        ),
                        child: CallBanner(
                          message: l10n.callLowBandwidth,
                          actionLabel: l10n.callTurnOffVideo,
                          onAction: onTurnOffVideo,
                        ),
                      ),
                    if (warn)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          0,
                        ),
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
                          icon:
                              state.cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                          label: state.cameraOn ? l10n.callCameraOff : l10n.callCameraOn,
                          style: state.cameraOn ? CallControlStyle.normal : CallControlStyle.active,
                          onPressed: onCamera,
                        ),
                        if (state.cameraOn)
                          CallControl(
                            icon: Icons.cameraswitch_outlined,
                            label: l10n.callFlipCamera,
                            onPressed: onFlip,
                          ),
                        CallControl(
                          icon: state.speakerOn ? Icons.volume_up_rounded : Icons.hearing_rounded,
                          label: state.speakerOn ? l10n.callSpeaker : l10n.callEarpiece,
                          style:
                              state.speakerOn ? CallControlStyle.active : CallControlStyle.normal,
                          onPressed: onSpeaker,
                        ),
                        CallControl(
                            icon: Icons.flag_outlined, label: l10n.callReport, onPressed: onReport),
                        CallControl(
                          icon: Icons.call_end_rounded,
                          label: l10n.callEnd,
                          style: CallControlStyle.danger,
                          onPressed: state.busy ? null : onEnd,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// This phone's own picture: small, in a corner, and dragged anywhere on the screen.
class DraggablePreview extends StatefulWidget {
  static const double width = 104;
  static const double height = 148;

  final String label;
  final Widget child;

  const DraggablePreview({super.key, required this.label, required this.child});

  @override
  State<DraggablePreview> createState() => _DraggablePreviewState();
}

class _DraggablePreviewState extends State<DraggablePreview> {
  Offset? _offset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final maxX = (box.maxWidth - DraggablePreview.width).clamp(0.0, double.infinity);
        final maxY = (box.maxHeight - DraggablePreview.height).clamp(0.0, double.infinity);
        final offset = _offset ?? Offset(maxX - AppSpacing.md, 96);
        final position = Offset(offset.dx.clamp(0.0, maxX), offset.dy.clamp(0.0, maxY));
        return Stack(
          children: [
            Positioned(
              left: position.dx,
              top: position.dy,
              child: GestureDetector(
                onPanUpdate: (details) => setState(() => _offset = position + details.delta),
                child: Semantics(
                  label: widget.label,
                  image: true,
                  child: Container(
                    width: DraggablePreview.width,
                    height: DraggablePreview.height,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.brandForeground,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.brandOnPrimary, width: 2),
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The call could not be read or joined.
class CallProblemView extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const CallProblemView({super.key, required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SingleChildScrollView(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading2.copyWith(color: AppColors.brandOnPrimary),
                  ),
                ),
              ),
            ),
          ),
        ),
        CallControlRow(
          children: [
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
