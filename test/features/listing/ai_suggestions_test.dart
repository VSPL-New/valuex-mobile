import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/app_router.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/home/domain/entities/home_location.dart';
import 'package:valuex_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:valuex_mobile/features/listing/data/listing_repository.dart';
import 'package:valuex_mobile/features/listing/data/photo_source.dart';
import 'package:valuex_mobile/features/listing/domain/category.dart';
import 'package:valuex_mobile/features/listing/domain/listing_details.dart';
import 'package:valuex_mobile/features/listing/domain/listing_photo.dart';
import 'package:valuex_mobile/features/listing/domain/listing_schema.dart';
import 'package:valuex_mobile/features/listing/domain/restricted_check.dart';
import 'package:valuex_mobile/features/listing/presentation/item_details_screen.dart';
import 'package:valuex_mobile/features/listing/presentation/listing_error_messages.dart';
import 'package:valuex_mobile/features/listing/presentation/providers/create_listing_controller.dart';
import 'package:valuex_mobile/features/listing/presentation/providers/item_details_controller.dart';
import 'package:valuex_mobile/features/notifications/data/notifications_repository.dart';
import 'package:valuex_mobile/l10n/app_localizations_en.dart';
import 'package:valuex_mobile/l10n/app_localizations_hi.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_secure_storage.dart';
import '../../helpers/fonts.dart';
import 'listing_fixtures.dart';

class _MockRepository extends Mock implements ListingRepository {}

class _MockNotifications extends Mock implements NotificationsRepository {}

class _FakeDraft extends Fake implements ListingDetailsDraft {}

class _FakeSchema extends Fake implements ListingSchema {}

class _FakeLocation extends HomeLocationController {
  @override
  Future<HomeLocationState> build() async =>
      const LocationKnown(HomeLocation(city: 'Pune', area: 'Baner', state: 'MH'));
}

final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _FakePhotoSource implements PhotoSource {
  List<PickedPhoto> next = [];

  @override
  Future<List<PickedPhoto>> pick(PhotoSourceKind kind, {required int limit}) async {
    final result = next;
    next = [];
    return result;
  }

  @override
  Future<PhotoInspection?> inspect(Uint8List bytes) async =>
      const PhotoInspection(contentType: 'image/png', width: 800, height: 600);
}

const _unavailableText =
    'AI Service is not available at this moment or your usage quota has exhausted, '
    'please do manual entry';

Map<String, dynamic> _answer({
  bool fallback = false,
  String? suggestionId = 's1',
  List<Map<String, dynamic>> categories = const [
    {'categoryCode': 'CAT-1', 'categoryPath': 'A > B > C', 'confidence': 0.9},
    {'categoryCode': 'CAT-2', 'categoryPath': 'A > B > D', 'confidence': 0.4},
  ],
  List<Map<String, dynamic>> attributes = const [
    {'key': 'brand', 'value': 'Sony', 'confidence': 0.95, 'verify': false},
    {'key': 'storage_gb', 'value': '128_GB', 'confidence': 0.7, 'verify': true},
    {'key': 'battery_health_pct', 'value': 87.5, 'confidence': 0.65, 'verify': true},
    {'key': 'pincode', 'value': null, 'confidence': 0.9, 'verify': false},
  ],
}) =>
    {
      'suggestionId': suggestionId,
      'status': fallback ? 'FAILED' : 'COMPLETED',
      'fallback': fallback,
      'errorCode': fallback ? 'ERROR_AI_SERVICE_UNAVAILABLE' : null,
      'message': fallback ? _unavailableText : null,
      'categorySuggestions': fallback ? null : categories,
      'titleSuggestion': fallback ? null : 'Sony WH-1000XM4',
      'conditionSuggestion': fallback ? null : 'LIKE_NEW',
      'conditionNotesSuggestion': fallback ? null : 'Light scratches on the band',
      'descriptionSuggestion': fallback ? null : 'Over-ear noise cancelling headphones',
      'attributeSuggestions': fallback ? null : attributes,
      'warnings': <String>[],
      'confidence': 0.88,
    };

AiSuggestion _parsed() => AiSuggestion.fromJson(_answer())!;

