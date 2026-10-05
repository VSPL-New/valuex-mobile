import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/colors.dart';

/// The one widget every screen uses to show the logo; replace
/// `assets/images/logo.png` to change it app-wide.
class BrandLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Page colour the logo sits on. The current PNG has an opaque white
  /// backdrop, so it is multiplied into this colour; pass null to disable
  /// once the logo is transparent.
  final Color? blendWith;

  const BrandLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.blendWith = AppColors.brandBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.logo,
      width: width,
      height: height,
      fit: fit,
      color: blendWith,
      colorBlendMode: blendWith == null ? null : BlendMode.multiply,
      semanticLabel: 'JustQlic',
    );
  }
}
