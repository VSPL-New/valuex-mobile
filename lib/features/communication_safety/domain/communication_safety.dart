import 'package:flutter/foundation.dart';

/// What a report is about. Only [user] is reportable until chat and calls exist (US-013, US-014).
enum ReportTarget {
  user('USER'),
  thread('THREAD'),
  message('MESSAGE'),
  call('CALL');

  /// The value the API expects.
  final String apiName;

  const ReportTarget(this.apiName);
}

/// Why a report is filed, in the order the sheet lists them.
enum ReportReason {
  spam('SPAM'),
  harassment('HARASSMENT'),
  scamOrFraud('SCAM_OR_FRAUD'),
  inappropriateContent('INAPPROPRIATE_CONTENT'),
  offensiveBehaviour('OFFENSIVE_BEHAVIOUR'),
  sharingContactDetails('SHARING_CONTACT_DETAILS'),
  other('OTHER');

  /// The value the API expects.
  final String apiName;

  const ReportReason(this.apiName);
}

/// The longest optional text a report can carry.
const int reportDetailsMaxLength = 500;

/// One person the user has blocked.
@immutable
class BlockedUser {
  final String userId;
  final String displayName;
  final DateTime? blockedAt;

  const BlockedUser({required this.userId, required this.displayName, this.blockedAt});

  factory BlockedUser.fromJson(Map<String, dynamic> json) => BlockedUser(
        userId: json['userId'] as String,
        displayName: json['displayName'] as String? ?? '',
        blockedAt: DateTime.tryParse(json['blockedAt'] as String? ?? ''),
      );
}

/// One page of the blocked users, newest block first.
@immutable
class BlockedUsersPage {
  final List<BlockedUser> items;
  final int page;
  final bool hasNext;
  final int total;

  const BlockedUsersPage({
    required this.items,
    required this.page,
    required this.hasNext,
    required this.total,
  });

  factory BlockedUsersPage.fromJson(Map<String, dynamic> json) => BlockedUsersPage(
        items: [
          for (final item in json['items'] as List<dynamic>? ?? const [])
            BlockedUser.fromJson(item as Map<String, dynamic>),
        ],
        page: (json['page'] as num?)?.toInt() ?? 0,
        hasNext: json['hasNext'] == true,
        total: (json['total'] as num?)?.toInt() ?? 0,
      );
}
