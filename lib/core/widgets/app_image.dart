import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// An image from an asset path (sample data) or a network URL, with a neutral fallback.
/// It is decorative: the caller labels the control that contains it.
class AppImage extends StatelessWidget {
  final String source;
  final BoxFit fit;

  /// Decode width in physical pixels; keeps large images cheap in lists.
  final int? cacheWidth;

  const AppImage({super.key, required this.source, this.fit = BoxFit.cover, this.cacheWidth});

  bool get _isAsset => source.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    if (source.isEmpty) return const ExcludeSemantics(child: _Fallback());
    final image = _isAsset
        ? Image.asset(
            source,
            fit: fit,
            cacheWidth: cacheWidth,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stack) => const _Fallback(),
          )
        : CachedNetworkImage(
            imageUrl: source,
            fit: fit,
            memCacheWidth: cacheWidth,
            placeholder: (context, url) => const ColoredBox(color: AppColors.brandMuted),
            errorWidget: (context, url, error) => const _Fallback(),
          );
    return ExcludeSemantics(child: image);
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.brandMuted,
      child: Center(child: Icon(Icons.image_outlined, color: AppColors.brandMutedText)),
    );
  }
}
