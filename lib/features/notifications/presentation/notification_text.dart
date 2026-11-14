import '../../../l10n/app_localizations.dart';
import '../domain/app_notification.dart';

/// The title in the user's language for the listing messages (US-115); every other message, and a
/// listing message whose values are missing, shows the server's English text.
String notificationTitle(AppLocalizations l10n, AppNotification notification) {
  return switch (notification.eventType) {
    'LISTING_UNDER_REVIEW' => l10n.notifListingUnderReviewTitle,
    'LISTING_PUBLISHED' => l10n.notifListingPublishedTitle,
    'LISTING_REVISION_REQUIRED' => l10n.notifListingRevisionTitle,
    'LISTING_REJECTED_FINAL' => l10n.notifListingRejectedTitle,
    'LISTING_REFUND_DUE' => l10n.notifListingRefundTitle,
    'LISTING_PAYMENT_FAILED' => l10n.notifListingPaymentFailedTitle,
    'LISTING_EXPIRED' => l10n.notifListingExpiredTitle,
    'LISTING_REMOVED_BY_ADMIN' => l10n.notifListingRemovedTitle,
    'SAVED_SEARCH_MATCHES' => l10n.notifSavedSearchTitle,
    _ => notification.title,
  };
}

/// "N new items match "name": title; title and more." from the digest's values; null when the
/// count or name are missing, so the server's English text shows instead.
String? _savedSearchBody(AppLocalizations l10n, Map<String, dynamic> params) {
  final count = params['count'] is num ? (params['count'] as num).toInt() : null;
  final name = _text(params['name']);
  if (count == null || count < 1 || name == null) return null;
  final titles = [
    for (final title in params['titles'] as List<dynamic>? ?? const [])
      if (_text(title) != null) title as String,
  ];
  final head = l10n.notifSavedSearchBody(count, name);
  if (titles.isEmpty) return '$head.';
  final more = count > titles.length ? ' ${l10n.notifSavedSearchAndMore}' : '';
  return '$head: ${titles.join('; ')}$more.';
}

String notificationBody(AppLocalizations l10n, AppNotification notification) {
  final params = notification.params;
  final title = _text(params['title']);
  final reason = _text(params['reason']);
  final amount = _text(params['amount']);
  final attempt = params['attempt'] is num ? (params['attempt'] as num).toInt() : null;
  final localized = switch (notification.eventType) {
    'LISTING_UNDER_REVIEW' => l10n.notifListingUnderReviewBody,
    'LISTING_PUBLISHED' => title == null ? null : l10n.notifListingPublishedBody(title),
    'LISTING_REVISION_REQUIRED' => title == null || reason == null
        ? null
        : attempt == null
            ? l10n.notifListingRevisionEditBody(title, reason)
            : l10n.notifListingRevisionBody(title, reason, attempt),
    'LISTING_REJECTED_FINAL' => title == null
        ? null
        : amount == null
            ? l10n.notifListingRejectedBody(title)
            : l10n.notifListingRejectedRefundBody(title, amount),
    'LISTING_REFUND_DUE' => amount == null ? null : l10n.notifListingRefundBody(amount),
    'LISTING_PAYMENT_FAILED' => l10n.notifListingPaymentFailedBody,
    'LISTING_EXPIRED' => title == null ? null : l10n.notifListingExpiredBody(title),
    'LISTING_REMOVED_BY_ADMIN' => title == null ? null : l10n.notifListingRemovedBody(title),
    'SAVED_SEARCH_MATCHES' => _savedSearchBody(l10n, params),
    _ => null,
  };
  return localized ?? notification.body;
}

String? _text(Object? value) => value is String && value.isNotEmpty ? value : null;
