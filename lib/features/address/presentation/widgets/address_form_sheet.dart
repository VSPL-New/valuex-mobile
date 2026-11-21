import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/widgets/state_picker_field.dart';
import '../../data/address_repository.dart';
import '../../domain/address_details.dart';
import '../../domain/address_value.dart';
import '../../domain/indian_state_names.dart';
import '../../domain/saved_address.dart';
import '../providers/address_providers.dart';
import 'address_search_field.dart';
import 'address_verification_status.dart';

/// Opens the new address form (US-020) and returns the address that was saved, or null when the
/// buyer closed it. [hasSavedAddresses] says whether a "make this my default" switch makes sense: the
/// first address a user saves is the default without asking.
Future<SavedAddress?> showAddressFormSheet(BuildContext context,
    {required bool hasSavedAddresses}) {
  return showModalBottomSheet<SavedAddress>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.brandBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) => AddressFormSheet(hasSavedAddresses: hasSavedAddresses),
  );
}

enum _NameChoice { none, home, office, other }

/// The address form: search a place or type the address, pick the state, name it, and save. The
/// backend checks the address again before it saves, and the check shown while typing is only a hint.
class AddressFormSheet extends ConsumerStatefulWidget {
  final bool hasSavedAddresses;

  const AddressFormSheet({super.key, required this.hasSavedAddresses});

  @override
  ConsumerState<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<AddressFormSheet> {
  static final RegExp _pincode = RegExp(r'^[1-9]\d{5}$');

  final _line = TextEditingController();
  final _landmark = TextEditingController();
  final _city = TextEditingController();
  final _pincodeField = TextEditingController();
  final _custom = TextEditingController();
  String? _state;
  String? _placeId;
  _NameChoice _name = _NameChoice.none;
  bool _makeDefault = false;
  bool _busy = false;
  String? _saveError;

  @override
  void dispose() {
    for (final controller in [_line, _landmark, _city, _pincodeField, _custom]) {
      controller.dispose();
    }
    super.dispose();
  }

  AddressValue? get _value {
    final line = _line.text.trim();
    final city = _city.text.trim();
    final state = _state;
    final pincode = _pincodeField.text.trim();
    if (line.length < 10 || city.length < 2 || state == null || !_pincode.hasMatch(pincode)) {
      return null;
    }
    final landmark = _landmark.text.trim();
    return AddressValue(
      address: line,
      landmark: landmark.isEmpty ? null : landmark,
      city: city,
      state: state,
      pincode: pincode,
      placeId: _placeId,
    );
  }

  void _changed({bool edited = true}) {
    if (edited) _placeId = null;
    setState(() => _saveError = null);
    final value = _value;
    final check = ref.read(addressVerificationProvider.notifier);
    value == null ? check.reset() : check.schedule(value);
  }

  void _fill(AddressDetails details) {
    _line.text = details.line1;
    _city.text = details.city;
    _pincodeField.text = details.pincode;
    _state = normalizeIndianState(details.state);
    _placeId = details.placeId;
    _changed(edited: false);
  }

  String? _label(AppLocalizations l10n) => switch (_name) {
        _NameChoice.none => null,
        _NameChoice.home => l10n.cartAddressNameHome,
        _NameChoice.office => l10n.cartAddressNameOffice,
        _NameChoice.other => _custom.text.trim().isEmpty ? l10n.cartAddressNameOther : _custom.text,
      };

  Future<void> _save() async {
    final value = _value;
    if (value == null || _busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _saveError = null;
    });
    try {
      final saved = await ref.read(addressRepositoryProvider).create(
            value,
            label: _label(l10n),
            makeDefault: widget.hasSavedAddresses && _makeDefault,
          );
      if (mounted) Navigator.of(context).pop(saved);
    } on Object catch (error) {
      if (!mounted) return;
      if (error is ApiError && isAddressRejection(error)) {
        ref.read(addressVerificationProvider.notifier).reject(error, value);
        setState(() => _busy = false);
        return;
      }
      setState(() {
        _busy = false;
        _saveError = l10n.cartAddressSaveFailed;
      });
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.words,
    List<TextInputFormatter>? formatters,
    int? maxLength,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Text(label, style: AppTextStyles.label)),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          label: label,
          textField: true,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: capitalization,
            inputFormatters: formatters,
            maxLength: maxLength,
            onChanged: (_) => _changed(),
            style: AppTextStyles.input,
            cursorColor: AppColors.brandPrimary,
            decoration: InputDecoration(hintText: hint, counterText: ''),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.cartAddressTitle, style: AppTextStyles.heading2),
            ),
            const SizedBox(height: AppSpacing.md),
            AddressSearchField(onSelected: _fill),
            const SizedBox(height: AppSpacing.md),
            _field(l10n.cartAddressLine, _line),
            const SizedBox(height: AppSpacing.md),
            _field(l10n.addressLandmarkLabel, _landmark, hint: l10n.addressLandmarkHint),
            const SizedBox(height: AppSpacing.md),
            _field(l10n.cartAddressCity, _city),
            const SizedBox(height: AppSpacing.md),
            ExcludeSemantics(child: Text(l10n.signupStateLabel, style: AppTextStyles.label)),
            const SizedBox(height: AppSpacing.sm),
            StatePickerField(
              value: _state,
              onChanged: (state) {
                _state = state;
                _changed();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _field(
              l10n.cartAddressPincode,
              _pincodeField,
              keyboardType: TextInputType.number,
              capitalization: TextCapitalization.none,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
            ),
            const SizedBox(height: AppSpacing.sm),
            const AddressVerificationStatus(),
            const SizedBox(height: AppSpacing.md),
            ExcludeSemantics(child: Text(l10n.cartAddressName, style: AppTextStyles.label)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final (choice, text) in [
                  (_NameChoice.home, l10n.cartAddressNameHome),
                  (_NameChoice.office, l10n.cartAddressNameOffice),
                  (_NameChoice.other, l10n.cartAddressNameOther),
                ])
                  ChoiceChip(
                    label: Text(text),
                    selected: _name == choice,
                    onSelected: (selected) =>
                        setState(() => _name = selected ? choice : _NameChoice.none),
                  ),
              ],
            ),
            if (_name == _NameChoice.other) ...[
              const SizedBox(height: AppSpacing.sm),
              _field(l10n.cartAddressNameCustom, _custom, maxLength: 50),
            ],
            const SizedBox(height: AppSpacing.md),
            if (widget.hasSavedAddresses)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _makeDefault,
                onChanged: (value) => setState(() => _makeDefault = value),
                title: Text(l10n.cartAddressMakeDefault, style: AppTextStyles.body),
              )
            else
              Text(l10n.cartAddressFirstIsDefault, style: AppTextStyles.hint),
            if (_saveError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  _saveError!,
                  style: AppTextStyles.hint.copyWith(color: AppColors.brandError),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            BrandGradientButton(
              label: l10n.cartAddressSave,
              isLoading: _busy,
              onPressed: _value == null || _busy ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
