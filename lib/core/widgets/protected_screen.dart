import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../security/screen_protection_service.dart';

/// Turns screenshot protection on while [child] is on screen.
class ProtectedScreen extends ConsumerStatefulWidget {
  final Widget child;

  const ProtectedScreen({super.key, required this.child});

  @override
  ConsumerState<ProtectedScreen> createState() => _ProtectedScreenState();
}

class _ProtectedScreenState extends ConsumerState<ProtectedScreen> {
  late final ScreenProtectionService _service;

  @override
  void initState() {
    super.initState();
    _service = ref.read(screenProtectionServiceProvider);
    _service.enable();
  }

  @override
  void dispose() {
    _service.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
