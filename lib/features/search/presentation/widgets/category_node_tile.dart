import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../listing/domain/category.dart';

/// One category in a list: its name and a chevron when it has sub-categories. 48 dp or taller.
class CategoryNodeTile extends StatelessWidget {
  final CategoryNode node;
  final VoidCallback onTap;

  const CategoryNodeTile({super.key, required this.node, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: AppSizes.minTouchTarget,
      contentPadding: EdgeInsets.zero,
      title: Text(node.name, style: AppTextStyles.body),
      trailing: node.hasChildren && node.level < 3
          ? const Icon(Icons.chevron_right_rounded, color: AppColors.brandMutedText)
          : null,
      onTap: onTap,
    );
  }
}
