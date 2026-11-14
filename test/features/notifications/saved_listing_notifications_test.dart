import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/notifications/domain/app_notification.dart';
import 'package:valuex_mobile/features/notifications/domain/notification_deep_links.dart';
import 'package:valuex_mobile/features/notifications/presentation/notification_presentation.dart';
import 'package:valuex_mobile/features/notifications/presentation/notification_text.dart';
import 'package:valuex_mobile/l10n/app_localizations_en.dart';
import 'package:valuex_mobile/l10n/app_localizations_hi.dart';

final _en = AppLocalizationsEn();
final _hi = AppLocalizationsHi();

AppNotification _gone({
  Map<String, dynamic>? params,
  String deepLink = '/saved-items',
  String body = 'Server body',
}) =>
    AppNotification(
      id: 'n1',
      eventType: 'SAVED_LISTING_UNAVAILABLE',
      title: 'Server title',
      body: body,
      deepLink: deepLink,
      params: params ?? {'listingId': 'l1', 'reason': 'SOLD', 'title': 'Hero phone'},
      priority: NotificationPriority.medium,
      read: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    );

void main() {
  group('saved listing notification text', () {
    test('has a title in English and Hindi', () {
      expect(notificationTitle(_en, _gone()), 'A saved item is no longer available');
      expect(notificationTitle(_hi, _gone()), isNot('Server title'));
    });

    test('says why, with the title, for each reason', () {
      String body(String reason, [AppLocalizationsEn? l10n]) => notificationBody(
            l10n ?? _en,
            _gone(params: {'reason': reason, 'title': 'Hero phone'}),
          );

      expect(body('SOLD'), '"Hero phone" has been sold.');
      expect(body('EXPIRED'), '"Hero phone" has expired.');
      expect(body('REMOVED'), '"Hero phone" has been removed.');
      expect(body('DELETED'), '"Hero phone" has been removed.');
      expect(body('SELLER_SUSPENDED'), '"Hero phone" is no longer available.');
    });

    test('has Hindi text that names the listing', () {
      for (final reason in ['SOLD', 'EXPIRED', 'REMOVED', 'SELLER_SUSPENDED']) {
        final hindi =
            notificationBody(_hi, _gone(params: {'reason': reason, 'title': 'Hero phone'}));

        expect(hindi, contains('Hero phone'));
        expect(hindi, isNot('Server body'));
      }
    });

    test('falls back to the server text when the title or reason is missing or unknown', () {
      expect(notificationBody(_en, _gone(params: {'reason': 'SOLD', 'title': ''})), 'Server body');
      expect(notificationBody(_en, _gone(params: {'reason': 'SOLD'})), 'Server body');
      expect(notificationBody(_en, _gone(params: {'title': 'Hero phone'})), 'Server body');
      expect(
        notificationBody(_en, _gone(params: {'reason': 'NEW_ONE', 'title': 'Hero phone'})),
        'Server body',
      );
    });
  });

  group('saved listing notification link and icon', () {
    test('opens Saved Items', () {
      final target = notificationTargetFor('/saved-items');

      expect(target!.route, RouteNames.savedItems);
      expect(target.isTab, isFalse);
    });

    test('has its own icon', () {
      expect(notificationIcon(_gone()), Icons.heart_broken_outlined);
    });
  });
}
