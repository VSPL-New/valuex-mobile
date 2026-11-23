import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_error.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/brand_gradient_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/square_back_button.dart';
import '../../../l10n/app_localizations.dart';
import '../data/address_repository.dart';
import '../domain/saved_address.dart';
import 'providers/address_providers.dart';
import 'widgets/address_card.dart';
import 'widgets/address_form_sheet.dart';

/// My Addresses (US-113): the user's saved addresses, default first, with add, edit, rename, set
/// as default and delete. The list is re-read after every change.
class MyAddressesScreen extends ConsumerStatefulWidget {
  const MyAddressesScreen({super.key});

  @override
  ConsumerState<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends ConsumerState<MyAddressesScreen> {
  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refresh() async {
    ref.invalidate(savedAddressesProvider);
    try {
      await ref.read(savedAddressesProvider.future);
    } on Object {
      // The error is shown in place; the spinner just stops.
    }
  }

  Future<void> _add(List<SavedAddress> addresses) async {
    final saved = await showAddressFormSheet(context, hasSavedAddresses: addresses.isNotEmpty);
    if (saved == null || !mounted) return;
    ref.invalidate(savedAddressesProvider);
    _show(AppLocalizations.of(context).cartAddressSaved);
  }

  Future<void> _edit(SavedAddress address, List<SavedAddress> addresses) async {
    final saved = await showAddressFormSheet(
      context,
      hasSavedAddresses: addresses.isNotEmpty,
      existing: address,
    );
    if (saved == null || !mounted) return;
    ref.invalidate(savedAddressesProvider);
    _show(AppLocalizations.of(context).addressUpdated);
  }

  Future<void> _setDefault(SavedAddress address) async {
    await _run(
      () => ref.read(addressRepositoryProvider).setDefault(address.id),
      AppLocalizations.of(context).addressDefaultChanged,
    );
  }

  Future<void> _delete(SavedAddress address) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addressDeleteTitle),
        content: Text(l10n.addressDeleteMessage(addressDisplayName(l10n, address))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.addressDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(
      () => ref.read(addressRepositoryProvider).delete(address.id),
      l10n.addressDeleted,
    );
  }

  /// Runs one change, re-reads the list and says what happened; a refusal shows its own reason.
  Future<void> _run(Future<void> Function() change, String done) async {
    final l10n = AppLocalizations.of(context);
    try {
      await change();
    } on Object catch (error) {
      if (!mounted) return;
      _show(addressManageError(l10n, error));
      ref.invalidate(savedAddressesProvider);
      return;
    }
    if (!mounted) return;
    ref.invalidate(savedAddressesProvider);
    _show(done);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(savedAddressesProvider);
    final addresses = async.value;

    final Widget body;
    if (addresses == null && async.hasError) {
      body = ErrorView(
        message: l10n.myAddressesLoadFailed,
        onRetry: () => ref.invalidate(savedAddressesProvider),
      );
    } else if (addresses == null) {
      body = const LoadingIndicator();
    } else if (addresses.isEmpty) {
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: _EmptyState(onAdd: () => _add(addresses)),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: addresses.length + 1,
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            if (index == addresses.length) {
              return BrandGradientButton(
                label: l10n.myAddressesAdd,
                onPressed: () => _add(addresses),
              );
            }
            final address = addresses[index];
            return AddressCard(
              address: address,
              onEdit: () => _edit(address, addresses),
              onSetDefault: address.isDefault ? null : () => _setDefault(address),
              onDelete: () => _delete(address),
            );
          },
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: SquareBackButton(
                      onPressed: () =>
                          context.canPop() ? context.pop() : context.go(RouteNames.profile),
                    ),
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(l10n.profileMyAddresses, style: AppTextStyles.heading2),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// The text of a refused or failed address change, chosen by backend error code.
String addressManageError(AppLocalizations l10n, Object error) {
  if (error is ApiError) {
    return switch (error.code) {
      'ERROR_ADDRESS_IN_USE' => l10n.addressErrorInUse,
      'ERROR_ADDRESS_LIMIT_REACHED' => l10n.addressErrorLimit,
      _ => l10n.addressActionFailed,
    };
  }
  return l10n.addressActionFailed;
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ExcludeSemantics(
                  child:
                      Icon(Icons.location_on_outlined, size: 48, color: AppColors.brandMutedText),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.myAddressesEmpty, style: AppTextStyles.body, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.myAddressesEmptyHint,
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                BrandGradientButton(label: l10n.myAddressesAdd, onPressed: onAdd),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
