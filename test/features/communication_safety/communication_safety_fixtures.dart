import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/features/communication_safety/data/communication_safety_repository.dart';
import 'package:valuex_mobile/features/communication_safety/domain/communication_safety.dart';

Map<String, dynamic> blockedUserJson(String id, {String name = 'Asha K'}) => {
      'userId': id,
      'displayName': name,
      'blockedAt': '2026-11-16T10:00:00Z',
    };

Map<String, dynamic> blockedPageJson(
  List<Map<String, dynamic>> items, {
  int page = 0,
  bool hasNext = false,
  int? total,
}) =>
    {
      'items': items,
      'page': page,
      'size': 20,
      'total': total ?? items.length,
      'hasNext': hasNext,
    };

BlockedUsersPage blockedPage(
  List<Map<String, dynamic>> items, {
  int page = 0,
  bool hasNext = false,
  int? total,
}) =>
    BlockedUsersPage.fromJson(blockedPageJson(items, page: page, hasNext: hasNext, total: total));

/// One report as the repository was asked to send it.
class SentReport {
  final ReportTarget target;
  final String targetId;
  final ReportReason reason;
  final String? details;

  const SentReport(this.target, this.targetId, this.reason, this.details);
}

/// A communication safety repository that answers from callbacks and records the calls.
class FakeCommunicationSafetyRepository extends Fake implements CommunicationSafetyRepository {
  Future<BlockedUsersPage> Function(int page) onList = (page) async => blockedPage(const []);
  Future<void> Function(String id) onBlock = (id) async {};
  Future<void> Function(String id) onUnblock = (id) async {};
  Future<void> Function(SentReport report) onReport = (report) async {};

  final List<int> listed = [];
  final List<String> blocked = [];
  final List<String> unblocked = [];
  final List<SentReport> reports = [];

  @override
  Future<BlockedUsersPage> listBlocked({int page = 0}) {
    listed.add(page);
    return onList(page);
  }

  @override
  Future<void> block(String userId) {
    blocked.add(userId);
    return onBlock(userId);
  }

  @override
  Future<void> unblock(String userId) {
    unblocked.add(userId);
    return onUnblock(userId);
  }

  @override
  Future<void> report({
    required ReportTarget target,
    required String targetId,
    required ReportReason reason,
    String? details,
  }) {
    final report = SentReport(target, targetId, reason, details);
    reports.add(report);
    return onReport(report);
  }
}
