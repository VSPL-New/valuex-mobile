import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/features/negotiation/data/negotiation_repository.dart';
import 'package:valuex_mobile/features/negotiation/domain/negotiation.dart';

import '../../helpers/mocks.dart';
import 'negotiation_fixtures.dart';

void main() {
  late MockApiClient client;
  late NegotiationRepository repository;

  setUp(() {
    client = MockApiClient();
    repository = NegotiationRepository(client);
  });

  T Function(Object?) parserOf<T>(Invocation invocation) =>
      invocation.namedArguments[#parse] as T Function(Object?);

  test('makeOffer posts the amount as text with the client id and tells created from repeated',
      () async {
    for (final (status, created) in [(201, true), (200, false)]) {
      when(() => client.postWithStatus<Negotiation>(
            '/listings/l1/offers',
            data: {'amount': '12000', 'clientRequestId': 'c1', 'confirmLowOffer': false},
            parse: any(named: 'parse'),
          )).thenAnswer(
        (invocation) async => (parserOf<Negotiation>(invocation)(negotiationJson()), status),
      );

      final made = await repository.makeOffer('l1', amount: '12000', clientRequestId: 'c1');

      expect(made.created, created);
      expect(made.negotiation.negotiationId, 'n1');
    }
  });

  test('makeOffer sends the low offer confirmation', () async {
    when(() => client.postWithStatus<Negotiation>(
          '/listings/l1/offers',
          data: {'amount': '100.00', 'clientRequestId': 'c2', 'confirmLowOffer': true},
          parse: any(named: 'parse'),
        )).thenAnswer(
      (invocation) async => (parserOf<Negotiation>(invocation)(negotiationJson()), 201),
    );

    final made = await repository.makeOffer(
      'l1',
      amount: '100.00',
      clientRequestId: 'c2',
      confirmLowOffer: true,
    );

    expect(made.created, isTrue);
  });

  test('get reads one negotiation', () async {
    when(() => client.get<Negotiation>('/negotiations/n1', parse: any(named: 'parse')))
        .thenAnswer((invocation) async => parserOf<Negotiation>(invocation)(negotiationJson()));

    expect((await repository.get('n1')).listing.title, 'Apple Watch');
  });

  test('accept, reject and cancel post to their own paths', () async {
    for (final path in ['/offers/o1/accept', '/offers/o1/reject', '/negotiations/n1/cancel']) {
      when(() => client.post<Negotiation>(path, parse: any(named: 'parse')))
          .thenAnswer((invocation) async => parserOf<Negotiation>(invocation)(negotiationJson()));
    }

    expect((await repository.accept('o1')).negotiationId, 'n1');
    expect((await repository.reject('o1')).negotiationId, 'n1');
    expect((await repository.cancel('n1')).negotiationId, 'n1');
  });

  test('counter posts the amount as text with its client id', () async {
    when(() => client.post<Negotiation>(
          '/offers/o2/counter',
          data: {'amount': '13000.00', 'clientRequestId': 'c3'},
          parse: any(named: 'parse'),
        )).thenAnswer((invocation) async => parserOf<Negotiation>(invocation)(negotiationJson()));

    final updated = await repository.counter('o2', amount: '13000.00', clientRequestId: 'c3');

    expect(updated.negotiationId, 'n1');
  });
}
