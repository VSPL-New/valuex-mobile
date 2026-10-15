/// A chosen place broken into the fields of the address form.
class AddressDetails {
  /// Street, house and locality; may be empty when the place has no street.
  final String line1;

  /// Neighbourhood (not part of the postal address).
  final String? area;
  final String city;

  /// One of the states in `indian_states.dart`, or null when Google's name has no match.
  final String? state;
  final String pincode;
  final String placeId;

  const AddressDetails({
    required this.line1,
    required this.city,
    required this.pincode,
    required this.placeId,
    this.area,
    this.state,
  });
}
