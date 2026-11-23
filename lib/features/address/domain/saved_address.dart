/// One of the user's saved addresses, as listed by the backend.
class SavedAddress {
  final String id;

  /// The user's name for it (Home, Office, anything custom); null for addresses saved without one.
  final String? label;
  final String address;

  /// House or flat number and landmark.
  final String? landmark;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  /// True only when a provider confirmed the address (the place check of US-113 is on); an address that
  /// passed our own checks is saved unverified, and nothing is shown for it.
  final bool verified;

  const SavedAddress({
    required this.id,
    this.label,
    required this.address,
    this.landmark,
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
    this.verified = false,
  });

  factory SavedAddress.fromJson(Object? json) {
    final map = json as Map<String, dynamic>;
    return SavedAddress(
      id: map['id'] as String,
      label: map['label'] as String?,
      address: map['address'] as String,
      landmark: map['landmark'] as String?,
      city: map['city'] as String,
      state: map['state'] as String,
      pincode: map['pincode'] as String,
      isDefault: map['defaultAddress'] as bool? ?? false,
      verified: map['verified'] as bool? ?? false,
    );
  }

  /// The whole address on one line.
  String get fullAddress {
    final line2 = landmark;
    return [
      if (line2 != null && line2.isNotEmpty) line2,
      address,
      city,
      '$state $pincode',
    ].join(', ');
  }
}
