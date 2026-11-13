import '../../search/domain/search_criteria.dart';

const List<String> _leadingCommands = [
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
  'मुझे',
];

const List<String> _trailingCommands = [
  'please',
  'pls',
  'for me',
  'दिखाओ',
  'दिखाइए',
  'खोजो',
  'ढूंढो',
  'चाहिए',
];

String normalizeVoiceQuery(String raw) {
  var text = raw.replaceAll(RegExp(r'[\x00-\x1f\x7f-\x9f]'), ' ');
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  text = text.replaceFirst(RegExp(r'[.?!,।]+$'), '').trim();

  final lowered = text.toLowerCase();
  for (final phrase in _leadingCommands) {
    final match = lowered == phrase.toLowerCase() || lowered.startsWith('${phrase.toLowerCase()} ');
    if (match && lowered.length > phrase.length) {
      text = text.substring(phrase.length).trimLeft();
      break;
    }
  }

  final normalizedLower = text.toLowerCase();
  for (final phrase in _trailingCommands) {
    final loweredPhrase = phrase.toLowerCase();
    if (normalizedLower.endsWith(' $loweredPhrase') && text.trim().length > phrase.length) {
      text = text.substring(0, text.length - phrase.length).trimRight();
      break;
    }
  }

  final characters = text.runes.toList(growable: false);
  if (characters.length > SearchCriteria.maxQueryLength) {
    text = String.fromCharCodes(characters.take(SearchCriteria.maxQueryLength));
  }
  return text;
}
