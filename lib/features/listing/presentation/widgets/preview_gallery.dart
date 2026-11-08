import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/existing_listing.dart';
import '../providers/listing_preview_providers.dart';

/// The photos of the preview, in the seller's order. Each photo gets its own short-lived link when it
/// is shown, so one that cannot be loaded does not hide the others.
class PreviewGallery extends StatefulWidget {
  static const double height = 240;

  final List<ListingImageRef> images;

  const PreviewGallery({super.key, required this.images});

  @override
  State<PreviewGallery> createState() => _PreviewGalleryState();
}

class _PreviewGalleryState extends State<PreviewGallery> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final images = widget.images;
    if (images.isEmpty) {
      return SizedBox(
        height: PreviewGallery.height,
        child: ColoredBox(
          color: AppColors.brandMuted,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ExcludeSemantics(
                    child: Icon(Icons.image_outlined, color: AppColors.brandMutedText)),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.previewNoPhoto, style: AppTextStyles.hint),
              ],
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: PreviewGallery.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: images.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) => _PhotoPage(
              mediaId: images[index].mediaId,
              label: l10n.previewPhotoLabel(index + 1, images.length),
            ),
          ),
          if (images.length > 1)
            PositionedDirectional(
              end: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.brandSurface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    child: Text('${_page + 1} / ${images.length}', style: AppTextStyles.caption),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoPage extends ConsumerWidget {
  final String mediaId;
  final String label;

  const _PhotoPage({required this.mediaId, required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final link = ref.watch(listingPhotoLinkProvider(mediaId));
    return link.when(
      loading: () => const ColoredBox(
        color: AppColors.brandMuted,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => ColoredBox(
        color: AppColors.brandMuted,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.previewPhotoFailed, style: AppTextStyles.hint, textAlign: TextAlign.center),
              TextButton(
                onPressed: () => ref.invalidate(listingPhotoLinkProvider(mediaId)),
                child: Text(l10n.commonRetry, style: AppTextStyles.link),
              ),
            ],
          ),
        ),
      ),
      data: (photo) => Semantics(
        button: true,
        label: '$label. ${l10n.previewEnlargePhoto}',
        excludeSemantics: true,
        child: InkWell(
          onTap: () => _enlarge(context, photo.url),
          child: SizedBox.expand(child: AppImage(source: photo.url, cacheWidth: 1080)),
        ),
      ),
    );
  }

  void _enlarge(BuildContext context, String url) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.brandBackground,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: l10n.commonClose,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
            Flexible(
              child: InteractiveViewer(
                child: AppImage(source: url, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
