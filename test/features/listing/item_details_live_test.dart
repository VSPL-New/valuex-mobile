import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/app_router.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/home/domain/entities/home_location.dart';
import 'package:valuex_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:valuex_mobile/features/listing/data/listing_repository.dart';
import 'package:valuex_mobile/features/listing/data/photo_source.dart';
import 'package:valuex_mobile/features/listing/domain/category.dart';
import 'package:valuex_mobile/features/listing/domain/existing_listing.dart';
import 'package:valuex_mobile/features/listing/domain/listing_details.dart';
import 'package:valuex_mobile/features/listing/domain/listing_photo.dart';
import 'package:valuex_mobile/features/listing/domain/listing_schema.dart';
import 'package:valuex_mobile/features/listing/domain/live_photo.dart';
import 'package:valuex_mobile/features/listing/presentation/item_details_screen.dart';
import 'package:valuex_mobile/features/listing/presentation/providers/item_details_controller.dart';
import 'package:valuex_mobile/features/listing/presentation/providers/live_photos_controller.dart';
import 'package:valuex_mobile/features/listing/presentation/widgets/remoderation_sheet.dart';
import 'package:valuex_mobile/features/listing/presentation/widgets/sell_step_header.dart';
import 'package:valuex_mobile/features/notifications/data/notifications_repository.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/app_harness.dart';
import '../../helpers/fonts.dart';
import 'listing_fixtures.dart';

class _MockRepository extends Mock implements ListingRepository {}

class _MockNotifications extends Mock implements NotificationsRepository {}

class _FakeLocation extends HomeLocationController {
  final HomeLocationState location;

  _FakeLocation([this.location = const LocationNeeded(LocationNeed.notAsked)]);

  @override
  Future<HomeLocationState> build() async => location;
}

class _FakeDraft extends Fake implements ListingDetailsDraft {}

class _FakeSchema extends Fake implements ListingSchema {}

class _FakePhotoSource implements PhotoSource {
  List<PickedPhoto> next = [];
  Object? pickError;
  PhotoInspection? inspection =
      const PhotoInspection(contentType: 'image/png', width: 800, height: 600);
  final List<int> limits = [];

  @override
  Future<List<PickedPhoto>> pick(PhotoSourceKind kind, {required int limit}) async {
    limits.add(limit);
    if (pickError != null) throw pickError!;
    final result = next;
    next = [];
    return result;
  }

  @override
  Future<PhotoInspection?> inspect(Uint8List bytes) async => inspection;
}

/// A real 1x1 PNG, so Image.memory can decode it in widget tests.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

const _confirmation = ApiError(
  type: ApiErrorType.business,
  message: 'review',
  code: 'ERROR_REMODERATION_CONFIRMATION_REQUIRED',
  statusCode: 409,
  details: {'reasons': 'PRICE_CHANGE_TOO_HIGH,PHOTOS_ADDED'},
);

