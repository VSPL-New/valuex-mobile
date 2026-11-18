import 'dart:async';

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Counts down to the end of a reservation (US-068, used again by checkout in Sprint 5). The time left
/// is counted from the server's clock ([serverTime], when the server answered), so a wrong clock on the
/// phone does not matter. It shows minutes and seconds, turns to the warning colour in the last minute,
/// and tells screen readers the time left once a minute (every 10 seconds in the last minute) instead
/// of every second. [onEnded] runs once when the time is up.
class ReservationTimer extends StatefulWidget {
  /// The last minute is the warning window.
  static const Duration warnWindow = Duration(minutes: 1);

  final DateTime validUntil;
  final DateTime serverTime;
  final VoidCallback? onEnded;

  /// The phone's clock, replaceable in tests.
  final DateTime Function() now;

  const ReservationTimer({
    super.key,
    required this.validUntil,
    required this.serverTime,
    this.onEnded,
    this.now = DateTime.now,
  });

  @override
  State<ReservationTimer> createState() => _ReservationTimerState();
}

class _ReservationTimerState extends State<ReservationTimer> {
  late DateTime _receivedAt;
  Timer? _timer;
  bool _endedReported = false;

  @override
  void initState() {
    super.initState();
    _receivedAt = widget.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(ReservationTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serverTime != widget.serverTime || oldWidget.validUntil != widget.validUntil) {
      _receivedAt = widget.now();
      _endedReported = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration get _remaining {
    final now = widget.serverTime.add(widget.now().difference(_receivedAt));
    final left = widget.validUntil.toUtc().difference(now.toUtc());
    return left.isNegative ? Duration.zero : left;
  }

  /// What screen readers hear: it changes once a minute, and every 10 seconds in the last minute, so the
  /// live region speaks only then.
  static String _spoken(AppLocalizations l10n, Duration left) {
    if (left > ReservationTimer.warnWindow) return l10n.reservationSpoken(left.inMinutes);
    return l10n.reservationSpokenSeconds((left.inSeconds / 10).ceil() * 10);
  }

  static String _clock(Duration left) {
    final minutes = left.inMinutes.toString().padLeft(2, '0');
    final seconds = (left.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final left = _remaining;
    final ended = left == Duration.zero;
    if (ended && !_endedReported && widget.onEnded != null) {
      _endedReported = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onEnded!();
      });
    }
    final warning = !ended && left <= ReservationTimer.warnWindow;
    final text = ended ? l10n.reservationEnded : l10n.reservationTimeLeft(_clock(left));
    final spoken = ended ? l10n.reservationEnded : _spoken(l10n, left);
    return Semantics(
      liveRegion: true,
      label: spoken,
      excludeSemantics: true,
      child: Text(
        text,
        style: AppTextStyles.label.copyWith(
          color: warning || ended ? AppColors.brandError : AppColors.brandForeground,
        ),
      ),
    );
  }
}
