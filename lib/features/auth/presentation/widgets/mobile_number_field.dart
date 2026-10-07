import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';

/// Indian mobile number entry: fixed +91 prefix plus a 10-digit field. [errorText] is shown
/// under the field with an icon and turns both edges red.
class MobileNumberField extends StatefulWidget {
  static const _mobileLength = 10;

  final ValueChanged<String> onChanged;
  final String semanticLabel;
  final String? errorText;

  const MobileNumberField({
    super.key,
    required this.onChanged,
    required this.semanticLabel,
    this.errorText,
  });

  @override
  State<MobileNumberField> createState() => _MobileNumberFieldState();
}

class _MobileNumberFieldState extends State<MobileNumberField> {
  @override
  void didUpdateWidget(MobileNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // At large text sizes the message can sit below the fold.
    if (widget.errorText != null && widget.errorText != oldWidget.errorText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 200));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorText = widget.errorText;
    final hasError = errorText != null;
    final edge = hasError ? AppColors.brandError : AppColors.brandControlBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.brandSurfaceTint,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: edge, width: hasError ? 2 : 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('\u{1F1EE}\u{1F1F3}', style: AppTextStyles.input),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '+91',
                        style: AppTextStyles.input.copyWith(color: AppColors.brandMutedText),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Semantics(
                  label: '${widget.semanticLabel} +91',
                  child: TextField(
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(MobileNumberField._mobileLength),
                    ],
                    onChanged: widget.onChanged,
                    style: AppTextStyles.input,
                    cursorColor: AppColors.brandPrimary,
                    decoration: InputDecoration(
                      hintText: '9876543210',
                      enabledBorder:
                          hasError ? Theme.of(context).inputDecorationTheme.errorBorder : null,
                      focusedBorder: hasError
                          ? Theme.of(context).inputDecorationTheme.focusedErrorBorder
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.error_outline_rounded, size: 18, color: AppColors.brandError),
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(errorText, style: AppTextStyles.error)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
