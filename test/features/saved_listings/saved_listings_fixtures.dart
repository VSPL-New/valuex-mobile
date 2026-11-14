import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/features/saved_listings/data/saved_listings_repository.dart';
import 'package:valuex_mobile/features/saved_listings/domain/saved_listing.dart';

Map<String, dynamic> savedListingJson(
  String id, {
  String title = 'Apple iPhone 14',
  num? price = 42000,
  String? condition = 'LIKE_NEW',
  bool available = true,
  String? reason,
  bool photo = true,
}) =>
    {
      'listingId': id,
      'title': title,
      'price': price,
      'condition': condition,
      'photo': available && photo
          ? {
              'thumbnailUrl': 'https://media.example/thumb.jpg',
              'cardUrl': 'https://media.example/card.jpg'
            }
          : null,
      'available': available,
      'unavailableReason': available ? null : reason ?? 'SOLD',
      'savedAt': '2026-11-14T10:00:00Z',
    };

Map<String, dynamic> savedPageJson(
  List<Map<String, dynamic>> items, {
  int page = 0,
  bool hasNext = false,
  int? total,
  int maxSaved = 200,
}) =>
    {
      'items': items,
      'page': page,
      'size': 20,
      'totalItems': total ?? items.length,
      'hasNext': hasNext,
      'maxSaved': maxSaved,
    };

SavedListingsPage savedPage(
  List<Map<String, dynamic>> items, {
  int page = 0,
  bool hasNext = false,
  int? total,
}) =>
    SavedListingsPage.fromJson(savedPageJson(items, page: page, hasNext: hasNext, total: total));

/// A saved-listings repository that answers from callbacks and records the calls.
class FakeSavedListingsRepository extends Fake implements SavedListingsRepository {
  Future<SavedListingsPage> Function(int page) onList = (page) async => savedPage(const []);
  Future<void> Function(String id) onSave = (id) async {};
  Future<void> Function(String id) onRemove = (id) async {};

  final List<int> listed = [];
  final List<String> saved = [];
  final List<String> removed = [];

  @override
  Future<SavedListingsPage> list({int page = 0}) {
    listed.add(page);
    return onList(page);
  }

  @override
  Future<void> save(String listingId) {
    saved.add(listingId);
    return onSave(listingId);
  }

  @override
  Future<void> remove(String listingId) {
    removed.add(listingId);
    return onRemove(listingId);
  }
}
