import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Asks the user to confirm a block, saying what changes. Returns true only for Block.
Future<bool> confirmBlockUser(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.blockUserTitle),
      content: Text(l10n.blockUserMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.brandError),
          child: Text(l10n.blockUserConfirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
