import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/field_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../address/domain/saved_address.dart';
import '../../../address/presentation/providers/address_providers.dart';
import '../providers/home_providers.dart';

/// Lists the user's saved addresses (name and full address) as radio options; the chosen one
/// becomes the place to look for listings near.
Future<void> showSavedLocationDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _SavedLocationDialog(),
  );
}

class _SavedLocationDialog extends ConsumerStatefulWidget {
  const _SavedLocationDialog();

  @override
  ConsumerState<_SavedLocationDialog> createState() => _SavedLocationDialogState();
}

class _SavedLocationDialogState extends ConsumerState<_SavedLocationDialog> {
  String? _selectedId;

  /// The user's pick, else their default address, else the first one.
  SavedAddress? _selected(List<SavedAddress> addresses) {
    if (addresses.isEmpty) return null;
    return addresses.firstWhere(
      (a) => a.id == _selectedId,
      orElse: () => addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final saved = ref.watch(savedAddressesProvider);
    final addresses = saved.value ?? const <SavedAddress>[];
    final selected = _selected(addresses);

    return AlertDialog(
      title: Semantics(header: true, child: Text(l10n.homeSavedLocationTitle)),
      content: SizedBox(
        width: double.maxFinite,
        child: saved.when(
          loading: () => Center(
            child: Semantics(
              label: l10n.loading,
              child: const CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldError(text: l10n.homeSavedLocationFailed),
              TextButton(
                onPressed: () => ref.invalidate(savedAddressesProvider),
                child: Text(l10n.commonRetry),
              ),
            ],
          ),
          data: (list) {
            if (list.isEmpty) {
              return Text(l10n.homeSavedLocationEmpty, style: AppTextStyles.body);
            }
            return RadioGroup<String>(
              groupValue: selected?.id,
              onChanged: (id) => setState(() => _selectedId = id),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: list.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) => _AddressTile(address: list[index]),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        if (selected != null)
          FilledButton(
            onPressed: () {
              ref.read(homeLocationControllerProvider.notifier).useSavedAddress(selected);
              Navigator.of(context).pop();
            },
            child: Text(l10n.homeSavedLocationConfirm),
          ),
      ],
    );
  }
}

class _AddressTile extends StatelessWidget {
  final SavedAddress address;

  const _AddressTile({required this.address});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = address.label ?? l10n.homeSavedLocationUnnamed;
    return RadioListTile<String>(
      value: address.id,
      contentPadding: EdgeInsets.zero,
      title: Text(name, style: AppTextStyles.cardTitle),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Text(address.fullAddress, style: AppTextStyles.bodySecondary),
      ),
    );
  }
}
