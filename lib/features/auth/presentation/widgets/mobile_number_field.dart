import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';

/// Indian mobile number entry: fixed +91 prefix plus a 10-digit field.
class MobileNumberField extends StatelessWidget {
  static const _mobileLength = 10;

  final ValueChanged<String> onChanged;

  const MobileNumberField({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brandSurfaceTint,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.brandBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('\u{1F1EE}\u{1F1F3}', style: AppTextStyles.input),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '+91',
                  style: AppTextStyles.input.copyWith(
                    color: AppColors.brandMutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(_mobileLength),
              ],
              onChanged: onChanged,
              style: AppTextStyles.input,
              cursorColor: AppColors.brandPrimary,
              decoration: const InputDecoration(hintText: '9876543210'),
            ),
          ),
        ],
      ),
    );
  }
}
