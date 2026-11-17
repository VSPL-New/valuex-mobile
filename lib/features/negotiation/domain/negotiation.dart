/// Where a negotiation stands (US-017). Only the states the server stores are named; anything else
/// reads as [other] and shows no actions.
enum NegotiationState {
  sellerReviewing,
  buyerReviewing,
  offerAccepted,
  offerRejected,
  expired,
  cancelled,
  converted,
  other;

  static NegotiationState from(String? value) => switch (value) {
        'SELLER_REVIEWING' => sellerReviewing,
        'BUYER_REVIEWING' => buyerReviewing,
        'OFFER_ACCEPTED' => offerAccepted,
        'OFFER_REJECTED' => offerRejected,
        'NEGOTIATION_EXPIRED' => expired,
        'NEGOTIATION_CANCELLED' => cancelled,
        'NEGOTIATION_CONVERTED' => converted,
        _ => other,
      };

  /// An answer is awaited from one of the two people.
  bool get isAwaitingAnswer => this == sellerReviewing || this == buyerReviewing;
}

/// Which side of a negotiation a person or an offer is on.
enum NegotiationRole {
  buyer,
  seller;

  static NegotiationRole from(String? value) => value == 'SELLER' ? seller : buyer;

  NegotiationRole get other => this == buyer ? seller : buyer;
}

/// One price put forward in a negotiation.
class NegotiationOffer {
  final String offerId;
  final NegotiationRole party;
  final num amount;
  final int round;
  final String status;
  final DateTime? createdAt;

  const NegotiationOffer({
    required this.offerId,
    required this.party,
    required this.amount,
    required this.round,
    required this.status,
    this.createdAt,
  });

  bool get isPending => status == 'PENDING';

  factory NegotiationOffer.fromJson(Map<String, dynamic> json) => NegotiationOffer(
        offerId: json['offerId'] as String,
        party: NegotiationRole.from(json['party'] as String?),
        amount: json['amount'] as num? ?? 0,
        round: (json['round'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}

/// What the person may do now; the server works it out, the app never guesses.
class NegotiationActions {
  final bool canAccept;
  final bool canReject;
  final bool canCounter;
  final bool canCancel;

  const NegotiationActions({
    this.canAccept = false,
    this.canReject = false,
    this.canCounter = false,
    this.canCancel = false,
  });

  factory NegotiationActions.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    return NegotiationActions(
      canAccept: map['canAccept'] == true,
      canReject: map['canReject'] == true,
      canCounter: map['canCounter'] == true,
      canCancel: map['canCancel'] == true,
    );
  }
}

/// The prices a counter offer may use, both ends included.
class CounterRange {
  final num min;
  final num max;

  const CounterRange({required this.min, required this.max});

  static CounterRange? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final min = json['min'];
    final max = json['max'];
    return min is num && max is num ? CounterRange(min: min, max: max) : null;
  }
}

class NegotiationListing {
  final String listingId;
  final String title;
  final String? thumbnailUrl;
  final num askingPrice;
  final bool available;
  final bool realEstate;

  const NegotiationListing({
    required this.listingId,
    required this.title,
    required this.askingPrice,
    required this.available,
    required this.realEstate,
    this.thumbnailUrl,
  });

  factory NegotiationListing.fromJson(Map<String, dynamic> json) => NegotiationListing(
        listingId: json['listingId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        thumbnailUrl: json['thumbnailUrl'] as String?,
        askingPrice: json['askingPrice'] as num? ?? 0,
        available: json['available'] == true,
        realEstate: json['realEstate'] == true,
      );
}

class NegotiationParty {
  final String userId;
  final String displayName;

  const NegotiationParty({required this.userId, required this.displayName});

  factory NegotiationParty.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    return NegotiationParty(
      userId: map['userId'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
    );
  }
}

/// One negotiation as the signed-in person sees it (US-017).
class Negotiation {
  final String negotiationId;

  /// Whose view this is: the buyer's or the seller's.
  final NegotiationRole role;
  final NegotiationState state;

  /// Whose answer is awaited; null when nobody's (accepted or closed).
  final NegotiationRole? awaiting;
  final NegotiationListing listing;
  final NegotiationParty buyer;
  final NegotiationParty seller;
  final int round;
  final int maxRounds;
  final List<NegotiationOffer> offers;
  final num? agreedPrice;
  final DateTime? priceLockExpiresAt;
  final DateTime? expiresAt;
  final NegotiationActions actions;
  final CounterRange? counterRange;
  final String? threadId;

  /// The server's clock when it answered, so countdowns do not depend on the phone's clock.
  final DateTime serverTime;

  const Negotiation({
    required this.negotiationId,
    required this.role,
    required this.state,
    required this.awaiting,
    required this.listing,
    required this.buyer,
    required this.seller,
    required this.round,
    required this.maxRounds,
    required this.offers,
    required this.actions,
    required this.serverTime,
    this.agreedPrice,
    this.priceLockExpiresAt,
    this.expiresAt,
    this.counterRange,
    this.threadId,
  });

  /// The person the viewer is talking to.
  NegotiationParty get counterpart => role == NegotiationRole.buyer ? seller : buyer;

  /// The latest price still waiting for an answer, if any.
  NegotiationOffer? get pendingOffer {
    for (final offer in offers.reversed) {
      if (offer.isPending) return offer;
    }
    return null;
  }

  bool get isMyTurn => awaiting == role;

  factory Negotiation.fromJson(Map<String, dynamic> json) {
    final awaiting = json['awaiting'] as String?;
    return Negotiation(
      negotiationId: json['negotiationId'] as String,
      role: NegotiationRole.from(json['role'] as String?),
      state: NegotiationState.from(json['state'] as String?),
      awaiting: awaiting == 'BUYER' || awaiting == 'SELLER' ? NegotiationRole.from(awaiting) : null,
      listing: NegotiationListing.fromJson(json['listing'] as Map<String, dynamic>? ?? const {}),
      buyer: NegotiationParty.fromJson(json['buyer']),
      seller: NegotiationParty.fromJson(json['seller']),
      round: (json['round'] as num?)?.toInt() ?? 0,
      maxRounds: (json['maxRounds'] as num?)?.toInt() ?? 0,
      offers: [
        for (final item in json['offers'] as List<dynamic>? ?? const [])
          NegotiationOffer.fromJson(item as Map<String, dynamic>),
      ],
      agreedPrice: json['agreedPrice'] as num?,
      priceLockExpiresAt: DateTime.tryParse(json['priceLockExpiresAt'] as String? ?? ''),
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
      actions: NegotiationActions.fromJson(json['actions']),
      counterRange: CounterRange.fromJson(json['counterRange']),
      threadId: json['threadId'] as String?,
      serverTime:
          DateTime.tryParse(json['serverTime'] as String? ?? '')?.toUtc() ?? DateTime.now().toUtc(),
    );
  }
}
