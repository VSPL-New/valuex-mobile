import '../domain/address_details.dart';
import '../domain/address_search_service.dart';
import '../domain/address_suggestion.dart';

/// Development search over a small list of Indian addresses; needs no key.
class MockAddressSearchService implements AddressSearchService {
  const MockAddressSearchService();

  @override
  Future<List<AddressSuggestion>> suggest(String query, {required String sessionToken}) async {
    final words = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return const [];
    return [
      for (final place in _places)
        if (words.every(place.searchText.contains))
          AddressSuggestion(
            placeId: place.id,
            primaryText: place.details.line1,
            secondaryText: '${place.details.area}, ${place.details.city}, ${place.details.state}',
          ),
    ].take(5).toList();
  }

  @override
  Future<AddressDetails> details(String placeId, {required String sessionToken}) async {
    final place = _places.where((p) => p.id == placeId).firstOrNull;
    if (place == null) throw const AddressSearchUnavailable('Unknown place');
    return place.details;
  }
}

class _Place {
  final String id;
  final AddressDetails details;

  _Place(this.id, String line1, String area, String city, String state, String pincode)
      : details = AddressDetails(
          line1: line1,
          area: area,
          city: city,
          state: state,
          pincode: pincode,
          placeId: id,
        );

  String get searchText =>
      '${details.line1} ${details.area} ${details.city} ${details.state} ${details.pincode}'
          .toLowerCase();
}

final List<_Place> _places = [
  _Place('mock-1', '204, Anand Nagar', 'Andheri East', 'Mumbai', 'Maharashtra', '400069'),
  _Place('mock-2', '5th Floor, Tech Park, BKC', 'Bandra Kurla Complex', 'Mumbai', 'Maharashtra',
      '400051'),
  _Place('mock-3', '12 MG Road', 'Indiranagar', 'Bengaluru', 'Karnataka', '560038'),
  _Place('mock-4', '14 Outer Circle, Connaught Place', 'Connaught Place', 'New Delhi', 'Delhi',
      '110001'),
  _Place('mock-5', 'Plot 8, Sector V', 'Salt Lake', 'Kolkata', 'West Bengal', '700091'),
  _Place(
      'mock-6', 'Road No 12, Banjara Hills', 'Banjara Hills', 'Hyderabad', 'Telangana', '500034'),
  _Place('mock-7', '88 Anna Salai', 'Teynampet', 'Chennai', 'Tamil Nadu', '600018'),
  _Place('mock-8', '21 FC Road', 'Shivajinagar', 'Pune', 'Maharashtra', '411005'),
  _Place('mock-9', '5 CG Road', 'Navrangpura', 'Ahmedabad', 'Gujarat', '380009'),
  _Place('mock-10', '40 MI Road', 'Panch Batti', 'Jaipur', 'Rajasthan', '302001'),
  _Place('mock-11', '16 Hazratganj Main Road', 'Hazratganj', 'Lucknow', 'Uttar Pradesh', '226001'),
  _Place('mock-12', '7 Marine Drive', 'Ernakulam', 'Kochi', 'Kerala', '682031'),
];
