import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/soft_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/listing_photo.dart';
import '../../domain/live_photo.dart';
import '../listing_error_messages.dart';
import '../providers/live_photos_controller.dart';

/// The photos of a live listing on the edit page (US-010): the main one is marked and cannot be
/// removed, any other can be, as long as two remain; up to ten in all. A photo added here is
/// checked before it goes live, which the note under the grid says.
class LivePhotosSection extends StatelessWidget {
  /// Three columns, not the draft grid's four: a failed photo holds a retry and a remove target of
  /// 48 dp each, which need about 96 dp of tile between them.
  static const int _columns = 3;

  final LivePhotosState state;
  final VoidCallback onAdd;
  final ValueChanged<LivePhoto> onRemove;
  final ValueChanged<LivePhoto> onRetry;

  const LivePhotosSection({
    super.key,
    required this.state,
    required this.onAdd,
    required this.onRemove,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final photos = state.photos;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.itemPhotosLabel.toUpperCase(),
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.brandForeground, letterSpacing: 0.8),
                  ),
                ),
              ),
              Text(l10n.itemPhotosCount(photos.length), style: AppTextStyles.caption),
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
                _Tile(
                  key: ValueKey(photos[i].localId),
                  photo: photos[i],
                  position: i + 1,
                  removable: state.canRemove(i),
                  onRemove: () => onRemove(photos[i]),
                  onRetry: () => onRetry(photos[i]),
                ),
              if (state.remaining > 0) _AddTile(onTap: state.isBusy ? null : onAdd),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            state.hasEnoughPhotos ? l10n.itemPhotosAddedNote : l10n.itemPhotosMinHint,
            style: AppTextStyles.hint,
          ),
        ],
      ),
    );
  }
}

class _Tile extends ConsumerWidget {
  final LivePhoto photo;
  final int position;
  final bool removable;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  const _Tile({
    super.key,
    required this.photo,
    required this.position,
    required this.removable,
    required this.onRemove,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final busy = photo.status == PhotoStatus.uploading;
    final failed = photo.status == PhotoStatus.failed;
    final status = busy
        ? l10n.sellPhotoUploading
        : failed
            ? (listingCodeMessage(l10n, photo.errorCode) ?? l10n.sellPhotoFailed)
            : null;
    final bytes = photo.bytes;
    final mediaId = photo.mediaId;
    final url =
        bytes == null && mediaId != null ? ref.watch(listingPhotoUrlProvider(mediaId)).value : null;
    final label = [
      l10n.sellPhotoLabel(position),
      if (position == 1) l10n.sellMainPhoto,
      if (status != null) status,
    ].join(', ');

    return Semantics(
      container: true,
      label: label,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              child: bytes != null
                  ? Image.memory(bytes, fit: BoxFit.cover, cacheWidth: 300, gaplessPlayback: true)
                  : AppImage(source: url ?? '', cacheWidth: 300),
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
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandOnPrimary),
                  ),
                ),
              ),
            if (failed)
              ColoredBox(
                color: AppColors.brandError,
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
            if (removable && !busy)
              Positioned(
                top: 0,
                right: 0,
                child: _RemoveButton(label: l10n.sellRemovePhoto(position), onPressed: onRemove),
              ),
          ],
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
  final VoidCallback? onTap;

  const _AddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: const BorderSide(color: AppColors.brandControlBorder, width: 1.5),
    );
    return Semantics(
      button: true,
      label: l10n.itemPhotosAdd,
      excludeSemantics: true,
      child: Material(
        color: AppColors.sellAddTile,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: const Center(
            child: Icon(Icons.add_a_photo_outlined, color: AppColors.brandLink),
          ),
        ),
      ),
    );
  }
}
