import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/field_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../address/domain/saved_address.dart';
import '../../../address/presentation/providers/address_providers.dart';
import '../providers/home_providers.dart';

/// Asks the user to pick one of their saved addresses (name and full address) as the place to
/// look for listings near.
Future<void> showSavedLocationDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _SavedLocationDialog(),
  );
}

class _SavedLocationDialog extends ConsumerWidget {
  const _SavedLocationDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final saved = ref.watch(savedAddressesProvider);

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
          data: (addresses) {
            if (addresses.isEmpty) {
              return Text(l10n.homeSavedLocationEmpty, style: AppTextStyles.body);
            }
            return ListView.separated(
              shrinkWrap: true,
              itemCount: addresses.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => _AddressTile(
                address: addresses[index],
                onTap: () {
                  ref
                      .read(homeLocationControllerProvider.notifier)
                      .useSavedAddress(addresses[index]);
                  Navigator.of(context).pop();
                },
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
      ],
    );
  }
}

class _AddressTile extends StatelessWidget {
  final SavedAddress address;
  final VoidCallback onTap;

  const _AddressTile({required this.address, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = address.label ?? l10n.homeSavedLocationUnnamed;
    return Semantics(
      button: true,
      label: '$name, ${address.fullAddress}',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTextStyles.cardTitle),
              const SizedBox(height: AppSpacing.xs),
              Text(address.fullAddress, style: AppTextStyles.bodySecondary),
            ],
          ),
        ),
      ),
    );
  }
}
