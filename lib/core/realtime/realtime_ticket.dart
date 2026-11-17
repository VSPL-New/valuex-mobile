import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';

/// What the server gives for opening the socket: a single-use ticket and where to use it.
@immutable
class RealtimeTicket {
  final String ticket;
  final int expiresInSeconds;
  final String url;
  final int pingIntervalSeconds;

  const RealtimeTicket({
    required this.ticket,
    required this.expiresInSeconds,
    required this.url,
    required this.pingIntervalSeconds,
  });

  factory RealtimeTicket.fromJson(Map<String, dynamic> json) => RealtimeTicket(
        ticket: json['ticket'] as String,
        expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 30,
        url: json['url'] as String,
        pingIntervalSeconds: (json['pingIntervalSeconds'] as num?)?.toInt() ?? 25,
      );

  /// The address to open: the url with the ticket as its only credential.
  Uri get socketUri => Uri.parse(url).replace(queryParameters: {'ticket': ticket});
}

/// Asks the server for a ticket (US-130). Failures surface as `ApiError`.
class RealtimeTicketRepository {
  final ApiClient _client;

  RealtimeTicketRepository(this._client);

  Future<RealtimeTicket> issue() => _client.post<RealtimeTicket>(
        ApiConstants.realtimeTickets,
        parse: (json) => RealtimeTicket.fromJson(json as Map<String, dynamic>),
      );
}
