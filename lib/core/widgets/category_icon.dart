import 'package:flutter/material.dart';
import '../constants/app_assets.dart';
import '../theme/category_icon_catalog.g.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Stable codes take precedence over names so renamed categories keep their artwork.
IconData categoryIconFor({required String name, String? code, IconData? fallback}) =>
    categoryIconsByCode[code] ??
    categoryIconsByName[name.trim().toLowerCase()] ??
    fallback ??
    Icons.category_outlined;

/// Artwork uses exact taxonomy codes; names and parents never select leaf images.
String? categoryArtworkFor({String? code}) =>
    AppAssets.l1CategoryArtwork[AppAssets.homeCategoryArtworkCodes[code] ?? code] ??
    AppAssets.l3CategoryArtwork[code];

/// Decorative artwork; the surrounding tile supplies the accessible category label.
class CategoryIcon extends StatelessWidget {
  final String name;
  final String? code;
  final double size;
  final IconData? fallback;

  const CategoryIcon({
    super.key,
    required this.name,
    this.code,
    this.size = AppSizes.minTouchTarget,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final artwork = categoryArtworkFor(code: code);
    final decodeSize = (size * MediaQuery.devicePixelRatioOf(context))
        .ceil()
        .clamp(1, AppAssets.categoryArtworkPixelSize);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.brandSurfaceTint,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        clipBehavior: Clip.antiAlias,
        child: artwork != null
            ? Image.asset(
                artwork,
                width: size,
                height: size,
                fit: BoxFit.cover,
                cacheWidth: decodeSize,
                cacheHeight: decodeSize,
                excludeFromSemantics: true,
              )
            : Icon(
                categoryIconFor(name: name, code: code, fallback: fallback),
                size: size * 0.55,
                color: AppColors.brandPrimary,
              ),
      ),
    );
  }
}
