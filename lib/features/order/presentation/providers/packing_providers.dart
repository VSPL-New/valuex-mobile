import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../listing/data/photo_source.dart';
import '../../../listing/domain/listing_photo.dart';
import '../../../profile/data/profile_repository.dart';
import '../../domain/entities/incoming_order.dart';
import '../../domain/entities/packing.dart';
import '../../domain/repositories/seller_order_repository.dart';
import 'seller_order_providers.dart';

/// Error codes the packing screen turns into its own messages (Sprint 6 LLD 0.5).
abstract final class PackingErrors {
  static const String imageRequired = 'ERROR_IMAGE_REQUIRED';
  static const String uploadFailed = 'ERROR_IMAGE_UPLOAD_FAILED';
  static const String qualityLow = 'WARNING_IMAGE_QUALITY_LOW';
  static const String proofLimit = 'ERROR_PROOF_LIMIT';
  static const String actionNotAllowed = 'ERROR_ORDER_ACTION_NOT_ALLOWED';
}

/// A photo picked on this device that is uploading, or failed and can be retried. Its bytes stay
/// here until the server has attached it, so a retry never asks for the photo again.
class PendingPhoto {
  final int localId;
  final ProofKind kind;
  final Uint8List bytes;
  final String fileName;
  final PhotoInspection inspection;

  /// Already in storage; a retry only attaches it.
  final String? mediaId;
  final bool failed;

  const PendingPhoto({
    required this.localId,
    required this.kind,
    required this.bytes,
    required this.fileName,
    required this.inspection,
    this.mediaId,
    this.failed = false,
  });

  PendingPhoto copyWith({String? mediaId, bool? failed}) => PendingPhoto(
        localId: localId,
        kind: kind,
        bytes: bytes,
        fileName: fileName,
        inspection: inspection,
        mediaId: mediaId ?? this.mediaId,
        failed: failed ?? this.failed,
      );
}

class PackingState {
  final PackingView? view;
  final bool isLoading;
  final Object? error;
  final List<PendingPhoto> pending;
  final bool isCompleting;

  const PackingState({
    this.view,
    this.isLoading = true,
    this.error,
    this.pending = const [],
    this.isCompleting = false,
  });

  PackingRules get rules => view?.rules ?? const PackingRules();

  /// Photos shown in a section: attached, uploading and failed.
  int count(ProofKind kind) =>
      (view?.of(kind).length ?? 0) + pending.where((p) => p.kind == kind).length;

  bool canAdd(ProofKind kind) => view != null && count(kind) < rules.max(kind);

  /// The attached photos missing in a section before packing can finish.
  int missing(ProofKind kind) => (rules.min(kind) - (view?.of(kind).length ?? 0)).clamp(0, 99);

  /// Both sections have their minimum and nothing is still uploading.
  bool get canSubmit =>
      view != null &&
      !isCompleting &&
      pending.isEmpty &&
      ProofKind.values.every((kind) => missing(kind) == 0);

  PackingState copyWith({
    PackingView? view,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    List<PendingPhoto>? pending,
    bool? isCompleting,
  }) {
    return PackingState(
      view: view ?? this.view,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      pending: pending ?? this.pending,
      isCompleting: isCompleting ?? this.isCompleting,
    );
  }
}

/// Pack & Upload Proof (US-026, Sprint 6 LLD D.5) for one order: each photo uploads and is attached
/// on its own, so a poor network loses nothing; leaving the screen keeps the attached photos as
/// drafts on the server, and Continue Packing shows them again.
class PackingController extends Notifier<PackingState> {
  final String orderId;
  int _nextLocalId = 0;

  PackingController(this.orderId);

  SellerOrderRepository get _repository => ref.read(sellerOrderRepositoryProvider);

