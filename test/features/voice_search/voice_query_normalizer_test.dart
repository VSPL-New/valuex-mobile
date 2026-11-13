import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/features/search/domain/search_criteria.dart';
import 'package:valuex_mobile/features/voice_search/domain/voice_query_normalizer.dart';

void main() {
  group('normalizeVoiceQuery', () {
    test('removes each supported English and Hindi command phrase', () {
      for (final phrase in [
        'show me',
        'find me',
        'find',
        'search for',
        'search',
        'i want',
        'i need',
        'looking for',
        'please',
        'pls',
        'मुझे'
      ]) {
        expect(normalizeVoiceQuery('$phrase Samsung phones'), 'Samsung phones');
      }
      for (final phrase in [
        'please',
        'pls',
        'for me',
        'दिखाओ',
        'दिखाइए',
        'खोजो',
        'ढूंढो',
        'चाहिए',
      ]) {
        expect(normalizeVoiceQuery('Samsung phones $phrase'), 'Samsung phones');
      }
    });

    test('keeps command-only input and preserves digits, case and currency words', () {
      expect(normalizeVoiceQuery('Find'), 'Find');
      expect(normalizeVoiceQuery('चाहिए'), 'चाहिए');
      expect(normalizeVoiceQuery('iPhone 14 for ₹20000'), 'iPhone 14 for ₹20000');
    });

    test('trims whitespace, controls and trailing punctuation', () {
      expect(normalizeVoiceQuery('\u0000\u0085  Show   me  phones?!। '), 'phones');
      expect(normalizeVoiceQuery('  Apple  iPhone 14. '), 'Apple iPhone 14');
    });

    test('cuts at 200 Unicode characters without splitting an emoji', () {
      final normalized = normalizeVoiceQuery('${'a' * 199}😀b');
      expect(normalized.runes.length, SearchCriteria.maxQueryLength);
      expect(normalized.endsWith('😀'), isTrue);
    });

    test('keeps empty and whitespace-only input empty', () {
      expect(normalizeVoiceQuery(''), isEmpty);
      expect(normalizeVoiceQuery(' \n\t '), isEmpty);
    });
  });
}
