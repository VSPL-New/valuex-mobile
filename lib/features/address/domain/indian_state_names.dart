import '../../auth/domain/entities/indian_states.dart';

const Map<String, String> _aliases = {
  'national capital territory of delhi': 'Delhi',
  'nct of delhi': 'Delhi',
  'delhi ncr': 'Delhi',
  'orissa': 'Odisha',
  'pondicherry': 'Puducherry',
  'uttaranchal': 'Uttarakhand',
  'dadra and nagar haveli': 'Dadra and Nagar Haveli and Daman and Diu',
  'daman and diu': 'Dadra and Nagar Haveli and Daman and Diu',
  'jammu & kashmir': 'Jammu and Kashmir',
  'andaman & nicobar islands': 'Andaman and Nicobar Islands',
};

/// Maps the state name Google returns to the app's own list; null when there is no match.
String? normalizeIndianState(String? name) {
  if (name == null) return null;
  final cleaned = name.trim();
  if (cleaned.isEmpty) return null;
  for (final state in IndianStates.names) {
    if (state.toLowerCase() == cleaned.toLowerCase()) return state;
  }
  return _aliases[cleaned.toLowerCase()] ?? _aliases[cleaned.toLowerCase().replaceAll('&', 'and')];
}
