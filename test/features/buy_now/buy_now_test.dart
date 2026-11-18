import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/buy_now/data/buy_now_repository.dart';
import 'package:valuex_mobile/features/buy_now/domain/buy_now_reservation.dart';
import 'package:valuex_mobile/features/buy_now/presentation/buy_now_error_messages.dart';
import 'package:valuex_mobile/features/buy_now/presentation/providers/buy_now_launcher.dart';
import 'package:valuex_mobile/l10n/app_localizations_en.dart';
import 'package:valuex_mobile/l10n/app_localizations_hi.dart';

import '../../helpers/mocks.dart';

class MockBuyNowRepository extends Mock implements BuyNowRepository {}

Map<String, dynamic> reservationJson({String source = 'BUY_NOW', Object price = '4500.50'}) => {
      'agreementId': 'a1',
      'source': source,
      'agreedPrice': price,
      'validUntil': '2026-11-18T10:15:00Z',
      'serverTime': '2026-11-18T10:00:00Z',
    };

BuyNowReservation reservation() => BuyNowReservation.fromJson(reservationJson());

ApiError error(String code, {int status = 409, ApiErrorType? type}) => ApiError(
      type: type ?? ApiErrorType.business,
      message: 'server words',
      code: code,
      statusCode: status,
    );

void main() {
  final en = AppLocalizationsEn();
  final hi = AppLocalizationsHi();

  group('BuyNowReservation', () {
    test('reads the price as a decimal, the end and the server clock', () {
      final value = reservation();

      expect(value.agreementId, 'a1');
      expect(value.source, 'BUY_NOW');
      expect(value.agreedPrice, 4500.50);
      expect(value.validUntil, DateTime.utc(2026, 11, 18, 10, 15));
      expect(value.serverTime, DateTime.utc(2026, 11, 18, 10));
    });

    test('accepts a number price and defaults the source to Buy Now', () {
      final json = reservationJson(price: 1200)..remove('source');

      final value = BuyNowReservation.fromJson(json);

      expect(value.agreedPrice, 1200);
      expect(value.source, 'BUY_NOW');
    });
  });

  group('BuyNowRepository', () {
    late MockApiClient client;
    late BuyNowRepository repository;

    setUp(() {
      client = MockApiClient();
      repository = BuyNowRepository(client);
    });

    test('start posts the price as text with the client id and reads the reservation', () async {
      when(() => client.post<BuyNowReservation>(
            '/listings/l1/buy-now',
            data: {'expectedPrice': '4500.5', 'clientRequestId': 'c1'},
            parse: any(named: 'parse'),
          )).thenAnswer((invocation) async {
        final parse = invocation.namedArguments[#parse] as BuyNowReservation Function(Object?);
        return parse(reservationJson());
      });

      final value = await repository.start('l1', expectedPrice: '4500.5', clientRequestId: 'c1');

      expect(value.agreementId, 'a1');
    });

    test('release deletes the agreement', () async {
      when(() => client.delete<void>('/price-agreements/a1')).thenAnswer((_) async {});

      await repository.release('a1');

      verify(() => client.delete<void>('/price-agreements/a1')).called(1);
    });
  });

  group('BuyNowLauncher', () {
    late MockBuyNowRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = MockBuyNowRepository();
      container = ProviderContainer(
        overrides: [buyNowRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      container.listen(buyNowLauncherProvider, (_, __) {});
    });

    test('gives the reservation and goes back to idle', () async {
      when(() => repository.start('l1',
          expectedPrice: any(named: 'expectedPrice'),
          clientRequestId: any(named: 'clientRequestId'))).thenAnswer((_) async => reservation());

      final result = await container
          .read(buyNowLauncherProvider.notifier)
          .start('l1', expectedPrice: '4500.5', clientRequestId: 'c1');

      expect(result.reservation?.agreementId, 'a1');
      expect(result.error, isNull);
      expect(container.read(buyNowLauncherProvider), isFalse);
    });

    test('gives the refusal as the error', () async {
      when(() => repository.start('l1',
          expectedPrice: any(named: 'expectedPrice'),
          clientRequestId: any(named: 'clientRequestId'))).thenThrow(error('ERROR_ITEM_SOLD'));

      final result = await container
          .read(buyNowLauncherProvider.notifier)
          .start('l1', expectedPrice: '4500.5', clientRequestId: 'c1');

      expect(result.reservation, isNull);
      expect((result.error as ApiError).code, 'ERROR_ITEM_SOLD');
      expect(container.read(buyNowLauncherProvider), isFalse);
    });

    test('ignores a second tap while the first is running, so the server sees one request',
        () async {
      final pending = Future<BuyNowReservation>.delayed(
        const Duration(milliseconds: 10),
        reservation,
      );
      when(() => repository.start('l1',
          expectedPrice: any(named: 'expectedPrice'),
          clientRequestId: any(named: 'clientRequestId'))).thenAnswer((_) => pending);
      final launcher = container.read(buyNowLauncherProvider.notifier);

      final first = launcher.start('l1', expectedPrice: '4500.5', clientRequestId: 'c1');
      expect(container.read(buyNowLauncherProvider), isTrue);
      final second = await launcher.start('l1', expectedPrice: '4500.5', clientRequestId: 'c2');
      await first;

      expect(second.reservation, isNull);
      expect(second.error, isNull);
      verify(() => repository.start('l1',
          expectedPrice: any(named: 'expectedPrice'),
          clientRequestId: any(named: 'clientRequestId'))).called(1);
    });
  });

  group('buyNowErrorMessage', () {
    test('says each refusal in English', () {
      expect(buyNowErrorMessage(en, error('ERROR_ITEM_SOLD')), 'This item is no longer available');
      expect(
          buyNowErrorMessage(en, error('ERROR_PRICE_CHANGED')), 'Price has changed. Please review');
      expect(buyNowErrorMessage(en, error('ERROR_BUY_NOW_DISABLED')),
          'Seller requires price negotiation for this item');
      expect(buyNowErrorMessage(en, error('ERROR_BUY_NOW_NOT_APPLICABLE')),
          'Buy Now is not available for property');
      expect(buyNowErrorMessage(en, error('ERROR_CHECKOUT_UNAVAILABLE', status: 503)),
          'Buy Now is not available yet. Please try again later');
      expect(buyNowErrorMessage(en, error('RATE_LIMIT_EXCEEDED', status: 429)),
          'Too many Buy Now attempts. Try again later');
    });

    test('says them in Hindi', () {
      expect(buyNowErrorMessage(hi, error('ERROR_ITEM_SOLD')), 'यह वस्तु अब उपलब्ध नहीं है');
      expect(buyNowErrorMessage(hi, error('ERROR_PRICE_CHANGED')), contains('कीमत बदल गई है'));
    });

    test('falls back to the negotiation texts for a reserved item and for verification', () {
      expect(buyNowErrorMessage(en, error('ERROR_ITEM_RESERVED')), en.negotiationErrorReserved);
      expect(buyNowErrorMessage(en, error('AADHAAR_VERIFICATION_REQUIRED', status: 403)),
          en.negotiationErrorAadhaar);
    });

    test('falls back to the general text for an error that is not an API error', () {
      expect(buyNowErrorMessage(en, StateError('x')), isNotEmpty);
    });

    test('asks for the page to be read again only when what the buyer saw is no longer true', () {
      for (final code in [
        'ERROR_ITEM_SOLD',
        'ERROR_PRICE_CHANGED',
        'ERROR_BUY_NOW_DISABLED',
        'ERROR_ITEM_RESERVED',
        'ERROR_LISTING_NOT_AVAILABLE',
      ]) {
        expect(buyNowErrorStalesPage(error(code)), isTrue, reason: code);
      }
      expect(buyNowErrorStalesPage(error('RATE_LIMIT_EXCEEDED', status: 429)), isFalse);
      expect(buyNowErrorStalesPage(StateError('x')), isFalse);
    });
  });
}
