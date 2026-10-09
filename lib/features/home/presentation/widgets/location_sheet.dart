import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../core/widgets/field_error.dart';
import '../../../../core/widgets/single_tone_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/widgets/state_picker_field.dart';
import '../../domain/entities/home_location.dart';
import '../providers/home_providers.dart';

/// Lets the user switch to the device location or type an address.
/// Placeholder for the address component of US-108, which will replace the typed fields.
Future<void> showLocationSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.brandBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) => const _LocationSheet(),
  );
}

class _LocationSheet extends ConsumerStatefulWidget {
  const _LocationSheet();

  @override
  ConsumerState<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends ConsumerState<_LocationSheet> {
  final _area = TextEditingController();
  final _city = TextEditingController();
  String? _state;
  bool _cityError = false;
  bool _stateError = false;

  @override
  void dispose() {
    _area.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final validCity = Validators.isValidCity(_city.text);
    final validState = _state != null;
    setState(() {
      _cityError = !validCity;
      _stateError = !validState;
    });
    if (!validCity || !validState) return;

    final navigator = Navigator.of(context);
    await ref.read(homeLocationControllerProvider.notifier).useAddress(
          HomeLocation(city: _city.text.trim(), area: _area.text.trim(), state: _state),
        );
    navigator.pop();
  }

  Future<void> _useDevice() async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await ref.read(homeLocationControllerProvider.notifier).useDeviceLocation();
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String semanticsLabel,
    String? error,
    TextInputAction action = TextInputAction.next,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          label: semanticsLabel,
          textField: true,
          child: TextField(
            controller: controller,
            textInputAction: action,
            textCapitalization: TextCapitalization.words,
            style: AppTextStyles.input,
            onChanged: (_) {
              if (_cityError || _stateError) setState(() => _cityError = _stateError = false);
            },
            decoration: InputDecoration(
              hintText: hint,
              error: error == null ? null : FieldError(text: error),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.homeLocationSheetTitle, style: AppTextStyles.heading2),
            ),
            const SizedBox(height: AppSpacing.md),
            SingleToneButton(label: l10n.homeUseMyLocation, onPressed: _useDevice),
            const SizedBox(height: AppSpacing.md),
            _field(
              label: l10n.homeAreaLabel,
              hint: l10n.homeAreaHint,
              controller: _area,
              semanticsLabel: l10n.homeAreaLabel,
            ),
            const SizedBox(height: AppSpacing.md),
            _field(
              label: l10n.homeCityLabel,
              hint: l10n.homeCityHint,
              controller: _city,
              semanticsLabel: l10n.homeCityLabel,
              error: _cityError ? l10n.homeCityError : null,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.signupStateLabel, style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            StatePickerField(
              value: _state,
              errorText: _stateError ? l10n.homeStateError : null,
              onChanged: (value) => setState(() {
                _state = value;
                _stateError = false;
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            BrandGradientButton(label: l10n.homeSaveLocation, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
