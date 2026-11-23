import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/call.dart';

/// Calls with a seller (US-014, US-015), every one on the server's REST API. Failures surface as
/// `ApiError`; the screens map the codes to text.
class CallRepository {
  final ApiClient _client;

  CallRepository(this._client);

  /// Rings the seller of [listingId]. The server finds or opens the buyer's chat itself.
  Future<CallSession> start(String listingId, {required CallType type}) => _client.post(
        type.hasVideo ? ApiConstants.callsVideo : ApiConstants.callsVoice,
        data: {'listingId': listingId},
        parse: _session,
      );

  Future<CallSession> get(String callId) => _client.get(ApiConstants.call(callId), parse: _session);

  Future<CallSession> accept(String callId) => _action(callId, 'accept');

  Future<CallSession> decline(String callId) => _action(callId, 'decline');

  Future<CallSession> cancel(String callId) => _action(callId, 'cancel');

  /// Tells the server this phone is in the room; when both are, the call is on.
  Future<CallSession> connected(String callId) => _action(callId, 'connected');

  /// Hangs up. Ending a call that is over returns it as it was left.
  Future<CallSession> end(String callId) => _action(callId, 'end');

  /// What to join the room with. Only for an accepted call.
  Future<CallCredentials> join(String callId) => _client.post(
        ApiConstants.callAction(callId, 'join'),
        parse: (json) => CallCredentials.fromJson(json as Map<String, dynamic>),
      );

  /// A sign of life; 409 `ERROR_CALL_NOT_ACTIVE` once the call is over.
  Future<void> heartbeat(String callId) =>
      _client.post<void>(ApiConstants.callAction(callId, 'heartbeat'));

  Future<List<CallHistoryItem>> history(String threadId, {int page = 0}) => _client.get(
        ApiConstants.calls,
        queryParameters: {'threadId': threadId, 'page': page},
        parse: (json) => [
          for (final item in (json as Map<String, dynamic>)['items'] as List<dynamic>? ?? const [])
            CallHistoryItem.fromJson(item as Map<String, dynamic>),
        ],
      );

  Future<CallSession> _action(String callId, String action) =>
      _client.post(ApiConstants.callAction(callId, action), parse: _session);

  static CallSession _session(Object? json) =>
      CallSession.fromJson(json as Map<String, dynamic>, receivedAt: DateTime.now());
}

final callRepositoryProvider = Provider<CallRepository>(
  (ref) => CallRepository(ref.watch(apiClientProvider)),
);
