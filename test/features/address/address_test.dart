import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/address/data/address_repository.dart';
import 'package:valuex_mobile/features/address/data/google_places_service.dart';
import 'package:valuex_mobile/features/address/data/mock_address_search_service.dart';
import 'package:valuex_mobile/features/address/domain/address_details.dart';
import 'package:valuex_mobile/features/address/domain/address_search_service.dart';
import 'package:valuex_mobile/features/address/domain/address_suggestion.dart';
import 'package:valuex_mobile/features/address/domain/address_value.dart';
import 'package:valuex_mobile/features/address/domain/indian_state_names.dart';
import 'package:valuex_mobile/features/address/presentation/providers/address_providers.dart';
import 'package:valuex_mobile/features/address/presentation/widgets/address_search_field.dart';
import 'package:valuex_mobile/features/address/presentation/widgets/address_verification_status.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_secure_storage.dart';
import '../../helpers/fonts.dart';

class _MockRepository extends Mock implements AddressRepository {}

class _FakeSearch implements AddressSearchService {
  final List<String> tokens = [];
  final List<String> queries = [];
  Future<List<AddressSuggestion>> Function(String query)? onSuggest;
  Object? detailsError;

  @override
  Future<List<AddressSuggestion>> suggest(String query, {required String sessionToken}) {
    queries.add(query);
    tokens.add(sessionToken);
    return onSuggest?.call(query) ?? Future.value(_suggestions);
  }

  @override
  Future<AddressDetails> details(String placeId, {required String sessionToken}) async {
    tokens.add(sessionToken);
    final error = detailsError;
    if (error != null) throw error;
    return _details;
  }
}

const _suggestions = [
  AddressSuggestion(
    placeId: 'p1',
    primaryText: '12 MG Road',
    secondaryText: 'Indiranagar, Bengaluru',
  ),
  AddressSuggestion(placeId: 'p2', primaryText: '14 MG Road', secondaryText: 'Pune'),
];

const _details = AddressDetails(
  line1: '12 MG Road, Indiranagar',
  area: 'Indiranagar',
  city: 'Bengaluru',
  state: 'Karnataka',
  pincode: '560038',
  placeId: 'p1',
);

const _value = AddressValue(
  address: '12 MG Road, Indiranagar',
  city: 'Bengaluru',
  state: 'Karnataka',
  pincode: '560038',
);

ApiError _error(String code) =>
    ApiError(type: ApiErrorType.business, message: code, code: code, statusCode: 400);

final _config = AppConfig.parse(
  env: 'dev',
  apiBaseUrl: 'http://localhost:8080/api/v1',
  aadhaarFlow: 'sandbox',
);

