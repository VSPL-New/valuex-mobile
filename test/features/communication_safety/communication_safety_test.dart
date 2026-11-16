import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/constants/api_constants.dart';
import 'package:valuex_mobile/core/network/api_client.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/communication_safety/data/communication_safety_repository.dart';
import 'package:valuex_mobile/features/communication_safety/domain/communication_safety.dart';
import 'package:valuex_mobile/features/communication_safety/presentation/providers/blocked_users_controller.dart';

import 'communication_safety_fixtures.dart';

class _FakeApi extends Fake implements ApiClient {
  String? method;
  String? path;
  Object? body;
  Map<String, dynamic>? query;
  Object? response;

  @override
  Future<T> put<T>(
    String path, {
    Object? data,
    bool authenticated = true,
    T Function(Object? data)? parse,
  }) async {
    method = 'PUT';
    this.path = path;
    return null as T;
  }

  @override
  Future<T> delete<T>(
    String path, {
    Object? data,
    bool authenticated = true,
    T Function(Object? data)? parse,
  }) async {
    method = 'DELETE';
    this.path = path;
    return null as T;
  }

  @override
  Future<T> post<T>(
    String path, {
    Object? data,
    bool authenticated = true,
    String? bearerToken,
    Duration? receiveTimeout,
    T Function(Object? data)? parse,
  }) async {
    method = 'POST';
    this.path = path;
    body = data;
    return null as T;
  }

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
    T Function(Object? data)? parse,
  }) async {
    method = 'GET';
    this.path = path;
    query = queryParameters;
    return parse!(response);
  }
}

const _offline = ApiError(type: ApiErrorType.network, message: 'offline');

