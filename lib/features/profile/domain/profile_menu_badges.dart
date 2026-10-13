/// Keys of the `badges` map in `GET /users/me/menu-summary` (LLD Sprint 1 section 8.3). A key is
/// absent until the story that owns it ships, so a row without a key simply shows no badge.
class ProfileMenuKeys {
  ProfileMenuKeys._();

  static const String myOrders = 'MY_ORDERS';
  static const String incomingOrders = 'INCOMING_ORDERS';
  static const String myListings = 'MY_LISTINGS';
  static const String savedItems = 'SAVED_ITEMS';
  static const String transactions = 'TRANSACTIONS';
  static const String payouts = 'PAYOUTS';
  static const String notifications = 'NOTIFICATIONS';
  static const String supportTickets = 'SUPPORT_TICKETS';
  static const String disputes = 'DISPUTES';
}

/// Counts of items that need the user's attention, per profile menu row.
class ProfileMenuBadges {
  final Map<String, int> _counts;

  const ProfileMenuBadges([this._counts = const {}]);

  /// Zero when the key is absent.
  int count(String key) => _counts[key] ?? 0;
}