void main() {
  setUpAll(() async {
    await loadBrandFonts();
    registerFallbackValue(_value);
  });

  group('normalizeIndianState', () {
    test('keeps a name that is already in the list, ignoring case', () {
      expect(normalizeIndianState('Karnataka'), 'Karnataka');
      expect(normalizeIndianState(' tamil nadu '), 'Tamil Nadu');
    });

    test('maps the names Google uses to the app list', () {
      expect(normalizeIndianState('National Capital Territory of Delhi'), 'Delhi');
      expect(normalizeIndianState('Orissa'), 'Odisha');
      expect(normalizeIndianState('Jammu & Kashmir'), 'Jammu and Kashmir');
      expect(normalizeIndianState('Daman and Diu'), 'Dadra and Nagar Haveli and Daman and Diu');
    });

    test('has no state for blank or unknown names', () {
      expect(normalizeIndianState(null), isNull);
      expect(normalizeIndianState('  '), isNull);
      expect(normalizeIndianState('Atlantis'), isNull);
    });
  });

  group('GooglePlacesService', () {
    late FakeHttpAdapter adapter;
    late GooglePlacesService service;

    setUp(() {
      adapter = FakeHttpAdapter((options) async {
        if (options.path == '/places:autocomplete') {
          return FakeHttpAdapter.json(200, {
            'suggestions': [
              {
                'placePrediction': {
                  'placeId': 'abc',
                  'text': {'text': '12 MG Road, Bengaluru, Karnataka, India'},
                  'structuredFormat': {
                    'mainText': {'text': '12 MG Road'},
                    'secondaryText': {'text': 'Indiranagar, Bengaluru'},
                  },
                },
              },
              {
                'queryPrediction': {
                  'text': {'text': 'mg road'},
                },
              },
              {
                'placePrediction': {
                  'placeId': 'def',
                  'text': {'text': 'Anna Salai, Chennai'},
                },
              },
            ],
          });
        }
        if (options.path.startsWith('/places/')) {
          return FakeHttpAdapter.json(200, {
            'id': 'abc',
            'formattedAddress': '12 MG Road, Indiranagar, Bengaluru, Karnataka 560038, India',
            'addressComponents': [
              {
                'longText': '12',
                'types': ['street_number']
              },
              {
                'longText': 'MG Road',
                'types': ['route']
              },
              {
                'longText': 'Indiranagar',
                'types': ['sublocality_level_1', 'sublocality']
              },
              {
                'longText': 'Bengaluru',
                'types': ['locality']
              },
              {
                'longText': 'Karnataka',
                'types': ['administrative_area_level_1']
              },
              {
                'longText': '560 038',
                'types': ['postal_code']
              },
            ],
          });
        }
        return FakeHttpAdapter.error(404, 'NOT_FOUND', 'x');
      });
      final dio = Dio()..httpClientAdapter = adapter;
      service = GooglePlacesService(apiKey: 'key-1', dio: dio);
    });

    test('asks for suggestions in India with the key and the session token', () async {
      final found = await service.suggest('mg road', sessionToken: 'token-1');

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.toString(), 'https://places.googleapis.com/v1/places:autocomplete');
      expect(request.headers['X-Goog-Api-Key'], 'key-1');
      expect(request.data, {
        'input': 'mg road',
        'sessionToken': 'token-1',
        'includedRegionCodes': ['in'],
        'languageCode': 'en',
      });
      expect(found.map((s) => s.placeId), ['abc', 'def']);
      expect(found.first.primaryText, '12 MG Road');
      expect(found.first.secondaryText, 'Indiranagar, Bengaluru');
      expect(found.last.primaryText, 'Anna Salai, Chennai');
    });

    test('turns a place into the address fields', () async {
      final place = await service.details('abc', sessionToken: 'token-1');

      final request = adapter.requests.single;
      expect(request.uri.path, '/v1/places/abc');
      expect(request.queryParameters['sessionToken'], 'token-1');
      expect(request.headers['X-Goog-FieldMask'], contains('addressComponents'));
      expect(place.line1, '12, MG Road, Indiranagar');
      expect(place.area, 'Indiranagar');
      expect(place.city, 'Bengaluru');
      expect(place.state, 'Karnataka');
      expect(place.pincode, '560038');
      expect(place.placeId, 'abc');
    });

    test('a failed request means the search is unavailable', () async {
      final failing = GooglePlacesService(
        apiKey: 'k',
        dio: Dio()
          ..httpClientAdapter = FakeHttpAdapter(
            (_) async => FakeHttpAdapter.error(403, 'FORBIDDEN', 'key'),
          ),
      );

      await expectLater(
        failing.suggest('mg', sessionToken: 't'),
        throwsA(isA<AddressSearchUnavailable>()),
      );
      await expectLater(
        failing.details('abc', sessionToken: 't'),
        throwsA(isA<AddressSearchUnavailable>()),
      );
    });

    test('a place without street parts falls back to the formatted address', () {
      final place = GooglePlacesService.parseDetails({
        'id': 'z',
        'formattedAddress': 'Marine Drive, Kochi, Kerala 682031, India',
        'addressComponents': [
          {
            'longText': 'Kochi',
            'types': ['administrative_area_level_2']
          },
          {
            'longText': 'Atlantis',
            'types': ['administrative_area_level_1']
          },
        ],
      });

      expect(place.line1, 'Marine Drive, Kochi');
      expect(place.city, 'Kochi');
      expect(place.state, isNull);
      expect(place.pincode, isEmpty);
    });

    test('no suggestions in the answer is an empty list', () {
      expect(GooglePlacesService.parseSuggestions({}), isEmpty);
    });
  });

  group('MockAddressSearchService', () {
    const service = MockAddressSearchService();

    test('finds addresses containing every word typed', () async {
      final found = await service.suggest('mg road', sessionToken: 't');

      expect(found.map((s) => s.placeId), ['mock-3']);
      expect((await service.suggest('mumbai', sessionToken: 't')), hasLength(2));
    });

    test('finds nothing for blank or unmatched text', () async {
      expect(await service.suggest('  ', sessionToken: 't'), isEmpty);
      expect(await service.suggest('zzzz', sessionToken: 't'), isEmpty);
    });

    test('gives the details of a suggestion and fails for an unknown place', () async {
      final place = await service.details('mock-3', sessionToken: 't');

      expect(place.city, 'Bengaluru');
      expect(place.state, 'Karnataka');
      expect(place.pincode, '560038');
      await expectLater(
        service.details('nope', sessionToken: 't'),
        throwsA(isA<AddressSearchUnavailable>()),
      );
    });
  });

  group('AddressRepository', () {
    test('lists the saved addresses with their names', () async {
      final adapter = FakeHttpAdapter(
        (_) async => FakeHttpAdapter.ok([
          {
            'id': 'a-1',
            'label': 'Home',
            'address': '12 MG Road, Indiranagar',
            'landmark': 'Flat 4',
            'city': 'Bengaluru',
            'state': 'Karnataka',
            'pincode': '560038',
            'verified': true,
            'defaultAddress': true,
          },
          {
            'id': 'a-2',
            'label': null,
            'address': 'Cyber Park, Hinjewadi',
            'landmark': null,
            'city': 'Pune',
            'state': 'Maharashtra',
            'pincode': '411057',
            'verified': false,
            'defaultAddress': false,
          },
        ]),
      );
      final repository = AddressRepository(
        ApiClient(
          FakeSecureStorage(accessToken: 'access-1', refreshToken: 'refresh-1'),
          _config,
          adapter: adapter,
        ),
      );

      final saved = await repository.savedAddresses();

      expect(adapter.requests.single.path, '/users/me/addresses');
      expect(adapter.requests.single.method, 'GET');
      expect(saved, hasLength(2));
      expect(saved[0].label, 'Home');
      expect(saved[0].isDefault, isTrue);
      expect(saved[0].fullAddress, 'Flat 4, 12 MG Road, Indiranagar, Bengaluru, Karnataka 560038');
      expect(saved[1].label, isNull);
      expect(saved[1].fullAddress, 'Cyber Park, Hinjewadi, Pune, Maharashtra 411057');
    });

    test('sends the address, leaving out what is empty', () async {
      final adapter = FakeHttpAdapter((_) async => FakeHttpAdapter.ok({'verified': true}));
      final repository = AddressRepository(
        ApiClient(
          FakeSecureStorage(accessToken: 'access-1', refreshToken: 'refresh-1'),
          _config,
          adapter: adapter,
        ),
      );

      await repository.verify(_value);
      await repository.verify(
        const AddressValue(
          address: '12 MG Road, Indiranagar',
          landmark: 'Flat 4',
          city: 'Bengaluru',
          state: 'Karnataka',
          pincode: '560038',
          placeId: 'p1',
        ),
      );

      expect(adapter.requests[0].path, '/addresses/verify');
      expect(adapter.requests[0].headers['Authorization'], 'Bearer access-1');
      expect(adapter.requests[0].data, {
        'address': '12 MG Road, Indiranagar',
        'city': 'Bengaluru',
        'state': 'Karnataka',
        'pincode': '560038',
      });
      expect(adapter.requests[1].data, {
        'address': '12 MG Road, Indiranagar',
        'landmark': 'Flat 4',
        'city': 'Bengaluru',
        'state': 'Karnataka',
        'pincode': '560038',
        'placeId': 'p1',
      });
    });
  });

  group('AddressSearchController', () {
    late _FakeSearch search;
    late ProviderContainer container;

    AddressSearchController controller() =>
        container.read(addressSearchControllerProvider.notifier);
    AddressSearchState state() => container.read(addressSearchControllerProvider);

    setUp(() {
      search = _FakeSearch();
      container = ProviderContainer(
        overrides: [addressSearchServiceProvider.overrideWithValue(search)],
      );
      container.listen(addressSearchControllerProvider, (_, __) {});
      addTearDown(container.dispose);
    });

    test('does not search for fewer than three characters', () {
      fakeAsync((async) {
        controller().onQueryChanged('mg');
        async.elapse(const Duration(seconds: 1));

        expect(search.queries, isEmpty);
        expect(state().status, AddressSearchStatus.idle);
      });
    });

    test('waits for a pause in typing, then shows the results', () {
      fakeAsync((async) {
        controller().onQueryChanged('mg r');
        async.elapse(const Duration(milliseconds: 200));
        controller().onQueryChanged('mg ro');
        expect(state().status, AddressSearchStatus.searching);
        async.elapse(const Duration(milliseconds: 200));
        expect(search.queries, isEmpty);

        async.elapse(const Duration(milliseconds: 150));
        async.flushMicrotasks();

        expect(search.queries, ['mg ro']);
        expect(state().status, AddressSearchStatus.results);
        expect(state().suggestions, _suggestions);
      });
    });

    test('says so when nothing matches', () {
      fakeAsync((async) {
        search.onSuggest = (_) async => const [];
        controller().onQueryChanged('zzz');
        async.elapse(AddressSearchController.debounce);
        async.flushMicrotasks();

        expect(state().status, AddressSearchStatus.empty);
      });
    });

    test('a failing search makes the search unavailable', () {
      fakeAsync((async) {
        search.onSuggest = (_) async => throw const AddressSearchUnavailable();
        controller().onQueryChanged('mg road');
        async.elapse(AddressSearchController.debounce);
        async.flushMicrotasks();

        expect(state().status, AddressSearchStatus.unavailable);
      });
    });

    test('an answer for text that has since changed is ignored', () {
      fakeAsync((async) {
        final slow = Completer<List<AddressSuggestion>>();
        search.onSuggest = (query) => query == 'first' ? slow.future : Future.value(_suggestions);
        controller().onQueryChanged('first');
        async.elapse(AddressSearchController.debounce);
        controller().onQueryChanged('second');
        async.elapse(AddressSearchController.debounce);
        async.flushMicrotasks();
        slow.complete(const []);
        async.flushMicrotasks();

        expect(state().status, AddressSearchStatus.results);
        expect(state().suggestions, _suggestions);
      });
    });

    test('picking a suggestion returns the place and starts a new session', () async {
      final place = await controller().select(_suggestions.first);

      expect(place, _details);
      expect(state().status, AddressSearchStatus.idle);
      await controller().select(_suggestions.last);
      expect(search.tokens.toSet(), hasLength(2));
    });

    test('a failed pick leaves the user to type the address', () async {
      search.detailsError = const AddressSearchUnavailable();

      final place = await controller().select(_suggestions.first);

      expect(place, isNull);
      expect(state().status, AddressSearchStatus.unavailable);
    });
  });

  group('AddressVerificationController', () {
    late _MockRepository repository;
    late ProviderContainer container;

    AddressVerificationController controller() =>
        container.read(addressVerificationProvider.notifier);
    AddressVerificationState state() => container.read(addressVerificationProvider);

    setUp(() {
      repository = _MockRepository();
      container = ProviderContainer(
        overrides: [addressRepositoryProvider.overrideWithValue(repository)],
      );
      container.listen(addressVerificationProvider, (_, __) {});
      addTearDown(container.dispose);
    });

    test('checks the address after a pause and reports it verified', () {
      fakeAsync((async) {
        when(() => repository.verify(any())).thenAnswer((_) async {});

        controller().schedule(_value);
        async.elapse(const Duration(milliseconds: 500));
        verifyNever(() => repository.verify(any()));
        async.elapse(const Duration(milliseconds: 250));
        async.flushMicrotasks();

        verify(() => repository.verify(_value)).called(1);
        expect(state().status, AddressCheckStatus.verified);
      });
    });

    test('does not check the same address twice', () {
      fakeAsync((async) {
        when(() => repository.verify(any())).thenAnswer((_) async {});
        controller().schedule(_value);
        async.elapse(AddressVerificationController.debounce);
        async.flushMicrotasks();

        controller().schedule(_value);
        async.elapse(AddressVerificationController.debounce);
        async.flushMicrotasks();

        verify(() => repository.verify(any())).called(1);
        expect(state().status, AddressCheckStatus.verified);
      });
    });

    test('a refused address is rejected with the reason', () {
      fakeAsync((async) {
        when(() => repository.verify(any())).thenThrow(_error('ERROR_PINCODE_MISMATCH'));

        controller().schedule(_value);
        async.elapse(AddressVerificationController.debounce);
        async.flushMicrotasks();

        expect(state().status, AddressCheckStatus.rejected);
        expect(state().code, 'ERROR_PINCODE_MISMATCH');
      });
    });

    test('a check that cannot run is only unavailable', () {
      fakeAsync((async) {
        when(() => repository.verify(any())).thenThrow(
          const ApiError(type: ApiErrorType.network, message: 'offline'),
        );

        controller().schedule(_value);
        async.elapse(AddressVerificationController.debounce);
        async.flushMicrotasks();

        expect(state().status, AddressCheckStatus.unavailable);
      });
    });

    test('the service being down or the limit being reached is only unavailable', () {
      fakeAsync((async) {
        when(() => repository.verify(any())).thenThrow(_error('ERROR_ADDRESS_SERVICE_UNAVAILABLE'));

        controller().schedule(_value);
        async.elapse(AddressVerificationController.debounce);
        async.flushMicrotasks();

        expect(state().status, AddressCheckStatus.unavailable);
      });
    });

    test('editing cancels a check that has not started', () {
      fakeAsync((async) {
        controller().schedule(_value);
        async.elapse(const Duration(milliseconds: 300));
        controller().reset();
        async.elapse(const Duration(seconds: 1));

        verifyNever(() => repository.verify(any()));
        expect(state().status, AddressCheckStatus.idle);
      });
    });

    test('an answer for an address that was edited meanwhile is ignored', () {
      fakeAsync((async) {
        final slow = Completer<void>();
        when(() => repository.verify(_value)).thenAnswer((_) => slow.future);
        controller().schedule(_value);
        async.elapse(AddressVerificationController.debounce);
        controller().reset();
        slow.complete();
        async.flushMicrotasks();

        expect(state().status, AddressCheckStatus.idle);
      });
    });

    test('a refusal that comes back when the address is saved is shown as a rejection', () {
      controller().reject(_error('ERROR_ADDRESS_NOT_VERIFIED'), _value);

      expect(state().status, AddressCheckStatus.rejected);
      expect(state().code, 'ERROR_ADDRESS_NOT_VERIFIED');
      expect(state().checked, _value);
    });

    test('only refusals of the address itself count as rejections', () {
      expect(isAddressRejection(_error('ERROR_ADDRESS_NOT_VERIFIED')), isTrue);
      expect(isAddressRejection(_error('ERROR_INVALID_ADDRESS_STATE')), isTrue);
      expect(
        isAddressRejection(const ApiError(type: ApiErrorType.validation, message: 'x')),
        isTrue,
      );
      expect(isAddressRejection(_error('ERROR_ADDRESS_RATE_LIMIT')), isFalse);
      expect(isAddressRejection(_error('ERROR_TERMS_NOT_ACCEPTED')), isFalse);
      expect(isAddressRejection(StateError('x')), isFalse);
    });
  });

  group('widgets', () {
    late _FakeSearch search;
    late _MockRepository repository;
    AddressDetails? picked;

    Future<void> pump(WidgetTester tester, {AppConfig? config}) async {
      search = _FakeSearch();
      repository = _MockRepository();
      picked = null;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(config ?? _config),
            addressSearchServiceProvider.overrideWithValue(search),
            addressRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    AddressSearchField(onSelected: (place) => picked = place),
                    const AddressVerificationStatus(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    Future<void> type(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump(AddressSearchController.debounce + const Duration(milliseconds: 50));
      await tester.pump();
    }

    testWidgets('shows suggestions while typing and fills the form when one is picked',
        (tester) async {
      await pump(tester);

      await type(tester, 'mg road');
      expect(find.text('12 MG Road'), findsOneWidget);
      expect(find.text('Indiranagar, Bengaluru'), findsOneWidget);
      expect(find.text('Powered by Google'), findsNothing);

      await tester.tap(find.text('12 MG Road'));
      await tester.pump();
      await tester.pump();

      expect(picked, _details);
      expect(find.text('12 MG Road'), findsNothing);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    });

    testWidgets('names Google as the source when it is the provider', (tester) async {
      await pump(
        tester,
        config: AppConfig.parse(
          env: 'dev',
          apiBaseUrl: 'http://localhost:8080/api/v1',
          aadhaarFlow: 'sandbox',
          addressSearch: 'google',
          googlePlacesApiKey: 'key',
        ),
      );

      await type(tester, 'mg road');

      expect(find.text('Powered by Google'), findsOneWidget);
    });

    testWidgets('says when nothing matches and when the search is unavailable', (tester) async {
      await pump(tester);
      search.onSuggest = (_) async => const [];
      await type(tester, 'zzz');
      expect(find.text('No matching address found. Enter it below'), findsOneWidget);

      search.onSuggest = (_) async => throw const AddressSearchUnavailable();
      await type(tester, 'zzzz');
      expect(
        find.text('Address search is unavailable. Enter your address below'),
        findsOneWidget,
      );
    });

    testWidgets('shows Searching while a search is under way', (tester) async {
      await pump(tester);
      final slow = Completer<List<AddressSuggestion>>();
      search.onSuggest = (_) => slow.future;

      await tester.enterText(find.byType(TextField), 'mg road');
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.text('Searching\u2026'), findsOneWidget);

      await tester.pump(AddressSearchController.debounce);
      slow.complete(_suggestions);
      await tester.pump();
      expect(find.text('Searching\u2026'), findsNothing);
    });

    testWidgets('the status line follows the check', (tester) async {
      await pump(tester);
      when(() => repository.verify(any())).thenAnswer((_) async {});
      final container = ProviderScope.containerOf(tester.element(find.byType(AddressSearchField)));
      container.listen(addressVerificationProvider, (_, __) {});

      container.read(addressVerificationProvider.notifier).schedule(_value);
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pump();

      expect(find.text('Address verified'), findsOneWidget);

      container
          .read(addressVerificationProvider.notifier)
          .reject(_error('ERROR_PINCODE_MISMATCH'), _value);
      await tester.pump();
      expect(find.text('The pincode does not match the selected city or state'), findsOneWidget);

      container
          .read(addressVerificationProvider.notifier)
          .reject(_error('ERROR_ADDRESS_NOT_VERIFIED'), _value);
      await tester.pump();
      expect(
        find.text('We could not verify this address. Please check and try again'),
        findsOneWidget,
      );
    });

    testWidgets('the status line says when the check cannot run, and while it runs',
        (tester) async {
      await pump(tester);
      final pending = Completer<void>();
      when(() => repository.verify(any())).thenAnswer((_) => pending.future);
      final container = ProviderScope.containerOf(tester.element(find.byType(AddressSearchField)));
      container.listen(addressVerificationProvider, (_, __) {});

      container.read(addressVerificationProvider.notifier).schedule(_value);
      await tester.pump(AddressVerificationController.debounce);
      await tester.pump();
      expect(find.text('Checking your address\u2026'), findsOneWidget);

      pending.completeError(const ApiError(type: ApiErrorType.network, message: 'offline'));
      await tester.pump();
      await tester.pump();
      expect(
        find.text('Address verification is unavailable right now. You can still continue'),
        findsOneWidget,
      );
    });

    testWidgets('meets the tap target, label and contrast guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      await type(tester, 'mg road');

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrast));
      expect(find.bySemanticsLabel('12 MG Road, Indiranagar, Bengaluru'), findsOneWidget);
      handle.dispose();
    });
  });
}
