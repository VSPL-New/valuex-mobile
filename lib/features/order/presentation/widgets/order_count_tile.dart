import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';

/// A count shown on a tile or badge: up to 99, then "99+".
String cappedCount(int count) => count > 99 ? '99+' : '$count';

/// One of the four count tiles (New, Packing, Scheduled, Shipped). The full number is shown; the
/// tile is read as one phrase, for example "1, New".
class OrderCountTile extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;

  const OrderCountTile({super.key, required this.icon, required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.brandSurface,
          border: Border.all(color: AppColors.brandBorder),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            ExcludeSemantics(child: Icon(icon, size: 20, color: AppColors.brandForeground)),
            Text('$count', style: AppTextStyles.sectionTitle.copyWith(fontWeight: FontWeight.w700)),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(letterSpacing: 0),
            ),
          ],
        ),
      ),
    );
  }
}
