import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/public_listing.dart';

/// The photos of a listing: swipe through the detail size, jump with the thumbnail strip, tap one
/// for the full-resolution view. A photo that fails to load shows a placeholder; the rest stay.
class ListingGallery extends StatefulWidget {
  static const double height = 280;
  static const double _thumbSize = 56;

  final List<ListingPhoto> photos;

  /// Asked for when signed links may have expired and the buyer taps Refresh.
  final VoidCallback? onRefresh;

  const ListingGallery({super.key, required this.photos, this.onRefresh});

  @override
  State<ListingGallery> createState() => _ListingGalleryState();
}

class _ListingGalleryState extends State<ListingGallery> {
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
    final photos = widget.photos;
    if (photos.isEmpty) {
      return SizedBox(
        height: ListingGallery.height,
        child: ColoredBox(
          color: AppColors.brandMuted,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ExcludeSemantics(
                  child: Icon(Icons.image_outlined, color: AppColors.brandMutedText),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.previewNoPhoto, style: AppTextStyles.hint),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: ListingGallery.height,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: photos.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) => Semantics(
                  button: true,
                  label:
                      '${l10n.previewPhotoLabel(index + 1, photos.length)}. ${l10n.previewEnlargePhoto}',
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => _enlarge(context, photos[index]),
                    child: SizedBox.expand(
                      child: AppImage(source: photos[index].detailUrl, cacheWidth: 1080),
                    ),
                  ),
                ),
              ),
              if (photos.length > 1)
                PositionedDirectional(
                  end: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  child: ExcludeSemantics(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.brandMutedText,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: Text(
                          '${_page + 1} / ${photos.length}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.brandOnPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.onRefresh != null)
                PositionedDirectional(
                  end: AppSpacing.sm,
                  top: AppSpacing.sm,
                  child: IconButton.filled(
                    tooltip: l10n.listingViewRefreshPhotos,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.brandSurface,
                      foregroundColor: AppColors.brandLink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      minimumSize: const Size(
                        AppSizes.minTouchTarget,
                        AppSizes.minTouchTarget,
                      ),
                    ),
                    onPressed: widget.onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
            ],
          ),
        ),
        if (photos.length > 1) _thumbnails(l10n, photos),
      ],
    );
  }

  Widget _thumbnails(AppLocalizations l10n, List<ListingPhoto> photos) {
    return SizedBox(
      height: ListingGallery._thumbSize + AppSpacing.md,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        itemCount: photos.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) => Semantics(
          button: true,
          selected: index == _page,
          label: l10n.listingViewShowPhoto(index + 1),
          excludeSemantics: true,
          child: InkWell(
            onTap: () => _controller.animateToPage(
              index,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: index == _page ? AppColors.brandPrimary : AppColors.brandDivider,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: SizedBox(
                  width: ListingGallery._thumbSize,
                  height: ListingGallery._thumbSize,
                  child: AppImage(source: photos[index].thumbnailUrl, cacheWidth: 160),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _enlarge(BuildContext context, ListingPhoto photo) {
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
                child: AppImage(source: photo.zoomUrl, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