void main() {
  group('paths', () {
    test('block, blocked users, reports and the screen route', () {
      expect(ApiConstants.userBlock('u1'), '/users/u1/block');
      expect(ApiConstants.blockedUsers, '/users/me/blocks');
      expect(ApiConstants.reports, '/reports');
      expect(RouteNames.blockedUsers, '/profile/blocked-users');
    });
  });

  group('models', () {
    test('a blocked user is read from the API', () {
      final user = BlockedUser.fromJson(blockedUserJson('u1'));

      expect(user.userId, 'u1');
      expect(user.displayName, 'Asha K');
      expect(user.blockedAt, DateTime.utc(2026, 11, 16, 10));
    });

    test('a missing name and time fall back to empty and null', () {
      final user = BlockedUser.fromJson(const {'userId': 'u1'});

      expect(user.displayName, '');
      expect(user.blockedAt, isNull);
    });

    test('a page is read with its paging fields', () {
      final page = blockedPage([blockedUserJson('u1'), blockedUserJson('u2')],
          page: 1, hasNext: true, total: 5);

      expect(page.items.map((u) => u.userId), ['u1', 'u2']);
      expect(page.page, 1);
      expect(page.hasNext, isTrue);
      expect(page.total, 5);
    });

    test('an empty body is an empty last page', () {
      final page = BlockedUsersPage.fromJson(const {});

      expect(page.items, isEmpty);
      expect(page.page, 0);
      expect(page.hasNext, isFalse);
      expect(page.total, 0);
    });

    test('reasons and targets use the names the API expects', () {
      expect(ReportReason.values.map((r) => r.apiName), [
        'SPAM',
        'HARASSMENT',
        'SCAM_OR_FRAUD',
        'INAPPROPRIATE_CONTENT',
        'OFFENSIVE_BEHAVIOUR',
        'SHARING_CONTACT_DETAILS',
        'OTHER',
      ]);
      expect(ReportTarget.values.map((t) => t.apiName), ['USER', 'THREAD', 'MESSAGE', 'CALL']);
      expect(reportDetailsMaxLength, 500);
    });
  });

  group('CommunicationSafetyRepository', () {
    late _FakeApi api;
    late CommunicationSafetyRepository repository;

    setUp(() {
      api = _FakeApi();
      repository = CommunicationSafetyRepository(api);
    });

    test('blocks with a PUT to the user', () async {
      await repository.block('u1');

      expect(api.method, 'PUT');
      expect(api.path, '/users/u1/block');
    });

    test('unblocks with a DELETE to the user', () async {
      await repository.unblock('u1');

      expect(api.method, 'DELETE');
      expect(api.path, '/users/u1/block');
    });

    test('lists a page of blocked users', () async {
      api.response = blockedPageJson([blockedUserJson('u1')], total: 1);

      final page = await repository.listBlocked(page: 2);

      expect(api.method, 'GET');
      expect(api.path, '/users/me/blocks');
      expect(api.query, {'page': 2, 'size': 20});
      expect(page.items.single.userId, 'u1');
    });

    test('reports with the target, reason and trimmed details', () async {
      await repository.report(
        target: ReportTarget.user,
        targetId: 'u1',
        reason: ReportReason.harassment,
        details: '  rude messages  ',
      );

      expect(api.method, 'POST');
      expect(api.path, '/reports');
      expect(api.body, {
        'targetType': 'USER',
        'targetId': 'u1',
        'reason': 'HARASSMENT',
        'details': 'rude messages',
      });
    });

    test('leaves the details out when they are missing or blank', () async {
      await repository.report(target: ReportTarget.user, targetId: 'u1', reason: ReportReason.spam);
      expect(api.body, {'targetType': 'USER', 'targetId': 'u1', 'reason': 'SPAM'});

      await repository.report(
        target: ReportTarget.user,
        targetId: 'u1',
        reason: ReportReason.spam,
        details: '   ',
      );
      expect(api.body, {'targetType': 'USER', 'targetId': 'u1', 'reason': 'SPAM'});
    });
  });

  group('BlockedUsersController', () {
    late FakeCommunicationSafetyRepository safety;
    late ProviderContainer container;

    BlockedUsersController controller() => container.read(blockedUsersControllerProvider.notifier);
    BlockedUsersState? current() => container.read(blockedUsersControllerProvider).value;

    setUp(() {
      safety = FakeCommunicationSafetyRepository();
      container = ProviderContainer(
        overrides: [communicationSafetyRepositoryProvider.overrideWithValue(safety)],
      );
      addTearDown(container.dispose);
    });

    Future<void> load() async {
      container.listen(blockedUsersControllerProvider, (_, __) {});
      await container.read(blockedUsersControllerProvider.future);
    }

    test('loads the first page', () async {
      safety.onList = (page) async => blockedPage([blockedUserJson('u1')], hasNext: true, total: 2);

      await load();

      expect(safety.listed, [0]);
      expect(current()!.items.single.userId, 'u1');
      expect(current()!.hasNext, isTrue);
    });

    test('appends the next page without repeating a user', () async {
      safety.onList = (page) async => page == 0
          ? blockedPage([blockedUserJson('u1')], hasNext: true, total: 2)
          : blockedPage([blockedUserJson('u1'), blockedUserJson('u2')], page: 1, total: 2);
      await load();

      final ok = await controller().loadMore();

      expect(ok, isTrue);
      expect(current()!.items.map((u) => u.userId), ['u1', 'u2']);
      expect(current()!.hasNext, isFalse);
      expect(current()!.loadingMore, isFalse);
    });

    test('does not ask for another page when there is none', () async {
      safety.onList = (page) async => blockedPage([blockedUserJson('u1')]);
      await load();

      expect(await controller().loadMore(), isTrue);
      expect(safety.listed, [0]);
    });

    test('a page that fails to load keeps the list and says so', () async {
      safety.onList = (page) async => page == 0
          ? blockedPage([blockedUserJson('u1')], hasNext: true, total: 2)
          : throw _offline;
      await load();

      final ok = await controller().loadMore();

      expect(ok, isFalse);
      expect(current()!.items.length, 1);
      expect(current()!.loadingMore, isFalse);
    });

    test('unblocking takes the user off the list and asks the server', () async {
      safety.onList = (page) async => blockedPage([blockedUserJson('u1'), blockedUserJson('u2')]);
      await load();

      final ok = await controller().unblock('u1');

      expect(ok, isTrue);
      expect(safety.unblocked, ['u1']);
      expect(current()!.items.map((u) => u.userId), ['u2']);
    });

    test('a refused unblock puts the user back where they were', () async {
      safety.onList = (page) async =>
          blockedPage([blockedUserJson('u1'), blockedUserJson('u2'), blockedUserJson('u3')]);
      safety.onUnblock = (id) async => throw _offline;
      await load();

      final ok = await controller().unblock('u2');

      expect(ok, isFalse);
      expect(current()!.items.map((u) => u.userId), ['u1', 'u2', 'u3']);
    });

    test('unblocking someone not on the list does nothing', () async {
      safety.onList = (page) async => blockedPage([blockedUserJson('u1')]);
      await load();

      expect(await controller().unblock('zzz'), isTrue);
      expect(safety.unblocked, isEmpty);
    });

    test('unblocking before the list has loaded is refused', () async {
      expect(await controller().unblock('u1'), isFalse);
    });
  });
}
