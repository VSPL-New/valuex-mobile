import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/config/app_config.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/listing/data/listing_repository.dart';
import 'package:valuex_mobile/features/order/data/mock_seller_order_repository.dart';
import 'package:valuex_mobile/features/order/data/seller_order_repository_impl.dart';
import 'package:valuex_mobile/features/order/domain/entities/incoming_order.dart';
import 'package:valuex_mobile/features/order/domain/entities/packing.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_secure_storage.dart';

class _MockListingRepository extends Mock implements ListingRepository {}

const _card = {
  'orderId': 'order-1',
  'orderNumber': 'VX-261128-000123',
  'bucket': 'PACKING',
  'orderState': 'SELLER_PACKING_PENDING',
  'placedAt': '2026-11-28T08:05:00Z',
  'amount': '55000.00',
  'item': {'listingId': 'listing-1', 'title': 'iPhone 15 Pro Max'},
  'actions': ['CONTINUE_PACKING'],
};

const _view = {
  'order': _card,
  'proofs': [
    {
      'proofId': 'p1',
      'kind': 'ITEM_CONDITION',
      'url': 'https://r2/p1',
      'uploadedAt': '2026-11-28T09:00:00Z',
      'submitted': false,
    },
    {'proofId': 'p2', 'kind': 'PACKAGE_SEALED', 'uploadedAt': '2026-11-28T09:01:00Z'},
    {'proofId': 'p3', 'kind': 'PACKAGE_RECEIVED', 'uploadedAt': '2026-11-28T09:02:00Z'},
    'not a proof',
  ],
  'packageSize': {'weightKg': 1.205, 'lengthCm': 30, 'breadthCm': 20.5, 'heightCm': 15},
  'rules': {'itemMin': 1, 'itemMax': 8, 'packageMin': 1, 'packageMax': 4, 'minPixels': 600},
};

