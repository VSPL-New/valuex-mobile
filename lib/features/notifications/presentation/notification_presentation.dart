import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/app_notification.dart';

String notificationCategoryLabel(AppLocalizations l10n, NotificationCategory category) {
  return switch (category) {
    NotificationCategory.account => l10n.notificationsTabAccount,
    NotificationCategory.orders => l10n.notificationsTabOrders,
    NotificationCategory.messages => l10n.notificationsTabMessages,
    NotificationCategory.listings => l10n.notificationsTabListings,
    NotificationCategory.others => l10n.notificationsTabOthers,
  };
}

/// The icon in front of a notification: its own for known account events, else its tab's.
IconData notificationIcon(AppNotification notification) {
  return switch (notification.eventType) {
    'ACCOUNT_CREATED' => Icons.celebration_outlined,
    'AADHAAR_VERIFIED' => Icons.verified_user_outlined,
    'ACCOUNT_UNDER_REVIEW' => Icons.flag_outlined,
    'ACCOUNT_SUSPENDED' => Icons.block,
    'ACCOUNT_BANNED' => Icons.gavel,
    'LISTING_UNDER_REVIEW' => Icons.hourglass_top_outlined,
    'LISTING_PUBLISHED' => Icons.check_circle_outline,
    'LISTING_REVISION_REQUIRED' => Icons.edit_note_outlined,
    'LISTING_REJECTED_FINAL' => Icons.cancel_outlined,
    'LISTING_REFUND_DUE' => Icons.currency_rupee,
    'LISTING_PAYMENT_FAILED' => Icons.credit_card_off_outlined,
    'LISTING_EXPIRED' => Icons.timer_off_outlined,
    'LISTING_REMOVED_BY_ADMIN' => Icons.remove_circle_outline,
    'SAVED_SEARCH_MATCHES' => Icons.notifications_active_outlined,
    'SAVED_LISTING_UNAVAILABLE' => Icons.heart_broken_outlined,
    _ => switch (notification.category) {
        NotificationCategory.account => Icons.person_outline,
        NotificationCategory.orders => Icons.inventory_2_outlined,
        NotificationCategory.messages => Icons.chat_bubble_outline,
        NotificationCategory.listings => Icons.sell_outlined,
        NotificationCategory.others => Icons.notifications_none,
      },
  };
}

/// "Just now", "5 minutes ago", "2 hours ago", "3 days ago", then the date.
String notificationTimeLabel(BuildContext context, DateTime createdAt, {DateTime? now}) {
  final l10n = AppLocalizations.of(context);
  final elapsed = (now ?? DateTime.now()).difference(createdAt);
  if (elapsed.inMinutes < 1) return l10n.notificationJustNow;
  if (elapsed.inHours < 1) return l10n.notificationMinutesAgo(elapsed.inMinutes);
  if (elapsed.inDays < 1) return l10n.notificationHoursAgo(elapsed.inHours);
  if (elapsed.inDays < 7) return l10n.notificationDaysAgo(elapsed.inDays);
  return DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(createdAt);
}