  @override
  PackingState build() => const PackingState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final view = await _repository.packing(orderId);
      if (!ref.mounted) return;
      state = state.copyWith(view: view, isLoading: false);
    } on ApiError catch (error) {
      if (ref.mounted) state = state.copyWith(isLoading: false, error: error);
    }
  }

  /// Adds a picked photo to [kind] and uploads it. Returns why it was not added, or null. A photo
  /// smaller than the minimum or a full section is refused here, before any upload.
  Future<ApiError?> addPhoto(ProofKind kind, PickedPhoto photo, PhotoInspection inspection) async {
    if (!state.canAdd(kind)) return _local(PackingErrors.proofLimit);
    final minPixels = state.rules.minPixels;
    if (inspection.width < minPixels || inspection.height < minPixels) {
      return _local(PackingErrors.qualityLow);
    }
    final pending = PendingPhoto(
      localId: _nextLocalId++,
      kind: kind,
      bytes: photo.bytes,
      fileName: photo.name,
      inspection: inspection,
    );
    state = state.copyWith(pending: [...state.pending, pending]);
    return _send(pending);
  }

  /// Tries a failed photo again.
  Future<ApiError?> retry(int localId) async {
    final pending = _pending(localId);
    if (pending == null || !pending.failed) return null;
    _replace(pending.copyWith(failed: false));
    return _send(pending);
  }

  /// Drops a failed photo that was never attached.
  void discard(int localId) {
    state = state.copyWith(pending: [...state.pending.where((p) => p.localId != localId)]);
  }

  /// Removes an attached draft photo; null when it worked.
  Future<ApiError?> remove(String proofId) async {
    final view = state.view;
    if (view == null) return null;
    try {
      await _repository.removeProof(orderId, proofId);
      if (!ref.mounted) return null;
      state = state.copyWith(
          view: view.copyWith(proofs: [...view.proofs.where((p) => p.id != proofId)]));
      return null;
    } on ApiError catch (error) {
      return error;
    }
  }

  /// Submits the photos and the packed size. Returns the order now waiting for pickup scheduling,
  /// or why it could not finish (the photos then reload, in case another device changed them).
  Future<({IncomingOrder? order, ApiError? error})> complete(PackageSize size) async {
    if (!state.canSubmit) return (order: null, error: _local(PackingErrors.imageRequired));
    state = state.copyWith(isCompleting: true);
    try {
      final order = await _repository.completePacking(orderId, size);
      if (ref.mounted) state = state.copyWith(isCompleting: false);
      return (order: order, error: null);
    } on ApiError catch (error) {
      if (!ref.mounted) return (order: null, error: error);
      state = state.copyWith(isCompleting: false);
      if (error.code != null) await load();
      return (order: null, error: error);
    }
  }

  Future<ApiError?> _send(PendingPhoto pending) async {
    try {
      var mediaId = pending.mediaId;
      if (mediaId == null) {
        final owner = await ref.read(userProfileProvider.future);
        mediaId = await _repository.uploadProofPhoto(
          ownerId: owner.userId,
          fileName: pending.fileName,
          contentType: pending.inspection.contentType,
          bytes: pending.bytes,
          width: pending.inspection.width,
          height: pending.inspection.height,
        );
        if (!ref.mounted) return null;
        _replace(pending.copyWith(mediaId: mediaId));
      }
      final proof = await _repository.attachProof(orderId, mediaId, pending.kind);
      if (!ref.mounted) return null;
      final view = state.view!;
      state = state.copyWith(
        view: view.copyWith(proofs: [...view.proofs.where((p) => p.id != proof.id), proof]),
        pending: [...state.pending.where((p) => p.localId != pending.localId)],
      );
      return null;
    } on ApiError catch (error) {
      if (!ref.mounted) return error;
      if (_retryable(error)) {
        final current = _pending(pending.localId);
        if (current != null) _replace(current.copyWith(failed: true));
        return _local(PackingErrors.uploadFailed);
      }
      discard(pending.localId);
      return error;
    }
  }

  /// A failed connection or server can be retried; a refusal (too small, full, order moved on)
  /// cannot.
  static bool _retryable(ApiError error) =>
      error.code == null ||
      error.type == ApiErrorType.network ||
      error.type == ApiErrorType.timeout ||
      error.type == ApiErrorType.server;

  PendingPhoto? _pending(int localId) =>
      state.pending.where((p) => p.localId == localId).firstOrNull;

  void _replace(PendingPhoto photo) {
    state = state.copyWith(pending: [
      for (final p in state.pending) p.localId == photo.localId ? photo : p,
    ]);
  }

  static ApiError _local(String code) =>
      ApiError(type: ApiErrorType.validation, message: code, code: code);
}

final packingControllerProvider = NotifierProvider.autoDispose
    .family<PackingController, PackingState, String>(PackingController.new);
