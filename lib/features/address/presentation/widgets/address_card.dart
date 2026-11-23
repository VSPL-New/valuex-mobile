import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/saved_address.dart';

/// The name shown for an address: the user's own name for it, or "Address" when it has none.
String addressDisplayName(AppLocalizations l10n, SavedAddress address) {
  final label = address.label;
  return label == null || label.trim().isEmpty ? l10n.addressUnnamed : label;
}

enum _Action { edit, setDefault, delete }

/// One saved address on My Addresses (US-113): its name, the Default and Verified chips (Verified
/// only when a provider confirmed it), the full address, and a menu of what can be done with it.
class AddressCard extends StatelessWidget {
  final SavedAddress address;
  final VoidCallback onEdit;

  /// Null for the address that already is the default.
  final VoidCallback? onSetDefault;
  final VoidCallback onDelete;

  const AddressCard({
    super.key,
    required this.address,
    required this.onEdit,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = addressDisplayName(l10n, address);
    return SoftCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(name, style: AppTextStyles.cardTitle),
                    if (address.isDefault) _Chip(text: l10n.addressChipDefault),
                    if (address.verified) _Chip(text: l10n.addressChipVerified),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(address.fullAddress, style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
          PopupMenuButton<_Action>(
            tooltip: l10n.addressMenuLabel(name),
            onSelected: (action) => switch (action) {
              _Action.edit => onEdit(),
              _Action.setDefault => onSetDefault?.call(),
              _Action.delete => onDelete(),
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: _Action.edit, child: Text(l10n.addressMenuEdit)),
              if (onSetDefault != null)
                PopupMenuItem(value: _Action.setDefault, child: Text(l10n.addressMenuSetDefault)),
              PopupMenuItem(value: _Action.delete, child: Text(l10n.addressMenuDelete)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;

  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        child: Text(text, style: AppTextStyles.hint.copyWith(color: AppColors.brandPrimary)),
      ),
    );
  }
}
