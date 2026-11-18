import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/negotiation/presentation/negotiation_error_messages.dart';
import 'package:valuex_mobile/features/notifications/domain/app_notification.dart';
import 'package:valuex_mobile/features/notifications/domain/notification_deep_links.dart';
import 'package:valuex_mobile/features/notifications/presentation/notification_text.dart';
import 'package:valuex_mobile/l10n/app_localizations_en.dart';
import 'package:valuex_mobile/l10n/app_localizations_hi.dart';

final _en = AppLocalizationsEn();
final _hi = AppLocalizationsHi();

AppNotification _n(String eventType, {Map<String, dynamic> params = const {}}) => AppNotification(
      id: 'n-$eventType',
      eventType: eventType,
      title: 'Server title',
      body: 'Server body',
      deepLink: '/negotiations/n1',
      params: params,
      priority: NotificationPriority.medium,
      read: false,
      createdAt: DateTime.now(),
    );

ApiError _error(String code, {Map<String, String> details = const {}, ApiErrorType? type}) =>
    ApiError(
      type: type ?? ApiErrorType.business,
      message: 'server words',
      code: code,
      statusCode: 409,
      details: details,
    );

void main() {
  buyNowNotificationTests();
  group('offer notifications', () {
    const params = {'listingTitle': 'Apple Watch', 'amount': '12000.00'};

    test('are shown in English from their values', () {
      expect(
          notificationTitle(_en, _n('OFFER_RECEIVED', params: params)), 'New offer on Apple Watch');
      expect(
          notificationBody(_en, _n('OFFER_RECEIVED', params: params)), 'A buyer offered ₹12,000');
      expect(notificationTitle(_en, _n('OFFER_COUNTERED', params: params)),
          'Counter offer on Apple Watch');
      expect(
        notificationBody(_en, _n('OFFER_COUNTERED', params: params)),
        'The other side countered with ₹12,000',
      );
      expect(notificationTitle(_en, _n('OFFER_ACCEPTED', params: params)),
          'Offer accepted for Apple Watch');
      expect(notificationBody(_en, _n('OFFER_ACCEPTED', params: params)),
          'The price ₹12,000 is agreed');
      expect(notificationTitle(_en, _n('OFFER_REJECTED', params: params)),
          'Offer declined for Apple Watch');
      expect(notificationBody(_en, _n('OFFER_REJECTED', params: params)),
          'The offer of ₹12,000 was declined');
      expect(
        notificationTitle(_en, _n('OFFER_WITHDRAWN', params: params)),
        'Offer withdrawn for Apple Watch',
      );
      expect(notificationBody(_en, _n('OFFER_WITHDRAWN', params: params)),
          'The buyer withdrew the offer');
      expect(
        notificationTitle(
            _en, _n('NEGOTIATION_CANCELLED', params: {'listingTitle': 'Apple Watch'})),
        'Negotiation ended for Apple Watch',
      );
      expect(
        notificationBody(_en, _n('NEGOTIATION_CANCELLED', params: {'listingTitle': 'Apple Watch'})),
        'This item is no longer available',
      );
    });

    test('tell a declined buyer neutrally, with no price', () {
      expect(notificationTitle(_en, _n('OFFER_SUPERSEDED', params: params)),
          'Offer closed for Apple Watch');
      expect(
        notificationBody(_en, _n('OFFER_SUPERSEDED', params: {'listingTitle': 'Apple Watch'})),
        'The seller accepted another offer for this item. You can make a new offer if it becomes available again',
      );
      expect(notificationBody(_hi, _n('OFFER_SUPERSEDED', params: params)), isNot(contains('₹')));
      expect(notificationCategoryOf('OFFER_SUPERSEDED'), NotificationCategory.messages);
    });

    test('are shown in Hindi', () {
      expect(
          notificationTitle(_hi, _n('OFFER_RECEIVED', params: params)), 'Apple Watch पर नया ऑफ़र');
      expect(
        notificationBody(_hi, _n('OFFER_RECEIVED', params: params)),
        'एक खरीदार ने ₹12,000 का ऑफ़र दिया',
      );
      expect(notificationTitle(_hi, _n('OFFER_ACCEPTED', params: params)), isNot('Server title'));
    });

    test('fall back to the server text when a value is missing or the type is unknown', () {
      expect(notificationTitle(_en, _n('OFFER_RECEIVED')), 'Server title');
      expect(notificationBody(_en, _n('OFFER_RECEIVED', params: {'listingTitle': 'Apple Watch'})),
          'Server body');
      expect(notificationBody(_en, _n('OFFER_RECEIVED', params: {'amount': 'abc'})), 'Server body');
      expect(notificationTitle(_en, _n('OFFER_SOMETHING', params: params)), 'Server title');
      expect(notificationBody(_en, _n('OFFER_SOMETHING', params: params)), 'Server body');
    });

    test('are listed under Messages', () {
      expect(notificationCategoryOf('OFFER_RECEIVED'), NotificationCategory.messages);
      expect(notificationCategoryOf('NEGOTIATION_CANCELLED'), NotificationCategory.messages);
    });
  });

  group('negotiation deep link', () {
    test('opens that negotiation', () {
      final target = notificationTargetFor('/negotiations/abc-123')!;

      expect(target.route, '/negotiations/abc-123');
      expect(target.isTab, isFalse);
      expect(target.needsListing, isFalse);
    });

    test('is not built without an id', () {
      expect(notificationTargetFor('/negotiations'), isNull);
      expect(notificationTargetFor('/negotiations/'), isNull);
    });
  });

  group('negotiationErrorMessage', () {
    test('says the range of a refused offer and counter, without needless decimals', () {
      expect(
        negotiationErrorMessage(
            _en, _error('ERROR_INVALID_OFFER', details: {'min': '1', 'max': '14500.00'})),
        'Offer must be between ₹1 and ₹14,500',
      );
      expect(
        negotiationErrorMessage(
          _en,
          _error('ERROR_INVALID_COUNTER', details: {'min': '12000.01', 'max': '14500.00'}),
        ),
        'Counter offer must be between ₹12,000.01 and ₹14,500',
      );
    });

    test('has words for a refusal that carries no range', () {
      expect(negotiationErrorMessage(_en, _error('ERROR_INVALID_OFFER')),
          'This item is no longer available');
      expect(negotiationErrorMessage(_en, _error('ERROR_INVALID_COUNTER')),
          'This offer has changed. The latest is shown');
    });

    test('maps every negotiation code to its own text', () {
      const expected = {
        'ERROR_MAX_NEGOTIATIONS': 'Maximum negotiation attempts reached',
        'WARNING_MAX_NEGOTIATIONS': 'Maximum negotiation rounds reached',
        'ERROR_NEGOTIATION_EXPIRED': 'This negotiation has expired',
        'ERROR_NOT_NEGOTIABLE': 'This listing does not take offers',
        'ERROR_NEGOTIATION_EXISTS': 'You already have an open negotiation on this listing',
        'ERROR_NEGOTIATION_COOLDOWN': 'You can make a new offer on this item later',
        'ERROR_TOO_MANY_NEGOTIATIONS':
            'You have too many open negotiations. Finish or cancel one first',
        'ERROR_OFFER_NOT_CURRENT': 'This offer has changed. The latest is shown',
        'ERROR_ITEM_RESERVED': 'This item is reserved for another buyer right now',
        'ERROR_ITEM_UNAVAILABLE': 'This item is no longer available',
        'ERROR_ALREADY_ACCEPTED': 'A price for this item has already been accepted',
        'AADHAAR_VERIFICATION_REQUIRED': 'Complete Aadhaar verification to make an offer',
        'RATE_LIMIT_EXCEEDED': 'Too many offers. Try again in a minute',
      };
      expected.forEach((code, text) {
        expect(negotiationErrorMessage(_en, _error(code)), text, reason: code);
      });
    });

    test('falls back to the contact texts, then to the general ones', () {
      expect(negotiationErrorMessage(_en, _error('ERROR_BLOCKED')), contains('cannot contact'));
      expect(
        negotiationErrorMessage(_en, _error('ERROR_OWN_LISTING')),
        isNotEmpty,
      );
      expect(negotiationErrorMessage(_en, StateError('x')), isNotEmpty);
      expect(
        negotiationErrorMessage(_en, _error(null.toString(), type: ApiErrorType.network)),
        isNotEmpty,
      );
    });

    test('is available in Hindi', () {
      expect(negotiationErrorMessage(_hi, _error('ERROR_ITEM_RESERVED')),
          isNot('This item is reserved for another buyer right now'));
    });
  });
}

void buyNowNotificationTests() {
  group('Buy Now price change notification (US-068)', () {
    const params = {'listingTitle': 'Apple Watch'};

    test('is shown in English and in Hindi from its values', () {
      final notification = _n('BUY_NOW_PRICE_CHANGED', params: params);

      expect(notificationTitle(_en, notification), 'Price changed for Apple Watch');
      expect(notificationBody(_en, notification), 'Please review the new price');
      expect(notificationTitle(_hi, notification), 'Apple Watch की कीमत बदल गई');
      expect(notificationBody(_hi, notification), 'कृपया नई कीमत देखें');
    });

    test('shows the server English text when the title is missing', () {
      expect(notificationTitle(_en, _n('BUY_NOW_PRICE_CHANGED')), 'Server title');
    });

    test('opens the listing from its link', () {
      expect(notificationTargetFor('/listings/l1')?.route, '/listing/l1');
      expect(notificationTargetFor('/listings/'), isNull);
    });
  });
}
