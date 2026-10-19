import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/post_aadhaar_route.dart';
import 'package:valuex_mobile/core/routing/route_guard.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_controller.dart';
import 'package:valuex_mobile/features/auth/presentation/providers/session_state.dart';
import 'package:valuex_mobile/features/auth/presentation/screens/aadhaar_screen.dart';
import 'package:valuex_mobile/features/listing/data/listing_repository.dart';
import 'package:valuex_mobile/features/listing/data/photo_source.dart';
import 'package:valuex_mobile/features/listing/domain/listing_photo.dart';
import 'package:valuex_mobile/features/listing/presentation/listing_error_messages.dart';
import 'package:valuex_mobile/features/listing/presentation/create_listing_screen.dart';
import 'package:valuex_mobile/features/listing/presentation/item_details_screen.dart';
import 'package:valuex_mobile/core/widgets/square_back_button.dart';
import 'package:valuex_mobile/features/listing/presentation/providers/create_listing_controller.dart';
import 'package:valuex_mobile/features/notifications/data/notifications_repository.dart';
import 'package:valuex_mobile/l10n/app_localizations_en.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_secure_storage.dart';
import '../../helpers/fonts.dart';

class _MockRepository extends Mock implements ListingRepository {}

class _MockNotifications extends Mock implements NotificationsRepository {}

/// A real 1x1 PNG, so Image.memory can decode it in widget tests.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

const _goodInspection = PhotoInspection(contentType: 'image/png', width: 800, height: 600);
const _offline = ApiError(type: ApiErrorType.network, message: 'offline');

class _FakePhotoSource implements PhotoSource {
  List<PickedPhoto> next = [];
  Object? pickError;
  PhotoInspection? inspection = _goodInspection;
  final List<(PhotoSourceKind, int)> calls = [];

  @override
  Future<List<PickedPhoto>> pick(PhotoSourceKind kind, {required int limit}) async {
    calls.add((kind, limit));
    if (pickError != null) throw pickError!;
    final result = next;
    next = [];
    return result;
  }

  @override
  Future<PhotoInspection?> inspect(Uint8List bytes) async => inspection;
}

List<PickedPhoto> _photos(int count, {int size = 0}) => [
      for (var i = 0; i < count; i++)
        PickedPhoto(name: 'p$i.png', bytes: size == 0 ? _png : Uint8List(size)),
    ];

