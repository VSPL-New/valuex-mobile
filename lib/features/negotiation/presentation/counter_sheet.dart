import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand_gradient_button.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/negotiation.dart';
import 'negotiation_format.dart';

/// Opens the counter offer sheet (US-017) and answers with the amount as decimal text, or null when
/// it is closed without one. The corridor comes from the server, which checks it again.
Future<String?> showCounterSheet(BuildContext context, {required CounterRange range}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.brandSurface,
    builder: (context) => CounterSheet(range: range),
  );
}

class CounterSheet extends StatefulWidget {
  final CounterRange range;

  const CounterSheet({super.key, required this.range});

  @override
  State<CounterSheet> createState() => _CounterSheetState();
}

class _CounterSheetState extends State<CounterSheet> {
  final _amount = TextEditingController();
  String? _error;

  /// The slider moves in whole rupees between the ends of the corridor; the field takes paise too.
  late final double _sliderMin = widget.range.min.ceilToDouble();
  late final double _sliderMax = widget.range.max.floorToDouble();
  bool get _hasSlider => _sliderMax > _sliderMin;

  /// Where the slider stands for what is typed: the typed amount held inside the slider's ends, and
  /// the low end while nothing valid is typed.
  double get _sliderValue {
    final typed = parseOfferAmount(_amount.text);
    return typed == null ? _sliderMin : double.parse(typed).clamp(_sliderMin, _sliderMax);
  }

  void _slide(double value) {
    final rupees = value.round();
    _amount.value = TextEditingValue(
      text: '$rupees',
      selection: TextSelection.collapsed(offset: '$rupees'.length),
    );
    setState(() => _error = _validate(AppLocalizations.of(context), _amount.text));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  String? _validate(AppLocalizations l10n, String raw) {
    if (raw.trim().isEmpty) return l10n.offerAmountRequired;
    final amount = parseOfferAmount(raw);
    if (amount == null) return l10n.offerAmountInvalid;
    final value = paise(double.parse(amount));
    if (value < paise(widget.range.min) || value > paise(widget.range.max)) {
      return l10n.counterAmountOutOfRange(
        Formatters.money(widget.range.min),
        Formatters.money(widget.range.max),
      );
    }
    return null;
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final problem = _validate(l10n, _amount.text);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    Navigator.of(context).pop(parseOfferAmount(_amount.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hint = l10n.counterRangeHint(
      Formatters.money(widget.range.min),
      Formatters.money(widget.range.max),
    );
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
            Text(l10n.counterSheetTitle, style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _amount,
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
                helperText: hint,
                helperMaxLines: 2,
                errorText: _error,
                errorMaxLines: 3,
              ),
            ),
            if (_hasSlider) ...[
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                label: l10n.counterSliderLabel,
                child: Slider(
                  min: _sliderMin,
                  max: _sliderMax,
                  value: _sliderValue,
                  semanticFormatterCallback: (value) => Formatters.money(value.round()),
                  onChanged: _slide,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            BrandGradientButton(label: l10n.counterSubmit, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
