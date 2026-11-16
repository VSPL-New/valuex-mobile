import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/communication_safety.dart';

/// Block, unblock and report other users (US-132). Failures surface as `ApiError`.
class CommunicationSafetyRepository {
  /// Page size of the blocked users list.
  static const int pageSize = 20;

  final ApiClient _client;

  CommunicationSafetyRepository(this._client);

  /// Blocks the user; blocking someone already blocked is harmless.
  Future<void> block(String userId) => _client.put<void>(ApiConstants.userBlock(userId));

  /// Removes the block; unblocking someone not blocked is harmless.
  Future<void> unblock(String userId) => _client.delete<void>(ApiConstants.userBlock(userId));

  Future<BlockedUsersPage> listBlocked({int page = 0}) => _client.get(
        ApiConstants.blockedUsers,
        queryParameters: {'page': page, 'size': pageSize},
        parse: (json) => BlockedUsersPage.fromJson(json as Map<String, dynamic>),
      );

  /// Files a report. Sending the same report twice is harmless. [details] is trimmed and left out
  /// when empty.
  Future<void> report({
    required ReportTarget target,
    required String targetId,
    required ReportReason reason,
    String? details,
  }) {
    final text = details?.trim();
    return _client.post<void>(
      ApiConstants.reports,
      data: {
        'targetType': target.apiName,
        'targetId': targetId,
        'reason': reason.apiName,
        if (text != null && text.isNotEmpty) 'details': text,
      },
    );
  }
}

final communicationSafetyRepositoryProvider = Provider<CommunicationSafetyRepository>(
  (ref) => CommunicationSafetyRepository(ref.watch(apiClientProvider)),
);
