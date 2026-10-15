/// An address as the form holds it, ready to send to the backend.
class AddressValue {
  final String address;
  final String? landmark;
  final String city;
  final String state;
  final String pincode;

  /// The Google place the fields came from; null once the user edited them.
  final String? placeId;

  const AddressValue({
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
    this.placeId,
  });

  @override
  bool operator ==(Object other) =>
      other is AddressValue &&
      other.address == address &&
      other.landmark == landmark &&
      other.city == city &&
      other.state == state &&
      other.pincode == pincode &&
      other.placeId == placeId;

  @override
  int get hashCode => Object.hash(address, landmark, city, state, pincode, placeId);
}
