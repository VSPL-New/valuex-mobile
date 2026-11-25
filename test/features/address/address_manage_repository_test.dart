import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/address/data/address_repository.dart';
import 'package:valuex_mobile/features/address/data/google_places_service.dart';
import 'package:valuex_mobile/features/address/domain/address_value.dart';
import 'package:valuex_mobile/features/address/domain/saved_address.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_secure_storage.dart';

final _config = AppConfig.parse(
  env: 'dev',
  apiBaseUrl: 'http://localhost:8080/api/v1',
  aadhaarFlow: 'sandbox',
);

const _value = AddressValue(
  address: '99 Brigade Road, Ashok Nagar',
  landmark: 'Flat 4',
  city: 'Bengaluru',
  state: 'Karnataka',
  pincode: '560001',
  placeId: 'p2',
);

Map<String, dynamic> _savedJson({bool verified = false, bool isDefault = false}) => {
      'id': 'a1',
      'label': 'Office',
      'address': '99 Brigade Road, Ashok Nagar',
      'landmark': 'Flat 4',
      'city': 'Bengaluru',
      'state': 'Karnataka',
      'pincode': '560001',
      'verified': verified,
      'defaultAddress': isDefault,
    };

void main() {
  late FakeHttpAdapter adapter;
  late AddressRepository repository;

  void answer(ResponseBody Function(RequestOptions options) reply) {
    adapter = FakeHttpAdapter((options) async => reply(options));
    repository = AddressRepository(ApiClient(FakeSecureStorage(), _config, adapter: adapter));
  }

  group('verify', () {
    test('answers true when a provider confirmed the address', () async {
      answer((_) => FakeHttpAdapter.ok({'verified': true}));

      expect(await repository.verify(_value), isTrue);
    });

    test('answers false when the address only passed the backend checks', () async {
      answer((_) => FakeHttpAdapter.ok({'verified': false}));

      expect(await repository.verify(_value), isFalse);
    });

    test('answers false when the answer carries no flag', () async {
      answer((_) => FakeHttpAdapter.ok(<String, dynamic>{}));

      expect(await repository.verify(_value), isFalse);
    });
  });

  group('update', () {
    test('puts the address and the name to the address id and returns the saved one', () async {
      answer((_) => FakeHttpAdapter.ok(_savedJson()));

      final saved = await repository.update('a1', _value, label: ' Office ');

      final request = adapter.requests.single;
      expect(request.path, '/users/me/addresses/a1');
      expect(request.method, 'PUT');
      expect(request.data, {
        'address': '99 Brigade Road, Ashok Nagar',
        'landmark': 'Flat 4',
        'city': 'Bengaluru',
        'state': 'Karnataka',
        'pincode': '560001',
        'placeId': 'p2',
        'label': 'Office',
      });
      expect(saved.label, 'Office');
    });

    test('leaves the name out to remove it', () async {
      answer((_) => FakeHttpAdapter.ok(_savedJson()));

      await repository.update('a1', _value);
      await repository.update('a1', _value, label: '   ');

      for (final request in adapter.requests) {
        expect((request.data as Map).containsKey('label'), isFalse);
      }
    });

    test('shows the reason when the backend refuses the new address', () async {
      answer((_) => FakeHttpAdapter.error(400, 'ERROR_PINCODE_MISMATCH', 'mismatch'));

      await expectLater(
        repository.update('a1', _value),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'ERROR_PINCODE_MISMATCH')),
      );
    });
  });

  group('setDefault and delete', () {
    test('sets the default with a put and returns the address', () async {
      answer((_) => FakeHttpAdapter.ok(_savedJson(isDefault: true)));

      final saved = await repository.setDefault('a1');

      expect(adapter.requests.single.path, '/users/me/addresses/a1/default');
      expect(adapter.requests.single.method, 'PUT');
      expect(saved.isDefault, isTrue);
    });

    test('deletes with a delete and accepts an empty answer', () async {
      answer((_) => FakeHttpAdapter.json(204, ''));

      await repository.delete('a1');

      expect(adapter.requests.single.path, '/users/me/addresses/a1');
      expect(adapter.requests.single.method, 'DELETE');
    });

    test('shows that an address in use cannot be deleted', () async {
      answer((_) => FakeHttpAdapter.error(409, 'ERROR_ADDRESS_IN_USE', 'in use'));

      await expectLater(
        repository.delete('a1'),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'ERROR_ADDRESS_IN_USE')),
      );
    });
  });

  group('SavedAddress', () {
    test('reads the verified flag, false when the backend sends none', () {
      expect(SavedAddress.fromJson(_savedJson(verified: true)).verified, isTrue);
      expect(SavedAddress.fromJson(_savedJson()).verified, isFalse);
      final withoutFlag = _savedJson()..remove('verified');
      expect(SavedAddress.fromJson(withoutFlag).verified, isFalse);
    });
  });

  test('the place details call asks for address fields only', () {
    expect(
      GooglePlacesService.detailsFieldMask.split(','),
      unorderedEquals(['id', 'formattedAddress', 'addressComponents']),
    );
  });
}
