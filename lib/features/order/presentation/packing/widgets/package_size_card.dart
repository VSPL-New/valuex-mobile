import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/packing.dart';

/// The four controllers of the packed size; [read] gives the values once all are valid.
class PackageSizeFields {
  final TextEditingController weight = TextEditingController();
  final TextEditingController length = TextEditingController();
  final TextEditingController breadth = TextEditingController();
  final TextEditingController height = TextEditingController();

  /// Prefills the size the seller already confirmed; an empty field stays for the seller to fill.
  void fill(PackageSize? size) {
    if (size == null) return;
    String text(double value) =>
        value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';
    weight.text = text(size.weightKg);
    length.text = text(size.lengthCm);
    breadth.text = text(size.breadthCm);
    height.text = text(size.heightCm);
  }

  PackageSize? read() {
    final kg = parse(weight.text);
    final sides = [parse(length.text), parse(breadth.text), parse(height.text)];
    if (!PackageSize.validWeight(kg) || !sides.every(PackageSize.validSide)) return null;
    return PackageSize(
        weightKg: kg!, lengthCm: sides[0]!, breadthCm: sides[1]!, heightCm: sides[2]!);
  }

  static double? parse(String? text) => double.tryParse((text ?? '').trim());

  void dispose() {
    weight.dispose();
    length.dispose();
    breadth.dispose();
    height.dispose();
  }
}

/// "Packed size and weight" (plan G11): not in the Make design; the courier booking needs it
/// (LLD C.4.1). Built from the app's form fields, in the same card style as the photo sections.
class PackageSizeCard extends StatelessWidget {
  final PackageSizeFields fields;

  const PackageSizeCard({super.key, required this.fields});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String? weight(String? value) =>
        PackageSize.validWeight(PackageSizeFields.parse(value)) ? null : l10n.packingWeightInvalid;
    String? side(String? value) =>
        PackageSize.validSide(PackageSizeFields.parse(value)) ? null : l10n.packingSideInvalid;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandSurface,
        border: Border.all(color: AppColors.brandBorder),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.packingSizeTitle, style: AppTextStyles.cardTitle),
            ),
            Text(l10n.packingSizeHint, style: AppTextStyles.caption),
            const SizedBox(height: 12),
            _field(fields.weight, l10n.packingWeight, weight),
            const SizedBox(height: 12),
            _field(fields.length, l10n.packingLength, side),
            const SizedBox(height: 12),
            _field(fields.breadth, l10n.packingBreadth, side),
            const SizedBox(height: 12),
            _field(fields.height, l10n.packingHeight, side),
          ],
        ),
      ),
    );
  }

  static Widget _field(
      TextEditingController controller, String label, String? Function(String?) validator) {
    return AppTextField(
      controller: controller,
      label: label,
      validator: validator,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), _maxLength],
    );
  }

  static final TextInputFormatter _maxLength = LengthLimitingTextInputFormatter(6);
}
