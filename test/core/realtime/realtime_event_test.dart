import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/realtime/realtime_event.dart';
import 'package:valuex_mobile/core/realtime/realtime_ticket.dart';

void main() {
  group('RealtimeEvent.tryParse', () {
    test('reads an event with its id, type, time and data', () {
      final event = RealtimeEvent.tryParse(
        '{"v":1,"type":"chat.read","id":"e1","ts":"2026-11-17T10:00:00Z","data":{"upToSeq":4}}',
      )!;

      expect(event.id, 'e1');
      expect(event.type, 'chat.read');
      expect(event.at, DateTime.utc(2026, 11, 17, 10));
      expect(event.data, {'upToSeq': 4});
    });

    test('takes empty data when there is none or it is not an object', () {
      expect(RealtimeEvent.tryParse('{"type":"pong","id":"p"}')!.data, isEmpty);
      expect(RealtimeEvent.tryParse('{"type":"x","id":"p","data":3}')!.data, isEmpty);
      expect(RealtimeEvent.tryParse('{"type":"x","id":"p","ts":"bad"}')!.at, isNull);
    });

    test('is null for anything that is not an event', () {
      expect(RealtimeEvent.tryParse('not json'), isNull);
      expect(RealtimeEvent.tryParse('[1]'), isNull);
      expect(RealtimeEvent.tryParse('{"id":"e1"}'), isNull);
      expect(RealtimeEvent.tryParse('{"type":"x"}'), isNull);
      expect(RealtimeEvent.tryParse('{"type":3,"id":"e"}'), isNull);
    });
  });

  group('EventDeduper', () {
    test('says an id is new only the first time', () {
      final deduper = EventDeduper();

      expect(deduper.firstTime('a'), isTrue);
      expect(deduper.firstTime('a'), isFalse);
      expect(deduper.firstTime('b'), isTrue);
    });

    test('forgets the oldest ids beyond its capacity', () {
      final deduper = EventDeduper(capacity: 2);
      deduper.firstTime('a');
      deduper.firstTime('b');
      deduper.firstTime('c');

      expect(deduper.firstTime('c'), isFalse);
      expect(deduper.firstTime('a'), isTrue);
    });
  });

  group('RealtimeTicket', () {
    test('reads the answer and builds the address with the ticket as the only credential', () {
      final ticket = RealtimeTicket.fromJson(const {
        'ticket': 'abc',
        'expiresInSeconds': 30,
        'url': 'wss://api.example.com/ws/v1',
        'pingIntervalSeconds': 25,
      });

      expect(ticket.socketUri.toString(), 'wss://api.example.com/ws/v1?ticket=abc');
      expect(ticket.expiresInSeconds, 30);
      expect(ticket.pingIntervalSeconds, 25);
    });

    test('falls back to the documented lifetimes when the server omits them', () {
      final ticket = RealtimeTicket.fromJson(const {'ticket': 't', 'url': 'ws://h/ws/v1'});

      expect(ticket.expiresInSeconds, 30);
      expect(ticket.pingIntervalSeconds, 25);
    });
  });
}