void _stubHappyUploads(_MockRepository repository) {
  var media = 0;
  var image = 0;
  when(() => repository.createDraft()).thenAnswer((_) async => 'listing-1');
  when(() => repository.requestUpload(
            listingId: any(named: 'listingId'),
            fileName: any(named: 'fileName'),
            contentType: any(named: 'contentType'),
            sizeBytes: any(named: 'sizeBytes'),
          ))
      .thenAnswer(
          (_) async => UploadTicket(mediaId: 'media-${media++}', uploadUrl: 'https://s3/x'));
  when(() => repository.uploadBytes(any(), any(), any())).thenAnswer((_) async {});
  when(() => repository.completeUpload(
        mediaId: any(named: 'mediaId'),
        contentType: any(named: 'contentType'),
        sizeBytes: any(named: 'sizeBytes'),
        width: any(named: 'width'),
        height: any(named: 'height'),
      )).thenAnswer((_) async {});
  when(() => repository.attachImage(any(), any())).thenAnswer((_) async => 'image-${image++}');
  when(() => repository.deleteImage(any(), any())).thenAnswer((_) async {});
  when(() => repository.submitDraft(any())).thenAnswer((_) async {});
}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    loadBrandFonts();
  });

  group('photo rules', () {
    test('detects JPEG, PNG and HEIC from their bytes, nothing else', () {
      expect(detectImageType(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])), 'image/jpeg');
      expect(detectImageType(_png), 'image/png');
      Uint8List heif(String brand) =>
          Uint8List.fromList([0, 0, 0, 24, ...'ftyp'.codeUnits, ...brand.codeUnits, 0, 0]);
      expect(detectImageType(heif('heic')), 'image/heic');
      expect(detectImageType(heif('mif1')), 'image/heic');
      expect(detectImageType(heif('avif')), isNull);
      expect(detectImageType(Uint8List.fromList(utf8.encode('GIF89a...'))), isNull);
      expect(detectImageType(Uint8List(2)), isNull);
    });

    test('rejects photos over 10 MB, under 480 px or unreadable', () {
      expect(photoRuleViolation(sizeBytes: 1024, inspection: _goodInspection), isNull);
      expect(
        photoRuleViolation(sizeBytes: ListingPhotoRules.maxBytes + 1, inspection: _goodInspection),
        'ERROR_PHOTO_TOO_LARGE',
      );
      expect(
        photoRuleViolation(
          sizeBytes: 1024,
          inspection: const PhotoInspection(contentType: 'image/png', width: 479, height: 900),
        ),
        'ERROR_INVALID_PHOTO',
      );
      expect(photoRuleViolation(sizeBytes: 1024), 'ERROR_INVALID_PHOTO');
    });

    testWidgets('the device source reads real dimensions and refuses non-images', (tester) async {
      final source = DevicePhotoSource();
      final result = await tester.runAsync(() => source.inspect(_png));
      expect(result!.contentType, 'image/png');
      expect(result.width, 1);
      expect(result.height, 1);
      expect(await tester.runAsync(() => source.inspect(Uint8List.fromList([1, 2, 3]))), isNull);
      final broken = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 0, 0]);
      expect(await tester.runAsync(() => source.inspect(broken)), isNull);
    });
  });

  group('repository', () {
    late FakeHttpAdapter api;
    late FakeHttpAdapter storage;
    late ListingRepository repository;

    setUp(() {
      api = FakeHttpAdapter((options) async {
        return switch (options.path) {
          '/listings' => FakeHttpAdapter.json(201, {
              'success': true,
              'data': {'listingId': 'listing-1', 'status': 'DRAFT'},
            }),
          '/media/uploads' => FakeHttpAdapter.ok({
              'mediaId': 'media-1',
              'uploadUrl': 'https://storage.example/put',
              'expiresAt': '2026-10-14T10:00:00Z',
            }),
          '/listings/listing-1/images' =>
            FakeHttpAdapter.ok({'imageId': 'image-1', 'mediaId': 'media-1'}),
          _ => FakeHttpAdapter.ok(null),
        };
      });
      storage = FakeHttpAdapter((_) async => ResponseBody.fromString('', 200));
      repository = ListingRepository(
        ApiClient(FakeSecureStorage(accessToken: 'a', refreshToken: 'r'), testConfig, adapter: api),
        Dio()..httpClientAdapter = storage,
      );
    });

    test('creates a draft, uploads, completes and attaches with the documented bodies', () async {
      expect(await repository.createDraft(), 'listing-1');

      final ticket = await repository.requestUpload(
        listingId: 'listing-1',
        fileName: 'p.png',
        contentType: 'image/png',
        sizeBytes: 68,
      );
      expect(ticket.mediaId, 'media-1');
      expect(api.requests.last.data, {
        'purpose': 'LISTING_IMAGE',
        'ownerType': 'LISTING',
        'ownerId': 'listing-1',
        'fileName': 'p.png',
        'contentType': 'image/png',
        'sizeBytes': 68,
      });

      await repository.uploadBytes(ticket.uploadUrl, _png, 'image/png');
      final put = storage.requests.single;
      expect(put.method, 'PUT');
      expect(put.uri.toString(), 'https://storage.example/put');
      expect(put.headers[Headers.contentTypeHeader], 'image/png');
      expect(put.headers[Headers.contentLengthHeader], _png.length);
      expect(put.headers['Authorization'], isNull,
          reason: 'storage must never get the bearer token');

      await repository.completeUpload(
        mediaId: 'media-1',
        contentType: 'image/png',
        sizeBytes: 68,
        width: 800,
        height: 600,
      );
      expect(api.requests.last.path, '/media/media-1/complete');
      expect(api.requests.last.data,
          {'contentType': 'image/png', 'sizeBytes': 68, 'width': 800, 'height': 600});

      expect(await repository.attachImage('listing-1', 'media-1'), 'image-1');
      expect(api.requests.last.data, {'mediaId': 'media-1'});

      await repository.deleteImage('listing-1', 'image-1');
      expect(api.requests.last.method, 'DELETE');
      expect(api.requests.last.path, '/listings/listing-1/images/image-1');
    });

    test('a failed transfer to storage is reported as an upload failure', () async {
      storage = FakeHttpAdapter((_) async => ResponseBody.fromString('denied', 403));
      repository = ListingRepository(
        ApiClient(FakeSecureStorage(), testConfig, adapter: api),
        Dio()..httpClientAdapter = storage,
      );

      expect(
        () => repository.uploadBytes('https://storage.example/put', _png, 'image/png'),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'ERROR_PHOTO_UPLOAD_FAILED')),
      );
    });
  });

  group('controller', () {
    late _MockRepository repository;
    late _FakePhotoSource source;
    late ProviderContainer container;

    CreateListingController controller() =>
        container.read(createListingControllerProvider.notifier);
    CreateListingState state() => container.read(createListingControllerProvider);

    setUp(() {
      repository = _MockRepository();
      source = _FakePhotoSource();
      _stubHappyUploads(repository);
      container = ProviderContainer(overrides: [
        listingRepositoryProvider.overrideWithValue(repository),
        photoSourceProvider.overrideWithValue(source),
      ]);
      container.listen(createListingControllerProvider, (_, __) {});
    });

    tearDown(() => container.dispose());

    test('creates the draft on the first photo and uploads every photo to it', () async {
      source.next = _photos(2);

      final notice = await controller().addPhotos(PhotoSourceKind.gallery);

      expect(notice, isNull);
      expect(source.calls.single, (PhotoSourceKind.gallery, 10));
      expect(state().listingId, 'listing-1');
      expect(state().photos.map((p) => p.status), [PhotoStatus.ready, PhotoStatus.ready]);
      expect(state().photos.map((p) => p.imageId), ['image-0', 'image-1']);
      expect(state().canSubmit, isTrue);
      verify(() => repository.createDraft()).called(1);
      verify(() => repository.uploadBytes('https://s3/x', _png, 'image/png')).called(2);
      verify(() => repository.completeUpload(
            mediaId: 'media-0',
            contentType: 'image/png',
            sizeBytes: _png.length,
            width: 800,
            height: 600,
          )).called(1);

      source.next = _photos(1);
      await controller().addPhotos(PhotoSourceKind.camera);
      verifyNever(() => repository.createDraft());
      expect(source.calls.last, (PhotoSourceKind.camera, 8));
    });

    test('nothing happens when the user cancels the picker', () async {
      expect(await controller().addPhotos(PhotoSourceKind.camera), isNull);
      expect(state().photos, isEmpty);
      expect(state().canSubmit, isFalse);
      verifyNever(() => repository.createDraft());
    });

    test('keeps at most 10 photos and says so', () async {
      source.next = _photos(12);

      final notice = await controller().addPhotos(PhotoSourceKind.gallery);

      expect(notice!.kind, ListingNoticeKind.maxPhotos);
      expect(state().photos, hasLength(10));
      expect((await controller().addPhotos(PhotoSourceKind.gallery))!.kind,
          ListingNoticeKind.maxPhotos);
      expect(source.calls, hasLength(1), reason: 'the picker is not opened when full');
    });

    test('skips low-quality and oversized photos before uploading', () async {
      source.inspection = const PhotoInspection(contentType: 'image/png', width: 200, height: 200);
      source.next = _photos(1);
      expect((await controller().addPhotos(PhotoSourceKind.camera))!.kind,
          ListingNoticeKind.invalidPhoto);

      source.inspection = _goodInspection;
      source.next = _photos(1, size: ListingPhotoRules.maxBytes + 1);
      expect((await controller().addPhotos(PhotoSourceKind.camera))!.kind,
          ListingNoticeKind.photoTooLarge);

      expect(state().photos, isEmpty);
      verifyNever(() => repository.createDraft());
    });

    test('reports camera and gallery permission denial', () async {
      source.pickError = const PhotoAccessDeniedException(PhotoSourceKind.camera);
      expect((await controller().addPhotos(PhotoSourceKind.camera))!.kind,
          ListingNoticeKind.cameraDenied);
      source.pickError = const PhotoAccessDeniedException(PhotoSourceKind.gallery);
      expect((await controller().addPhotos(PhotoSourceKind.gallery))!.kind,
          ListingNoticeKind.galleryDenied);
      expect(state().isBusy, isFalse);
    });

    test('reports a draft that cannot be created and keeps no photos', () async {
      const blocked = ApiError(
        type: ApiErrorType.business,
        message: 'x',
        code: 'AADHAAR_VERIFICATION_REQUIRED',
        statusCode: 403,
      );
      when(() => repository.createDraft()).thenThrow(blocked);
      source.next = _photos(1);

      final notice = await controller().addPhotos(PhotoSourceKind.camera);

      expect(notice!.kind, ListingNoticeKind.draftFailed);
      expect(notice.error, blocked);
      expect(state().photos, isEmpty);
      expect(state().isBusy, isFalse);
    });

    test('creating a draft is not blocked for a seller who has not verified Aadhaar', () async {
      source.next = _photos(1);

      final notice = await controller().addPhotos(PhotoSourceKind.camera);

      expect(notice, isNull);
      expect(state().listingId, 'listing-1');
    });

    test('submit sends the draft and reports success', () async {
      source.next = _photos(2);
      await controller().addPhotos(PhotoSourceKind.camera);

      final result = await controller().submit();

      expect(result.outcome, SubmitOutcome.submitted);
      verify(() => repository.submitDraft('listing-1')).called(1);
      expect(state().isBusy, isFalse);
    });

    test('submit asks for Aadhaar when the server says it is required', () async {
      source.next = _photos(2);
      await controller().addPhotos(PhotoSourceKind.camera);
      when(() => repository.submitDraft(any())).thenThrow(const ApiError(
        type: ApiErrorType.business,
        message: 'x',
        code: 'AADHAAR_VERIFICATION_REQUIRED',
        statusCode: 403,
      ));

      final result = await controller().submit();

      expect(result.outcome, SubmitOutcome.aadhaarRequired);
      expect(state().photos, hasLength(2));
      expect(state().isBusy, isFalse);
    });

    test('submit reports any other failure and keeps the photos', () async {
      source.next = _photos(2);
      await controller().addPhotos(PhotoSourceKind.camera);
      when(() => repository.submitDraft(any())).thenThrow(_offline);

      final result = await controller().submit();

      expect(result.outcome, SubmitOutcome.failed);
      expect(result.error, _offline);
      expect(state().photos, hasLength(2));
    });

    test('submit does nothing without a ready photo', () async {
      final result = await controller().submit();

      expect(result.outcome, SubmitOutcome.failed);
      verifyNever(() => repository.submitDraft(any()));
    });

    test('holding for Aadhaar keeps the draft and the way back until the screen resumes', () async {
      source.next = _photos(1);
      await controller().addPhotos(PhotoSourceKind.camera);

      controller().holdForAadhaar();
      expect(container.read(postAadhaarRouteProvider), RouteNames.sell);

      expect(controller().resumeFromAadhaar(), isTrue);
      expect(container.read(postAadhaarRouteProvider), isNull);
      expect(controller().resumeFromAadhaar(), isFalse);
    });

    test('marks a failed upload and retries it from the start', () async {
      when(() => repository.uploadBytes(any(), any(), any())).thenThrow(
        const ApiError(type: ApiErrorType.network, message: 'x', code: 'ERROR_PHOTO_UPLOAD_FAILED'),
      );
      source.next = _photos(2);
      await controller().addPhotos(PhotoSourceKind.camera);

      final failed = state().photos.first;
      expect(failed.status, PhotoStatus.failed);
      expect(failed.errorCode, 'ERROR_PHOTO_UPLOAD_FAILED');
      expect(failed.canRetry, isTrue);
      expect(state().canSubmit, isFalse);

      when(() => repository.uploadBytes(any(), any(), any())).thenAnswer((_) async {});
      await controller().retry(failed.localId);
      expect(state().canSubmit, isFalse, reason: 'one photo is still failed');
      await controller().retry(state().photos.last.localId);

      expect(state().photos.map((p) => p.status), [PhotoStatus.ready, PhotoStatus.ready]);
      expect(state().canSubmit, isTrue);
    });

    test('a photo the server rejects cannot be retried, only removed', () async {
      when(() => repository.completeUpload(
                mediaId: any(named: 'mediaId'),
                contentType: any(named: 'contentType'),
                sizeBytes: any(named: 'sizeBytes'),
                width: any(named: 'width'),
                height: any(named: 'height'),
              ))
          .thenThrow(const ApiError(
              type: ApiErrorType.business, message: 'x', code: 'ERROR_INVALID_PHOTO'));
      source.next = _photos(1);
      await controller().addPhotos(PhotoSourceKind.camera);

      final rejected = state().photos.single;
      expect(rejected.canRetry, isFalse);
      await controller().retry(rejected.localId);
      verify(() => repository.requestUpload(
            listingId: any(named: 'listingId'),
            fileName: any(named: 'fileName'),
            contentType: any(named: 'contentType'),
            sizeBytes: any(named: 'sizeBytes'),
          )).called(1);

      expect(await controller().remove(rejected.localId), isNull);
      expect(state().photos, isEmpty);
      verifyNever(() => repository.deleteImage(any(), any()));
    });

    test('removing an attached photo deletes it on the server', () async {
      source.next = _photos(2);
      await controller().addPhotos(PhotoSourceKind.gallery);
      final first = state().photos.first;

      expect(await controller().remove(first.localId), isNull);

      verify(() => repository.deleteImage('listing-1', 'image-0')).called(1);
      expect(state().photos.single.imageId, 'image-1');
    });

    test('a removal the server refuses keeps the photo and explains why', () async {
      source.next = _photos(1);
      await controller().addPhotos(PhotoSourceKind.gallery);
      when(() => repository.deleteImage(any(), any())).thenThrow(_offline);

      final notice = await controller().remove(state().photos.single.localId);

      expect(notice!.kind, ListingNoticeKind.removeFailed);
      expect(state().photos.single.status, PhotoStatus.ready);
      expect(await controller().remove('unknown'), isNull);
    });
  });

  group('messages', () {
    final l10n = AppLocalizationsEn();

    test('every US-004 error scenario has its own text', () {
      expect(listingCodeMessage(l10n, 'ERROR_MAX_PHOTOS_EXCEEDED'), 'Maximum 10 photos allowed');
      expect(listingCodeMessage(l10n, 'ERROR_INVALID_PHOTO'),
          'Photo quality too low or invalid format');
      expect(listingCodeMessage(l10n, 'ERROR_PHOTO_UPLOAD_FAILED'),
          'Failed to upload photo. Check your connection');
      expect(listingCodeMessage(l10n, 'ACCOUNT_NOT_ACTIVE'),
          'Only active accounts can create listings');
      expect(listingCodeMessage(l10n, 'AADHAAR_VERIFICATION_REQUIRED'),
          'Please complete Aadhaar verification to proceed');
      expect(listingCodeMessage(l10n, 'OTHER'), isNull);
      expect(listingNoticeMessage(l10n, const ListingNotice(ListingNoticeKind.cameraDenied)),
          'Camera access required to capture photos');
      expect(listingNoticeMessage(l10n, const ListingNotice(ListingNoticeKind.galleryDenied)),
          'Photo library access required to choose photos');
      expect(listingNoticeMessage(l10n, const ListingNotice(ListingNoticeKind.photoTooLarge)),
          'Photo exceeds 10MB limit');
      expect(
          listingNoticeMessage(l10n, const ListingNotice(ListingNoticeKind.removeFailed, _offline)),
          l10n.errorUnableToConnect);
      expect(listingErrorMessage(l10n, null), l10n.errorSomethingWentWrong);
    });
  });

  group('screen', () {
    late _MockRepository repository;
    late _FakePhotoSource source;

    Future<AppHarness> openSell(WidgetTester tester, {bool aadhaarVerified = true}) async {
      final notifications = _MockNotifications();
      when(notifications.unreadCount).thenAnswer((_) async => 0);
      final harness = AppHarness(tester, extraOverrides: [
        notificationsRepositoryProvider.overrideWithValue(notifications),
        listingRepositoryProvider.overrideWithValue(repository),
        photoSourceProvider.overrideWithValue(source),
      ])
        ..signedInAs(AccountStatus.active, aadhaarVerified: aadhaarVerified);
      await harness.launch(location: RouteNames.home);
      await tester.tap(find.text('Sell'));
      await harness.settle();
      return harness;
    }

    setUp(() {
      repository = _MockRepository();
      source = _FakePhotoSource();
      _stubHappyUploads(repository);
    });

    testWidgets('Sell opens the camera and shows the AI intro, tips and Submit to AI',
        (tester) async {
      final harness = await openSell(tester);

      expect(source.calls.single.$1, PhotoSourceKind.camera);
      expect(find.text('Add Photos'), findsWidgets);
      expect(find.text('Let AI do the work for you'), findsOneWidget);
      expect(find.text('Photo tips for best results'), findsOneWidget);
      expect(find.text('Take clear, well-lit photos'), findsOneWidget);
      expect(find.text('Include all accessories (if available)'), findsOneWidget);
      expect(find.text('Submit to AI'), findsOneWidget);
      expect(find.text('Add at least 2 photos to continue'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('adding photos from the gallery fills the grid and Submit to AI opens Item Details',
        (tester) async {
      final harness = await openSell(tester);

      source.next = _photos(1);
      await tester.tap(find.widgetWithText(InkWell, 'Add Photos').first);
      await harness.settle();
      await tester.tap(find.text('Choose from gallery'));
      await harness.settle();
      expect(find.text('1/10'), findsOneWidget);
      expect(find.text('Add at least 2 photos to continue'), findsOneWidget);
      await tester.tap(find.text('Submit to AI'));
      await harness.settle();
      verifyNever(() => repository.submitDraft(any()));

      source.next = _photos(1);
      await tester.tap(find.widgetWithText(InkWell, 'Add').first);
      await harness.settle();
      await tester.tap(find.text('Choose from gallery'));
      await harness.settle();

      expect(find.text('2/10'), findsOneWidget);
      expect(find.text('MAIN'), findsOneWidget);
      expect(find.text('Add at least 2 photos to continue'), findsNothing);
      await tester.tap(find.text('Submit to AI'));
      await harness.settle();
      expect(find.byType(ItemDetailsScreen), findsOneWidget);
      expect(find.text('Fill in the details'), findsOneWidget);

      await tester.tap(find.byType(SquareBackButton));
      await harness.settle();
      await tester.tap(find.bySemanticsLabel('Remove photo 1'));
      await harness.settle();
      expect(find.text('1/10'), findsOneWidget);
      expect(find.text('Add at least 2 photos to continue'), findsOneWidget);
      verify(() => repository.deleteImage('listing-1', 'image-0')).called(1);
      await harness.dispose();
    });

    testWidgets('an unverified seller is not blocked until the listing is submitted', (
      tester,
    ) async {
      final harness = await openSell(tester, aadhaarVerified: false);
      expect(find.byType(CreateListingScreen), findsOneWidget);
      when(() => repository.submitDraft(any())).thenThrow(const ApiError(
        type: ApiErrorType.business,
        message: 'x',
        code: 'AADHAAR_VERIFICATION_REQUIRED',
        statusCode: 403,
      ));

      source.next = _photos(2);
      await tester.tap(find.widgetWithText(InkWell, 'Add Photos').first);
      await harness.settle();
      await tester.tap(find.text('Choose from gallery'));
      await harness.settle();
      expect(find.text('2/10'), findsOneWidget);

      await tester.tap(find.text('Submit to AI'));
      await harness.settle();
      expect(find.byType(AadhaarScreen), findsOneWidget);

      await tester.tap(find.text('Not now'));
      await harness.settle();
      expect(find.byType(CreateListingScreen), findsOneWidget);
      expect(find.text('2/10'), findsOneWidget, reason: 'the photos are kept');
      await harness.dispose();
    });

    testWidgets('after verifying Aadhaar the seller returns to the listing and it is submitted', (
      tester,
    ) async {
      final harness = await openSell(tester, aadhaarVerified: false);
      var verified = false;
      when(() => repository.submitDraft(any())).thenAnswer((_) async {
        if (!verified) {
          throw const ApiError(
            type: ApiErrorType.business,
            message: 'x',
            code: 'AADHAAR_VERIFICATION_REQUIRED',
            statusCode: 403,
          );
        }
      });
      source.next = _photos(2);
      await tester.tap(find.widgetWithText(InkWell, 'Add Photos').first);
      await harness.settle();
      await tester.tap(find.text('Choose from gallery'));
      await harness.settle();
      await tester.tap(find.text('Submit to AI'));
      await harness.settle();
      expect(find.byType(AadhaarScreen), findsOneWidget);

      verified = true;
      harness.container.read(sessionControllerProvider.notifier).signedIn(
            const AuthResult(
              session: AuthSession(accessToken: 'a', refreshToken: 'r', userId: 'user-1'),
              status: AccountStatus.active,
              aadhaarVerified: true,
            ),
          );
      await harness.settle();
      await harness.settle();

      expect(find.byType(CreateListingScreen, skipOffstage: false), findsOneWidget);
      expect(find.text('2/10', skipOffstage: false), findsOneWidget);
      expect(find.byType(ItemDetailsScreen), findsOneWidget);
      verify(() => repository.submitDraft('listing-1')).called(2);
      await harness.dispose();
    });

    testWidgets('a denied camera explains that access is needed', (tester) async {
      source.pickError = const PhotoAccessDeniedException(PhotoSourceKind.camera);

      final harness = await openSell(tester);

      expect(find.text('Camera access required to capture photos'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a failed upload offers a retry on the tile', (tester) async {
      when(() => repository.uploadBytes(any(), any(), any())).thenThrow(
        const ApiError(type: ApiErrorType.network, message: 'x', code: 'ERROR_PHOTO_UPLOAD_FAILED'),
      );
      source.next = _photos(1);

      final harness = await openSell(tester);

      expect(find.byTooltip('Retry photo 1'), findsOneWidget);
      when(() => repository.uploadBytes(any(), any(), any())).thenAnswer((_) async {});
      await tester.tap(find.byTooltip('Retry photo 1'));
      await harness.settle();
      expect(find.byTooltip('Retry photo 1'), findsNothing);
      expect(find.text('MAIN'), findsOneWidget, reason: 'retry must not remove the photo');
      verify(() => repository.attachImage('listing-1', any())).called(1);
      verifyNever(() => repository.deleteImage(any(), any()));
      await harness.dispose();
    });

    testWidgets('Back returns to Home', (tester) async {
      final harness = await openSell(tester);

      await tester.tap(find.bySemanticsLabel('Back'));
      await harness.settle();

      expect(find.text('Featured Deals Near You'), findsOneWidget);
      await harness.dispose();
    });
  });

  test('Sell is for signed-in, fully registered users only', () {
    expect(
      redirectFor(
          session: const AsyncData<SessionState>(Unauthenticated()), location: RouteNames.sell),
      RouteNames.signIn,
    );
    expect(
      redirectFor(
        session: const AsyncData<SessionState>(
          Authenticated(status: AccountStatus.active, aadhaarVerified: true),
        ),
        location: RouteNames.sell,
      ),
      isNull,
    );
    expect(
      redirectFor(
        session: const AsyncData<SessionState>(
          Authenticated(status: AccountStatus.emailVerificationPending, aadhaarVerified: false),
        ),
        location: RouteNames.sell,
      ),
      isNot(isNull),
    );
  });
}
