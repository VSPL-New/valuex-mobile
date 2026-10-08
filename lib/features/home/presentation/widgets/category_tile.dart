import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/listing_category.dart';

/// One category: a picture and its name. The whole tile is a 48 dp or larger tap area.
class CategoryTile extends StatelessWidget {
  final String name;
  final String? image;
  final bool isMore;
  final VoidCallback onTap;

  const CategoryTile({
    super.key,
    required this.name,
    required this.onTap,
    this.image,
    this.isMore = false,
  });

  static const double _maxImage = 48;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.md);
    return Semantics(
      button: true,
      label: name,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.maxWidth < _maxImage ? constraints.maxWidth : _maxImage;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: side,
                  height: side,
                  child: ClipRRect(
                    borderRadius: radius,
                    child: isMore
                        ? ColoredBox(
                            color: AppColors.brandSurfaceTint,
                            child: Center(
                              child:
                                  SvgPicture.asset(AppAssets.homeMoreIcon, width: 22, height: 22),
                            ),
                          )
                        : AppImage(source: image ?? '', cacheWidth: 160),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(color: AppColors.brandForeground),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The first five categories in a row that scrolls sideways, and a More tile that stays in view.
/// Tiles are as wide as the text needs, so names are never cut or broken inside a word.
class CategoryRow extends StatelessWidget {
  final List<ListingCategory> categories;
  final ValueChanged<ListingCategory> onSelect;
  final VoidCallback onMore;

  const CategoryRow({
    super.key,
    required this.categories,
    required this.onSelect,
    required this.onMore,
  });

  static const int visibleCount = 5;
  static const double _tileWidth = 68;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scale = (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(1.0, 2.0);
    final width = _tileWidth * scale;
    final shown = categories.take(visibleCount).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final category in shown)
                  SizedBox(
                    width: width,
                    child: CategoryTile(
                      name: category.name,
                      image: category.image,
                      onTap: () => onSelect(category),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: width,
          child: CategoryTile(name: l10n.homeMore, isMore: true, onTap: onMore),
        ),
      ],
    );
  }
}
