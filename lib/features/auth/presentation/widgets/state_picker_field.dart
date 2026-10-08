import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/field_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/indian_states.dart';

/// Field-looking row that opens the list of states and union territories.
class StatePickerField extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  final String? errorText;

  const StatePickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  Future<void> _pick(BuildContext context) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.brandBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => _StateSheet(selected: value),
    );
    if (chosen != null) onChanged(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final radius = BorderRadius.circular(AppRadius.lg);
    final errorText = this.errorText;

    final field = Semantics(
      button: true,
      label: l10n.signupStateLabel,
      value: value,
      excludeSemantics: true,
      onTap: () => _pick(context),
      child: Material(
        color: AppColors.brandSurfaceTint,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () => _pick(context),
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSizes.buttonMedium),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: errorText != null ? AppColors.brandError : AppColors.brandControlBorder,
                width: errorText != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? l10n.signupStateHint,
                    overflow: TextOverflow.ellipsis,
                    style: value == null
                        ? AppTextStyles.input.copyWith(color: AppColors.brandPlaceholder)
                        : AppTextStyles.input,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.brandMutedText),
              ],
            ),
          ),
        ),
      ),
    );

    if (errorText == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        field,
        const SizedBox(height: AppSpacing.sm),
        FieldError(text: errorText),
      ],
    );
  }
}

class _StateSheet extends StatelessWidget {
  final String? selected;

  const _StateSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.signupStateSheetTitle, style: AppTextStyles.heading2),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: IndianStates.names.length,
                itemBuilder: (context, index) {
                  final name = IndianStates.names[index];
                  return ListTile(
                    minTileHeight: 48,
                    title: Text(name, style: AppTextStyles.input),
                    selected: name == selected,
                    selectedColor: AppColors.brandPrimary,
                    trailing: name == selected ? const Icon(Icons.check_rounded) : null,
                    onTap: () => Navigator.of(context).pop(name),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
