import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/listing_schema.dart';
import 'option_chip.dart';

/// One category-specific question, drawn to match its type: text, number, yes/no, date, one or
/// several options, a list, dimensions or free key/value details. Values go out as JSON-ready
/// objects (see ListingDetailsDraft.attributes); a blank value clears the field.
class SchemaFieldInput extends StatelessWidget {
  /// Up to this many options are shown as chips; longer lists open a searchable sheet.
  static const int maxChipOptions = 8;

  final SchemaField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  const SchemaFieldInput({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return switch (field.type) {
      FieldType.text => _TextInput(field: field, value: value, onChanged: onChanged),
      FieldType.longText =>
        _TextInput(field: field, value: value, onChanged: onChanged, multiline: true),
      FieldType.integer || FieldType.decimal => _NumberInput(
          field: field,
          value: value,
          onChanged: onChanged,
        ),
      FieldType.boolean => _YesNo(value: value, onChanged: onChanged),
      FieldType.date => _DateInput(field: field, value: value, onChanged: onChanged),
      FieldType.option => field.options.length <= maxChipOptions
          ? _OptionChips(field: field, value: value, onChanged: onChanged)
          : _OptionSheetButton(field: field, value: value, onChanged: onChanged),
      FieldType.multiOption => field.options.length <= maxChipOptions
          ? _MultiChips(field: field, value: value, onChanged: onChanged)
          : _OptionSheetButton(field: field, value: value, onChanged: onChanged, multi: true),
      FieldType.optionOrText => _OptionOrText(field: field, value: value, onChanged: onChanged),
      FieldType.textList => _TextListInput(field: field, value: value, onChanged: onChanged),
      FieldType.object => _DimensionsInput(value: value, onChanged: onChanged),
      FieldType.json => _KeyValueInput(field: field, value: value, onChanged: onChanged),
    };
  }
}

String _labelOf(SchemaField field, String? code) {
  for (final option in field.options) {
    if (option.code == code) return option.label;
  }
  return code ?? '';
}

class _TextInput extends StatefulWidget {
  final SchemaField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;
  final bool multiline;

  const _TextInput({
    required this.field,
    required this.value,
    required this.onChanged,
    this.multiline = false,
  });

  @override
  State<_TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<_TextInput> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value as String? ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      maxLines: widget.multiline ? 3 : 1,
      maxLength: widget.field.maxLength,
      keyboardType: widget.multiline ? TextInputType.multiline : TextInputType.text,
      onChanged: widget.onChanged,
    );
  }
}

/// Numbers are kept as typed (so "1,200" and "12." survive editing) and parsed when saved.
class _NumberInput extends StatefulWidget {
  final SchemaField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  const _NumberInput({required this.field, required this.value, required this.onChanged});

  @override
  State<_NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<_NumberInput> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value == null ? '' : '${widget.value}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final decimal = widget.field.type == FieldType.decimal;
    final negative = (widget.field.min ?? 0) < 0;
    return AppTextField(
      controller: _controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal, signed: negative),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(decimal ? r'[0-9.,-]' : r'[0-9,-]')),
      ],
      onChanged: widget.onChanged,
    );
  }
}

class _YesNo extends StatelessWidget {
  final Object? value;
  final ValueChanged<Object?> onChanged;

  const _YesNo({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        OptionChip(label: l10n.itemYes, selected: value == true, onTap: () => onChanged(true)),
        OptionChip(label: l10n.itemNo, selected: value == false, onTap: () => onChanged(false)),
      ],
    );
  }
}

class _DateInput extends StatelessWidget {
  final SchemaField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  const _DateInput({required this.field, required this.value, required this.onChanged});

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse('$value') ?? now,
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 30),
    );
    if (picked != null) {
      final month = picked.month.toString().padLeft(2, '0');
      final day = picked.day.toString().padLeft(2, '0');
      onChanged('${picked.year}-$month-$day');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = value is String && (value as String).isNotEmpty ? value as String : null;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: OutlinedButton.icon(
        onPressed: () => _pick(context),
        icon: const Icon(Icons.event_outlined),
        label: Text(text ?? l10n.itemSelectDate),
      ),
    );
  }
}

