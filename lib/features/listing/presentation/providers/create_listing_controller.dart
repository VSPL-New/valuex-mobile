import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;
import '../../../../core/network/api_error.dart';
import '../../../../core/routing/post_aadhaar_route.dart';
import '../../../../core/routing/route_names.dart';
import '../../data/listing_repository.dart';
import '../../data/photo_source.dart';
import '../../domain/listing_details.dart';
import '../../domain/listing_photo.dart';

/// Something the screen should tell the user once, after an action.
enum ListingNoticeKind {
  maxPhotos,
  invalidPhoto,
  photoTooLarge,
  cameraDenied,
  galleryDenied,
  draftFailed,
  removeFailed,
}

class ListingNotice {
  final ListingNoticeKind kind;
  final Object? error;

  const ListingNotice(this.kind, [this.error]);
}

/// How a submit ended.
enum SubmitOutcome { submitted, aadhaarRequired, failed }

/// Why the seller fills the page by hand after a submit (US-005).
enum AiNotice {
  /// AI is off, down or its quota is used up.
  unavailable,

  /// AI answered but could not recognise the item.
  notRecognised,
}

/// The result of a submit. After [SubmitOutcome.submitted], [suggestion] is what AI suggested and
/// [aiNotice] says why there is none. AI never blocks the seller.
typedef SubmitResult = ({
  SubmitOutcome outcome,
  Object? error,
  AiSuggestion? suggestion,
  AiNotice? aiNotice,
});

class CreateListingState {
  final String? listingId;
  final List<ListingPhoto> photos;
  final bool isBusy;

  /// True while AI looks at the photos after a submit.
  final bool isAnalysing;

  const CreateListingState({
    this.listingId,
    this.photos = const [],
    this.isBusy = false,
    this.isAnalysing = false,
  });

  int get remaining => ListingPhotoRules.maxPhotos - photos.length;
  int get readyCount => photos.where((p) => p.status == PhotoStatus.ready).length;
  bool get hasPending =>
      photos.any((p) => p.status == PhotoStatus.uploading || p.status == PhotoStatus.removing);

  /// At least one uploaded photo and nothing still in flight.
  bool get canSubmit =>
      listingId != null && readyCount >= ListingPhotoRules.minPhotos && !hasPending && !isBusy;

  CreateListingState copyWith({
    String? listingId,
    List<ListingPhoto>? photos,
    bool? isBusy,
    bool? isAnalysing,
  }) {
    return CreateListingState(
      listingId: listingId ?? this.listingId,
      photos: photos ?? this.photos,
      isBusy: isBusy ?? this.isBusy,
      isAnalysing: isAnalysing ?? this.isAnalysing,
    );
  }
}

/// US-004 photo capture: creates the draft on the first photo, validates each photo on the
/// device, then uploads it, confirms it and attaches it to the draft.
class CreateListingController extends Notifier<CreateListingState> {
  int _nextId = 0;
  KeepAliveLink? _hold;

  ListingRepository get _repository => ref.read(listingRepositoryProvider);
  PhotoSource get _source => ref.read(photoSourceProvider);

  @override
  CreateListingState build() => const CreateListingState();

  /// The seller is on their way to verify Aadhaar; keep the draft and its photos meanwhile.
  void holdForAadhaar() {
    _hold ??= ref.keepAlive();
    ref.read(postAadhaarRouteProvider.notifier).set(RouteNames.sell);
  }

  /// True when the screen is opening again after the Aadhaar detour; ends the hold.
  bool resumeFromAadhaar() {
    final resuming = _hold != null;
    _hold?.close();
    _hold = null;
    if (resuming) ref.read(postAadhaarRouteProvider.notifier).clear();
    return resuming;
  }

  /// Submits the draft, then asks AI for suggestions. Aadhaar verification is asked for here, not
  /// earlier. AI never blocks the seller: when it cannot answer, the result says so.
  Future<SubmitResult> submit() async {
    final listingId = state.listingId;
    if (!state.canSubmit || listingId == null) {
      return _result(SubmitOutcome.failed);
    }
    state = state.copyWith(isBusy: true);
    try {
      await _repository.submitDraft(listingId);
      state = state.copyWith(isAnalysing: true);
      return await _suggest(listingId);
    } on ApiError catch (error) {
      final outcome = error.code == 'AADHAAR_VERIFICATION_REQUIRED'
          ? SubmitOutcome.aadhaarRequired
          : SubmitOutcome.failed;
      return _result(outcome, error: error);
    } finally {
      if (ref.mounted) state = state.copyWith(isBusy: false, isAnalysing: false);
    }
  }

  Future<SubmitResult> _suggest(String listingId) async {
    try {
      final suggestion = await _repository.generateAiSuggestions(listingId);
      if (suggestion == null) {
        return _result(SubmitOutcome.submitted, aiNotice: AiNotice.unavailable);
      }
      if (suggestion.isEmpty) {
        return _result(SubmitOutcome.submitted, aiNotice: AiNotice.notRecognised);
      }
      return _result(SubmitOutcome.submitted, suggestion: suggestion);
    } on ApiError {
      return _result(SubmitOutcome.submitted, aiNotice: AiNotice.unavailable);
    }
  }

