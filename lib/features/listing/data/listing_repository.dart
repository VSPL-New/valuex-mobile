import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/api_error_mapper.dart';
import '../domain/listing_details.dart';

/// A short-lived URL the photo bytes are sent to, for one media asset.
class UploadTicket {
  final String mediaId;
  final String uploadUrl;

  const UploadTicket({required this.mediaId, required this.uploadUrl});
}

/// Draft listings and their photos (US-004). Bytes go straight to object storage through a
/// signed URL; the API only records and validates them.
class ListingRepository {
  final ApiClient _client;
  final Dio _storage;

  ListingRepository(this._client, this._storage);

  /// Creates an empty draft and returns its id.
  Future<String> createDraft() => _client.post(
        ApiConstants.listings,
        parse: (json) => (json as Map<String, dynamic>)['listingId'] as String,
      );

  /// Hands the draft over for plan selection; an unverified seller is refused here with
  /// `AADHAAR_VERIFICATION_REQUIRED`.
  Future<void> submitDraft(String listingId) =>
      _client.post<void>(ApiConstants.listingSubmit(listingId));

  Future<UploadTicket> requestUpload({
    required String listingId,
    required String fileName,
    required String contentType,
    required int sizeBytes,
  }) {
    return _client.post(
      ApiConstants.mediaUploads,
      data: {
        'purpose': 'LISTING_IMAGE',
        'ownerType': 'LISTING',
        'ownerId': listingId,
        'fileName': fileName,
        'contentType': contentType,
        'sizeBytes': sizeBytes,
      },
      parse: (json) {
        final map = json as Map<String, dynamic>;
        return UploadTicket(
            mediaId: map['mediaId'] as String, uploadUrl: map['uploadUrl'] as String);
      },
    );
  }

  /// Sends the bytes to storage. The URL is signed for this exact type and length.
  Future<void> uploadBytes(String uploadUrl, Uint8List bytes, String contentType) async {
    try {
      await _storage.put<void>(
        uploadUrl,
        data: Stream<List<int>>.value(bytes),
        options: Options(
          headers: {
            Headers.contentTypeHeader: contentType,
            Headers.contentLengthHeader: bytes.length,
          },
        ),
      );
    } on DioException catch (e) {
      final error = ApiErrorMapper.fromDio(e);
      throw ApiError(
        type: error.type,
        message: error.message,
        code: 'ERROR_PHOTO_UPLOAD_FAILED',
        statusCode: error.statusCode,
      );
    }
  }

  Future<void> completeUpload({
    required String mediaId,
    required String contentType,
    required int sizeBytes,
    required int width,
    required int height,
  }) {
    return _client.post<void>(
      ApiConstants.mediaComplete(mediaId),
      data: {
        'contentType': contentType,
        'sizeBytes': sizeBytes,
        'width': width,
        'height': height,
      },
    );
  }

  /// Adds a ready photo to the draft and returns the listing image id.
  Future<String> attachImage(String listingId, String mediaId) => _client.post(
        ApiConstants.listingImages(listingId),
        data: {'mediaId': mediaId},
        parse: (json) => (json as Map<String, dynamic>)['imageId'] as String,
      );

  Future<void> deleteImage(String listingId, String imageId) =>
      _client.delete<void>(ApiConstants.listingImage(listingId, imageId));

  /// Saves the item details of a draft (US-114). Only the city is sent as the location.
  Future<void> saveDetails(String listingId, ListingDetailsDraft details, {String? city}) =>
      _client.patch<void>(
        ApiConstants.listing(listingId),
        data: {
          'title': details.title.trim(),
          'categorySlug': details.categorySlug,
          'condition': details.condition?.apiValue,
          'description': details.description.trim(),
          'price': details.parsedPrice,
          'location': city,
        },
      );

  /// Tells the server what the seller did with each AI suggestion (US-005 contract).
  Future<void> sendSuggestionFeedback(
    String listingId,
    String suggestionId,
    List<SuggestionFeedback> feedback,
  ) =>
      _client.patch<void>(
        ApiConstants.listingAiFeedback(listingId, suggestionId),
        data: {
          'fields': [for (final item in feedback) item.toJson()]
        },
      );
}

/// Plain client for signed storage URLs: no base URL, no bearer token, no envelope.
final storageUploadDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: ApiConstants.connectTimeout,
    sendTimeout: const Duration(minutes: 2),
    receiveTimeout: ApiConstants.receiveTimeout,
  ));
  ref.onDispose(dio.close);
  return dio;
});

final listingRepositoryProvider = Provider<ListingRepository>(
  (ref) => ListingRepository(ref.watch(apiClientProvider), ref.watch(storageUploadDioProvider)),
);
