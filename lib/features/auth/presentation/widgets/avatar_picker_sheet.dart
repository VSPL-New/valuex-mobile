import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/avatar_catalog.dart';
import 'avatar_image.dart';

/// Opens the avatar grid and returns the chosen avatar id, or null when dismissed.
Future<String?> showAvatarPicker(BuildContext context, {required String selectedId}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.brandBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) => _AvatarPickerSheet(selectedId: selectedId),
  );
}

class _AvatarPickerSheet extends StatelessWidget {
  final String selectedId;

  const _AvatarPickerSheet({required this.selectedId});

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
                  for (final id in entry.value)
                    _AvatarTile(
                      avatarId: id,
                      number: int.parse(id.split('-').last),
                      selected: id == selectedId,
                    ),
                ],
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

  const _AvatarTile({required this.avatarId, required this.number, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: AppLocalizations.of(context).avatarLabel(number),
      child: InkWell(
        key: Key('avatar-$avatarId'),
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).pop(avatarId),
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
