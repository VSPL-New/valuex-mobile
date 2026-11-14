import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/public_listing.dart';

class ListingAttributeTable extends StatelessWidget {
  final List<ListingAttribute> attributes;

  const ListingAttributeTable({super.key, required this.attributes});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.brandBorder),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          for (var i = 0; i < attributes.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.brandBorder),
            ColoredBox(
              color: i.isEven ? AppColors.brandBackground : AppColors.brandSurface,
              child: _AttributeRow(attribute: attributes[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttributeRow extends StatelessWidget {
  final ListingAttribute attribute;

  const _AttributeRow({required this.attribute});

  @override
  Widget build(BuildContext context) {
    final value = formatAttributeValue(AppLocalizations.of(context), attribute);
    return Semantics(
      container: true,
      label: '${attribute.label}: $value',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked =
                constraints.maxWidth < 260 || MediaQuery.textScalerOf(context).scale(14) > 20;
            final label = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_attributeIcon(attribute.key), size: 16, color: AppColors.brandAccent),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(attribute.label, style: AppTextStyles.bodySecondary)),
              ],
            );
            final text = Text(
              value,
              textAlign: stacked ? TextAlign.start : TextAlign.end,
              style: AppTextStyles.cardTitle,
            );
            return stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      label,
                      const SizedBox(height: AppSpacing.xs),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: AppSpacing.lg),
                        child: text,
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: label),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: text),
                    ],
                  );
          },
        ),
      ),
    );
  }

  // Use stable schema keys, not translated labels; unfamiliar categories keep a neutral icon.
  static IconData _attributeIcon(String key) => switch (key) {
        'battery' || 'battery_health_pct' => Icons.battery_charging_full_rounded,
        'has_box' => Icons.inventory_2_outlined,
        'accessories' => Icons.cable_rounded,
        'storage' || 'storage_gb' => Icons.storage_rounded,
        'model' => Icons.label_outline_rounded,
        _ => Icons.tune_rounded,
      };
}

/// Yes/No for a boolean, a comma list for several values, followed by its optional unit.
String formatAttributeValue(AppLocalizations l10n, ListingAttribute attribute) {
  final value = attribute.value;
  final text = switch (value) {
    bool flag => flag ? l10n.itemYes : l10n.itemNo,
    List<dynamic> items => items.join(', '),
    num number => number == number.roundToDouble() ? '${number.toInt()}' : '$number',
    _ => '$value',
  };
  final unit = attribute.unit;
  return unit == null || unit.isEmpty || value is bool ? text : '$text $unit';
}
