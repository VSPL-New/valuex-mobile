import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_error_messages.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/square_back_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../listing/data/photo_source.dart';
import '../../domain/entities/packing.dart';
import '../providers/packing_providers.dart';
import 'widgets/package_size_card.dart';
import 'widgets/packing_info_cards.dart';
import 'widgets/proof_photo_section.dart';

/// Pack & Upload Proof (US-026, Sprint 6 LLD D.5, Figma Make `SellerPackingScreen`), opened from
/// Start Packing and Continue Packing on Incoming Orders. Pops `true` once packing is complete, so
/// Incoming Orders can say so; any other way back keeps the attached photos as drafts.
class PackAndUploadProofScreen extends ConsumerStatefulWidget {
  final String orderId;

  const PackAndUploadProofScreen({super.key, required this.orderId});

  @override
  ConsumerState<PackAndUploadProofScreen> createState() => _PackAndUploadProofScreenState();
}

class _PackAndUploadProofScreenState extends ConsumerState<PackAndUploadProofScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final PackageSizeFields _size = PackageSizeFields();
  bool _prefilled = false;

  NotifierProvider<PackingController, PackingState> get _provider =>
      packingControllerProvider(widget.orderId);

  PackingController get _controller => ref.read(_provider.notifier);

  @override
  void initState() {
    super.initState();
    Future.microtask(_controller.load);
  }

  @override
  void dispose() {
    _size.dispose();
    super.dispose();
  }

  Future<void> _add(ProofKind kind) async {
    final l10n = AppLocalizations.of(context);
    final source = await _chooseSource(l10n);
    if (source == null || !mounted) return;
    final photos = ref.read(photoSourceProvider);
    final state = ref.read(_provider);
    try {
      final picked = await photos.pick(source, limit: state.rules.max(kind) - state.count(kind));
      for (final photo in picked) {
        if (!mounted) return;
        final inspection = await photos.inspect(photo.bytes);
        if (!mounted) return;
        if (inspection == null) {
          _say(l10n.packingErrorPhotoInvalid);
          continue;
        }
        final error = await _controller.addPhoto(kind, photo, inspection);
        if (error != null) _onError(error);
      }
    } on PhotoAccessDeniedException {
      if (mounted) _say(l10n.packingPhotoDenied);
    }
  }

  Future<PhotoSourceKind?> _chooseSource(AppLocalizations l10n) {
    return showModalBottomSheet<PhotoSourceKind>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.packingTakePhoto),
              onTap: () => Navigator.of(sheetContext).pop(PhotoSourceKind.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.packingChooseGallery),
              onTap: () => Navigator.of(sheetContext).pop(PhotoSourceKind.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final valid = _form.currentState?.validate() ?? false;
    final size = _size.read();
    if (!valid || size == null) return;
    final result = await _controller.complete(size);
    if (!mounted) return;
    if (result.order != null) {
      context.pop(true);
      return;
    }
    if (result.error case final error?) _onError(error);
  }

  void _onError(ApiError error) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (error.code == PackingErrors.actionNotAllowed) {
      // Another device finished packing, or the order moved on: back to the refreshed list.
      _say(l10n.sellerOrdersActionNotAllowed);
      context.pop(false);
      return;
    }
    _say(switch (error.code) {
      PackingErrors.imageRequired => l10n.packingErrorImageRequired,
      PackingErrors.uploadFailed => l10n.packingErrorUploadFailed,
      PackingErrors.qualityLow => l10n.packingErrorQualityLow,
      PackingErrors.proofLimit => l10n.packingErrorLimit,
      'ERROR_VALIDATION' => l10n.packingErrorPhotoInvalid,
      'ERROR_ORDER_NOT_FOUND' => l10n.sellerOrdersNotFound,
      _ => apiErrorMessage(l10n, error),
    });
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(_provider);
    ref.listen(_provider.select((s) => s.view), (previous, view) {
      if (_prefilled || view == null) return;
      _prefilled = true;
      _size.fill(view.packageSize);
    });
    // The header scrolls with the content and only the button stays pinned, so large text and
    // Hindi still leave room for the photos.
    final header = _Header(onBack: () => context.pop(false));
    final view = state.view;
    return Scaffold(
      body: view == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                Expanded(
                  child: state.error != null
                      ? ErrorView(message: l10n.packingLoadFailed, onRetry: _controller.load)
                      : const Center(child: LoadingIndicator()),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _body(l10n, state, view, header)),
                _BottomBar(state: state, onSubmit: _submit),
              ],
            ),
    );
  }

  Widget _body(AppLocalizations l10n, PackingState state, PackingView view, Widget header) {
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        children: [
          header,
          const SizedBox(height: AppSpacing.md),
          for (final child in _content(l10n, state, view))
            Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), child: child),
        ],
      ),
    );
  }

  List<Widget> _content(AppLocalizations l10n, PackingState state, PackingView view) {
    Widget section(ProofKind kind, String title, String hint) => ProofPhotoSection(
          kind: kind,
          title: title,
          hint: hint,
          proofs: view.of(kind),
          pending: [...state.pending.where((p) => p.kind == kind)],
          rules: view.rules,
          canAdd: state.canAdd(kind),
          onAdd: () => unawaited(_add(kind)),
          onRemove: (proof) async {
            final error = await _controller.remove(proof.id);
            if (error != null) _onError(error);
          },
          onRetry: (photo) async {
            final error = await _controller.retry(photo.localId);
            if (error != null) _onError(error);
          },
          onDiscard: (photo) => _controller.discard(photo.localId),
        );
    return [
      PackingOrderCard(title: view.order.title, orderNumber: view.order.orderNumber),
      const SizedBox(height: AppSpacing.md),
      const PackingStepsCard(),
      const SizedBox(height: AppSpacing.md),
      section(ProofKind.itemCondition, l10n.packingItemPhotos,
          l10n.packingItemPhotosHint(view.rules.itemMin, view.rules.itemMax)),
      const SizedBox(height: AppSpacing.md),
      section(ProofKind.packageSealed, l10n.packingPackagePhotos, l10n.packingPackagePhotosHint),
      const SizedBox(height: AppSpacing.md),
      PackageSizeCard(fields: _size),
      const SizedBox(height: AppSpacing.md),
      EscrowNote(amount: Formatters.currency(view.order.amount)),
    ];
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.brandDivider)),
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
              Semantics(
                  header: true, child: Text(l10n.packingTitle, style: AppTextStyles.heading2)),
              Text(l10n.packingSubtitle, style: AppTextStyles.hint),
            ],
          ),
        ),
      ),
    );
  }
}

/// The gradient button, with the red hint below it while photos are missing (Make).
class _BottomBar extends StatelessWidget {
  final PackingState state;
  final VoidCallback onSubmit;

  const _BottomBar({required this.state, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rules = state.rules;
    final missing = ProofKind.values.any((kind) => state.missing(kind) > 0);
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.brandDivider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 12, AppSpacing.md, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BrandGradientButton(
                label: l10n.packingSubmit,
                onPressed: state.canSubmit ? onSubmit : null,
                isLoading: state.isCompleting,
                trailingIcon: Icons.chevron_right,
              ),
              if (missing)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    l10n.packingMissingHint(rules.itemMin, rules.packageMin),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(color: AppColors.brandError),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
