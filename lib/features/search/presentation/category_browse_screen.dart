import 'package:flutter/material.dart';
import '../../listing/domain/category.dart';
import 'search_screen.dart';

/// Keeps existing category deep links on the shared, single-screen browser.
class CategoryBrowseScreen extends StatelessWidget {
  final String? parentCode;
  final String? parentName;
  final int? parentLevel;
  final bool realEstate;

  const CategoryBrowseScreen({
    super.key,
    this.parentCode,
    this.parentName,
    this.parentLevel,
    this.realEstate = false,
  });

  @override
  Widget build(BuildContext context) => SearchScreen(
        browseParent: parentCode == null
            ? null
            : CategoryNode(
                code: parentCode!,
                name: parentName ?? parentCode!,
                level: parentLevel ?? 1,
                hasChildren: true,
              ),
        browseRealEstate: realEstate,
      );
}