ExistingListing _existing({String status = 'PUBLISHED', int photos = 2}) => ExistingListing(
      listingId: 'l1',
      status: status,
      draft: complete.copyWith(locationArea: 'Baner'),
      category: const CategoryRef(
        code: 'CAT-1',
        name: 'Android Phones',
        path: [
          CategoryPathItem(code: 'L1-M', name: 'Mobiles & Tablets', level: 1),
          CategoryPathItem(code: 'L2-S', name: 'Smartphones', level: 2),
          CategoryPathItem(code: 'CAT-1', name: 'Android Phones', level: 3),
        ],
      ),
      city: 'Pune',
      images: [
        for (var i = 1; i <= photos; i++)
          ListingImageRef(imageId: 'i$i', mediaId: 'm$i', sortOrder: i - 1),
      ],
    );

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeDraft());
    registerFallbackValue(_FakeSchema());
    registerFallbackValue(Uint8List(0));
    loadBrandFonts();
  });

  group('live photos state', () {
    test('the main photo stays, and so do the last two', () {
      const photo = LivePhoto(localId: 'a', imageId: 'i1', mediaId: 'm1');
      const three = LivePhotosState(photos: [photo, photo, photo]);
      const two = LivePhotosState(photos: [photo, photo]);

      expect(three.canRemove(0), isFalse);
      expect(three.canRemove(1), isTrue);
      expect(three.canRemove(2), isTrue);
      expect(two.canRemove(1), isFalse);
      expect(three.hasEnoughPhotos, isTrue);
      expect(const LivePhotosState(photos: [photo]).hasEnoughPhotos, isFalse);
    });

    test('only uploaded new photos count as added, and a retry is for failures that can succeed',
        () {
      final state = LivePhotosState(photos: [
        const LivePhoto(localId: 'a', imageId: 'i1', mediaId: 'm1'),
        LivePhoto(localId: 'n1', mediaId: 'm9', bytes: _png),
        LivePhoto(localId: 'n2', bytes: _png, status: PhotoStatus.uploading),
      ]);

      expect(state.addedMediaIds, ['m9']);
      expect(state.hasPending, isTrue);
      expect(state.remaining, 7);
      expect(LivePhoto(localId: 'x', bytes: _png, status: PhotoStatus.failed).canRetry, isTrue);
      expect(
        LivePhoto(
          localId: 'x',
          bytes: _png,
          status: PhotoStatus.failed,
          errorCode: 'ERROR_INVALID_PHOTO',
        ).canRetry,
        isFalse,
      );
    });
  });

  group('remoderation reasons', () {
    test('the 409 detail is read in the order they are shown, ignoring what is unknown', () {
      expect(
        parseRemoderationReasons('PHOTOS_ADDED, PRICE_CHANGE_TOO_HIGH,SOMETHING_NEW'),
        ['PRICE_CHANGE_TOO_HIGH', 'PHOTOS_ADDED'],
      );
      expect(parseRemoderationReasons(null), isEmpty);
      expect(parseRemoderationReasons(''), isEmpty);
    });
  });

  group('ItemDetailsScreen on a live listing', () {
    late _MockRepository repository;
    late _FakePhotoSource source;
    late AppHarness harness;

    void stubRepository() {
      repository = _MockRepository();
      source = _FakePhotoSource();
      when(() => repository.listingSchema(any())).thenAnswer((_) async => phoneSchema);
      when(() => repository.photoUrl(any())).thenAnswer((_) async => '');
      when(() => repository.editLiveListing(
            any(),
            any(),
            any(),
            city: any(named: 'city'),
            addMediaIds: any(named: 'addMediaIds'),
            removeImageIds: any(named: 'removeImageIds'),
            confirmRemoderation: any(named: 'confirmRemoderation'),
          )).thenAnswer((_) async {});
      when(() => repository.requestUpload(
                listingId: any(named: 'listingId'),
                fileName: any(named: 'fileName'),
                contentType: any(named: 'contentType'),
                sizeBytes: any(named: 'sizeBytes'),
              ))
          .thenAnswer((_) async => const UploadTicket(mediaId: 'm-new', uploadUrl: 'https://s3/x'));
      when(() => repository.uploadBytes(any(), any(), any())).thenAnswer((_) async {});
      when(() => repository.completeUpload(
            mediaId: any(named: 'mediaId'),
            contentType: any(named: 'contentType'),
            sizeBytes: any(named: 'sizeBytes'),
            width: any(named: 'width'),
            height: any(named: 'height'),
          )).thenAnswer((_) async {});
    }

    Future<void> open(WidgetTester tester,
        {ExistingListing? existing, HomeLocationState? location}) async {
      final notifications = _MockNotifications();
      when(notifications.unreadCount).thenAnswer((_) async => 0);
      harness = AppHarness(tester, extraOverrides: [
        notificationsRepositoryProvider.overrideWithValue(notifications),
        listingRepositoryProvider.overrideWithValue(repository),
        photoSourceProvider.overrideWithValue(source),
        homeLocationControllerProvider.overrideWith(
          () => _FakeLocation(location ?? const LocationNeeded(LocationNeed.notAsked)),
        ),
      ])
        ..signedInAs(AccountStatus.active, aadhaarVerified: true);
      await harness.launch(location: RouteNames.home);
      // Tall screen so the whole form is built (the list builds lazily).
      tester.view.physicalSize = const Size(1080, 6400);
      final listing = existing ?? _existing();
      harness.container.read(appRouterProvider).push(
            RouteNames.sellDetails,
            extra: ItemDetailsArgs(listingId: 'l1', existing: listing),
          );
      await harness.settle();
    }

    final saveButton = find.text('Save changes');
    Finder removeButton(int position) => find.bySemanticsLabel('Remove photo $position');

    bool saveEnabled(WidgetTester tester) {
      final button = tester.widget<InkWell>(
        find.ancestor(of: saveButton, matching: find.byType(InkWell)).first,
      );
      return button.onTap != null;
    }

    setUp(stubRepository);

    testWidgets('opens as an edit page: no steps, the stored details, a locked category',
        (tester) async {
      await open(tester);

      expect(find.byType(ItemDetailsScreen), findsOneWidget);
      expect(find.text('Edit Listing'), findsOneWidget);
      expect(find.text('Your listing stays live unless a change needs a review'), findsOneWidget);
      expect(tester.widget<SellStepHeader>(find.byType(SellStepHeader)).showProgress, isFalse);
      expect(find.widgetWithText(TextField, 'Sony headphones'), findsOneWidget);
      expect(find.text('Android Phones'), findsOneWidget);
      expect(find.text("The category can't be changed after your listing has gone live"),
          findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.text('Change'), findsNothing);
      expect(find.text('Choose Listing Plan'), findsNothing);
      expect(saveButton, findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a draft still opens as a step, without the photo section', (tester) async {
      await open(tester, existing: _existing(status: 'DRAFT'));

      expect(find.text('Edit Listing'), findsNothing);
      expect(find.text('Item Details'), findsOneWidget);
      expect(find.text('PHOTOS'), findsNothing);
      expect(find.text('Save changes'), findsNothing);
      await harness.dispose();
    });

    testWidgets('shows the photos with the main one marked and the count', (tester) async {
      await open(tester, existing: _existing(photos: 3));

      expect(find.text('PHOTOS'), findsOneWidget);
      expect(find.text('3 of 10'), findsOneWidget);
      expect(find.text('MAIN'), findsOneWidget);
      expect(find.text('Added photos are checked before they go live'), findsOneWidget);
      expect(removeButton(1), findsNothing);
      expect(removeButton(2), findsOneWidget);
      expect(removeButton(3), findsOneWidget);
      expect(find.bySemanticsLabel('Add photos'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('with two photos none can be removed, and the hint says why', (tester) async {
      await open(tester);

      expect(removeButton(2), findsNothing);
      expect(removeButton(1), findsNothing);
      await harness.dispose();
    });

    testWidgets('a photo is loaded from a short-lived link of its media asset', (tester) async {
      await open(tester);

      verify(() => repository.photoUrl('m1')).called(1);
      verify(() => repository.photoUrl('m2')).called(1);
      await harness.dispose();
    });

    testWidgets('removing a photo is sent with the save, and the last two stay', (tester) async {
      await open(tester, existing: _existing(photos: 3));

      await tester.tap(removeButton(3));
      await harness.settle();
      expect(find.text('2 of 10'), findsOneWidget);
      expect(removeButton(2), findsNothing);
      verifyNever(() => repository.editLiveListing(any(), any(), any(),
          city: any(named: 'city'),
          addMediaIds: any(named: 'addMediaIds'),
          removeImageIds: any(named: 'removeImageIds'),
          confirmRemoderation: any(named: 'confirmRemoderation')));

      await tester.tap(saveButton);
      await harness.settle();

      verify(() => repository.editLiveListing('l1', any(), any(),
          city: 'Pune',
          addMediaIds: const <String>[],
          removeImageIds: const ['i3'],
          confirmRemoderation: false)).called(1);
      await harness.dispose();
    });

    testWidgets('a minor edit is saved at once, the page closes and says so', (tester) async {
      await open(tester);

      await tester.tap(saveButton);
      await harness.settle();

      final draft = verify(() => repository.editLiveListing('l1', captureAny(), any(),
          city: 'Pune',
          addMediaIds: const <String>[],
          removeImageIds: const <String>[],
          confirmRemoderation: false)).captured.single as ListingDetailsDraft;
      expect(draft.locationArea, 'Baner');
      expect(find.byType(ItemDetailsScreen), findsNothing);
      expect(find.text('Changes saved'), findsOneWidget);
      await harness.dispose();
    });

    for (final area in ['Kothrud', null]) {
      testWidgets('live edit uses the selected area $area, not the stored area', (tester) async {
        await open(tester, location: LocationKnown(HomeLocation(city: 'Pune', area: area)));
        await tester.tap(saveButton);
        await harness.settle();

        final draft = verify(() => repository.editLiveListing('l1', captureAny(), any(),
            city: 'Pune',
            addMediaIds: const <String>[],
            removeImageIds: const <String>[],
            confirmRemoderation: false)).captured.single as ListingDetailsDraft;
        expect(draft.toJson(phoneSchema)['locationArea'], area ?? '');
        await harness.dispose();
      });
    }

    testWidgets('a major edit asks first with every reason, and nothing is saved until confirmed',
        (tester) async {
      when(() => repository.editLiveListing(any(), any(), any(),
          city: any(named: 'city'),
          addMediaIds: any(named: 'addMediaIds'),
          removeImageIds: any(named: 'removeImageIds'),
          confirmRemoderation: false)).thenThrow(_confirmation);
      await open(tester);

      await tester.tap(saveButton);
      await harness.settle();

      expect(find.text('This change needs a review'), findsOneWidget);
      expect(find.text('The price is more than 20% away from the approved price'), findsOneWidget);
      expect(find.text('You added photos'), findsOneWidget);
      expect(find.text('The new text needs a look from our team'), findsNothing);
      expect(find.text('Your plan keeps running meanwhile.'), findsOneWidget);
      expect(find.byType(ItemDetailsScreen), findsOneWidget);
      verifyNever(() => repository.editLiveListing(any(), any(), any(),
          city: any(named: 'city'),
          addMediaIds: any(named: 'addMediaIds'),
          removeImageIds: any(named: 'removeImageIds'),
          confirmRemoderation: true));
      await harness.dispose();
    });

    testWidgets('Keep editing leaves the page as it was and sends nothing more', (tester) async {
      when(() => repository.editLiveListing(any(), any(), any(),
          city: any(named: 'city'),
          addMediaIds: any(named: 'addMediaIds'),
          removeImageIds: any(named: 'removeImageIds'),
          confirmRemoderation: false)).thenThrow(_confirmation);
      await open(tester);
      await tester.tap(saveButton);
      await harness.settle();

      await tester.tap(find.text('Keep editing'));
      await harness.settle();

      expect(find.text('This change needs a review'), findsNothing);
      expect(find.byType(ItemDetailsScreen), findsOneWidget);
      verify(() => repository.editLiveListing(any(), any(), any(),
          city: any(named: 'city'),
          addMediaIds: any(named: 'addMediaIds'),
          removeImageIds: any(named: 'removeImageIds'),
          confirmRemoderation: false)).called(1);
      await harness.dispose();
    });

    testWidgets(
        'confirming sends the same edit again with the confirmation and says it went to review',
        (tester) async {
      when(() => repository.editLiveListing(any(), any(), any(),
          city: any(named: 'city'),
          addMediaIds: any(named: 'addMediaIds'),
          removeImageIds: any(named: 'removeImageIds'),
          confirmRemoderation: false)).thenThrow(_confirmation);
      await open(tester);
      await tester.tap(saveButton);
      await harness.settle();

      await tester.tap(find.text('Save and send for review'));
      await harness.settle();

      verify(() => repository.editLiveListing('l1', any(), any(),
          city: 'Pune',
          addMediaIds: const <String>[],
          removeImageIds: const <String>[],
          confirmRemoderation: true)).called(1);
      expect(find.byType(ItemDetailsScreen), findsNothing);
      expect(find.textContaining('Sent for review'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('any other refusal stays on the page and says why', (tester) async {
      when(() => repository.editLiveListing(any(), any(), any(),
              city: any(named: 'city'),
              addMediaIds: any(named: 'addMediaIds'),
              removeImageIds: any(named: 'removeImageIds'),
              confirmRemoderation: any(named: 'confirmRemoderation')))
          .thenThrow(const ApiError(
              type: ApiErrorType.business, message: 'x', code: 'ERROR_LISTING_NOT_EDITABLE'));
      await open(tester);

      await tester.tap(saveButton);
      await harness.settle();

      expect(find.byType(ItemDetailsScreen), findsOneWidget);
      expect(find.text('This listing can no longer be edited'), findsOneWidget);
      expect(find.text('This change needs a review'), findsNothing);
      await harness.dispose();
    });

    testWidgets('an added photo is uploaded at once and sent with the save', (tester) async {
      await open(tester);
      source.next = [PickedPhoto(name: 'new.png', bytes: _png)];

      await tester.tap(find.bySemanticsLabel('Add photos'));
      await harness.settle();
      await tester.tap(find.text('Choose from gallery'));
      await harness.settle();

      expect(source.limits, [8]);
      expect(find.text('3 of 10'), findsOneWidget);
      verify(() => repository.uploadBytes('https://s3/x', any(), 'image/png')).called(1);
      verify(() => repository.completeUpload(
          mediaId: 'm-new',
          contentType: 'image/png',
          sizeBytes: _png.length,
          width: 800,
          height: 600));
      verifyNever(() => repository.attachImage(any(), any()));

      await tester.tap(saveButton);
      await harness.settle();

      verify(() => repository.editLiveListing('l1', any(), any(),
          city: 'Pune',
          addMediaIds: const ['m-new'],
          removeImageIds: const <String>[],
          confirmRemoderation: false)).called(1);
      await harness.dispose();
    });

    testWidgets('a photo that fails to upload blocks the save until it is removed', (tester) async {
      when(() => repository.uploadBytes(any(), any(), any())).thenThrow(const ApiError(
          type: ApiErrorType.network, message: 'offline', code: 'ERROR_PHOTO_UPLOAD_FAILED'));
      await open(tester);
      source.next = [PickedPhoto(name: 'new.png', bytes: _png)];
      await tester.tap(find.bySemanticsLabel('Add photos'));
      await harness.settle();
      await tester.tap(find.text('Choose from gallery'));
      await harness.settle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(saveEnabled(tester), isFalse);

      await tester.tap(removeButton(3));
      await harness.settle();

      expect(find.text('2 of 10'), findsOneWidget);
      expect(saveEnabled(tester), isTrue);
      await harness.dispose();
    });

    Future<void> pickFromGallery(WidgetTester tester) async {
      await tester.tap(find.bySemanticsLabel('Add photos'));
      await harness.settle();
      await tester.tap(find.text('Choose from gallery'));
      await harness.settle();
    }

    testWidgets('a failed upload can be tried again and then be saved', (tester) async {
      var attempts = 0;
      when(() => repository.uploadBytes(any(), any(), any())).thenAnswer((_) async {
        if (attempts++ == 0) {
          throw const ApiError(
            type: ApiErrorType.network,
            message: 'offline',
            code: 'ERROR_PHOTO_UPLOAD_FAILED',
          );
        }
      });
      await open(tester);
      source.next = [PickedPhoto(name: 'new.png', bytes: _png)];
      await pickFromGallery(tester);
      expect(saveEnabled(tester), isFalse);

      await tester.tap(find.byIcon(Icons.refresh));
      await harness.settle();

      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(saveEnabled(tester), isTrue);
      expect(attempts, 2);
      await harness.dispose();
    });

    testWidgets('a photo the app cannot read is dropped with a message', (tester) async {
      await open(tester);
      source
        ..next = [PickedPhoto(name: 'x.gif', bytes: _png)]
        ..inspection = null;

      await pickFromGallery(tester);

      expect(find.text('Photo quality too low or invalid format'), findsOneWidget);
      expect(find.text('2 of 10'), findsOneWidget);
      verifyNever(() => repository.uploadBytes(any(), any(), any()));
      await harness.dispose();
    });

    testWidgets('a photo over 10 MB is dropped with a message', (tester) async {
      await open(tester);
      source.next = [PickedPhoto(name: 'big.png', bytes: Uint8List(10 * 1024 * 1024 + 1))];

      await pickFromGallery(tester);

      expect(find.text('Photo exceeds 10MB limit'), findsOneWidget);
      expect(find.text('2 of 10'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('more photos than there is room for are cut at ten, with a message',
        (tester) async {
      await open(tester, existing: _existing(photos: 9));
      source.next = [
        PickedPhoto(name: 'a.png', bytes: _png),
        PickedPhoto(name: 'b.png', bytes: _png),
      ];

      await pickFromGallery(tester);

      expect(find.text('10 of 10'), findsOneWidget);
      expect(find.text('Maximum 10 photos allowed'), findsOneWidget);
      verify(() => repository.uploadBytes(any(), any(), any())).called(1);
      await harness.dispose();
    });

    testWidgets('a rejected photo says so and is not added', (tester) async {
      await open(tester);
      source.pickError = const PhotoAccessDeniedException(PhotoSourceKind.gallery);

      await tester.tap(find.bySemanticsLabel('Add photos'));
      await harness.settle();
      await tester.tap(find.text('Choose from gallery'));
      await harness.settle();

      expect(find.text('Photo library access required to choose photos'), findsOneWidget);
      expect(find.text('2 of 10'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('at ten photos there is nothing more to add', (tester) async {
      await open(tester, existing: _existing(photos: 10));

      expect(find.text('10 of 10'), findsOneWidget);
      expect(find.bySemanticsLabel('Add photos'), findsNothing);
      await harness.dispose();
    });

    testWidgets('the page passes the tap target and label guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester, existing: _existing(photos: 3));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrast));
      handle.dispose();
      await harness.dispose();
    });

    for (final locale in const [Locale('en'), Locale('hi')]) {
      testWidgets('on a 320 x 640 screen at 200% text in ${locale.languageCode} nothing overflows',
          (tester) async {
        await open(tester, existing: _existing(photos: 3));
        tester.view.physicalSize = const Size(640, 1280);
        tester.view.devicePixelRatio = 2;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        tester.platformDispatcher.localesTestValue = [locale];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        await harness.settle();

        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
        await harness.settle();
        expect(tester.takeException(), isNull);
        await harness.dispose();
      });
    }
  });
}
