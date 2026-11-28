import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_image.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/packing.dart';
import '../../providers/packing_providers.dart';

/// One photo section of Pack & Upload Proof (Figma Make `SellerPackingScreen`): title, rule, the
/// `count/max` chip (green once the minimum is met), the photos in a four-column grid and the Add
/// tile. Photos still uploading show a spinner; a failed one can be retried or dropped.
class ProofPhotoSection extends StatelessWidget {
  final ProofKind kind;
  final String title;
  final String hint;
  final List<OrderProof> proofs;
  final List<PendingPhoto> pending;
  final PackingRules rules;
  final bool canAdd;
  final VoidCallback onAdd;
  final ValueChanged<OrderProof> onRemove;
  final ValueChanged<PendingPhoto> onRetry;
  final ValueChanged<PendingPhoto> onDiscard;

  const ProofPhotoSection({
    super.key,
    required this.kind,
    required this.title,
    required this.hint,
    required this.proofs,
    required this.pending,
    required this.rules,
    required this.canAdd,
    required this.onAdd,
    required this.onRemove,
    required this.onRetry,
    required this.onDiscard,
  });

  bool get _isItem => kind == ProofKind.itemCondition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final count = proofs.length + pending.length;
    final max = rules.max(kind);
    final met = proofs.length >= rules.min(kind);
    String label(int index) => _isItem
        ? l10n.packingItemPhotoLabel(index + 1, count)
        : l10n.packingPackagePhotoLabel(index + 1, count);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandSurface,
        border: Border.all(color: AppColors.brandBorder),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(header: true, child: Text(title, style: AppTextStyles.cardTitle)),
                      Text(hint, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Semantics(
                  label: l10n.packingCountLabel(count, max),
                  excludeSemantics: true,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: met ? AppColors.brandSuccessTint : AppColors.brandErrorTint,
                      shape: const StadiumBorder(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                      child: Text(
                        l10n.packingCount(count, max),
                        style: AppTextStyles.label.copyWith(
                          color: met ? AppColors.brandSuccess : AppColors.brandError,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final (index, proof) in proofs.indexed)
                  _PhotoTile(
                    label: label(index),
                    image: AppImage(source: proof.url ?? '', cacheWidth: 192),
                    onRemove: () => onRemove(proof),
                  ),
                for (final (index, photo) in pending.indexed)
                  _PhotoTile(
                    label: photo.failed ? l10n.packingRetryUpload : l10n.packingUploading,
                    image: Image.memory(photo.bytes, fit: BoxFit.cover, cacheWidth: 192),
                    failed: photo.failed,
                    uploading: !photo.failed,
                    onTap: photo.failed ? () => onRetry(photo) : null,
                    onRemove: photo.failed ? () => onDiscard(photo) : null,
                    key: ValueKey('pending-${photo.localId}-$index'),
                  ),
                if (canAdd) _AddTile(item: _isItem, onTap: onAdd),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String label;
  final Widget image;
  final bool failed;
  final bool uploading;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const _PhotoTile({
    super.key,
    required this.label,
    required this.image,
    this.failed = false,
    this.uploading = false,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: label,
      button: onTap != null,
      image: onTap == null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            InkWell(onTap: onTap, child: ExcludeSemantics(child: image)),
            if (uploading)
              const ColoredBox(
                color: Color(0x66000000),
                child: Center(
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                ),
              ),
            if (failed)
              IgnorePointer(
                child: ColoredBox(
                  color: AppColors.brandError.withValues(alpha: 0.55),
                  child: const Center(child: Icon(Icons.refresh, color: Colors.white)),
                ),
              ),
            if (onRemove != null)
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  tooltip: l10n.packingRemovePhoto,
                  onPressed: onRemove,
                  icon: const DecoratedBox(
                    decoration: BoxDecoration(color: Color(0xB3000000), shape: BoxShape.circle),
                    child: Padding(
                      padding: EdgeInsets.all(3),
                      child: Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The dashed Add tile: blue with a camera for item photos, fuchsia with an upload arrow for
/// packaging photos, as in Make.
class _AddTile extends StatelessWidget {
  final bool item;
  final VoidCallback onTap;

  const _AddTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = item ? AppColors.brandPrimary : AppColors.brandAccent;
    return Semantics(
      button: true,
      label: item ? l10n.packingAddItemPhoto : l10n.packingAddPackagePhoto,
      excludeSemantics: true,
      child: Material(
        color: color.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: color.withValues(alpha: 0.25), width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item ? Icons.photo_camera_outlined : Icons.file_upload_outlined,
                  size: 18, color: color),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.packingAdd, style: AppTextStyles.caption.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
