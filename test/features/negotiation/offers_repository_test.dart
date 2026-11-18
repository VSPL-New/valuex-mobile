import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/features/negotiation/data/negotiation_repository.dart';
import 'package:valuex_mobile/features/negotiation/domain/offers.dart';

import '../../helpers/mocks.dart';
import 'negotiation_fixtures.dart';
import 'offers_fixtures.dart';

void main() {
  late MockApiClient client;
  late NegotiationRepository repository;

  setUp(() {
    client = MockApiClient();
    repository = NegotiationRepository(client);
  });

  T Function(Object?) parserOf<T>(Invocation invocation) =>
      invocation.namedArguments[#parse] as T Function(Object?);

  test('receivedOffers asks for one list and one page of the seller\'s offers', () async {
    when(() => client.get<OffersPage>(
          '/offers/received',
          queryParameters: {'status': 'ACCEPTED', 'page': 1, 'size': 20},
          parse: any(named: 'parse'),
        )).thenAnswer((invocation) async => parserOf<OffersPage>(invocation)(
          receivedPageJson([receivedJson(state: 'OFFER_ACCEPTED')], page: 1),
        ));

    final page = await repository.receivedOffers(OffersFilter.accepted, page: 1);

    expect(page.items.single.state.name, 'offerAccepted');
    expect(page.page, 1);
  });

  test('sentOffers reads the buyer\'s open negotiations for pending and accepted', () async {
    for (final filter in [OffersFilter.pending, OffersFilter.accepted]) {
      when(() => client.get<OffersPage>(
            '/negotiations',
            queryParameters: {'role': 'BUYER', 'status': 'OPEN', 'page': 0, 'size': 20},
            parse: any(named: 'parse'),
          )).thenAnswer((invocation) async => parserOf<OffersPage>(invocation)(
            negotiationsPageJson([
              negotiationJson(),
              negotiationJson(id: 'n2', state: 'OFFER_ACCEPTED', awaiting: 'NONE'),
            ]),
          ));

      final page = await repository.sentOffers(filter);

      expect(page.items.single.negotiationId, filter == OffersFilter.pending ? 'n1' : 'n2');
    }
  });

  test('sentOffers reads the closed negotiations for the closed list', () async {
    when(() => client.get<OffersPage>(
          '/negotiations',
          queryParameters: {'role': 'BUYER', 'status': 'CLOSED', 'page': 2, 'size': 20},
          parse: any(named: 'parse'),
        )).thenAnswer((invocation) async => parserOf<OffersPage>(invocation)(
          negotiationsPageJson([negotiationJson(state: 'OFFER_REJECTED', awaiting: 'NONE')]),
        ));

    final page = await repository.sentOffers(OffersFilter.closed, page: 2);

    expect(page.items, hasLength(1));
  });

  test('offersSummary reads the counts', () async {
    when(() => client.get<OffersSummary>('/offers/received/summary', parse: any(named: 'parse')))
        .thenAnswer((invocation) async => parserOf<OffersSummary>(invocation)(
              {'pending': 3, 'accepted': 1, 'expiringSoon': 2},
            ));

    final summary = await repository.offersSummary();

    expect(summary.pending, 3);
    expect(summary.expiringSoon, 2);
  });
}