class _OptionChips extends StatelessWidget {
  final SchemaField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  const _OptionChips({required this.field, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final option in field.options)
          OptionChip(
            label: option.label,
            selected: value == option.code,
            onTap: () => onChanged(option.code),
          ),
      ],
    );
  }
}

class _MultiChips extends StatelessWidget {
  final SchemaField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  const _MultiChips({required this.field, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final selected = <String>{if (value is List) ...(value as List).cast<String>()};
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final option in field.options)
          OptionChip(
            label: option.label,
            selected: selected.contains(option.code),
            onTap: () {
              final next = {...selected};
              if (!next.add(option.code)) next.remove(option.code);
              onChanged(next.toList());
            },
          ),
      ],
    );
  }
}

/// A long list of options: a button showing the choice that opens a searchable sheet.
class _OptionSheetButton extends StatelessWidget {
  final SchemaField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;
  final bool multi;

  const _OptionSheetButton({
    required this.field,
    required this.value,
    required this.onChanged,
    this.multi = false,
  });

  String _summary(AppLocalizations l10n) {
    if (multi) {
      final codes = value is List ? (value as List).cast<String>() : const <String>[];
      return codes.isEmpty ? l10n.itemSelect : codes.map((c) => _labelOf(field, c)).join(', ');
    }
    return value == null ? l10n.itemSelect : _labelOf(field, '$value');
  }

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OptionSheet(field: field, value: value, multi: multi),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: OutlinedButton.icon(
        onPressed: () => _open(context),
        icon: const Icon(Icons.arrow_drop_down_rounded),
        label: Text(_summary(l10n), overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _OptionSheet extends StatefulWidget {
  final SchemaField field;
  final Object? value;
  final bool multi;

  const _OptionSheet({required this.field, required this.value, required this.multi});

  @override
  State<_OptionSheet> createState() => _OptionSheetState();
}

class _OptionSheetState extends State<_OptionSheet> {
  late final Set<String> _selected = {
    if (widget.multi && widget.value is List) ...(widget.value as List).cast<String>(),
  };
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = [
      for (final option in widget.field.options)
        if (option.label.toLowerCase().contains(_query.toLowerCase())) option,
    ];
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppTextField(
                  hint: l10n.itemSearch,
                  prefixIcon: const Icon(Icons.search_rounded),
                  onChanged: (text) => setState(() => _query = text),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final option in options)
                      if (widget.multi)
                        CheckboxListTile(
                          value: _selected.contains(option.code),
                          title: Text(option.label),
                          onChanged: (on) => setState(() {
                            if (on ?? false) {
                              _selected.add(option.code);
                            } else {
                              _selected.remove(option.code);
                            }
                          }),
                        )
                      else
                        ListTile(
                          title: Text(option.label),
                          selected: widget.value == option.code,
                          onTap: () => Navigator.of(context).pop(option.code),
                        ),
                  ],
                ),
              ),
              if (widget.multi)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_selected.toList()),
                    child: Text(l10n.itemDone),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Free text with the known options offered as quick picks.
class _OptionOrText extends StatefulWidget {
  final SchemaField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  const _OptionOrText({required this.field, required this.value, required this.onChanged});

  @override
  State<_OptionOrText> createState() => _OptionOrTextState();
}

class _OptionOrTextState extends State<_OptionOrText> {
  late final TextEditingController _controller =
      TextEditingController(text: _labelOf(widget.field, widget.value as String?));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quick = widget.field.options.take(SchemaFieldInput.maxChipOptions);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final option in quick)
              OptionChip(
                label: option.label,
                selected: widget.value == option.code,
                onTap: () {
                  _controller.text = option.label;
                  widget.onChanged(option.code);
                },
              ),
          ],
        ),
        AppTextField(
          controller: _controller,
          hint: l10n.itemOtherValueHint,
          maxLength: widget.field.maxLength,
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}

