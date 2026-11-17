import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand_gradient_button.dart';
import '../../../l10n/app_localizations.dart';
import '../data/negotiation_repository.dart';
import 'negotiation_error_messages.dart';
import 'negotiation_format.dart';

/// Opens the Make Offer sheet (US-017) and answers with the id of the negotiation that was made, or
/// of the one the buyer already had; null when the sheet is closed without an offer.
Future<String?> showOfferSheet(
  BuildContext context, {
  required String listingId,
  required num askingPrice,
  VoidCallback? onChat,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.brandSurface,
    builder: (context) =>
        OfferSheet(listingId: listingId, askingPrice: askingPrice, onChat: onChat),
  );
}

/// A rupee amount, the asking price and the allowed range, live validation with the server's rules, a
/// confirmation for an offer far below the asking price, and a link to ask the seller first.
class OfferSheet extends ConsumerStatefulWidget {
  final String listingId;
  final num askingPrice;
  final VoidCallback? onChat;

  const OfferSheet({super.key, required this.listingId, required this.askingPrice, this.onChat});

  @override
  ConsumerState<OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends ConsumerState<OfferSheet> {
  static const _uuid = Uuid();

  final _amount = TextEditingController();
  final _clientRequestId = _uuid.v4();
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  /// The text for what is typed, or null when it is a valid amount within the asking price.
  String? _validate(AppLocalizations l10n, String raw) {
    if (raw.trim().isEmpty) return l10n.offerAmountRequired;
    final amount = parseOfferAmount(raw);
    if (amount == null) return l10n.offerAmountInvalid;
    if (paise(double.parse(amount)) > paise(widget.askingPrice)) {
      return l10n.offerAmountOutOfRange(Formatters.money(widget.askingPrice));
    }
    return null;
  }

  Future<void> _submit({bool confirmLow = false}) async {
    if (_sending) return;
    final l10n = AppLocalizations.of(context);
    final problem = _validate(l10n, _amount.text);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _error = null;
      _sending = true;
    });
    try {
      final made = await ref.read(negotiationRepositoryProvider).makeOffer(
            widget.listingId,
            amount: parseOfferAmount(_amount.text)!,
            clientRequestId: _clientRequestId,
            confirmLowOffer: confirmLow,
          );
      if (mounted) Navigator.of(context).pop(made.negotiation.negotiationId);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      await _onFailure(error);
    }
  }

  Future<void> _onFailure(Object error) async {
    final l10n = AppLocalizations.of(context);
    if (error is ApiError && error.code == 'WARNING_LOW_OFFER') {
      final confirmed = await _confirmLowOffer(l10n);
      if (confirmed == true && mounted) await _submit(confirmLow: true);
      return;
    }
    if (error is ApiError && error.code == 'ERROR_NEGOTIATION_EXISTS') {
      final existing = error.details['negotiationId'];
      if (existing != null && mounted) {
        Navigator.of(context).pop(existing);
        return;
      }
    }
    setState(() => _error = negotiationErrorMessage(l10n, error));
  }

  Future<bool?> _confirmLowOffer(AppLocalizations l10n) => showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.offerLowTitle),
          content: Text(l10n.offerLowBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.offerKeepEditing),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.offerLowConfirm),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asking = Formatters.money(widget.askingPrice);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.offerSheetTitle, style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.offerAskingPrice(asking),
              style: AppTextStyles.bodySecondary.copyWith(color: AppColors.brandMutedText),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _amount,
              enabled: !_sending,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              textInputAction: TextInputAction.done,
              onChanged: (value) =>
                  setState(() => _error = value.isEmpty ? null : _validate(l10n, value)),
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: l10n.offerAmountLabel,
                prefixText: '₹ ',
                helperText: l10n.offerRangeHint(asking),
                errorText: _error,
                errorMaxLines: 3,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            BrandGradientButton(
              label: l10n.offerSubmit,
              isLoading: _sending,
              onPressed: _sending ? null : () => _submit(),
            ),
            if (widget.onChat != null)
              TextButton(
                onPressed: _sending ? null : widget.onChat,
                child: Text(l10n.offerChatWithSeller),
              ),
          ],
        ),
      ),
    );
  }
}
