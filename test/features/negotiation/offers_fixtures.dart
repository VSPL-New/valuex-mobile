import 'package:valuex_mobile/features/negotiation/domain/offers.dart';

import 'negotiation_fixtures.dart';

/// One item of `GET /offers/received`; a seller's pending offer of 12,000 on a 14,500 watch by default.
Map<String, dynamic> receivedJson({
  String id = 'n1',
  String state = 'SELLER_REVIEWING',
  String buyer = 'Ravi K',
  num? rating,
  int ratingCount = 0,
  String title = 'Apple Watch',
  num offered = 12000,
  num asking = 14500,
  String? expiresAt = '2026-11-17T14:20:00Z',
  String? lockEndsAt,
  String? offerId = 'o1',
  String? thumbnailUrl,
}) =>
    {
      'negotiationId': id,
      'offerId': offerId,
      'state': state,
      'buyer': {
        'userId': 'u-$id',
        'displayName': buyer,
        'rating': rating,
        'ratingCount': ratingCount,
      },
      'listing': {
        'listingId': 'l-$id',
        'title': title,
        'thumbnailUrl': thumbnailUrl,
        'askingPrice': asking,
      },
      'offeredPrice': offered,
      'offeredAt': '2026-11-17T08:00:00Z',
      'round': 1,
      'expiresAt': expiresAt,
      'priceLockExpiresAt': lockEndsAt,
    };

/// A page of `GET /offers/received`.
Map<String, dynamic> receivedPageJson(
  List<Map<String, dynamic>> items, {
  int page = 0,
  bool hasNext = false,
}) =>
    {
      'items': items,
      'page': page,
      'size': 20,
      'totalItems': items.length,
      'hasNext': hasNext,
      'serverTime': '2026-11-17T10:00:00Z',
    };

/// A page of `GET /negotiations`.
Map<String, dynamic> negotiationsPageJson(
  List<Map<String, dynamic>> items, {
  int page = 0,
  bool hasNext = false,
}) =>
    {
      'items': items,
      'page': page,
      'size': 20,
      'totalItems': items.length,
      'hasNext': hasNext,
      'serverTime': '2026-11-17T10:00:00Z',
    };

OffersPage receivedPage(
  List<Map<String, dynamic>> items, {
  int page = 0,
  bool hasNext = false,
}) =>
    OffersPage.received(receivedPageJson(items, page: page, hasNext: hasNext));

OffersPage sentPage(
  List<Map<String, dynamic>> items, {
  OffersFilter filter = OffersFilter.pending,
  int page = 0,
  bool hasNext = false,
}) =>
    OffersPage.sent(negotiationsPageJson(items, page: page, hasNext: hasNext), filter);

/// The buyer's own negotiation JSON for the Sent tab: waiting for the seller by default.
Map<String, dynamic> sentJson({
  String id = 'n9',
  String state = 'SELLER_REVIEWING',
  String awaiting = 'SELLER',
  String? expiresAt = '2026-11-17T14:20:00Z',
  num? agreedPrice,
  String? priceLockExpiresAt,
  List<Map<String, dynamic>>? offers,
}) =>
    negotiationJson(
      id: id,
      state: state,
      awaiting: awaiting,
      expiresAt: expiresAt,
      agreedPrice: agreedPrice,
      priceLockExpiresAt: priceLockExpiresAt,
      offers: offers,
    );
