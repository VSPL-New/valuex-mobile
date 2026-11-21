import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/address/data/address_repository.dart';
import 'package:valuex_mobile/features/address/domain/address_value.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_secure_storage.dart';

final _config = AppConfig.parse(
  env: 'dev',
  apiBaseUrl: 'http://localhost:8080/api/v1',
  aadhaarFlow: 'sandbox',
);

const _value = AddressValue(
  address: '12 MG Road, Indiranagar',
  landmark: 'Flat 4',
  city: 'Bengaluru',
  state: 'Karnataka',
  pincode: '560038',
  placeId: 'p1',
);

Map<String, dynamic> _savedJson({bool isDefault = true}) => {
      'id': 'a1',
      'label': 'Home',
      'address': '12 MG Road, Indiranagar',
      'landmark': 'Flat 4',
      'city': 'Bengaluru',
      'state': 'Karnataka',
      'pincode': '560038',
      'verified': true,
      'defaultAddress': isDefault,
    };

void main() {
  late FakeHttpAdapter adapter;
  late AddressRepository repository;

  void answer(ResponseBody Function(RequestOptions options) reply) {
    adapter = FakeHttpAdapter((options) async => reply(options));
    repository = AddressRepository(ApiClient(FakeSecureStorage(), _config, adapter: adapter));
  }

  test('saves an address with its name and the default flag, and returns it', () async {
    answer((_) => FakeHttpAdapter.json(201, {'success': true, 'data': _savedJson()}));

    final saved = await repository.create(_value, label: ' Home ', makeDefault: true);

    final request = adapter.requests.single;
    expect(request.path, '/users/me/addresses');
    expect(request.method, 'POST');
    expect(request.data, {
      'address': '12 MG Road, Indiranagar',
      'landmark': 'Flat 4',
      'city': 'Bengaluru',
      'state': 'Karnataka',
      'pincode': '560038',
      'placeId': 'p1',
      'label': 'Home',
      'makeDefault': true,
    });
    expect(saved.id, 'a1');
    expect(saved.label, 'Home');
    expect(saved.isDefault, isTrue);
  });

  test('leaves out a blank name, a missing landmark and a missing place', () async {
    answer(
        (_) => FakeHttpAdapter.json(201, {'success': true, 'data': _savedJson(isDefault: false)}));

    final saved = await repository.create(
      const AddressValue(
          address: '12 MG Road, Indiranagar',
          city: 'Pune',
          state: 'Maharashtra',
          pincode: '411001'),
      label: '   ',
    );

    expect(adapter.requests.single.data, {
      'address': '12 MG Road, Indiranagar',
      'city': 'Pune',
      'state': 'Maharashtra',
      'pincode': '411001',
      'makeDefault': false,
    });
    expect(saved.isDefault, isFalse);
  });

  test('surfaces the refusal of an address the provider could not verify', () async {
    answer((_) => FakeHttpAdapter.error(
        400, 'ERROR_ADDRESS_NOT_VERIFIED', 'We could not verify this address'));

    await expectLater(
      repository.create(_value),
      throwsA(isA<ApiError>().having((e) => e.code, 'code', 'ERROR_ADDRESS_NOT_VERIFIED')),
    );
  });
}
