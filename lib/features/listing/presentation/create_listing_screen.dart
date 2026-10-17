import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/brand_gradient_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/providers/session_controller.dart';
import '../../auth/presentation/providers/session_state.dart';
import '../data/photo_source.dart';
import '../domain/listing_photo.dart';
import 'listing_error_messages.dart';
import 'providers/create_listing_controller.dart';
import 'providers/item_details_controller.dart';
import 'widgets/ai_intro_card.dart';
import 'widgets/photo_grid.dart';
import 'widgets/photo_tips_section.dart';
import 'widgets/sell_step_header.dart';

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
    // Back from the Aadhaar detour: keep the photos, carry on if the seller is now verified.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_controller.resumeFromAadhaar()) {
        final session = ref.read(sessionControllerProvider).value;
        if (session is Authenticated && session.aadhaarVerified) unawaited(_submit());
      } else if (widget.openCameraOnStart) {
        unawaited(_add(PhotoSourceKind.camera));
      }
    });
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

  Future<void> _submit() async {
    final result = await _controller.submit();
    if (!mounted) return;
    switch (result.outcome) {
      case SubmitOutcome.submitted:
        final listingId = ref.read(createListingControllerProvider).listingId;
        if (listingId != null) {
          unawaited(context.push(
            RouteNames.sellDetails,
            extra: ItemDetailsArgs(listingId: listingId),
          ));
        }
      case SubmitOutcome.aadhaarRequired:
        _controller.holdForAadhaar();
        context.go(RouteNames.signupAadhaar);
      case SubmitOutcome.failed:
        final error = result.error;
        if (error == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(listingErrorMessage(AppLocalizations.of(context), error))),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(createListingControllerProvider);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SellStepHeader(
            step: 0,
            title: l10n.sellAddPhotosTitle,
            subtitle: state.photos.isEmpty
                ? l10n.sellAddPhotosSubtitle
                : l10n.sellPhotoCount(state.photos.length),
            onBack: () => context.canPop() ? context.pop() : context.go(RouteNames.home),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.readyCount < ListingPhotoRules.minPhotos) ...[
                      Text(l10n.sellMinPhotosHint,
                          style: AppTextStyles.hint, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    BrandGradientButton(
                      label: l10n.sellSubmitToAi,
                      onPressed: state.canSubmit ? () => unawaited(_submit()) : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
