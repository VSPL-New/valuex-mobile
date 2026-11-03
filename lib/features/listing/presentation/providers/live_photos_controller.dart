import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../data/listing_repository.dart';
import '../../data/photo_source.dart';
import '../../domain/listing_photo.dart';
import '../../domain/live_photo.dart';
import 'create_listing_controller.dart' show ListingNotice, ListingNoticeKind;
import 'item_details_controller.dart';

class LivePhotosState {
  final List<LivePhoto> photos;

  /// Listing image ids the seller took off; they are sent with the save.
  final Set<String> removedImageIds;
  final bool isBusy;

  const LivePhotosState({
    this.photos = const [],
    this.removedImageIds = const {},
    this.isBusy = false,
  });

  int get remaining => ListingPhotoRules.maxPhotos - photos.length;
  bool get hasPending => photos.any((photo) => photo.status == PhotoStatus.uploading);
  bool get hasFailed => photos.any((photo) => photo.status == PhotoStatus.failed);

  /// Uploaded photos the listing does not have yet; they make the edit a major one.
  List<String> get addedMediaIds => [
        for (final photo in photos)
          if (photo.isNew && photo.status == PhotoStatus.ready && photo.mediaId != null)
            photo.mediaId!,
      ];

  bool get hasEnoughPhotos => photos.length >= ListingPhotoRules.minPhotos;

  /// The main photo (the first) stays, and so do the last two.
  bool canRemove(int index) => index > 0 && photos.length > ListingPhotoRules.minPhotos;

  LivePhotosState copyWith({
    List<LivePhoto>? photos,
    Set<String>? removedImageIds,
    bool? isBusy,
  }) {
    return LivePhotosState(
      photos: photos ?? this.photos,
      removedImageIds: removedImageIds ?? this.removedImageIds,
      isBusy: isBusy ?? this.isBusy,
    );
  }
}

/// US-010: the photos of a live listing while it is edited. Photos the listing has can be removed
/// (not the main one, never below two); up to ten can be held in all. An added photo is uploaded
/// at once but only attached when the edit is saved.
class LivePhotosController extends Notifier<LivePhotosState> {
  final ItemDetailsArgs args;

  LivePhotosController(this.args);

  int _nextId = 0;

  ListingRepository get _repository => ref.read(listingRepositoryProvider);
  PhotoSource get _source => ref.read(photoSourceProvider);

  @override
  LivePhotosState build() {
    final images = [...?args.existing?.images]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return LivePhotosState(
      photos: [
        for (final image in images)
          LivePhoto(
              localId: 'image-${image.imageId}', imageId: image.imageId, mediaId: image.mediaId),
      ],
    );
  }

  /// Picks photos and starts their uploads; returns what the seller should be told, if anything.
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

    ListingNotice? notice;
    final accepted = picked.take(state.remaining).toList();
    if (picked.length > accepted.length) notice = const ListingNotice(ListingNoticeKind.maxPhotos);
    final valid = <LivePhoto>[];
    for (final photo in accepted) {
      final inspection = await _source.inspect(photo.bytes);
      final violation = photoRuleViolation(sizeBytes: photo.bytes.length, inspection: inspection);
      if (violation != null) {
        notice ??= ListingNotice(violation == 'ERROR_PHOTO_TOO_LARGE'
            ? ListingNoticeKind.photoTooLarge
            : ListingNoticeKind.invalidPhoto);
        continue;
      }
      valid.add(LivePhoto(
        localId: 'new-${_nextId++}',
        bytes: photo.bytes,
        fileName: photo.name,
        contentType: inspection!.contentType,
        width: inspection.width,
        height: inspection.height,
        status: PhotoStatus.uploading,
      ));
    }
    if (!ref.mounted) return null;
    state = state.copyWith(photos: [...state.photos, ...valid], isBusy: false);
    await Future.wait(valid.map(_upload));
    return notice;
  }

  /// Uploads a failed photo again from the start.
  Future<void> retry(String localId) async {
    final photo = _find(localId);
    if (photo == null || !photo.canRetry) return;
    final restarted = photo.copyWith(status: PhotoStatus.uploading, clearError: true);
    _replace(restarted);
    await _upload(restarted);
  }

  /// Takes a photo off the listing (it is removed on the server when the edit is saved) or drops
  /// one that was only added. The main photo and the last two stay.
  void remove(String localId) {
    final index = state.photos.indexWhere((photo) => photo.localId == localId);
    if (index < 0 || !state.canRemove(index)) return;
    final photo = state.photos[index];
    final imageId = photo.imageId;
    state = state.copyWith(
      photos: [...state.photos]..removeAt(index),
      removedImageIds: imageId == null ? null : {...state.removedImageIds, imageId},
    );
  }

  Future<void> _upload(LivePhoto photo) async {
    try {
      final ticket = await _repository.requestUpload(
        listingId: args.listingId,
        fileName: photo.fileName,
        contentType: photo.contentType,
        sizeBytes: photo.bytes!.length,
      );
      await _repository.uploadBytes(ticket.uploadUrl, photo.bytes!, photo.contentType);
      await _repository.completeUpload(
        mediaId: ticket.mediaId,
        contentType: photo.contentType,
        sizeBytes: photo.bytes!.length,
        width: photo.width,
        height: photo.height,
      );
      if (ref.mounted) _replace(photo.copyWith(status: PhotoStatus.ready, mediaId: ticket.mediaId));
    } on ApiError catch (error) {
      if (ref.mounted) _replace(photo.copyWith(status: PhotoStatus.failed, errorCode: error.code));
    }
  }

  LivePhoto? _find(String localId) =>
      state.photos.where((photo) => photo.localId == localId).firstOrNull;

  void _replace(LivePhoto photo) {
    state = state.copyWith(photos: [
      for (final existing in state.photos) existing.localId == photo.localId ? photo : existing,
    ]);
  }
}

final livePhotosControllerProvider = NotifierProvider.autoDispose
    .family<LivePhotosController, LivePhotosState, ItemDetailsArgs>(LivePhotosController.new);

/// A short-lived link to show one of the listing's own photos; null when it cannot be made.
final listingPhotoUrlProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, mediaId) async {
  try {
    return await ref.read(listingRepositoryProvider).photoUrl(mediaId);
  } on ApiError {
    return null;
  }
});
