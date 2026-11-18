import 'negotiation.dart';

/// Which side of the Offers screen is shown (US-076): offers the person received as a seller, or the
/// offers they sent as a buyer.
enum OffersSide { received, sent }

/// The three lists of each side. The server also knows `ALL`, which the app does not use.
enum OffersFilter {
  /// Still in play: waiting for an answer from either side.
  pending,

  /// An accepted price that is still locked.
  accepted,

  /// Declined, withdrawn, expired or ended.
  closed;

  String get apiName => name.toUpperCase();
}

/// One side and one list, which is also the key of a loaded list.
typedef OffersQuery = (OffersSide side, OffersFilter filter);

/// One offer on the Offers screen, the same for both sides: the other person, the item, the price put
/// forward against the asking price, and the clocks. Received offers come from `GET /offers/received`;
/// sent ones are built from the buyer's negotiations.
class OfferCard {
  final String negotiationId;
  final NegotiationState state;

  /// The buyer for a received offer, the seller for a sent one.
  final String counterpartName;
  final num? counterpartRating;
  final int counterpartRatingCount;
  final String listingTitle;
  final String? thumbnailUrl;
  final num askingPrice;
  final num offeredPrice;
  final DateTime? offeredAt;
  final DateTime? expiresAt;
  final DateTime? priceLockExpiresAt;

  /// True when the person looking at the card is the one whose answer is awaited.
  final bool needsMyAnswer;

  /// The server's clock when it answered, so countdowns do not depend on the phone's clock.
  final DateTime serverTime;

  const OfferCard({
    required this.negotiationId,
    required this.state,
    required this.counterpartName,
    required this.listingTitle,
    required this.askingPrice,
    required this.offeredPrice,
    required this.needsMyAnswer,
    required this.serverTime,
    this.counterpartRating,
    this.counterpartRatingCount = 0,
    this.thumbnailUrl,
    this.offeredAt,
    this.expiresAt,
    this.priceLockExpiresAt,
  });

  /// An offer a seller received, from one item of `GET /offers/received`.
  factory OfferCard.received(Map<String, dynamic> json, DateTime serverTime) {
    final buyer = json['buyer'] as Map<String, dynamic>? ?? const {};
    final listing = json['listing'] as Map<String, dynamic>? ?? const {};
    final state = NegotiationState.from(json['state'] as String?);
    return OfferCard(
      negotiationId: json['negotiationId'] as String,
      state: state,
      counterpartName: buyer['displayName'] as String? ?? '',
      counterpartRating: buyer['rating'] as num?,
      counterpartRatingCount: (buyer['ratingCount'] as num?)?.toInt() ?? 0,
      listingTitle: listing['title'] as String? ?? '',
      thumbnailUrl: listing['thumbnailUrl'] as String?,
      askingPrice: listing['askingPrice'] as num? ?? 0,
      offeredPrice: json['offeredPrice'] as num? ?? 0,
      offeredAt: DateTime.tryParse(json['offeredAt'] as String? ?? ''),
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
      priceLockExpiresAt: DateTime.tryParse(json['priceLockExpiresAt'] as String? ?? ''),
      needsMyAnswer: state == NegotiationState.sellerReviewing,
      serverTime: serverTime,
    );
  }

  /// An offer the person sent as a buyer, from their negotiation.
  factory OfferCard.sent(Negotiation negotiation) {
    final last = negotiation.offers.isEmpty ? null : negotiation.offers.last;
    return OfferCard(
      negotiationId: negotiation.negotiationId,
      state: negotiation.state,
      counterpartName: negotiation.seller.displayName,
      listingTitle: negotiation.listing.title,
      thumbnailUrl: negotiation.listing.thumbnailUrl,
      askingPrice: negotiation.listing.askingPrice,
      offeredPrice: negotiation.agreedPrice ?? last?.amount ?? 0,
      offeredAt: last?.createdAt,
      expiresAt: negotiation.expiresAt,
      priceLockExpiresAt: negotiation.priceLockExpiresAt,
      needsMyAnswer: negotiation.state == NegotiationState.buyerReviewing,
      serverTime: negotiation.serverTime,
    );
  }

  /// A time passed while an answer was awaited: the offer shows as expired until the server says so.
  bool get isPastExpiry =>
      state.isAwaitingAnswer && expiresAt != null && !expiresAt!.isAfter(serverTime);
}

/// One page of offers for one list.
class OffersPage {
  final List<OfferCard> items;
  final int page;
  final bool hasNext;

  const OffersPage({required this.items, required this.page, required this.hasNext});

  /// A page of `GET /offers/received`.
  factory OffersPage.received(Map<String, dynamic> json) {
    final serverTime =
        DateTime.tryParse(json['serverTime'] as String? ?? '')?.toUtc() ?? DateTime.now().toUtc();
    return OffersPage(
      items: [
        for (final item in json['items'] as List<dynamic>? ?? const [])
          OfferCard.received(item as Map<String, dynamic>, serverTime),
      ],
      page: (json['page'] as num?)?.toInt() ?? 0,
      hasNext: json['hasNext'] == true,
    );
  }

  /// A page of the buyer's negotiations, narrowed to [filter]: the server lists open and closed ones,
  /// and a buyer holds few open negotiations at once, so the open list fits one page.
  factory OffersPage.sent(Map<String, dynamic> json, OffersFilter filter) {
    final all = [
      for (final item in json['items'] as List<dynamic>? ?? const [])
        Negotiation.fromJson(item as Map<String, dynamic>),
    ];
    final wanted = switch (filter) {
      OffersFilter.pending => all.where((n) => n.state.isAwaitingAnswer),
      OffersFilter.accepted => all.where((n) => n.state == NegotiationState.offerAccepted),
      OffersFilter.closed => all,
    };
    final cards = [for (final negotiation in wanted) OfferCard.sent(negotiation)];
    if (filter == OffersFilter.pending) {
      cards.sort((a, b) {
        final left = a.expiresAt;
        final right = b.expiresAt;
        if (left == null || right == null) return left == null ? (right == null ? 0 : 1) : -1;
        return left.compareTo(right);
      });
    }
    return OffersPage(
      items: cards,
      page: (json['page'] as num?)?.toInt() ?? 0,
      hasNext: json['hasNext'] == true,
    );
  }
}

/// What waits for the seller (`GET /offers/received/summary`).
class OffersSummary {
  final int pending;
  final int accepted;
  final int expiringSoon;

  const OffersSummary({this.pending = 0, this.accepted = 0, this.expiringSoon = 0});

  factory OffersSummary.fromJson(Map<String, dynamic> json) => OffersSummary(
        pending: (json['pending'] as num?)?.toInt() ?? 0,
        accepted: (json['accepted'] as num?)?.toInt() ?? 0,
        expiringSoon: (json['expiringSoon'] as num?)?.toInt() ?? 0,
      );
}