void main() {
  group('backend repository', () {
    late FakeHttpAdapter adapter;
    late _MockListingRepository uploads;
    late SellerOrderRepositoryImpl repository;

    setUpAll(() => registerFallbackValue(Uint8List(0)));

    setUp(() {
      adapter = FakeHttpAdapter((request) async => switch (request.path) {
            '/seller/orders/order-1/packing' => FakeHttpAdapter.ok(_view),
            '/seller/orders/order-2/packing' => FakeHttpAdapter.ok({'order': _card}),
            '/media/uploads' =>
              FakeHttpAdapter.ok({'mediaId': 'media-1', 'uploadUrl': 'https://storage/put'}),
            '/seller/orders/order-1/packing/proofs' => FakeHttpAdapter.json(201, {
                'success': true,
                'data': {
                  'proofId': 'p9',
                  'kind': 'PACKAGE_SEALED',
                  'uploadedAt': '2026-11-28T10:00:00Z',
                  'submitted': false,
                },
              }),
            '/seller/orders/order-1/packing/proofs/p1' => FakeHttpAdapter.json(204, ''),
            '/seller/orders/order-1/packing/complete' => FakeHttpAdapter.ok(_card),
            _ => FakeHttpAdapter.error(
                422, 'ERROR_IMAGE_REQUIRED', 'Please upload package images before scheduling'),
          });
      final client = ApiClient(
        FakeSecureStorage(accessToken: 'access', refreshToken: 'refresh'),
        AppConfig.parse(env: 'dev', apiBaseUrl: 'http://localhost/api/v1', aadhaarFlow: 'sandbox'),
        adapter: adapter,
      );
      addTearDown(client.dispose);
      uploads = _MockListingRepository();
      repository = SellerOrderRepositoryImpl(client, uploads);
    });

    test('reads the packing view, leaving out photos of kinds it does not know', () async {
      final view = await repository.packing('order-1');

      expect(view.order.title, 'iPhone 15 Pro Max');
      expect(view.proofs.map((p) => p.id), ['p1', 'p2']);
      expect(view.proofs.first.url, 'https://r2/p1');
      expect(view.proofs.last.url, isNull);
      expect(view.of(ProofKind.packageSealed).single.id, 'p2');
      expect(view.packageSize!.weightKg, 1.205);
      expect(view.packageSize!.breadthCm, 20.5);
      expect(view.rules.itemMax, 8);
      expect(view.rules.minPixels, 600);
      expect(view.rules.max(ProofKind.packageSealed), 4);
      expect(view.rules.min(ProofKind.itemCondition), 1);
    });

    test('uses the default rules and no size when the server sends none', () async {
      final view = await repository.packing('order-2');

      expect(view.proofs, isEmpty);
      expect(view.packageSize, isNull);
      expect(view.rules.itemMin, 2);
      expect(view.rules.packageMax, 2);
      expect(view.rules.minPixels, 480);
    });

    test('uploads a packing photo as private evidence and completes the upload', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      when(() => uploads.uploadBytes(any(), any(), any())).thenAnswer((_) async {});
      when(() => uploads.completeUpload(
            mediaId: any(named: 'mediaId'),
            contentType: any(named: 'contentType'),
            sizeBytes: any(named: 'sizeBytes'),
            width: any(named: 'width'),
            height: any(named: 'height'),
          )).thenAnswer((_) async {});

      final mediaId = await repository.uploadProofPhoto(
        ownerId: 'seller-1',
        fileName: 'box.jpg',
        contentType: 'image/jpeg',
        bytes: bytes,
        width: 1200,
        height: 900,
      );

      expect(mediaId, 'media-1');
      expect(adapter.requests.single.data, {
        'purpose': 'SELLER_PRE_SHIPMENT_EVIDENCE',
        'ownerType': 'USER',
        'ownerId': 'seller-1',
        'fileName': 'box.jpg',
        'contentType': 'image/jpeg',
        'sizeBytes': 3,
      });
      verify(() => uploads.uploadBytes('https://storage/put', bytes, 'image/jpeg')).called(1);
      verify(() => uploads.completeUpload(
          mediaId: 'media-1', contentType: 'image/jpeg', sizeBytes: 3, width: 1200, height: 900));
    });

    test('attaches, removes and completes with the server shapes', () async {
      final proof = await repository.attachProof('order-1', 'media-1', ProofKind.packageSealed);
      await repository.removeProof('order-1', 'p1');
      final order = await repository.completePacking(
        'order-1',
        const PackageSize(weightKg: 1.2, lengthCm: 30, breadthCm: 20, heightCm: 15),
      );

      expect(proof.id, 'p9');
      expect(proof.kind, ProofKind.packageSealed);
      expect(adapter.requests[0].data, {'mediaId': 'media-1', 'kind': 'PACKAGE_SEALED'});
      expect(adapter.requests[1].method, 'DELETE');
      expect(adapter.requests[2].data, {
        'package': {'weightKg': 1.2, 'lengthCm': 30.0, 'breadthCm': 20.0, 'heightCm': 15.0},
      });
      expect(order.actions, [SellerOrderAction.continuePacking]);
    });

    test('passes on the server refusal with its code', () async {
      await expectLater(
        repository.completePacking(
            'order-9', const PackageSize(weightKg: 1, lengthCm: 1, breadthCm: 1, heightCm: 1)),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'ERROR_IMAGE_REQUIRED')),
      );
    });
  });

  group('sample repository', () {
    final bytes = Uint8List(0);

    Future<String> upload(MockSellerOrderRepository repository, {int side = 1200}) =>
        repository.uploadProofPhoto(
            ownerId: 'me',
            fileName: 'a.jpg',
            contentType: 'image/jpeg',
            bytes: bytes,
            width: side,
            height: side);

    test('keeps packing photos in memory and completes the sample order', () async {
      final repository = MockSellerOrderRepository();
      for (final kind in [
        ProofKind.itemCondition,
        ProofKind.itemCondition,
        ProofKind.packageSealed
      ]) {
        await repository.attachProof('mock-1000', await upload(repository), kind);
      }
      final view = await repository.packing('mock-1000');
      expect(view.proofs, hasLength(3));
      await repository.removeProof('mock-1000', view.proofs.first.id);
      await expectLater(
        repository.completePacking(
            'mock-1000', const PackageSize(weightKg: 1, lengthCm: 1, breadthCm: 1, heightCm: 1)),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'ERROR_IMAGE_REQUIRED')),
      );
      await repository.attachProof('mock-1000', await upload(repository), ProofKind.itemCondition);

      final order = await repository.completePacking(
          'mock-1000', const PackageSize(weightKg: 1, lengthCm: 1, breadthCm: 1, heightCm: 1));

      expect(order.orderState, 'SELLER_PROOF_UPLOADED');
      expect(order.actions, [SellerOrderAction.schedulePickup]);
      final page = await repository.orders();
      expect(page.items.firstWhere((o) => o.id == 'mock-1000').actions,
          [SellerOrderAction.schedulePickup]);
    });

    test('refuses a small photo and a full section like the server', () async {
      final repository = MockSellerOrderRepository();
      await expectLater(upload(repository, side: 479),
          throwsA(isA<ApiError>().having((e) => e.code, 'code', 'WARNING_IMAGE_QUALITY_LOW')));
      await repository.attachProof('mock-1000', 'm1', ProofKind.packageSealed);
      await repository.attachProof('mock-1000', 'm2', ProofKind.packageSealed);
      await expectLater(repository.attachProof('mock-1000', 'm3', ProofKind.packageSealed),
          throwsA(isA<ApiError>().having((e) => e.code, 'code', 'ERROR_PROOF_LIMIT')));
    });
  });
}
