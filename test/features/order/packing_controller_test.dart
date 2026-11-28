import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/auth/domain/entities/user_profile.dart';
import 'package:valuex_mobile/features/listing/data/photo_source.dart';
import 'package:valuex_mobile/features/listing/domain/listing_photo.dart';
import 'package:valuex_mobile/features/order/domain/entities/incoming_order.dart';
import 'package:valuex_mobile/features/order/domain/entities/packing.dart';
import 'package:valuex_mobile/features/order/domain/repositories/seller_order_repository.dart';
import 'package:valuex_mobile/features/order/presentation/providers/packing_providers.dart';
import 'package:valuex_mobile/features/order/presentation/providers/seller_order_providers.dart';
import 'package:valuex_mobile/features/profile/data/profile_repository.dart';

class _MockRepository extends Mock implements SellerOrderRepository {}

final _order = IncomingOrder(
  id: 'o1',
  orderNumber: 'VX-1',
  bucket: FulfilmentBucket.packing,
  orderState: 'SELLER_PACKING_PENDING',
  placedAt: DateTime(2026, 11, 28),
  amount: 55000,
  title: 'iPhone 15 Pro Max',
);

const _size = PackageSize(weightKg: 1.2, lengthCm: 30, breadthCm: 20, heightCm: 15);
final _bytes = Uint8List.fromList([1, 2, 3]);
final _photo = PickedPhoto(name: 'a.jpg', bytes: _bytes);
const _good = PhotoInspection(contentType: 'image/jpeg', width: 1200, height: 900);
const _offline = ApiError(type: ApiErrorType.network, message: 'offline');

OrderProof _proof(String id, ProofKind kind) =>
    OrderProof(id: id, kind: kind, uploadedAt: DateTime(2026, 11, 28));

