import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_client.dart';
import '../../search/domain/search_listing.dart';
import '../../search/presentation/search_labels.dart';
import '../domain/entities/home_badges.dart';
import '../domain/entities/home_location.dart';
import '../domain/entities/listing.dart';
import '../domain/entities/promo.dart';
import '../domain/repositories/home_repository.dart';

/// Home content from the server (US-111): the featured listings near the chosen place and the
/// active promos. Only the city and state of the place go along, so the server can rank nearby
/// listings first; the area, pincode and coordinates are never sent.
class ApiHomeRepository implements HomeRepository {
  final ApiClient _client;

  const ApiHomeRepository(this._client);

  @override
  Future<List<Promo>> promos() => _client.get(
        ApiConstants.homePromos,
        parse: (json) => [
          for (final entry in json as List<dynamic>)
            if (_promo(entry as Map<String, dynamic>) case final promo?) promo,
        ],
      );

  @override
  Future<List<Listing>> featuredListings(HomeLocation location) {
    final state = location.state;
    return _client.get(
      ApiConstants.homeFeatured,
      queryParameters: {
        if (location.city.isNotEmpty) 'city': location.city,
        if (state != null && state.isNotEmpty) 'state': state,
      },
      parse: (json) => [
        for (final item in (json as Map<String, dynamic>)['items'] as List<dynamic>)
          SearchListing.fromJson(item as Map<String, dynamic>).toCardListing(),
      ],
    );
  }

  /// The cart is not built yet (Sprint 5), so its count is zero. The unread notification count
  /// comes from the notifications repository, not from here.
  @override
  Future<HomeBadges> badges() async => const HomeBadges();

  /// A promo whose target this app cannot open is left out.
  static Promo? _promo(Map<String, dynamic> json) {
    final target = json['target'] as Map<String, dynamic>?;
    final type = PromoTargetType.fromApi(target?['type'] as String?);
    final value = target?['value'] as String?;
    if (type == null || value == null) return null;
    return Promo(
      id: json['id'] as String,
      badge: json['badge'] as String? ?? '',
      title: json['title'] as String,
      body: json['body'] as String? ?? '',
      ctaLabel: json['ctaLabel'] as String,
      image: AppAssets.promoArtwork[json['imageKey']] ?? '',
      target: PromoTarget(type: type, value: value),
    );
  }
}
