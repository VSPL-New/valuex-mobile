import 'dart:typed_data';

import 'listing_photo.dart';

/// A photo on a live listing being edited (US-010): one the listing already has (shown from a
/// short-lived link by its media asset), or one the seller just added (shown from its bytes).
class LivePhoto {
  final String localId;

  /// Set for a photo the listing already has; it is what a removal is sent by.
  final String? imageId;

  /// The media asset; for an added photo it is set once the upload is complete.
  final String? mediaId;

  /// Only for an added photo.
  final Uint8List? bytes;
  final String fileName;
  final String contentType;
  final int width;
  final int height;
  final PhotoStatus status;
  final String? errorCode;

  const LivePhoto({
    required this.localId,
    this.imageId,
    this.mediaId,
    this.bytes,
    this.fileName = '',
    this.contentType = '',
    this.width = 0,
    this.height = 0,
    this.status = PhotoStatus.ready,
    this.errorCode,
  });

  bool get isNew => imageId == null;

  /// A rejected photo cannot succeed on retry; only removing it helps.
  bool get canRetry => status == PhotoStatus.failed && errorCode != 'ERROR_INVALID_PHOTO';

  LivePhoto copyWith(
      {PhotoStatus? status, String? mediaId, String? errorCode, bool clearError = false}) {
    return LivePhoto(
      localId: localId,
      imageId: imageId,
      mediaId: mediaId ?? this.mediaId,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
      width: width,
      height: height,
      status: status ?? this.status,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }
}