  SubmitResult _result(
    SubmitOutcome outcome, {
    Object? error,
    AiSuggestion? suggestion,
    AiNotice? aiNotice,
  }) =>
      (outcome: outcome, error: error, suggestion: suggestion, aiNotice: aiNotice);

  /// Picks photos and starts their uploads; returns what the user should be told, if anything.
  Future<ListingNotice?> addPhotos(PhotoSourceKind kind) async {
    if (state.isBusy) return null;
    if (state.remaining <= 0) return const ListingNotice(ListingNoticeKind.maxPhotos);

    state = state.copyWith(isBusy: true);
    final List<PickedPhoto> picked;
    try {
      picked = await _source.pick(kind, limit: state.remaining);
    } on PhotoAccessDeniedException catch (e) {
      if (ref.mounted) state = state.copyWith(isBusy: false);
      return ListingNotice(e.source == PhotoSourceKind.camera
          ? ListingNoticeKind.cameraDenied
          : ListingNoticeKind.galleryDenied);
    }
    if (!ref.mounted) return null;
    if (picked.isEmpty) {
      state = state.copyWith(isBusy: false);
      return null;
    }

    ListingNotice? notice;
    var accepted = picked;
    if (picked.length > state.remaining) {
      accepted = picked.take(state.remaining).toList();
      notice = const ListingNotice(ListingNoticeKind.maxPhotos);
    }

    final valid = <ListingPhoto>[];
    for (final photo in accepted) {
      final inspection = await _source.inspect(photo.bytes);
      final violation = photoRuleViolation(sizeBytes: photo.bytes.length, inspection: inspection);
      if (violation != null) {
        notice ??= ListingNotice(violation == 'ERROR_PHOTO_TOO_LARGE'
            ? ListingNoticeKind.photoTooLarge
            : ListingNoticeKind.invalidPhoto);
        continue;
      }
      valid.add(ListingPhoto(
        localId: 'photo-${_nextId++}',
        fileName: photo.name,
        bytes: photo.bytes,
        contentType: inspection!.contentType,
        width: inspection.width,
        height: inspection.height,
      ));
    }
    if (!ref.mounted) return null;
    if (valid.isEmpty) {
      state = state.copyWith(isBusy: false);
      return notice;
    }

    if (state.listingId == null) {
      try {
        final id = await _repository.createDraft();
        if (!ref.mounted) return null;
        state = state.copyWith(listingId: id);
      } on ApiError catch (error) {
        if (ref.mounted) state = state.copyWith(isBusy: false);
        return ListingNotice(ListingNoticeKind.draftFailed, error);
      }
    }

    state = state.copyWith(photos: [...state.photos, ...valid], isBusy: false);
    await Future.wait(valid.map(_upload));
    return notice;
  }

  /// Uploads a failed photo again from the start.
  Future<void> retry(String localId) async {
    final photo = _find(localId);
    if (photo == null || !photo.canRetry) return;
    _replace(photo.copyWith(status: PhotoStatus.uploading, clearError: true));
    await _upload(photo);
  }

  /// Takes a photo off the draft; returns a notice when the server could not remove it.
  Future<ListingNotice?> remove(String localId) async {
    final photo = _find(localId);
    if (photo == null || photo.status == PhotoStatus.uploading) return null;
    final listingId = state.listingId;
    if (photo.imageId == null || listingId == null) {
      _drop(localId);
      return null;
    }
    _replace(photo.copyWith(status: PhotoStatus.removing));
    try {
      await _repository.deleteImage(listingId, photo.imageId!);
      if (ref.mounted) _drop(localId);
      return null;
    } on ApiError catch (error) {
      if (ref.mounted) _replace(photo);
      return ListingNotice(ListingNoticeKind.removeFailed, error);
    }
  }

  Future<void> _upload(ListingPhoto photo) async {
    final listingId = state.listingId!;
    try {
      final ticket = await _repository.requestUpload(
        listingId: listingId,
        fileName: photo.fileName,
        contentType: photo.contentType,
        sizeBytes: photo.bytes.length,
      );
      await _repository.uploadBytes(ticket.uploadUrl, photo.bytes, photo.contentType);
      await _repository.completeUpload(
        mediaId: ticket.mediaId,
        contentType: photo.contentType,
        sizeBytes: photo.bytes.length,
        width: photo.width,
        height: photo.height,
      );
      final imageId = await _repository.attachImage(listingId, ticket.mediaId);
      if (ref.mounted) _replace(photo.copyWith(status: PhotoStatus.ready, imageId: imageId));
    } on ApiError catch (error) {
      if (!ref.mounted) return;
      _replace(photo.copyWith(
        status: PhotoStatus.failed,
        errorCode: error.code ?? 'ERROR_PHOTO_UPLOAD_FAILED',
      ));
    }
  }

  ListingPhoto? _find(String localId) {
    for (final photo in state.photos) {
      if (photo.localId == localId) return photo;
    }
    return null;
  }

  void _replace(ListingPhoto photo) {
    state = state.copyWith(photos: [
      for (final p in state.photos) p.localId == photo.localId ? photo : p,
    ]);
  }

  void _drop(String localId) {
    state = state.copyWith(photos: [
      for (final p in state.photos)
        if (p.localId != localId) p,
    ]);
  }
}

final createListingControllerProvider =
    NotifierProvider.autoDispose<CreateListingController, CreateListingState>(
  CreateListingController.new,
);
