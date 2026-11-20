import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/push/push_providers.dart';
import 'package:valuex_mobile/core/security/secure_storage_service.dart';

class _MockStorage extends Mock implements SecureStorageService {}

void main() {
  late _MockStorage storage;

  setUp(() {
    storage = _MockStorage();
    when(() => storage.saveInstallId(any())).thenAnswer((_) async {});
  });

  ProviderContainer make() {
    final container = ProviderContainer(
      overrides: [secureStorageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('makes a random id the first time and keeps it', () async {
    when(() => storage.getInstallId()).thenAnswer((_) async => null);

    final id = await make().read(installIdProvider.future);

    expect(id, hasLength(36));
    verify(() => storage.saveInstallId(id)).called(1);
  });

  test('reuses the saved id, so a sign-out does not make a new phone', () async {
    when(() => storage.getInstallId()).thenAnswer((_) async => 'saved-id');

    final id = await make().read(installIdProvider.future);

    expect(id, 'saved-id');
    verifyNever(() => storage.saveInstallId(any()));
  });

  test('replaces an empty saved id', () async {
    when(() => storage.getInstallId()).thenAnswer((_) async => '');

    final id = await make().read(installIdProvider.future);

    expect(id, isNotEmpty);
    verify(() => storage.saveInstallId(id)).called(1);
  });

  test('the default push service is the no-op one, so the app and tests run without Firebase', () {
    final service = make().read(pushServiceProvider);

    expect(service.isAvailable, isFalse);
  });
}
