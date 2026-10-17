import '../../../core/network/api_error.dart';
import '../../../core/network/api_error_messages.dart';
import '../../../l10n/app_localizations.dart';
import 'providers/create_listing_controller.dart';

/// User-facing text for a listing/media backend error code (US-004 error scenarios).
String? listingCodeMessage(AppLocalizations l10n, String? code) {
  return switch (code) {
    'ERROR_MAX_PHOTOS_EXCEEDED' => l10n.sellErrorMaxPhotos,
    'ERROR_INVALID_PHOTO' => l10n.sellErrorInvalidPhoto,
    'ERROR_PHOTO_UPLOAD_FAILED' => l10n.sellErrorUploadFailed,
    'ACCOUNT_NOT_ACTIVE' => l10n.sellErrorNotActive,
    'ERROR_MIN_PHOTOS_REQUIRED' => l10n.sellErrorMinPhotos,
    'ERROR_LISTING_NOT_EDITABLE' => l10n.sellErrorNotEditable,
    'ERROR_TITLE_REQUIRED' => l10n.itemTitleRequired,
    'ERROR_CATEGORY_REQUIRED' => l10n.itemCategoryRequired,
    'ERROR_CONDITION_REQUIRED' => l10n.itemConditionRequired,
    'ERROR_DESCRIPTION_REQUIRED' => l10n.itemDescriptionRequired,
    'ERROR_PRICE_INVALID' => l10n.itemPriceInvalid,
    'AADHAAR_VERIFICATION_REQUIRED' => l10n.homeSellAadhaarRequired,
    _ => null,
  };
}

String listingErrorMessage(AppLocalizations l10n, Object? error) {
  if (error is ApiError) {
    return listingCodeMessage(l10n, error.code) ?? apiErrorMessage(l10n, error);
  }
  return apiErrorMessage(l10n, error ?? Object());
}

String listingNoticeMessage(AppLocalizations l10n, ListingNotice notice) {
  return switch (notice.kind) {
    ListingNoticeKind.maxPhotos => l10n.sellErrorMaxPhotos,
    ListingNoticeKind.invalidPhoto => l10n.sellErrorInvalidPhoto,
    ListingNoticeKind.photoTooLarge => l10n.sellErrorPhotoTooLarge,
    ListingNoticeKind.cameraDenied => l10n.sellErrorCameraDenied,
    ListingNoticeKind.galleryDenied => l10n.sellErrorGalleryDenied,
    ListingNoticeKind.draftFailed ||
    ListingNoticeKind.removeFailed =>
      listingErrorMessage(l10n, notice.error),
  };
}
