import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/avatar_catalog.dart';
import 'avatar_image.dart';

/// Opens the avatar grid and returns the chosen avatar id, or null when dismissed.
Future<String?> showAvatarPicker(
  BuildContext context, {
  required String selectedId,
  List<String>? availableIds,
  bool confirmSelection = false,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.brandBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) => _AvatarPickerSheet(
      selectedId: selectedId,
      availableIds: availableIds,
      confirmSelection: confirmSelection,
    ),
  );
}

class _AvatarPickerSheet extends StatefulWidget {
  final String selectedId;
  final List<String>? availableIds;
  final bool confirmSelection;

  const _AvatarPickerSheet({
    required this.selectedId,
    this.availableIds,
    this.confirmSelection = false,
  });

  @override
  State<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<_AvatarPickerSheet> {
  late String selectedId = widget.selectedId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titles = {
      AvatarGroup.male: l10n.avatarGroupMale,
      AvatarGroup.female: l10n.avatarGroupFemale,
      AvatarGroup.neutral: l10n.avatarGroupNeutral,
    };

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.signupAvatarSheetTitle, style: AppTextStyles.heading2),
            for (final entry in AvatarCatalog.groups.entries) ...[
              const SizedBox(height: AppSpacing.md),
              Text(titles[entry.key]!, style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final id in widget.availableIds?.where(
                        (id) => AvatarCatalog.groupOf(id) == entry.key,
                      ) ??
                      entry.value)
                    _AvatarTile(
                      avatarId: id,
                      number: int.tryParse(id.split('-').last) ?? 0,
                      selected: id == selectedId,
                      onSelected: () {
                        if (widget.confirmSelection) {
                          setState(() => selectedId = id);
                        } else {
                          Navigator.of(context).pop(id);
                        }
                      },
                    ),
                ],
              ),
            ],
            if (widget.confirmSelection) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l10n.profileSave,
                onPressed: widget.availableIds?.contains(selectedId) == true
                    ? () => Navigator.of(context).pop(selectedId)
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  final String avatarId;
  final int number;
  final bool selected;
  final VoidCallback onSelected;

  const _AvatarTile({
    required this.avatarId,
    required this.number,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: AppLocalizations.of(context).avatarLabel(number),
      child: InkWell(
        key: Key('avatar-$avatarId'),
        customBorder: const CircleBorder(),
        onTap: onSelected,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.brandPrimary : Colors.transparent,
              width: 3,
            ),
          ),
          child: AvatarImage(avatarId: avatarId, size: 64),
        ),
      ),
    );
  }
}