void main() {
  late _MockRepository repository;
  late ProviderContainer container;
  final provider = packingControllerProvider('o1');

  PackingController controller() => container.read(provider.notifier);
  PackingState state() => container.read(provider);

  setUpAll(() {
    registerFallbackValue(ProofKind.itemCondition);
    registerFallbackValue(_size);
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    repository = _MockRepository();
    container = ProviderContainer(overrides: [
      sellerOrderRepositoryProvider.overrideWithValue(repository),
      userProfileProvider.overrideWith((ref) async => const UserProfile(
          userId: 'seller-1', status: AccountStatus.active, aadhaarVerified: true)),
    ]);
    container.listen(provider, (_, __) {});
    addTearDown(container.dispose);
    when(() => repository.packing('o1')).thenAnswer((_) async => PackingView(order: _order));
    when(() => repository.uploadProofPhoto(
          ownerId: any(named: 'ownerId'),
          fileName: any(named: 'fileName'),
          contentType: any(named: 'contentType'),
          bytes: any(named: 'bytes'),
          width: any(named: 'width'),
          height: any(named: 'height'),
        )).thenAnswer((_) async => 'media-1');
    var next = 0;
    when(() => repository.attachProof('o1', any(), any()))
        .thenAnswer((call) async => _proof('p${next++}', call.positionalArguments[2] as ProofKind));
  });

  test('loads the view, or keeps the error to show Retry', () async {
    expect(state().isLoading, isTrue);
    await controller().load();
    expect(state().view!.order.title, 'iPhone 15 Pro Max');
    expect(state().canSubmit, isFalse);
    expect(state().missing(ProofKind.itemCondition), 2);

    when(() => repository.packing('o1')).thenThrow(_offline);
    await controller().load();
    expect(state().error, _offline);
    expect(state().view, isNotNull);
  });

  test('uploads as the signed-in seller, attaches, and enables submit at the minimums', () async {
    await controller().load();

    expect(await controller().addPhoto(ProofKind.itemCondition, _photo, _good), isNull);
    expect(await controller().addPhoto(ProofKind.itemCondition, _photo, _good), isNull);
    expect(state().canSubmit, isFalse);
    expect(await controller().addPhoto(ProofKind.packageSealed, _photo, _good), isNull);

    expect(state().pending, isEmpty);
    expect(state().view!.proofs, hasLength(3));
    expect(state().canSubmit, isTrue);
    verify(() => repository.uploadProofPhoto(
          ownerId: 'seller-1',
          fileName: 'a.jpg',
          contentType: 'image/jpeg',
          bytes: _bytes,
          width: 1200,
          height: 900,
        )).called(3);
  });

  test('refuses a small photo and a full section before uploading', () async {
    await controller().load();
    const small = PhotoInspection(contentType: 'image/jpeg', width: 1200, height: 479);

    final low = await controller().addPhoto(ProofKind.itemCondition, _photo, small);
    await controller().addPhoto(ProofKind.packageSealed, _photo, _good);
    await controller().addPhoto(ProofKind.packageSealed, _photo, _good);
    final full = await controller().addPhoto(ProofKind.packageSealed, _photo, _good);

    expect(low?.code, PackingErrors.qualityLow);
    expect(full?.code, PackingErrors.proofLimit);
    expect(state().canAdd(ProofKind.packageSealed), isFalse);
    verify(() => repository.attachProof('o1', any(), any())).called(2);
  });

  test('keeps a photo that failed on the network and retries only what is missing', () async {
    await controller().load();
    when(() => repository.attachProof('o1', 'media-1', ProofKind.itemCondition))
        .thenThrow(_offline);

    final error = await controller().addPhoto(ProofKind.itemCondition, _photo, _good);

    expect(error?.code, PackingErrors.uploadFailed);
    final failed = state().pending.single;
    expect(failed.failed, isTrue);
    expect(failed.mediaId, 'media-1');
    expect(state().canSubmit, isFalse);

    when(() => repository.attachProof('o1', 'media-1', ProofKind.itemCondition))
        .thenAnswer((_) async => _proof('p1', ProofKind.itemCondition));
    expect(await controller().retry(failed.localId), isNull);
    expect(await controller().retry(failed.localId), isNull);

    expect(state().pending, isEmpty);
    expect(state().view!.proofs.single.id, 'p1');
    verify(() => repository.uploadProofPhoto(
          ownerId: any(named: 'ownerId'),
          fileName: any(named: 'fileName'),
          contentType: any(named: 'contentType'),
          bytes: any(named: 'bytes'),
          width: any(named: 'width'),
          height: any(named: 'height'),
        )).called(1);
  });

  test('drops a photo the server refuses and can drop a failed one', () async {
    await controller().load();
    when(() => repository.attachProof('o1', any(), any())).thenThrow(const ApiError(
        type: ApiErrorType.validation, message: 'low', code: PackingErrors.qualityLow));

    final error = await controller().addPhoto(ProofKind.itemCondition, _photo, _good);

    expect(error?.code, PackingErrors.qualityLow);
    expect(state().pending, isEmpty);

    when(() => repository.attachProof('o1', any(), any())).thenThrow(_offline);
    await controller().addPhoto(ProofKind.itemCondition, _photo, _good);
    controller().discard(state().pending.single.localId);
    expect(state().pending, isEmpty);
  });

  test('removes an attached draft, and reports a failed removal', () async {
    when(() => repository.packing('o1')).thenAnswer(
        (_) async => PackingView(order: _order, proofs: [_proof('p1', ProofKind.itemCondition)]));
    await controller().load();
    when(() => repository.removeProof('o1', 'p1')).thenThrow(_offline);
    expect(await controller().remove('p1'), _offline);
    expect(state().view!.proofs, hasLength(1));

    when(() => repository.removeProof('o1', 'p1')).thenAnswer((_) async {});
    expect(await controller().remove('p1'), isNull);
    expect(state().view!.proofs, isEmpty);
  });

  test('completes packing and returns the order now waiting for pickup', () async {
    when(() => repository.packing('o1'))
        .thenAnswer((_) async => PackingView(order: _order, proofs: [
              _proof('a', ProofKind.itemCondition),
              _proof('b', ProofKind.itemCondition),
              _proof('c', ProofKind.packageSealed),
            ]));
    await controller().load();
    when(() => repository.completePacking('o1', _size)).thenAnswer((_) async => _order);

    final result = await controller().complete(_size);

    expect(result.order, _order);
    expect(result.error, isNull);
    expect(state().isCompleting, isFalse);
  });

  test('does not send an incomplete packing, and reloads after a refusal', () async {
    await controller().load();
    final early = await controller().complete(_size);
    expect(early.error?.code, PackingErrors.imageRequired);
    verifyNever(() => repository.completePacking(any(), any()));

    when(() => repository.packing('o1'))
        .thenAnswer((_) async => PackingView(order: _order, proofs: [
              _proof('a', ProofKind.itemCondition),
              _proof('b', ProofKind.itemCondition),
              _proof('c', ProofKind.packageSealed),
            ]));
    await controller().load();
    const moved = ApiError(
        type: ApiErrorType.business, message: 'moved', code: PackingErrors.actionNotAllowed);
    when(() => repository.completePacking('o1', _size)).thenThrow(moved);

    final result = await controller().complete(_size);

    expect(result.error, moved);
    verify(() => repository.packing('o1')).called(3);
  });
}
