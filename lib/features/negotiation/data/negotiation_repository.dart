import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/negotiation.dart';
import '../domain/offers.dart';

/// The result of making an offer: the negotiation, and whether this call created it (201) or
/// returned the one a retry had already made (200).
class MadeOffer {
  final Negotiation negotiation;
  final bool created;

  const MadeOffer({required this.negotiation, required this.created});
}

/// Price negotiation with a seller or buyer (US-017). Failures surface as `ApiError`; the screens map
/// the codes to text. Amounts are sent as decimal strings, never as floating point numbers.
class NegotiationRepository {
  /// Offers in each page of the Offers screen; the server allows at most 50.
  static const int offersPageSize = 20;

  final ApiClient _client;

  NegotiationRepository(this._client);

  static Negotiation _parse(Object? json) => Negotiation.fromJson(json as Map<String, dynamic>);

  /// Makes the buyer's first offer. The same [clientRequestId] sent again returns the same
  /// negotiation, so a retry after a lost answer never doubles it. [confirmLowOffer] confirms an
  /// offer far below the asking price.
  Future<MadeOffer> makeOffer(
    String listingId, {
    required String amount,
    required String clientRequestId,
    bool confirmLowOffer = false,
  }) async {
    final (negotiation, status) = await _client.postWithStatus<Negotiation>(
      ApiConstants.listingOffers(listingId),
      data: {
        'amount': amount,
        'clientRequestId': clientRequestId,
        'confirmLowOffer': confirmLowOffer,
      },
      parse: _parse,
    );
    return MadeOffer(negotiation: negotiation, created: status == 201);
  }

  Future<Negotiation> get(String negotiationId) =>
      _client.get(ApiConstants.negotiation(negotiationId), parse: _parse);

  Future<Negotiation> accept(String offerId) =>
      _client.post(ApiConstants.offerAccept(offerId), parse: _parse);

  Future<Negotiation> reject(String offerId) =>
      _client.post(ApiConstants.offerReject(offerId), parse: _parse);

  Future<Negotiation> counter(
    String offerId, {
    required String amount,
    required String clientRequestId,
  }) =>
      _client.post(
        ApiConstants.offerCounter(offerId),
        data: {'amount': amount, 'clientRequestId': clientRequestId},
        parse: _parse,
      );

  /// Offers a seller received, for one list (US-076); sorted by the server.
  Future<OffersPage> receivedOffers(OffersFilter filter, {int page = 0}) => _client.get(
        ApiConstants.offersReceived,
        queryParameters: {'status': filter.apiName, 'page': page, 'size': offersPageSize},
        parse: (json) => OffersPage.received(json as Map<String, dynamic>),
      );

  /// Offers the person sent as a buyer, for one list (US-076).
  Future<OffersPage> sentOffers(OffersFilter filter, {int page = 0}) => _client.get(
        ApiConstants.negotiations,
        queryParameters: {
          'role': 'BUYER',
          'status': filter == OffersFilter.closed ? 'CLOSED' : 'OPEN',
          'page': page,
          'size': offersPageSize,
        },
        parse: (json) => OffersPage.sent(json as Map<String, dynamic>, filter),
      );

  /// What waits for the seller: offers to answer, locked prices, offers about to expire.
  Future<OffersSummary> offersSummary() => _client.get(
        ApiConstants.offersReceivedSummary,
        parse: (json) => OffersSummary.fromJson(json as Map<String, dynamic>),
      );

  /// The buyer withdraws; an accepted price is released.
  Future<Negotiation> cancel(String negotiationId) =>
      _client.post(ApiConstants.negotiationCancel(negotiationId), parse: _parse);
}

final negotiationRepositoryProvider =
    Provider<NegotiationRepository>((ref) => NegotiationRepository(ref.watch(apiClientProvider)));
