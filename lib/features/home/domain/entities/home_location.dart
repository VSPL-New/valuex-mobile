import 'dart:convert';

/// Where "near you" is measured from. Only the area, city, state and pincode are kept, never
/// coordinates, and it is never sent to the server.
class HomeLocation {
  final String? area;
  final String city;
  final String? state;
  final String? pincode;

  const HomeLocation({required this.city, this.area, this.state, this.pincode});

  /// First line in the header: the area, or the city when there is no area.
  String get title => (area != null && area!.isNotEmpty) ? area! : city;

  /// Second line in the header.
  String get subtitle => state == null || state!.isEmpty ? city : '$city, $state';

  String toJson() => jsonEncode({'area': area, 'city': city, 'state': state, 'pincode': pincode});

  static HomeLocation? tryParse(String? source) {
    if (source == null) return null;
    try {
      final map = jsonDecode(source) as Map<String, dynamic>;
      final city = map['city'] as String?;
      if (city == null || city.isEmpty) return null;
      return HomeLocation(
        city: city,
        area: map['area'] as String?,
        state: map['state'] as String?,
        pincode: map['pincode'] as String?,
      );
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is HomeLocation &&
      other.area == area &&
      other.city == city &&
      other.state == state &&
      other.pincode == pincode;

  @override
  int get hashCode => Object.hash(area, city, state, pincode);
}
