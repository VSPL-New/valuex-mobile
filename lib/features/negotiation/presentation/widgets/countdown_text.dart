import 'dart:async';

import 'package:flutter/material.dart';

/// Builds [builder] with the time left until [target], counted from the server's clock
/// ([serverTime], when the server answered) so a wrong clock on the phone does not matter. It
/// updates every 30 seconds and when [serverTime] changes.
class CountdownText extends StatefulWidget {
  final DateTime target;
  final DateTime serverTime;
  final Widget Function(BuildContext context, Duration remaining) builder;

  const CountdownText({
    super.key,
    required this.target,
    required this.serverTime,
    required this.builder,
  });

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  late DateTime _receivedAt;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _receivedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(CountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serverTime != widget.serverTime) _receivedAt = DateTime.now();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = widget.serverTime.add(DateTime.now().difference(_receivedAt));
    final remaining = widget.target.toUtc().difference(now);
    return widget.builder(context, remaining.isNegative ? Duration.zero : remaining);
  }
}
