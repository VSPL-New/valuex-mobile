import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../home/domain/entities/listing_category.dart';
import 'option_chip.dart';

/// How many rows the category chips may take before the rest move into the Others pop-up.
const int maxCategoryRows = 3;

/// Rows a wrapping group of chips with these [widths] takes in [maxWidth].
int chipRows(List<double> widths, double maxWidth, double spacing) {
  if (widths.isEmpty) return 0;
  var rows = 1;
  var used = 0.0;
  for (final raw in widths) {
    final width = math.min(raw, maxWidth);
    if (used > 0 && used + spacing + width > maxWidth) {
      rows++;
      used = width;
    } else {
      used += (used > 0 ? spacing : 0) + width;
    }
  }
  return rows;
}

/// Indexes of the chips to show: all of them when they fit in [maxRows]; otherwise as many as fit
/// together with the Others chip. A selected chip that would be hidden is kept, last.
List<int> visibleChipIndexes({
  required List<double> widths,
  required double othersWidth,
  required double maxWidth,
  required double spacing,
  int selectedIndex = -1,
  int maxRows = maxCategoryRows,
}) {
  final all = List<int>.generate(widths.length, (i) => i);
  if (chipRows(widths, maxWidth, spacing) <= maxRows) return all;
  for (var shown = widths.length - 1; shown >= 0; shown--) {
    final indexes = [
      ...all.take(shown),
      if (selectedIndex >= shown) selectedIndex,
    ];
    final rows = chipRows([for (final i in indexes) widths[i], othersWidth], maxWidth, spacing);
    if (rows <= maxRows) return indexes;
  }
  return const [];
}

/// Single-select category chips, at most [maxCategoryRows] rows. The categories that do not fit
/// are behind a last "Others" chip that opens a pop-up with them.
class CategoryChips extends StatelessWidget {
  final List<ListingCategory> categories;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final String othersLabel;
  final String closeLabel;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    required this.othersLabel,
    required this.closeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final selectedIndex = categories.indexWhere((c) => c.id == selectedId);
        final widths = [
          for (var i = 0; i < categories.length; i++)
            _chipWidth(context, categories[i].name, i == selectedIndex, constraints.maxWidth),
        ];
        final indexes = visibleChipIndexes(
          widths: widths,
          othersWidth: _chipWidth(context, othersLabel, false, constraints.maxWidth),
          maxWidth: constraints.maxWidth,
          spacing: AppSpacing.sm,
          selectedIndex: selectedIndex,
        );
        final hidden = [
          for (var i = 0; i < categories.length; i++)
            if (!indexes.contains(i)) categories[i],
        ];
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: 0,
          children: [
            for (final i in indexes)
              OptionChip(
                label: categories[i].name,
                selected: i == selectedIndex,
                onTap: () => onSelected(categories[i].id),
              ),
            if (hidden.isNotEmpty)
              OptionChip(
                label: othersLabel,
                selected: false,
                isAction: true,
                onTap: () => _showOthers(context, hidden),
              ),
          ],
        );
      },
    );
  }

  double _chipWidth(BuildContext context, String label, bool selected, double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: OptionChip.textStyle(selected: selected)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width =
        painter.width + OptionChip.padding.horizontal + (selected ? 4 + OptionChip.checkWidth : 2);
    painter.dispose();
    return math.min(width.ceilToDouble(), maxWidth);
  }

  Future<void> _showOthers(BuildContext context, List<ListingCategory> hidden) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Semantics(header: true, child: Text(othersLabel, style: AppTextStyles.heading2)),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: 0,
            children: [
              for (final category in hidden)
                OptionChip(
                  label: category.name,
                  selected: category.id == selectedId,
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    onSelected(category.id);
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(closeLabel)),
        ],
      ),
    );
  }
}
