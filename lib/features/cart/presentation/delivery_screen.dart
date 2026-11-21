import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_error.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand_gradient_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/square_back_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../address/domain/saved_address.dart';
import '../../address/presentation/providers/address_providers.dart';
import '../../address/presentation/widgets/address_form_sheet.dart';
import '../data/cart_repository.dart';
import '../domain/cart.dart';
import '../domain/delivery.dart';
import 'cart_error_messages.dart';
import 'delivery_format.dart';
import 'providers/cart_providers.dart';
import 'providers/delivery_providers.dart';

/// How the buyer receives one cart line (US-020): home delivery to one of their addresses, with the
/// shipping cost and date the server worked out, or self-pickup with a choice of how to pay. The buyer
/// agrees to the terms of what they chose, and the server stores the choice with the line. Nothing
/// here sends a price: the app only repeats the shipping cost it showed, so a change is noticed.
class DeliveryScreen extends ConsumerStatefulWidget {
  final String itemId;

  const DeliveryScreen({super.key, required this.itemId});

  @override
  ConsumerState<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends ConsumerState<DeliveryScreen> {
  bool _started = false;
  DeliveryMode? _mode;
  String? _addressId;
  PaymentOption? _payment;
  bool _terms = false;
  bool _busy = false;

  CartLine? _line(CartData data) {
    for (final group in data.groups) {
      for (final line in group.items) {
        if (line.itemId == widget.itemId) return line;
      }
    }
    return null;
  }

  /// Starts from what the buyer chose before; otherwise the default address, and the only way the
  /// item can be received when there is just one.
  void _start(CartLine line, List<SavedAddress> addresses, DeliveryOptions options) {
    if (_started) return;
    _started = true;
    final chosen = line.delivery;
    _mode = chosen.mode;
    _payment = chosen.paymentOption;
    final defaults = addresses.where((address) => address.isDefault);
    _addressId = chosen.addressId ?? (defaults.isEmpty ? null : defaults.first.id);
    if (_mode == null) {
      final delivery = options.delivery.available;
      final pickup = options.selfPickup.available;
      if (delivery != pickup) _mode = delivery ? DeliveryMode.delivery : DeliveryMode.selfPickup;
    }
  }

  void _back() => context.canPop() ? context.pop() : context.go(RouteNames.cart);

  void _select(DeliveryMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _terms = false;
    });
  }

  Future<void> _addAddress(bool hasSaved) async {
    final saved = await showAddressFormSheet(context, hasSavedAddresses: hasSaved);
    if (saved == null || !mounted) return;
    ref.invalidate(savedAddressesProvider);
    setState(() {
      _addressId = saved.id;
      _terms = false;
    });
  }

  Future<void> _save(num? shownCost) async {
    final mode = _mode;
    if (mode == null || !_terms || _busy) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final query = DeliveryQuery(widget.itemId, _addressId);
    setState(() => _busy = true);
    try {
      await ref.read(cartRepositoryProvider).chooseDelivery(
            widget.itemId,
            mode: mode,
            addressId: mode == DeliveryMode.delivery ? _addressId : null,
            paymentOption: mode == DeliveryMode.selfPickup ? _payment : null,
            expectedShippingCost: mode == DeliveryMode.delivery ? shownCost : null,
            termsAccepted: true,
          );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (error is ApiError && error.code == 'ERROR_SHIPPING_CHANGED') {
        ref.invalidate(deliveryOptionsProvider(query));
        setState(() => _terms = false);
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(cartErrorMessage(l10n, error))));
      return;
    }
    await ref.read(cartProvider.notifier).refreshQuietly();
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.cartDeliverySaved)));
    _back();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cart = ref.watch(cartProvider);
    final addresses = ref.watch(savedAddressesProvider);
    final base = ref.watch(deliveryOptionsProvider(DeliveryQuery(widget.itemId)));
    final data = cart.value;
    final line = data == null ? null : _line(data);

    Widget body;
    if (data != null && line == null) {
      body = ErrorView(message: l10n.cartErrorNotInCart, onRetry: _back);
    } else if (base.hasError && !base.hasValue) {
      body = ErrorView(
        message: cartErrorMessage(l10n, base.error!),
        onRetry: () => ref.invalidate(deliveryOptionsProvider(DeliveryQuery(widget.itemId))),
      );
    } else if (addresses.hasError && !addresses.hasValue) {
      body = ErrorView(
        message: l10n.cartDeliveryLoadFailed,
        onRetry: () => ref.invalidate(savedAddressesProvider),
      );
    } else if (line == null || !base.hasValue || !addresses.hasValue) {
      body = const LoadingIndicator();
    } else {
      _start(line, addresses.requireValue, base.requireValue);
      body = _Content(
        line: line,
        options: base.requireValue,
        addresses: addresses.requireValue,
        mode: _mode,
        addressId: _addressId,
        payment: _payment,
        terms: _terms,
        busy: _busy,
        onMode: _select,
        onAddress: (id) => setState(() {
          _addressId = id;
          _terms = false;
        }),
        onAddAddress: () => _addAddress(addresses.requireValue.isNotEmpty),
        onPayment: (option) => setState(() {
          _payment = option;
          _terms = false;
        }),
        onTerms: (value) => setState(() => _terms = value),
        onSave: _save,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(color: AppColors.brandSurface),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    SquareBackButton(onPressed: _back),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(l10n.cartDeliveryScreenTitle, style: AppTextStyles.heading2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  final CartLine line;
  final DeliveryOptions options;
  final List<SavedAddress> addresses;
  final DeliveryMode? mode;
  final String? addressId;
  final PaymentOption? payment;
  final bool terms;
  final bool busy;
  final ValueChanged<DeliveryMode> onMode;
  final ValueChanged<String> onAddress;
  final VoidCallback onAddAddress;
  final ValueChanged<PaymentOption> onPayment;
  final ValueChanged<bool> onTerms;
  final void Function(num? shownCost) onSave;

  const _Content({
    required this.line,
    required this.options,
    required this.addresses,
    required this.mode,
    required this.addressId,
    required this.payment,
    required this.terms,
    required this.busy,
    required this.onMode,
    required this.onAddress,
    required this.onAddAddress,
    required this.onPayment,
    required this.onTerms,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final deliverySelected = mode == DeliveryMode.delivery && options.delivery.available;
    final pickupSelected = mode == DeliveryMode.selfPickup && options.selfPickup.available;
    final priced = deliverySelected && addressId != null
        ? ref.watch(deliveryOptionsProvider(DeliveryQuery(line.itemId, addressId)))
        : null;
    final offer = priced?.value?.delivery;
    final canSave = !busy &&
        terms &&
        ((deliverySelected && offer != null && offer.available && offer.cost != null) ||
            (pickupSelected && payment != null));
    final termsText = _termsText(l10n, canSelectTerms: deliverySelected || pickupSelected);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(line.title ?? '', style: AppTextStyles.cardTitle, maxLines: 2),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.cartAgreedPrice(Formatters.money(line.agreedPrice)),
          style: AppTextStyles.bodySecondary,
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: Text(l10n.cartDeliveryQuestion, style: AppTextStyles.sectionTitle),
        ),
        const SizedBox(height: AppSpacing.sm),
        _OptionCard(
          title: l10n.cartDeliveryOptionDelivery,
          icon: Icons.local_shipping_outlined,
          selected: mode == DeliveryMode.delivery,
          enabled: options.delivery.available,
          unavailableText: options.delivery.available ? null : l10n.cartDeliveryUnavailableReason,
          onTap: () => onMode(DeliveryMode.delivery),
          child: _DeliveryBody(
            line: line,
            addresses: addresses,
            addressId: addressId,
            priced: priced,
            onAddress: onAddress,
            onAddAddress: onAddAddress,
            onRetry: () =>
                ref.invalidate(deliveryOptionsProvider(DeliveryQuery(line.itemId, addressId))),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _OptionCard(
          title: l10n.cartDeliveryOptionPickup,
          icon: Icons.storefront_outlined,
          selected: mode == DeliveryMode.selfPickup,
          enabled: options.selfPickup.available,
          unavailableText: options.selfPickup.available ? null : l10n.cartPickupUnavailableReason,
          onTap: () => onMode(DeliveryMode.selfPickup),
          child: _PickupBody(offer: options.selfPickup, payment: payment, onPayment: onPayment),
        ),
        if (termsText != null) ...[
          const SizedBox(height: AppSpacing.md),
          Material(
            color: AppColors.brandSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: const BorderSide(color: AppColors.brandBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(termsText, style: AppTextStyles.bodySecondary),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: terms,
                    onChanged: (value) => onTerms(value ?? false),
                    title: Text(l10n.cartTermsAgree, style: AppTextStyles.body),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        BrandGradientButton(
          label: l10n.cartDeliverySave,
          isLoading: busy,
          onPressed: canSave ? () => onSave(offer?.cost) : null,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  String? _termsText(AppLocalizations l10n, {required bool canSelectTerms}) {
    if (!canSelectTerms) return null;
    if (mode == DeliveryMode.delivery) return l10n.cartTermsDelivery;
    return switch (payment) {
      PaymentOption.payNow => l10n.cartTermsPickupNow,
      PaymentOption.payAtPickup => l10n.cartTermsPickupLater,
      null => null,
    };
  }
}

/// One way of receiving the item: a titled card that opens its details when chosen. A way that is not
/// possible stays dimmed and says why.
class _OptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final String? unavailableText;
  final VoidCallback onTap;
  final Widget child;

  const _OptionCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.unavailableText,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final border = selected ? AppColors.brandPrimary : AppColors.brandBorder;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.brandSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: border, width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              inMutuallyExclusiveGroup: true,
              checked: selected,
              enabled: enabled,
              label: unavailableText == null ? title : '$title, $unavailableText',
              excludeSemantics: true,
              onTap: enabled ? onTap : null,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: enabled ? onTap : null,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(icon, color: AppColors.brandPrimary),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: AppTextStyles.sectionTitle),
                              if (unavailableText != null)
                                Text(unavailableText!, style: AppTextStyles.hint),
                            ],
                          ),
                        ),
                        Icon(
                          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: selected ? AppColors.brandPrimary : AppColors.brandMutedText,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (selected && enabled)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                child: child,
              ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryBody extends StatelessWidget {
  final CartLine line;
  final List<SavedAddress> addresses;
  final String? addressId;
  final AsyncValue<DeliveryOptions>? priced;
  final ValueChanged<String> onAddress;
  final VoidCallback onAddAddress;
  final VoidCallback onRetry;

  const _DeliveryBody({
    required this.line,
    required this.addresses,
    required this.addressId,
    required this.priced,
    required this.onAddress,
    required this.onAddAddress,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.cartDeliveryAddressHeading, style: AppTextStyles.label),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final address in addresses) ...[
          _AddressTile(
            address: address,
            selected: address.id == addressId,
            onTap: () => onAddress(address.id),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
              foregroundColor: AppColors.brandLink,
              textStyle: AppTextStyles.linkSmall,
            ),
            onPressed: onAddAddress,
            icon: const Icon(Icons.add_location_alt_outlined, size: 18),
            label: Text(l10n.cartDeliveryAddAddress),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _price(context, l10n),
      ],
    );
  }

  Widget _price(BuildContext context, AppLocalizations l10n) {
    final priced = this.priced;
    if (addressId == null || priced == null) {
      return Text(l10n.cartDeliveryNoAddress, style: AppTextStyles.hint);
    }
    return priced.when(
      loading: () => Semantics(
        liveRegion: true,
        child: Text(l10n.cartDeliveryPricing, style: AppTextStyles.hint),
      ),
      error: (error, stack) => Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error is ApiError && error.code == 'ERROR_INVALID_ADDRESS'
                  ? l10n.cartErrorInvalidAddress
                  : l10n.cartDeliveryPriceFailed,
              style: AppTextStyles.hint.copyWith(color: AppColors.brandError),
            ),
            TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
          ],
        ),
      ),
      data: (options) {
        final offer = options.delivery;
        if (!offer.available || offer.cost == null) {
          return Text(
            l10n.cartDeliveryUnavailableReason,
            style: AppTextStyles.hint.copyWith(color: AppColors.brandError),
          );
        }
        final eta = offer.etaDate;
        return Semantics(
          liveRegion: true,
          container: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.cartDeliveryCost(Formatters.money(offer.cost!)),
                style: AppTextStyles.cardTitle,
              ),
              if (eta != null)
                Text(
                  l10n.cartDeliveryEta(deliveryDate(context, eta)),
                  style: AppTextStyles.bodySecondary,
                ),
              if (offer.exceedsPrice)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: AppColors.brandError),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          l10n.cartDeliveryExceedsPrice,
                          style: AppTextStyles.hint.copyWith(color: AppColors.brandError),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AddressTile extends StatelessWidget {
  final SavedAddress address;
  final bool selected;
  final VoidCallback onTap;

  const _AddressTile({required this.address, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = address.label;
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: [
        if (name != null && name.isNotEmpty) name,
        address.fullAddress,
        if (address.isDefault) l10n.cartDeliveryDefaultTag,
      ].join(', '),
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? AppColors.brandSurfaceTint : AppColors.brandSurface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selected ? AppColors.brandPrimary : AppColors.brandBorder,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected ? AppColors.brandPrimary : AppColors.brandMutedText,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (name != null && name.isNotEmpty)
                              Text(name, style: AppTextStyles.cardTitle),
                            if (address.isDefault)
                              Text(
                                l10n.cartDeliveryDefaultTag,
                                style: AppTextStyles.caption.copyWith(color: AppColors.brandLink),
                              ),
                          ],
                        ),
                        Text(address.fullAddress, style: AppTextStyles.bodySecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PickupBody extends StatelessWidget {
  final SelfPickupOffer offer;
  final PaymentOption? payment;
  final ValueChanged<PaymentOption> onPayment;

  const _PickupBody({required this.offer, required this.payment, required this.onPayment});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final place = offer.place;
    final seller = offer.sellerName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.cartPickupHeading, style: AppTextStyles.label),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (place != null) Text(place.text, style: AppTextStyles.body),
        if (seller != null && seller.isNotEmpty)
          Text(l10n.cartPickupSeller(seller), style: AppTextStyles.bodySecondary),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.cartPickupAfterOrder, style: AppTextStyles.hint),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: Text(l10n.cartPayHeading, style: AppTextStyles.label),
        ),
        const SizedBox(height: AppSpacing.sm),
        _PayTile(
          title: l10n.cartPayNow,
          hint: l10n.cartPayNowHint,
          selected: payment == PaymentOption.payNow,
          onTap: () => onPayment(PaymentOption.payNow),
        ),
        const SizedBox(height: AppSpacing.sm),
        _PayTile(
          title: l10n.cartPayAtPickup,
          hint: l10n.cartPayAtPickupHint,
          selected: payment == PaymentOption.payAtPickup,
          onTap: () => onPayment(PaymentOption.payAtPickup),
        ),
        if (payment == PaymentOption.payAtPickup)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Semantics(
              liveRegion: true,
              container: true,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.brandErrorTint,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 18, color: AppColors.brandError),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.cartPayAtPickupBanner,
                          style: AppTextStyles.bodySecondary.copyWith(color: AppColors.brandError),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PayTile extends StatelessWidget {
  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  const _PayTile({
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: '$title, $hint',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? AppColors.brandSurfaceTint : AppColors.brandSurface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selected ? AppColors.brandPrimary : AppColors.brandBorder,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected ? AppColors.brandPrimary : AppColors.brandMutedText,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.cardTitle),
                        Text(hint, style: AppTextStyles.bodySecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
