import 'dart:typed_data';

/// Rules from US-004: JPG/PNG/HEIC, at most 10 MB and at least 480x480, up to 10 photos.
class ListingPhotoRules {
  ListingPhotoRules._();

  static const int maxPhotos = 10;
  static const int minPhotos = 1;
  static const int maxBytes = 10 * 1024 * 1024;
  static const int minSide = 480;
}

enum PhotoStatus { uploading, ready, failed, removing }

/// A photo on the capture screen and how far its upload got.
class ListingPhoto {
  final String localId;
  final String fileName;
  final Uint8List bytes;
  final String contentType;
  final int width;
  final int height;
  final PhotoStatus status;

  /// Backend error code of the last failed step, if any.
  final String? errorCode;
  final String? imageId;

  const ListingPhoto({
    required this.localId,
    required this.fileName,
    required this.bytes,
    required this.contentType,
    required this.width,
    required this.height,
    this.status = PhotoStatus.uploading,
    this.errorCode,
    this.imageId,
  });

  /// A rejected photo cannot succeed on retry; only removing it helps.
  bool get canRetry => status == PhotoStatus.failed && errorCode != 'ERROR_INVALID_PHOTO';

  ListingPhoto copyWith({
    PhotoStatus? status,
    String? errorCode,
    String? imageId,
    bool clearError = false,
  }) {
    return ListingPhoto(
      localId: localId,
      fileName: fileName,
      bytes: bytes,
      contentType: contentType,
      width: width,
      height: height,
      status: status ?? this.status,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      imageId: imageId ?? this.imageId,
    );
  }
}

/// The image type and size read from a photo's bytes.
class PhotoInspection {
  final String contentType;
  final int width;
  final int height;

  const PhotoInspection({required this.contentType, required this.width, required this.height});
}

/// Returns the image type from the file's first bytes, or null for anything that is not
/// JPEG, PNG or HEIC (whatever the file name says).
String? detectImageType(Uint8List bytes) {
  if (bytes.length > 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
    return 'image/jpeg';
  }
  const png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  if (bytes.length >= png.length) {
    var match = true;
    for (var i = 0; i < png.length; i++) {
      if (bytes[i] != png[i]) {
        match = false;
        break;
      }
    }
    if (match) return 'image/png';
  }
  if (bytes.length >= 12 && String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp') {
    const heifBrands = {'heic', 'heix', 'heim', 'heis', 'hevc', 'hevx', 'mif1', 'msf1', 'heif'};
    if (heifBrands.contains(String.fromCharCodes(bytes.sublist(8, 12)).toLowerCase())) {
      return 'image/heic';
    }
  }
  return null;
}

/// The client-side check run before any upload; null when the photo may be uploaded.
String? photoRuleViolation({required int sizeBytes, PhotoInspection? inspection}) {
  if (sizeBytes > ListingPhotoRules.maxBytes) return 'ERROR_PHOTO_TOO_LARGE';
  if (inspection == null ||
      inspection.width < ListingPhotoRules.minSide ||
      inspection.height < ListingPhotoRules.minSide) {
    return 'ERROR_INVALID_PHOTO';
  }
  return null;
}
