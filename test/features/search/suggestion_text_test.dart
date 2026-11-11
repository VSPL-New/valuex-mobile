import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/features/search/presentation/suggestion_text.dart';

void main() {
  group('splitTypedPrefix', () {
    test('the typed start is split off, keeping the case of the suggestion', () {
      final parts = splitTypedPrefix('iPhone 14 128GB', 'iph');

      expect(parts.typed, 'iPh');
      expect(parts.rest, 'one 14 128GB');
    });

    test('the match ignores case in both directions', () {
      expect(splitTypedPrefix('Smartphones', 'SMART').typed, 'Smart');
      expect(splitTypedPrefix('smartphones', 'Smart').typed, 'smart');
    });

    test('spaces around the query are ignored', () {
      final parts = splitTypedPrefix('Mobile Phones', '  mobile ');

      expect(parts.typed, 'Mobile');
      expect(parts.rest, ' Phones');
    });

    test('the whole text can be typed', () {
      final parts = splitTypedPrefix('Books', 'books');

      expect(parts.typed, 'Books');
      expect(parts.rest, '');
    });

    test('text that does not start with the query has no bold part', () {
      final parts = splitTypedPrefix('Apple iPhone', 'phone');

      expect(parts.typed, '');
      expect(parts.rest, 'Apple iPhone');
    });

    test('a blank or longer query has no bold part', () {
      expect(splitTypedPrefix('Books', '   ').typed, '');
      expect(splitTypedPrefix('Books', '').rest, 'Books');
      expect(splitTypedPrefix('Bo', 'books').typed, '');
      expect(splitTypedPrefix('Bo', 'books').rest, 'Bo');
    });

    test('Devanagari text is split by the characters typed', () {
      final parts = splitTypedPrefix('मोबाइल फ़ोन', 'मोबा');

      expect(parts.typed, 'मोबा');
      expect(parts.rest, 'इल फ़ोन');
    });
  });
}
