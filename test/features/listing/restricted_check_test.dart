import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/listing/data/listing_repository.dart';
import 'package:valuex_mobile/features/listing/domain/restricted_check.dart';

import '../../helpers/app_harness.dart' show testConfig;
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_secure_storage.dart';

Map<String, dynamic> _check(String result, {List<Map<String, dynamic>>? policies}) => {
      'checkId': 'c1',
      'result': result,
      'policyVersion': 'v1',
      'policies': policies ??
          [
            {
              'code': 'DRONES',
              'status': 'CONDITIONAL',
              'title': 'Drones',
              'titleHi': 'ड्रोन',
              'message': 'Be legal',
              'messageHi': 'कानूनी रहें',
            },
          ],
      'message': null,
    };

void main() {
  group('RestrictedCheck', () {
    test('parses the result, the rows and the codes to agree to', () {
      final check = RestrictedCheck.fromJson(_check('COMPLIANCE_REQUIRED'));

      expect(check.checkId, 'c1');
      expect(check.result, RestrictedResult.complianceRequired);
      expect(check.policyCodes, ['DRONES']);
      expect(check.policies.single.title, 'Drones');
    });

    test('maps every result and treats an unknown one as unclear', () {
      expect(RestrictedResult.parse('SAFE'), RestrictedResult.safe);
      expect(RestrictedResult.parse('RESTRICTED'), RestrictedResult.restricted);
      expect(RestrictedResult.parse('SEVERE_VIOLATION'), RestrictedResult.severeViolation);
      expect(RestrictedResult.parse('UNCLEAR'), RestrictedResult.unclear);
      expect(RestrictedResult.parse(null), RestrictedResult.unclear);
      expect(RestrictedResult.restricted.isBlocked, isTrue);
      expect(RestrictedResult.severeViolation.isBlocked, isTrue);
      expect(RestrictedResult.complianceRequired.isBlocked, isFalse);
      expect(RestrictedResult.safe.isBlocked, isFalse);
    });

    test('a missing list of rows is empty', () {
      final check = RestrictedCheck.fromJson({'checkId': 'c1', 'result': 'SAFE'});

      expect(check.policies, isEmpty);
    });

    test('shows Hindi text to a Hindi reader and English otherwise or when Hindi is missing', () {
      final policy = RestrictedCheck.fromJson(_check('COMPLIANCE_REQUIRED')).policies.single;
      const english = RestrictionPolicy(code: 'X', title: 'Only English', message: 'Only message');

      expect(policy.titleIn('hi'), 'ड्रोन');
      expect(policy.messageIn('hi'), 'कानूनी रहें');
      expect(policy.titleIn('en'), 'Drones');
      expect(policy.messageIn('en'), 'Be legal');
      expect(english.titleIn('hi'), 'Only English');
      expect(english.messageIn('hi'), 'Only message');
    });
  });

  group('repository', () {
    late FakeHttpAdapter api;
    late ListingRepository repository;

    void use(FakeHandler handler) {
      api = FakeHttpAdapter(handler);
      repository = ListingRepository(
        ApiClient(FakeSecureStorage(accessToken: 'a', refreshToken: 'r'), testConfig, adapter: api),
        Dio(),
      );
    }

    test('posts the check and parses the cleared answer', () async {
      use((_) async => FakeHttpAdapter.ok(_check('SAFE', policies: [])));

      final check = await repository.checkRestrictedItems('l1');

      expect(api.requests.single.method, 'POST');
      expect(api.requests.single.path, '/listings/l1/restricted-check');
      expect(check.result, RestrictedResult.safe);
    });

    test('a prohibited item (400) comes back as a result with its rows', () async {
      use((_) async => FakeHttpAdapter.json(400, {
            'success': false,
            'error': {'code': 'ERROR_RESTRICTED_ITEM', 'message': 'blocked'},
            'data': _check('RESTRICTED'),
          }));

      final check = await repository.checkRestrictedItems('l1');

      expect(check.result, RestrictedResult.restricted);
      expect(check.policyCodes, ['DRONES']);
    });

    test('a severe violation (403) comes back as a result', () async {
      use((_) async => FakeHttpAdapter.json(403, {
            'success': false,
            'error': {'code': 'ERROR_ACCOUNT_SUSPENDED', 'message': 'suspended'},
            'data': _check('SEVERE_VIOLATION'),
          }));

      expect(
          (await repository.checkRestrictedItems('l1')).result, RestrictedResult.severeViolation);
    });

    test('any other failure is thrown, even one with a blocked code but no body', () async {
      use((_) async => FakeHttpAdapter.error(400, 'ERROR_MIN_PHOTOS_REQUIRED', 'x'));
      await expectLater(
        repository.checkRestrictedItems('l1'),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'ERROR_MIN_PHOTOS_REQUIRED')),
      );

      use((_) async => FakeHttpAdapter.error(400, 'ERROR_RESTRICTED_ITEM', 'x'));
      await expectLater(repository.checkRestrictedItems('l1'), throwsA(isA<ApiError>()));
    });

    test('sends the codes the seller agreed to', () async {
      use((_) async => FakeHttpAdapter.ok({'accepted': 2}));

      await repository.acceptCompliance('l1', 'c1', ['DRONES', 'REAL_ESTATE']);

      expect(api.requests.single.path, '/listings/l1/restricted-check/c1/compliance-acceptance');
      expect(api.requests.single.data, {
        'policyCodes': ['DRONES', 'REAL_ESTATE'],
      });
    });

    test('sends the appeal reason', () async {
      use((_) async => FakeHttpAdapter.ok({'appealId': 'a1', 'status': 'PENDING'}));

      await repository.appealRestricted('l1', 'c1', 'Decorative bottles');

      expect(api.requests.single.path, '/listings/l1/restricted-check/c1/appeal');
      expect(api.requests.single.data, {'reason': 'Decorative bottles'});
    });
  });
}