/// A list typed as comma-separated text.
class _TextListInput extends StatefulWidget {
  final SchemaField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  const _TextListInput({required this.field, required this.value, required this.onChanged});

  @override
  State<_TextListInput> createState() => _TextListInputState();
}

class _TextListInputState extends State<_TextListInput> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value is List ? (widget.value as List).join(', ') : '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      hint: AppLocalizations.of(context).itemListHint,
      onChanged: (text) => widget.onChanged([
        for (final part in text.split(','))
          if (part.trim().isNotEmpty) part.trim(),
      ]),
    );
  }
}

/// Length, width and height in centimetres.
class _DimensionsInput extends StatefulWidget {
  final Object? value;
  final ValueChanged<Object?> onChanged;

  const _DimensionsInput({required this.value, required this.onChanged});

  @override
  State<_DimensionsInput> createState() => _DimensionsInputState();
}

class _DimensionsInputState extends State<_DimensionsInput> {
  static const _keys = ['length', 'width', 'height'];
  late final Map<String, TextEditingController> _controllers = {
    for (final key in _keys)
      key: TextEditingController(
          text: widget.value is Map ? '${(widget.value as Map)[key] ?? ''}' : ''),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _changed() {
    final result = <String, num>{};
    for (final key in _keys) {
      final number = num.tryParse(_controllers[key]!.text.trim());
      if (number != null) result[key] = number;
    }
    widget.onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = {
      'length': l10n.itemDimLength,
      'width': l10n.itemDimWidth,
      'height': l10n.itemDimHeight,
    };
    return Row(
      children: [
        for (final key in _keys) ...[
          Expanded(
            child: AppTextField(
              controller: _controllers[key],
              hint: labels[key],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              onChanged: (_) => _changed(),
            ),
          ),
          if (key != _keys.last) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// Free name/value pairs for items that fit no category (at most the server's limit).
class _KeyValueInput extends StatefulWidget {
  final SchemaField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  const _KeyValueInput({required this.field, required this.value, required this.onChanged});

  @override
  State<_KeyValueInput> createState() => _KeyValueInputState();
}

class _Pair {
  final TextEditingController name;
  final TextEditingController value;

  _Pair(String name, String value)
      : name = TextEditingController(text: name),
        value = TextEditingController(text: value);

  void dispose() {
    name.dispose();
    value.dispose();
  }
}

class _KeyValueInputState extends State<_KeyValueInput> {
  late final List<_Pair> _pairs = [
    if (widget.value is Map)
      for (final entry in (widget.value as Map).entries) _Pair('${entry.key}', '${entry.value}'),
  ];

  @override
  void dispose() {
    for (final pair in _pairs) {
      pair.dispose();
    }
    super.dispose();
  }

  void _changed() {
    widget.onChanged({
      for (final pair in _pairs)
        if (pair.name.text.trim().isNotEmpty && pair.value.text.trim().isNotEmpty)
          pair.name.text.trim(): pair.value.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final limit = widget.field.maxItems ?? 20;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _pairs.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                      controller: _pairs[i].name,
                      hint: l10n.itemDetailName,
                      onChanged: (_) => _changed()),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextField(
                      controller: _pairs[i].value,
                      hint: l10n.itemDetailValue,
                      onChanged: (_) => _changed()),
                ),
                IconButton(
                  tooltip: l10n.itemRemoveDetail,
                  icon: const Icon(Icons.close_rounded, color: AppColors.brandForeground),
                  onPressed: () => setState(() {
                    _pairs.removeAt(i).dispose();
                    _changed();
                  }),
                ),
              ],
            ),
          ),
        if (_pairs.length < limit)
          TextButton.icon(
            onPressed: () => setState(() => _pairs.add(_Pair('', ''))),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.itemAddDetail, style: AppTextStyles.label),
          ),
      ],
    );
  }
}
