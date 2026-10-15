import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../domain/listing_photo.dart';

enum PhotoSourceKind { camera, gallery }

class PickedPhoto {
  final String name;
  final Uint8List bytes;

  const PickedPhoto({required this.name, required this.bytes});
}

/// Raised when the OS refuses access to the camera or photo library.
class PhotoAccessDeniedException implements Exception {
  final PhotoSourceKind source;

  const PhotoAccessDeniedException(this.source);
}

/// Camera / gallery access and reading a photo's real type and size.
abstract class PhotoSource {
  /// An empty list means the user cancelled.
  Future<List<PickedPhoto>> pick(PhotoSourceKind kind, {required int limit});

  /// Null when the bytes are not an image this app can read.
  Future<PhotoInspection?> inspect(Uint8List bytes);
}

class DevicePhotoSource implements PhotoSource {
  // Large camera photos are scaled down to keep uploads fast; 2560 px stays well above 480.
  static const double _maxSide = 2560;
  static const int _quality = 85;

  final ImagePicker _picker;

  DevicePhotoSource([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  @override
  Future<List<PickedPhoto>> pick(PhotoSourceKind kind, {required int limit}) async {
    try {
      final List<XFile> files;
      if (kind == PhotoSourceKind.camera) {
        final file = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: _maxSide,
          maxHeight: _maxSide,
          imageQuality: _quality,
        );
        files = [if (file != null) file];
      } else if (limit == 1) {
        final file = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: _maxSide,
          maxHeight: _maxSide,
          imageQuality: _quality,
        );
        files = [if (file != null) file];
      } else {
        files = await _picker.pickMultiImage(
          maxWidth: _maxSide,
          maxHeight: _maxSide,
          imageQuality: _quality,
          limit: limit,
        );
      }
      return [
        for (final file in files) PickedPhoto(name: file.name, bytes: await file.readAsBytes())
      ];
    } on PlatformException catch (e) {
      if (e.code.contains('access_denied') || e.code.contains('permission')) {
        throw PhotoAccessDeniedException(kind);
      }
      rethrow;
    }
  }

  @override
  Future<PhotoInspection?> inspect(Uint8List bytes) async {
    final type = detectImageType(bytes);
    if (type == null) return null;
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final inspection =
          PhotoInspection(contentType: type, width: descriptor.width, height: descriptor.height);
      descriptor.dispose();
      buffer.dispose();
      return inspection;
    } on Object {
      return null;
    }
  }
}

final photoSourceProvider = Provider<PhotoSource>((ref) => DevicePhotoSource());
