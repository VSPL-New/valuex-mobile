import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_page.dart';
import '../domain/app_notification.dart';

/// Backend header that carries the account's unread count on every list response.
const String unreadHeader = 'x-unread-notifications';

class NotificationsRepository {
  static const int pageSize = 20;

  final ApiClient _client;

  NotificationsRepository(this._client);

  Future<NotificationsPage> page(int page, {int size = pageSize}) async {
    final result = await _client.getPage(
      ApiConstants.notifications,
      queryParameters: {'page': page, 'size': size},
      parseItem: _notification,
    );
    return NotificationsPage(
      items: result.items,
      page: result.page,
      hasMore: result.hasMore,
      unread: _unread(result) ?? result.items.where((n) => !n.read).length,
    );
  }

  /// The count alone: asks for a single item, since only the header is needed.
  Future<int> unreadCount() async {
    final result = await _client.getPage(
      ApiConstants.notifications,
      queryParameters: {'page': 0, 'size': 1},
      parseItem: _notification,
    );
    return _unread(result) ?? 0;
  }

  Future<void> markRead(String id) => _client.patch<void>(ApiConstants.notificationRead(id));

  /// Marks every unread notification of the account as read.
  Future<void> markAllRead() => _client.patch<void>(ApiConstants.notificationsReadAll);

  static int? _unread(ApiPage<AppNotification> page) {
    final value = int.tryParse(page.headers.value(unreadHeader) ?? '');
    return value == null || value < 0 ? null : value;
  }

  static AppNotification _notification(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        eventType: json['eventType'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        deepLink: _link(json['deepLink']),
        priority: _priority(json['priority']),
        read: json['read'] == true,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      );

  static String? _link(Object? value) => value is String && value.startsWith('/') ? value : null;

  static NotificationPriority _priority(Object? value) => switch (value) {
        'HIGH' => NotificationPriority.high,
        'LOW' => NotificationPriority.low,
        _ => NotificationPriority.medium,
      };
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(apiClientProvider)),
);