PickedPhoto _photo(int i) => PickedPhoto(name: 'p$i.png', bytes: _png);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeDraft());
    registerFallbackValue(_FakeSchema());
    registerFallbackValue(CategoryScope.all);
    registerFallbackValue(Uint8List(0));
    loadBrandFonts();
  });

  group('AiSuggestion.fromJson', () {
    test('reads the top category, the texts, the condition and the attribute values', () {
      final suggestion = _parsed();

      expect(suggestion.id, 's1');
      expect(suggestion.categoryCode, 'CAT-1');
      expect(suggestion.title, 'Sony WH-1000XM4');
      expect(suggestion.condition, ListingCondition.likeNew);
      expect(suggestion.conditionNotes, 'Light scratches on the band');
      expect(suggestion.description, 'Over-ear noise cancelling headphones');
      expect(suggestion.attributes,
          {'brand': 'Sony', 'storage_gb': '128_GB', 'battery_health_pct': 87.5});
      expect(suggestion.verifyKeys, {'storage_gb', 'battery_health_pct'});
      expect(suggestion.isEmpty, isFalse);
    });

    test('the degraded answer and an answer without an id carry no suggestion', () {
      expect(AiSuggestion.fromJson(_answer(fallback: true)), isNull);
      expect(AiSuggestion.fromJson(_answer(suggestionId: null)), isNull);
    });

    test('an answer that recognised nothing is empty', () {
      final suggestion = AiSuggestion.fromJson({
        'suggestionId': 's2',
        'fallback': false,
        'categorySuggestions': <Object>[],
        'attributeSuggestions': <Object>[],
        'warnings': ['WARNING_UNABLE_TO_IDENTIFY'],
      })!;

      expect(suggestion.categoryCode, isNull);
      expect(suggestion.condition, isNull);
      expect(suggestion.isEmpty, isTrue);
    });

    test('the page starts with every suggested value, clipped to the limits', () {
      final draft = _parsed().asDraft;

      expect(draft.title, 'Sony WH-1000XM4');
      expect(draft.conditionNotes, 'Light scratches on the band');
      expect(draft.attributes['brand'], 'Sony');
      final long = AiSuggestion(id: 'x', conditionNotes: 'n' * 1500).asDraft;
      expect(long.conditionNotes, hasLength(ListingDetailsRules.maxConditionNotes));
    });
  });

  group('feedback', () {
    test('covers the condition notes and each AI attribute with its key', () {
      final suggestion = _parsed();
      final current = suggestion.asDraft.copyWith(
        conditionNotes: 'Scratches',
        attributes: {'brand': 'Sony', 'storage_gb': '64_GB'},
      );

      final feedback = {
        for (final item in suggestionFeedback(suggestion, current))
          '${item.field}:${item.attributeKey}': item,
      };

      expect(feedback['CONDITION_NOTES:null']!.action, SuggestionAction.edited);
      expect(feedback['ATTRIBUTE:brand']!.action, SuggestionAction.accepted);
      expect(feedback['ATTRIBUTE:storage_gb']!.action, SuggestionAction.edited);
      expect(feedback['ATTRIBUTE:storage_gb']!.originalValue, '128_GB');
      expect(feedback['ATTRIBUTE:storage_gb']!.finalValue, '64_GB');
      expect(feedback['ATTRIBUTE:battery_health_pct']!.action, SuggestionAction.rejected);
      expect(feedback['ATTRIBUTE:battery_health_pct']!.originalValue, '87.5');
      expect(feedback['ATTRIBUTE:brand']!.toJson(), {
        'field': 'ATTRIBUTE',
        'attributeKey': 'brand',
        'action': 'ACCEPTED',
        'originalValue': 'Sony',
        'finalValue': 'Sony',
      });
      expect(feedback['TITLE:null']!.toJson().containsKey('attributeKey'), isFalse);
    });

    test('list and object values are compared as JSON, numbers typed by the seller as text', () {
      const suggestion = AiSuggestion(id: 'x', attributes: {
        'tags': ['a', 'b'],
        'size': {'l': 1},
        'age': 5,
      });
      const current = ListingDetailsDraft(attributes: {
        'tags': ['a', 'b'],
        'size': {'l': 2},
        'age': '5',
      });

      final byKey = {
        for (final item in suggestionFeedback(suggestion, current)) item.attributeKey: item.action,
      };

      expect(byKey, {
        'tags': SuggestionAction.accepted,
        'size': SuggestionAction.edited,
        'age': SuggestionAction.accepted,
      });
    });
  });

  group('repository', () {
    late FakeHttpAdapter api;
    late ListingRepository repository;

    void useAnswer(Map<String, dynamic> answer) {
      api = FakeHttpAdapter((_) async => FakeHttpAdapter.ok(answer));
      repository = ListingRepository(
        ApiClient(FakeSecureStorage(accessToken: 'a', refreshToken: 'r'), testConfig, adapter: api),
        Dio(),
      );
    }

    test('posts to the listing with a 25 s receive timeout and parses a suggestion', () async {
      useAnswer(_answer());

      final suggestion = await repository.generateAiSuggestions('l1');

      expect(api.requests.single.method, 'POST');
      expect(api.requests.single.path, '/listings/l1/ai-suggestions');
      expect(api.requests.single.receiveTimeout, const Duration(seconds: 25));
      expect(suggestion!.categoryCode, 'CAT-1');
      expect(suggestion.attributes['brand'], 'Sony');
    });

    test('the degraded answer is null, not an error', () async {
      useAnswer(_answer(fallback: true));

      expect(await repository.generateAiSuggestions('l1'), isNull);
    });

    test('feedback is sent under "feedback" with the attribute key', () async {
      useAnswer(_answer());

      await repository.sendSuggestionFeedback('l1', 's1', [
        const SuggestionFeedback(
          field: 'ATTRIBUTE',
          attributeKey: 'brand',
          action: SuggestionAction.accepted,
          originalValue: 'Sony',
          finalValue: 'Sony',
        ),
      ]);

      expect(api.requests.single.method, 'PATCH');
      expect(api.requests.single.path, '/listings/l1/ai-suggestions/s1/feedback');
      expect(api.requests.single.data, {
        'feedback': [
          {
            'field': 'ATTRIBUTE',
            'attributeKey': 'brand',
            'action': 'ACCEPTED',
            'originalValue': 'Sony',
            'finalValue': 'Sony',
          },
        ],
      });
    });

    test('a failed call is thrown as an ApiError', () async {
      api = FakeHttpAdapter(
          (_) async => FakeHttpAdapter.error(429, 'AI_SUGGESTION_RATE_LIMITED', 'x'));
      repository = ListingRepository(
        ApiClient(FakeSecureStorage(accessToken: 'a', refreshToken: 'r'), testConfig, adapter: api),
        Dio(),
      );

      expect(
        () => repository.generateAiSuggestions('l1'),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'AI_SUGGESTION_RATE_LIMITED')),
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

    setUp(() async {
      repository = _MockRepository();
      source = _FakePhotoSource();
      var media = 0;
      when(() => repository.createDraft()).thenAnswer((_) async => 'l1');
      when(() => repository.requestUpload(
                listingId: any(named: 'listingId'),
                fileName: any(named: 'fileName'),
                contentType: any(named: 'contentType'),
                sizeBytes: any(named: 'sizeBytes'),
              ))
          .thenAnswer((_) async => UploadTicket(mediaId: 'm${media++}', uploadUrl: 'https://s3/x'));
      when(() => repository.uploadBytes(any(), any(), any())).thenAnswer((_) async {});
      when(() => repository.completeUpload(
            mediaId: any(named: 'mediaId'),
            contentType: any(named: 'contentType'),
            sizeBytes: any(named: 'sizeBytes'),
            width: any(named: 'width'),
            height: any(named: 'height'),
          )).thenAnswer((_) async {});
      when(() => repository.attachImage(any(), any())).thenAnswer((_) async => 'image');
      when(() => repository.submitDraft(any())).thenAnswer((_) async {});
      container = ProviderContainer(overrides: [
        listingRepositoryProvider.overrideWithValue(repository),
        photoSourceProvider.overrideWithValue(source),
      ]);
      container.listen(createListingControllerProvider, (_, __) {});
      source.next = [_photo(0), _photo(1)];
      await controller().addPhotos(PhotoSourceKind.gallery);
    });

    tearDown(() => container.dispose());

    test('a real suggestion comes back with the submit', () async {
      when(() => repository.generateAiSuggestions('l1')).thenAnswer((_) async => _parsed());

      final result = await controller().submit();

      expect(result.outcome, SubmitOutcome.submitted);
      expect(result.suggestion!.categoryCode, 'CAT-1');
      expect(result.aiNotice, isNull);
      expect(state().isBusy, isFalse);
      expect(state().isAnalysing, isFalse);
    });

    test('the degraded answer and a failed call both lead to manual entry', () async {
      when(() => repository.generateAiSuggestions('l1')).thenAnswer((_) async => null);
      final degraded = await controller().submit();
      expect(degraded.outcome, SubmitOutcome.submitted);
      expect(degraded.suggestion, isNull);
      expect(degraded.aiNotice, AiNotice.unavailable);

      when(() => repository.generateAiSuggestions('l1'))
          .thenThrow(const ApiError(type: ApiErrorType.network, message: 'x'));
      final failed = await controller().submit();
      expect(failed.outcome, SubmitOutcome.submitted);
      expect(failed.aiNotice, AiNotice.unavailable);
      expect(state().photos, hasLength(2), reason: 'the photos are kept');
    });

    test('an answer that recognised nothing says so instead of opening an empty AI page', () async {
      when(() => repository.generateAiSuggestions('l1'))
          .thenAnswer((_) async => const AiSuggestion(id: 's2'));

      final result = await controller().submit();

      expect(result.suggestion, isNull);
      expect(result.aiNotice, AiNotice.notRecognised);
    });

    test('while AI works the state is busy and a second submit starts nothing', () async {
      final answer = Completer<AiSuggestion?>();
      when(() => repository.generateAiSuggestions('l1')).thenAnswer((_) => answer.future);

      final first = controller().submit();
      await Future<void>.delayed(Duration.zero);
      expect(state().isAnalysing, isTrue);
      expect(state().isBusy, isTrue);
      expect(state().canSubmit, isFalse);

      final second = await controller().submit();
      expect(second.outcome, SubmitOutcome.failed);

      answer.complete(_parsed());
      await first;
      verify(() => repository.generateAiSuggestions('l1')).called(1);
      verify(() => repository.submitDraft('l1')).called(1);
    });

    test('AI is not asked when the submit itself fails', () async {
      when(() => repository.submitDraft(any())).thenThrow(
        const ApiError(
            type: ApiErrorType.business, message: 'x', code: 'AADHAAR_VERIFICATION_REQUIRED'),
      );

      final result = await controller().submit();

      expect(result.outcome, SubmitOutcome.aadhaarRequired);
      verifyNever(() => repository.generateAiSuggestions(any()));
    });
  });

  group('messages', () {
    test('the unavailable code and text exist in English and Hindi', () {
      final en = AppLocalizationsEn();
      final hi = AppLocalizationsHi();

      expect(listingCodeMessage(en, 'ERROR_AI_SERVICE_UNAVAILABLE'), _unavailableText);
      expect(listingCodeMessage(hi, 'ERROR_AI_SERVICE_UNAVAILABLE'), hi.sellAiUnavailable);
      expect(en.sellAiAnalysing, 'Analysing your photos');
      expect(en.itemPleaseVerify, 'Please verify');
      for (final text in [
        hi.sellAiUnavailable,
        hi.sellAiAnalysing,
        hi.sellAiNotRecognised,
        hi.itemPleaseVerify,
      ]) {
        expect(text, isNotEmpty);
      }
      expect(hi.sellAiAnalysing, isNot(en.sellAiAnalysing));
    });
  });

  group('Sell screen', () {
    late _MockRepository repository;
    late _FakePhotoSource source;

    void stubRepository() {
      repository = _MockRepository();
      source = _FakePhotoSource();
      var media = 0;
      when(() => repository.createDraft()).thenAnswer((_) async => 'l1');
      when(() => repository.requestUpload(
                listingId: any(named: 'listingId'),
                fileName: any(named: 'fileName'),
                contentType: any(named: 'contentType'),
                sizeBytes: any(named: 'sizeBytes'),
              ))
          .thenAnswer((_) async => UploadTicket(mediaId: 'm${media++}', uploadUrl: 'https://s3/x'));
      when(() => repository.uploadBytes(any(), any(), any())).thenAnswer((_) async {});
      when(() => repository.completeUpload(
            mediaId: any(named: 'mediaId'),
            contentType: any(named: 'contentType'),
            sizeBytes: any(named: 'sizeBytes'),
            width: any(named: 'width'),
            height: any(named: 'height'),
          )).thenAnswer((_) async {});
      when(() => repository.attachImage(any(), any())).thenAnswer((_) async => 'image');
      when(() => repository.submitDraft(any())).thenAnswer((_) async {});
      when(() => repository.setCategory(any(), any())).thenAnswer((_) async {});
      when(() => repository.listingSchema(any())).thenAnswer((_) async => phoneSchema);
      when(() => repository.sendSuggestionFeedback(any(), any(), any())).thenAnswer((_) async {});
      when(() => repository.saveDetails(any(), any(), any(), city: any(named: 'city')))
          .thenAnswer((_) async {});
      when(() => repository.sellerPlans()).thenAnswer((_) async => []);
    }

    setUp(stubRepository);

    Future<AppHarness> openSellWithTwoPhotos(WidgetTester tester) async {
      final notifications = _MockNotifications();
      when(notifications.unreadCount).thenAnswer((_) async => 0);
      final harness = AppHarness(tester, extraOverrides: [
        notificationsRepositoryProvider.overrideWithValue(notifications),
        listingRepositoryProvider.overrideWithValue(repository),
        photoSourceProvider.overrideWithValue(source),
        homeLocationControllerProvider.overrideWith(_FakeLocation.new),
      ])
        ..signedInAs(AccountStatus.active, aadhaarVerified: true);
      source.next = [_photo(0), _photo(1)];
      await harness.launch(location: RouteNames.home);
      await tester.tap(find.text('Sell'));
      await harness.settle();
      tester.view.physicalSize = const Size(1080, 6000);
      await harness.settle();
      return harness;
    }

    testWidgets('while AI works it says so, keeps the button off and tolerates a second tap',
        (tester) async {
      final answer = Completer<AiSuggestion?>();
      when(() => repository.generateAiSuggestions(any())).thenAnswer((_) => answer.future);
      final harness = await openSellWithTwoPhotos(tester);

      await tester.tap(find.text('Submit to AI'));
      await harness.settle();

      expect(find.text('Analysing your photos'), findsOneWidget);
      expect(find.text('Add at least 2 photos to continue'), findsNothing);
      expect(find.text('Submit to AI'), findsNothing, reason: 'the button shows a spinner instead');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      verify(() => repository.submitDraft('l1')).called(1);
      verify(() => repository.generateAiSuggestions('l1')).called(1);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      answer.complete(null);
      await harness.settle();
      expect(find.text('Analysing your photos'), findsNothing);
      await harness.dispose();
    });

    testWidgets('when AI is unavailable the message shows and the seller continues by hand',
        (tester) async {
      when(() => repository.generateAiSuggestions(any())).thenAnswer((_) async => null);
      final harness = await openSellWithTwoPhotos(tester);

      await tester.tap(find.text('Submit to AI'));
      await harness.settle();

      expect(find.byType(ItemDetailsScreen), findsOneWidget);
      expect(find.text(_unavailableText), findsOneWidget);
      expect(find.text('Fill in the details'), findsOneWidget);
      expect(find.textContaining('AI filled these'), findsNothing);
      await harness.dispose();
    });

    testWidgets('a failed AI call is treated the same way', (tester) async {
      when(() => repository.generateAiSuggestions(any()))
          .thenThrow(const ApiError(type: ApiErrorType.network, message: 'x'));
      final harness = await openSellWithTwoPhotos(tester);

      await tester.tap(find.text('Submit to AI'));
      await harness.settle();

      expect(find.byType(ItemDetailsScreen), findsOneWidget);
      expect(find.text(_unavailableText), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('an unrecognised item says so and opens an empty page', (tester) async {
      when(() => repository.generateAiSuggestions(any()))
          .thenAnswer((_) async => const AiSuggestion(id: 's2'));
      final harness = await openSellWithTwoPhotos(tester);

      await tester.tap(find.text('Submit to AI'));
      await harness.settle();

      expect(find.byType(ItemDetailsScreen), findsOneWidget);
      expect(find.textContaining('could not recognise the item'), findsOneWidget);
      expect(find.textContaining('AI filled these'), findsNothing);
      await harness.dispose();
    });

    testWidgets('a suggestion opens the prefilled page without any unavailable message',
        (tester) async {
      when(() => repository.generateAiSuggestions(any())).thenAnswer((_) async => _parsed());
      final harness = await openSellWithTwoPhotos(tester);

      await tester.tap(find.text('Submit to AI'));
      await harness.settle();

      expect(find.byType(ItemDetailsScreen), findsOneWidget);
      expect(find.text(_unavailableText), findsNothing);
      expect(find.textContaining('AI filled these'), findsOneWidget);
      verify(() => repository.setCategory('l1', 'CAT-1')).called(1);
      await harness.dispose();
    });
  });

  group('Item Details with a suggestion', () {
    late _MockRepository repository;

    setUp(() {
      repository = _MockRepository();
      when(() => repository.setCategory(any(), any())).thenAnswer((_) async {});
      when(() => repository.listingSchema(any())).thenAnswer((_) async => phoneSchema);
      when(() => repository.saveDetails(any(), any(), any(), city: any(named: 'city')))
          .thenAnswer((_) async {});
      when(() => repository.sendSuggestionFeedback(any(), any(), any())).thenAnswer((_) async {});
      when(() => repository.sellerPlans()).thenAnswer((_) async => []);
      when(() => repository.checkRestrictedItems(any())).thenAnswer(
          (_) async => const RestrictedCheck(checkId: 'c1', result: RestrictedResult.safe));
    });

    Future<AppHarness> open(WidgetTester tester, AiSuggestion suggestion) async {
      final notifications = _MockNotifications();
      when(notifications.unreadCount).thenAnswer((_) async => 0);
      final harness = AppHarness(tester, extraOverrides: [
        notificationsRepositoryProvider.overrideWithValue(notifications),
        listingRepositoryProvider.overrideWithValue(repository),
        homeLocationControllerProvider.overrideWith(_FakeLocation.new),
      ])
        ..signedInAs(AccountStatus.active, aadhaarVerified: true);
      await harness.launch(location: RouteNames.home);
      tester.view.physicalSize = const Size(1080, 8000);
      harness.container.read(appRouterProvider).go(
            RouteNames.sellDetails,
            extra: ItemDetailsArgs(listingId: 'l1', suggestion: suggestion),
          );
      await harness.settle();
      return harness;
    }

    Finder attributeField(String key) => find.descendant(
          of: find.byKey(ValueKey('CAT-1:$key')),
          matching: find.byType(TextField),
        );
    final priceField =
        find.byWidgetPredicate((w) => w is TextField && w.decoration?.prefixText == '₹ ');

    testWidgets('prefills attributes and notes, opens More details and asks to verify',
        (tester) async {
      final harness = await open(tester, _parsed());

      expect(find.text('Light scratches on the band'), findsOneWidget);
      expect(attributeField('brand'), findsOneWidget);
      expect(tester.widget<TextField>(attributeField('brand')).controller!.text, 'Sony');
      expect(find.text('battery health pct (%)'), findsOneWidget,
          reason: 'More details opens when AI filled something inside');
      expect(
          tester.widget<TextField>(attributeField('battery_health_pct')).controller!.text, '87.5');
      expect(find.text('Please verify'), findsNWidgets(2));
      expect(find.text('AI generated'), findsNWidgets(8));
      await harness.dispose();
    });

    testWidgets('editing a flagged value clears its hint and the seller can clear any value',
        (tester) async {
      final harness = await open(tester, _parsed());

      await tester.enterText(attributeField('battery_health_pct'), '80');
      await harness.settle();
      expect(find.text('Please verify'), findsOneWidget);

      await tester.enterText(attributeField('brand'), '');
      await harness.settle();
      expect(find.text('AI generated'), findsNWidgets(6));
      expect(find.text('brand is required'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('saving sends feedback for notes and attributes', (tester) async {
      final harness = await open(tester, _parsed());
      await tester.enterText(attributeField('battery_health_pct'), '80');
      await tester.enterText(priceField, '500');
      await tester.tap(find.text('Yes'));
      await harness.settle();
      await tester.tap(find.text('Choose Listing Plan'));
      await harness.settle();

      final feedback = verify(
        () => repository.sendSuggestionFeedback('l1', 's1', captureAny()),
      ).captured.single as List<SuggestionFeedback>;
      final byField = {for (final f in feedback) '${f.field}:${f.attributeKey}': f.action};
      expect(byField['CONDITION_NOTES:null'], SuggestionAction.accepted);
      expect(byField['ATTRIBUTE:brand'], SuggestionAction.accepted);
      expect(byField['ATTRIBUTE:storage_gb'], SuggestionAction.accepted);
      expect(byField['ATTRIBUTE:battery_health_pct'], SuggestionAction.edited);
      await harness.dispose();
    });

    testWidgets('More details stays closed when AI filled nothing inside it', (tester) async {
      final harness = await open(
        tester,
        const AiSuggestion(id: 's3', categoryCode: 'CAT-1', attributes: {'brand': 'Sony'}),
      );

      expect(find.text('battery health pct (%)'), findsNothing);
      expect(find.text('Please verify'), findsNothing);
      await harness.dispose();
    });
  });
}
