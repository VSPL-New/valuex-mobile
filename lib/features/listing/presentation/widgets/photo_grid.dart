import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/listing_photo.dart';
import '../listing_error_messages.dart';

/// "Your photos" with a count pill, then a four-column grid of the chosen photos plus an Add tile
/// while fewer than 10 are chosen.
class PhotoGrid extends StatelessWidget {
  static const int _columns = 4;

  final List<ListingPhoto> photos;
  final bool canAdd;
  final VoidCallback onAdd;
  final ValueChanged<ListingPhoto> onRemove;
  final ValueChanged<ListingPhoto> onRetry;

  const PhotoGrid({
    super.key,
    required this.photos,
    required this.canAdd,
    required this.onAdd,
    required this.onRemove,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(l10n.sellYourPhotos, style: AppTextStyles.cardTitle),
              ),
            ),
            Semantics(
              label: l10n.sellPhotoCount(photos.length),
              excludeSemantics: true,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.minTouchTarget),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  child: Text(
                    '${photos.length}/${ListingPhotoRules.maxPhotos}',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.brandForeground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: _columns,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < photos.length; i++)
              _PhotoTile(
                key: ValueKey(photos[i].localId),
                photo: photos[i],
                position: i + 1,
                onRemove: () => onRemove(photos[i]),
                onRetry: () => onRetry(photos[i]),
              ),
            if (canAdd) _AddTile(onTap: onAdd),
          ],
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final ListingPhoto photo;
  final int position;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  const _PhotoTile({
    super.key,
    required this.photo,
    required this.position,
    required this.onRemove,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = photo.status == PhotoStatus.uploading || photo.status == PhotoStatus.removing;
    final failed = photo.status == PhotoStatus.failed;
    final status = busy
        ? l10n.sellPhotoUploading
        : failed
            ? (listingCodeMessage(l10n, photo.errorCode) ?? l10n.sellPhotoFailed)
            : null;

    return Semantics(
      container: true,
      label: [l10n.sellPhotoLabel(position), if (status != null) status].join(', '),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: const [
            BoxShadow(color: Color(0x1F135CFF), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ExcludeSemantics(
                child: Image.memory(photo.bytes,
                    fit: BoxFit.cover, cacheWidth: 300, gaplessPlayback: true),
              ),
              if (position == 1)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: ExcludeSemantics(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary,
                        borderRadius: BorderRadius.circular(AppSizes.minTouchTarget),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Text(
                          l10n.sellMainPhoto,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.brandOnPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (busy)
                const ColoredBox(
                  color: Color(0x80000000),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.brandOnPrimary),
                    ),
                  ),
                ),
              if (failed)
                ColoredBox(
                  color: const Color(0x99C81E1E),
                  // Bottom-left keeps the retry target clear of the remove button (top-right).
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: photo.canRetry
                        ? IconButton(
                            tooltip: l10n.sellRetryPhoto(position),
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh, color: AppColors.brandOnPrimary),
                          )
                        : const Padding(
                            padding: EdgeInsets.all(AppSpacing.sm),
                            child: Icon(Icons.error_outline, color: AppColors.brandOnPrimary),
                          ),
                  ),
                ),
              if (!busy)
                Positioned(
                  top: 0,
                  right: 0,
                  child: _RemoveButton(label: l10n.sellRemovePhoto(position), onPressed: onRemove),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small dark close dot inside a full-size tap area.
class _RemoveButton extends StatelessWidget {
  static const double _dot = 22;

  final String label;
  final VoidCallback onPressed;

  const _RemoveButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: label,
      child: InkResponse(
        onTap: onPressed,
        radius: AppSizes.minTouchTarget / 2,
        child: const SizedBox(
          width: AppSizes.minTouchTarget,
          height: AppSizes.minTouchTarget,
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xs),
              child: CircleAvatar(
                radius: _dot / 2,
                backgroundColor: Color(0xB3000000),
                child: Icon(Icons.close, size: 14, color: AppColors.brandOnPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.sellAddPhotos,
      excludeSemantics: true,
      child: Material(
        color: AppColors.sellAddTile,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.brandControlBorder, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_camera_outlined, size: 32, color: AppColors.brandLink),
              const SizedBox(height: 2),
              Text(l10n.sellAddPhotoTile,
                  style: AppTextStyles.caption.copyWith(color: AppColors.brandLink)),
            ],
          ),
        ),
      ),
    );
  }
}
