enum NotificationPriority { high, medium, low }

/// Which tab a notification is listed under, decided from its backend `eventType`.
enum NotificationCategory { account, orders, messages, listings, others }

/// State changes that need the user's attention; shown in the error colour.
const Set<String> _alertEventTypes = {
  'ACCOUNT_UNDER_REVIEW',
  'ACCOUNT_SUSPENDED',
  'ACCOUNT_BANNED',
};

const Map<NotificationCategory, List<String>> _categoryPrefixes = {
  NotificationCategory.account: ['ACCOUNT_', 'AADHAAR_'],
  NotificationCategory.orders: [
    'ORDER_',
    'PAYMENT_',
    'ESCROW_',
    'SHIPMENT_',
    'DELIVERY_',
    'PICKUP_',
    'RETURN_',
    'REFUND_',
  ],
  NotificationCategory.messages: ['MESSAGE_', 'CHAT_', 'OFFER_', 'NEGOTIATION_'],
  NotificationCategory.listings: ['LISTING_'],
};

/// Event types this app does not know yet fall under [NotificationCategory.others].
NotificationCategory notificationCategoryOf(String eventType) {
  final type = eventType.toUpperCase();
  for (final entry in _categoryPrefixes.entries) {
    if (entry.value.any(type.startsWith)) return entry.key;
  }
  return NotificationCategory.others;
}

/// Named `AppNotification` because Flutter already has a `Notification` widget class.
class AppNotification {
  final String id;
  final String eventType;
  final String title;
  final String body;

  /// A path inside the app as the backend sends it, for example `/profile`.
  final String? deepLink;
  final NotificationPriority priority;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.eventType,
    required this.title,
    required this.body,
    required this.priority,
    required this.read,
    required this.createdAt,
    this.deepLink,
  });

  NotificationCategory get category => notificationCategoryOf(eventType);

  bool get isAlert => _alertEventTypes.contains(eventType);

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        eventType: eventType,
        title: title,
        body: body,
        deepLink: deepLink,
        priority: priority,
        read: read ?? this.read,
        createdAt: createdAt,
      );
}

/// One page of notifications, newest first, with the account's total unread count.
class NotificationsPage {
  final List<AppNotification> items;
  final int page;
  final bool hasMore;
  final int unread;

  const NotificationsPage({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.unread,
  });
}
