import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/field_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/gender.dart';

/// Three choices in a row: Male, Female, Others. Exposed as one radio group.
class GenderSelector extends StatelessWidget {
  final Gender? value;
  final ValueChanged<Gender> onChanged;
  final String? errorText;

  const GenderSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = {
      Gender.male: l10n.genderMale,
      Gender.female: l10n.genderFemale,
      Gender.others: l10n.genderOthers,
    };

    final errorText = this.errorText;
    // Three chips in a row no longer fit at large text; stack them instead of breaking words.
    final stacked = MediaQuery.textScalerOf(context).scale(16) > 16 * 1.25;
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stacked)
            for (final gender in Gender.values) ...[
              if (gender != Gender.male) const SizedBox(height: AppSpacing.sm),
              _GenderChip(
                label: labels[gender]!,
                selected: gender == value,
                hasError: errorText != null,
                onTap: () => onChanged(gender),
              ),
            ]
          else
            Row(
              children: [
                for (final gender in Gender.values) ...[
                  if (gender != Gender.male) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _GenderChip(
                      label: labels[gender]!,
                      selected: gender == value,
                      hasError: errorText != null,
                      onTap: () => onChanged(gender),
                    ),
                  ),
                ],
              ],
            ),
          if (errorText != null) ...[
            const SizedBox(height: AppSpacing.sm),
            FieldError(text: errorText),
          ],
        ],
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool hasError;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.selected,
    required this.hasError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? AppColors.brandSurfaceTint : AppColors.brandSurface,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSizes.buttonMedium),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected
                    ? AppColors.brandPrimary
                    : hasError
                        ? AppColors.brandError
                        : AppColors.brandControlBorder,
                width: selected || hasError ? 2 : 1,
              ),
            ),
            child: Text(
              label,
              style: AppTextStyles.input.copyWith(
                color: selected ? AppColors.brandPrimary : AppColors.brandForeground,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
