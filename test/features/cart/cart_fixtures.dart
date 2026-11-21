import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/features/address/data/address_repository.dart';
import 'package:valuex_mobile/features/address/domain/address_details.dart';
import 'package:valuex_mobile/features/address/domain/address_search_service.dart';
import 'package:valuex_mobile/features/address/domain/address_suggestion.dart';
import 'package:valuex_mobile/features/address/domain/saved_address.dart';
import 'package:valuex_mobile/features/cart/data/cart_repository.dart';
import 'package:valuex_mobile/features/cart/domain/cart.dart';
import 'package:valuex_mobile/features/cart/domain/delivery.dart';

class MockCartRepository extends Mock implements CartRepository {}

final DateTime cartServerTime = DateTime.utc(2026, 11, 19, 10);

Map<String, dynamic> lineJson(
  String id, {
  String listingId = 'l1',
  String? title = 'Hero phone',
  Object agreedPrice = '4500.50',
  Object? currentPrice = '4500.50',
  String status = 'ACCEPTED',
  String? problem,
  DateTime? agreementValidUntil,
  DateTime? expiresAt,
  Map<String, dynamic>? delivery,
}) =>
    {
      'itemId': id,
      'listingId': listingId,
      'title': title,
      'imageUrl': null,
      'agreedPrice': agreedPrice,
      'currentPrice': currentPrice,
      'status': status,
      'agreementValidUntil':
          (agreementValidUntil ?? cartServerTime.add(const Duration(minutes: 14)))
              .toIso8601String(),
      'addedAt': cartServerTime.subtract(const Duration(minutes: 5)).toIso8601String(),
      'expiresAt': (expiresAt ?? cartServerTime.add(const Duration(hours: 23))).toIso8601String(),
      'problem': problem,
      if (delivery != null) 'delivery': delivery,
    };

Map<String, dynamic> groupJson(String sellerId, String? name, List<Map<String, dynamic>> items) =>
    {'sellerId': sellerId, 'sellerName': name, 'items': items};

CartData cartOf(List<Map<String, dynamic>> groups, {int? valid}) {
  final lines = [
    for (final group in groups) ...(group['items'] as List<Map<String, dynamic>>),
  ];
  return CartData.fromJson({
    'cartId': lines.isEmpty ? null : 'c1',
    'serverTime': cartServerTime.toIso8601String(),
    'itemCount': lines.length,
    'validCount': valid ?? lines.where((line) => line['status'] == 'ACCEPTED').length,
    'groups': groups,
  });
}

AddedLine addedLine({bool created = true, String id = 'i1', String listingId = 'l1'}) =>
    AddedLine(line: CartLine.fromJson(lineJson(id, listingId: listingId)), created: created);

class MockAddressRepository extends Mock implements AddressRepository {}

/// An address search the tests drive: it suggests one place and fills the form with it.
class FakeAddressSearch implements AddressSearchService {
  @override
  Future<List<AddressSuggestion>> suggest(String query, {required String sessionToken}) async =>
      const [
        AddressSuggestion(
          placeId: 'p1',
          primaryText: '4 Residency Road',
          secondaryText: 'Shanti Nagar, Bengaluru',
        ),
      ];

  @override
  Future<AddressDetails> details(String placeId, {required String sessionToken}) async =>
      const AddressDetails(
        line1: '4 Residency Road, Shanti Nagar',
        city: 'Bengaluru',
        state: 'Karnataka',
        pincode: '560025',
        placeId: 'p1',
      );
}

const SavedAddress homeAddress = SavedAddress(
  id: 'a1',
  label: 'Home',
  address: '12 MG Road, Indiranagar',
  landmark: 'Flat 4',
  city: 'Bengaluru',
  state: 'Karnataka',
  pincode: '560038',
  isDefault: true,
);

const SavedAddress officeAddress = SavedAddress(
  id: 'a2',
  label: 'Office',
  address: '9 Baner Road',
  city: 'Pune',
  state: 'Maharashtra',
  pincode: '411045',
);

Map<String, dynamic> deliveryJson({
  String? mode,
  String? addressId,
  Object? cost,
  String? eta,
  String? payment,
  String? warning,
}) =>
    {
      'mode': mode,
      'addressId': addressId,
      'shippingCost': cost,
      'shippingEta': eta,
      'paymentOption': payment,
      'warning': warning,
    };

Map<String, dynamic> optionsJson({
  String itemId = 'i1',
  bool delivery = true,
  Object? cost,
  String? eta,
  String? warning,
  bool pickup = true,
  Map<String, dynamic>? place = const {
    'line1': '4 FC Road',
    'city': 'Pune',
    'state': 'Maharashtra',
    'pincode': '411004',
  },
}) =>
    {
      'itemId': itemId,
      'delivery': {
        'available': delivery,
        'reason': delivery ? null : 'ERROR_NO_DELIVERY_AVAILABLE',
        'cost': cost,
        'etaDate': eta,
        'courierName': cost == null ? null : 'Standard delivery',
        'warning': warning,
      },
      'selfPickup': {
        'available': pickup,
        'reason': pickup ? null : 'ERROR_NO_SELF_PICKUP',
        'pickupAddress': pickup ? place : null,
        'sellerDisplayName': pickup ? 'Asha K' : null,
      },
    };

DeliveryOptions optionsOf({
  bool delivery = true,
  Object? cost,
  String? eta,
  String? warning,
  bool pickup = true,
}) =>
    DeliveryOptions.fromJson(
      optionsJson(delivery: delivery, cost: cost, eta: eta, warning: warning, pickup: pickup),
    );
