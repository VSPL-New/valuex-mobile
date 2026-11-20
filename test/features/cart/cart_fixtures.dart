import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/features/cart/data/cart_repository.dart';
import 'package:valuex_mobile/features/cart/domain/cart.dart';

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
