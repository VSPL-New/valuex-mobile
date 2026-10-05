import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Six-digit code entry drawn as separate boxes over one real text field, so
/// paste, backspace, keyboard and SMS autofill all work.
class OtpInput extends StatefulWidget {
  static const length = 6;

  final ValueChanged<String> onChanged;
  final bool enabled;
  final bool hasError;
  final String semanticLabel;

  const OtpInput({
    super.key,
    required this.onChanged,
    required this.semanticLabel,
    this.enabled = true,
    this.hasError = false,
  });

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
    widget.onChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;

    return Semantics(
      label: widget.semanticLabel,
      textField: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? _focusNode.requestFocus : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < OtpInput.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _OtpBox(
                        digit: i < text.length ? text[i] : '',
                        active: widget.enabled && _focusNode.hasFocus && i == text.length,
                        hasError: widget.hasError,
                        enabled: widget.enabled,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(OtpInput.length),
                  ],
                  showCursor: false,
                  enableInteractiveSelection: false,
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final String digit;
  final bool active;
  final bool hasError;
  final bool enabled;

  const _OtpBox({
    required this.digit,
    required this.active,
    required this.hasError,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.brandError
        : active
            ? AppColors.brandPrimary
            : AppColors.brandBorder;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        height: AppSizes.buttonMedium,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.brandSurfaceTint,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderColor, width: active || hasError ? 2 : 1),
        ),
        child: Text(digit, style: AppTextStyles.heading2),
      ),
    );
  }
}
