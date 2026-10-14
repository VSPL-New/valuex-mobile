import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/brand_gradient_button.dart';
import '../../../core/widgets/square_back_button.dart';
import '../../../l10n/app_localizations.dart';
import '../data/photo_source.dart';
import 'listing_error_messages.dart';
import 'providers/create_listing_controller.dart';
import 'widgets/ai_intro_card.dart';
import 'widgets/photo_grid.dart';
import 'widgets/photo_tips_section.dart';

/// Sell step 1 of 5 (Figma Make: CreateListingScreen, "photos"): capture or choose up to
/// 10 photos, each uploaded to the draft listing as soon as it is added.
class CreateListingScreen extends ConsumerStatefulWidget {
  /// US-004: tapping Sell opens the camera straight away.
  final bool openCameraOnStart;

  const CreateListingScreen({super.key, this.openCameraOnStart = true});

  @override
  ConsumerState<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  CreateListingController get _controller => ref.read(createListingControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    if (widget.openCameraOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_add(PhotoSourceKind.camera));
      });
    }
  }

  void _notify(ListingNotice? notice) {
    if (notice == null || !mounted) return;
    final message = listingNoticeMessage(AppLocalizations.of(context), notice);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _add(PhotoSourceKind kind) async => _notify(await _controller.addPhotos(kind));

  Future<void> _chooseSource() async {
    final l10n = AppLocalizations.of(context);
    final kind = await showModalBottomSheet<PhotoSourceKind>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.sellTakePhoto),
              onTap: () => Navigator.pop(context, PhotoSourceKind.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.sellChooseFromGallery),
              onTap: () => Navigator.pop(context, PhotoSourceKind.gallery),
            ),
          ],
        ),
      ),
    );
    if (kind != null) await _add(kind);
  }

  void _submit() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).sellSubmitted)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(createListingControllerProvider);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            onBack: () => context.canPop() ? context.pop() : context.go(RouteNames.home),
            photoCount: state.photos.length,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const AiIntroCard(),
                const SizedBox(height: AppSpacing.md),
                if (state.photos.isEmpty)
                  _EmptyPhotos(onAdd: state.isBusy ? null : _chooseSource)
                else
                  PhotoGrid(
                    photos: state.photos,
                    canAdd: state.remaining > 0 && !state.isBusy,
                    onAdd: _chooseSource,
                    onRemove: (photo) async => _notify(await _controller.remove(photo.localId)),
                    onRetry: (photo) => unawaited(_controller.retry(photo.localId)),
                  ),
                const SizedBox(height: AppSpacing.md),
                const PhotoTipsSection(),
              ],
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.brandBorder)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                child: BrandGradientButton(
                  label: l10n.sellSubmitToAi,
                  onPressed: state.canSubmit ? _submit : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  static const int _steps = 5;

  final VoidCallback onBack;
  final int photoCount;

  const _Header({required this.onBack, required this.photoCount});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.brandBorder)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SquareBackButton(onPressed: onBack),
              const SizedBox(height: AppSpacing.sm),
              ExcludeSemantics(
                child: Row(
                  children: [
                    for (var i = 0; i < _steps; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: i == 0 ? AppGradients.brand : null,
                            color: i == 0 ? null : AppColors.brandBorder,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                header: true,
                child: Text(l10n.sellAddPhotosTitle, style: AppTextStyles.heading2),
              ),
              Text(
                photoCount == 0 ? l10n.sellAddPhotosSubtitle : l10n.sellPhotoCount(photoCount),
                style: AppTextStyles.hint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashed call-to-action shown before any photo is chosen.
class _EmptyPhotos extends StatelessWidget {
  final VoidCallback? onAdd;

  const _EmptyPhotos({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.sellAddTile,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.brandBorderFocused, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const ExcludeSemantics(
              child: Icon(Icons.file_upload_outlined, size: 36, color: AppColors.brandPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.sellEmptyTitle, style: AppTextStyles.cardTitle, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.sellEmptyBody, style: AppTextStyles.hint, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            BrandGradientButton(label: l10n.sellAddPhotos, onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}
