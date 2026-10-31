import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/api_error_mapper.dart';
import '../domain/category.dart';
import '../domain/listing_details.dart';
import '../domain/listing_schema.dart';
import '../domain/plan_selection.dart';
import '../domain/restricted_check.dart';
import '../domain/seller_plan.dart';

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

  /// Saves the item details of a draft (US-114, US-006): the common fields plus the values the
  /// category asks for. Only the city is sent as the location.
  Future<void> saveDetails(
    String listingId,
    ListingDetailsDraft details,
    ListingSchema schema, {
    String? city,
  }) =>
      _client.patch<void>(
        ApiConstants.listing(listingId),
        data: details.toJson(schema, city: city),
      );

  /// Files the draft under an L3 category; values the new category does not use are dropped
  /// by the server.
  Future<void> setCategory(String listingId, String categoryCode) => _client.put<void>(
        ApiConstants.listingCategory(listingId),
        data: {'categoryCode': categoryCode},
      );

  /// Enabled child categories; without a parent, the top-level categories.
  Future<List<CategoryNode>> categoryChildren({String? parentCode, CategoryScope? scope}) =>
      _client.get(
        ApiConstants.categoryChildren,
        queryParameters: {
          if (parentCode != null) 'parentCode': parentCode,
          'scope': (scope ?? CategoryScope.all).apiValue,
        },
        parse: (json) => [
          for (final item in json as List<dynamic>)
            CategoryNode.fromJson(item as Map<String, dynamic>),
        ],
      );

  /// Leaf categories whose name matches; the server needs at least two characters.
  Future<List<CategoryRef>> searchCategories(String query) => _client.get(
        ApiConstants.categorySearch,
        queryParameters: {'q': query},
        parse: (json) => [
          for (final item in json as List<dynamic>)
            CategoryRef.fromJson(item as Map<String, dynamic>),
        ],
      );

  /// The Item Details form for a leaf category.
  Future<ListingSchema> listingSchema(String categoryCode) => _client.get(
        ApiConstants.categoryListingSchema(categoryCode),
        parse: (json) => ListingSchema.fromJson(json as Map<String, dynamic>),
      );

  /// The listing plans with prices, features and the payment breakdown (US-078).
  Future<List<SellerPlan>> sellerPlans() => _client.get(
        ApiConstants.sellerPlans,
        parse: (json) => [
          for (final item in json as List<dynamic>)
            SellerPlan.fromJson(item as Map<String, dynamic>),
        ],
      );

  /// Chooses a plan for a finished draft (US-008). The server decides the amount; a plan that costs
  /// something comes back with the checkout details. An unverified seller is refused with
  /// `AADHAAR_VERIFICATION_REQUIRED`.
  Future<PlanSelection> selectPlan(String listingId, String planCode) => _client.post(
        ApiConstants.listingPlanSelection(listingId),
        data: {'planCode': planCode},
        parse: (json) => PlanSelection.fromJson(json as Map<String, dynamic>),
      );

  /// Asks AI to suggest the details of a submitted draft (US-005). Null when AI cannot help right
  /// now (off, down, quota used up): the seller then fills the page by hand. Network and server
  /// failures are thrown as [ApiError].
  Future<AiSuggestion?> generateAiSuggestions(String listingId) => _client.post(
        ApiConstants.listingAiSuggestions(listingId),
        receiveTimeout: ApiConstants.aiSuggestionTimeout,
        parse: (json) => AiSuggestion.fromJson(json as Map<String, dynamic>),
      );

  /// Checks the draft against the restricted items policy (US-007). A blocked item (400
  /// `ERROR_RESTRICTED_ITEM`, 403 `ERROR_ACCOUNT_SUSPENDED`) is returned as a result, not thrown,
  /// because the answer lists the rows behind it; every other failure is thrown as [ApiError].
  Future<RestrictedCheck> checkRestrictedItems(String listingId) async {
    try {
      return await _client.post(
        ApiConstants.listingRestrictedCheck(listingId),
        parse: (json) => RestrictedCheck.fromJson(json as Map<String, dynamic>),
      );
    } on ApiError catch (error) {
      final data = error.data;
      if (_blockedCodes.contains(error.code) && data is Map<String, dynamic>) {
        return RestrictedCheck.fromJson(data);
      }
      rethrow;
    }
  }

  /// "Agree & Continue": records the seller's agreement to every row the check showed.
  Future<void> acceptCompliance(String listingId, String checkId, List<String> policyCodes) =>
      _client.post<void>(
        ApiConstants.listingComplianceAcceptance(listingId, checkId),
        data: {'policyCodes': policyCodes},
      );

  /// Asks for a human to look at a blocked item again; one appeal per check.
  Future<void> appealRestricted(String listingId, String checkId, String reason) =>
      _client.post<void>(
        ApiConstants.listingRestrictedAppeal(listingId, checkId),
        data: {'reason': reason},
      );

  static const _blockedCodes = {'ERROR_RESTRICTED_ITEM', 'ERROR_ACCOUNT_SUSPENDED'};

  /// Tells the server what the seller did with each AI suggestion (US-005 contract).
  Future<void> sendSuggestionFeedback(
    String listingId,
    String suggestionId,
    List<SuggestionFeedback> feedback,
  ) =>
      _client.patch<void>(
        ApiConstants.listingAiFeedback(listingId, suggestionId),
        data: {
          'feedback': [for (final item in feedback) item.toJson()]
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
