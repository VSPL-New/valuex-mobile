import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/saved_searches/data/saved_searches_repository.dart';
import 'package:valuex_mobile/features/saved_searches/domain/saved_search.dart';
import 'package:valuex_mobile/features/saved_searches/presentation/providers/saved_searches_controller.dart';
import 'package:valuex_mobile/features/search/domain/search_criteria.dart';

import 'saved_search_fixtures.dart';

const _offline = ApiError(type: ApiErrorType.network, message: 'offline');

SavedSearch _search(String id, {bool alerts = true}) =>
    SavedSearch.fromJson(savedSearchJson(id, name: 'Search $id', alerts: alerts));

void main() {
  late FakeSavedSearchesRepository repository;

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [savedSearchesRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    repository = FakeSavedSearchesRepository();
    repository.onList = () async => [_search('a'), _search('b'), _search('c')];
  });

  /// Keeps the list controller alive, as the screen does.
  List<SavedSearch>? Function() open(FakeAsync async, ProviderContainer container) {
    container.listen(savedSearchesControllerProvider, (previous, next) {});
    async.flushMicrotasks();
    return () => container.read(savedSearchesControllerProvider).value;
  }

  group('the list', () {
    test('loads the account searches', () {
      fakeAsync((async) {
        final container = makeContainer();
        final list = open(async, container);

        expect(list()!.map((s) => s.id), ['a', 'b', 'c']);
        expect(repository.listCalls, 1);
      });
    });

    test('keeps the failure so the page can offer a retry', () {
      fakeAsync((async) {
        repository.onList = () async => throw _offline;
        final container = makeContainer();
        container.listen(savedSearchesControllerProvider, (previous, next) {});
        async.flushMicrotasks();

        expect(container.read(savedSearchesControllerProvider).hasError, isTrue);

        repository.onList = () async => [_search('a')];
        container.invalidate(savedSearchesControllerProvider);
        async.elapse(const Duration(milliseconds: 1));
        expect(container.read(savedSearchesControllerProvider).value, hasLength(1));
      });
    });
  });

  group('alerts switch', () {
    test('flips at once and stays when the server agrees', () {
      fakeAsync((async) {
        final gate = Completer<SavedSearch>();
        repository.onSetAlerts = (id, enabled) => gate.future;
        final container = makeContainer();
        final list = open(async, container);

        final result = container.read(savedSearchesControllerProvider.notifier).toggleAlerts('b');
        async.flushMicrotasks();

        expect(list()!.firstWhere((s) => s.id == 'b').alertsEnabled, isFalse);
        expect(repository.alertCalls, [('b', false)]);
        gate.complete(_search('b', alerts: false));
        async.flushMicrotasks();
        bool? ok;
        result.then((value) => ok = value);
        async.flushMicrotasks();
        expect(ok, isTrue);
        expect(list()!.firstWhere((s) => s.id == 'b').alertsEnabled, isFalse);
      });
    });

    test('is put back when the server refuses', () {
      fakeAsync((async) {
        repository.onSetAlerts = (id, enabled) async => throw _offline;
        final container = makeContainer();
        final list = open(async, container);

        bool? ok;
        container
            .read(savedSearchesControllerProvider.notifier)
            .toggleAlerts('a')
            .then((value) => ok = value);
        async.flushMicrotasks();

        expect(ok, isFalse);
        expect(list()!.firstWhere((s) => s.id == 'a').alertsEnabled, isTrue);
      });
    });

    test('switches back on again and ignores an unknown search', () {
      fakeAsync((async) {
        repository.onSetAlerts = (id, enabled) async => _search(id, alerts: enabled);
        repository.onList = () async => [_search('a', alerts: false)];
        final container = makeContainer();
        final list = open(async, container);
        final controller = container.read(savedSearchesControllerProvider.notifier);

        controller.toggleAlerts('a');
        async.flushMicrotasks();
        expect(list()!.single.alertsEnabled, isTrue);
        expect(repository.alertCalls, [('a', true)]);

        bool? ok;
        controller.toggleAlerts('zzz').then((value) => ok = value);
        async.flushMicrotasks();
        expect(ok, isFalse);
      });
    });
  });

  group('delete with undo', () {
    test('hides the search at once and sends the request only after the undo window', () {
      fakeAsync((async) {
        final container = makeContainer();
        final list = open(async, container);

        container.read(savedSearchesControllerProvider.notifier).deleteWithUndo('b');
        async.flushMicrotasks();

        expect(list()!.map((s) => s.id), ['a', 'c']);
        async.elapse(SavedSearchesController.undoWindow - const Duration(milliseconds: 1));
        expect(repository.deleted, isEmpty);
        async.elapse(const Duration(milliseconds: 2));
        expect(repository.deleted, ['b']);
        expect(list()!.map((s) => s.id), ['a', 'c']);
      });
    });

    test('undo puts the search back where it was and nothing is sent', () {
      fakeAsync((async) {
        final container = makeContainer();
        final list = open(async, container);
        final controller = container.read(savedSearchesControllerProvider.notifier);

        controller.deleteWithUndo('b');
        async.elapse(const Duration(seconds: 2));
        expect(controller.undoDelete('b'), isTrue);
        async.elapse(const Duration(seconds: 10));

        expect(list()!.map((s) => s.id), ['a', 'b', 'c']);
        expect(repository.deleted, isEmpty);
        expect(controller.undoDelete('b'), isFalse);
      });
    });

    test('a refused delete brings the search back and says so', () {
      fakeAsync((async) {
        repository.onDelete = (id) async => throw _offline;
        final container = makeContainer();
        final list = open(async, container);
        var failed = 0;

        container
            .read(savedSearchesControllerProvider.notifier)
            .deleteWithUndo('c', onFailed: () => failed++);
        async.elapse(SavedSearchesController.undoWindow);
        async.flushMicrotasks();

        expect(failed, 1);
        expect(list()!.map((s) => s.id), ['a', 'b', 'c']);
      });
    });

    test('a search that is already gone on the server stays deleted', () {
      fakeAsync((async) {
        repository.onDelete = (id) async => throw const ApiError(
              type: ApiErrorType.business,
              message: 'x',
              statusCode: 404,
            );
        final container = makeContainer();
        final list = open(async, container);
        var failed = 0;

        container
            .read(savedSearchesControllerProvider.notifier)
            .deleteWithUndo('a', onFailed: () => failed++);
        async.elapse(SavedSearchesController.undoWindow);
        async.flushMicrotasks();

        expect(failed, 0);
        expect(list()!.map((s) => s.id), ['b', 'c']);
      });
    });

    test('leaving the page sends a delete that was still waiting', () {
      fakeAsync((async) {
        final container = makeContainer();
        open(async, container);
        container.read(savedSearchesControllerProvider.notifier).deleteWithUndo('a');
        async.flushMicrotasks();

        container.dispose();
        async.flushMicrotasks();

        expect(repository.deleted, ['a']);
        async.elapse(const Duration(seconds: 10));
        expect(repository.deleted, ['a']);
      });
    });

    test('a failed flush on leaving is ignored', () {
      fakeAsync((async) {
        repository.onDelete = (id) async => throw _offline;
        final container = makeContainer();
        open(async, container);
        container.read(savedSearchesControllerProvider.notifier).deleteWithUndo('a');

        container.dispose();
        async.flushMicrotasks();

        expect(repository.deleted, ['a']);
      });
    });

    test('deleting the same search twice or an unknown one does nothing more', () {
      fakeAsync((async) {
        final container = makeContainer();
        final list = open(async, container);
        final controller = container.read(savedSearchesControllerProvider.notifier);

        controller.deleteWithUndo('a');
        controller.deleteWithUndo('a');
        controller.deleteWithUndo('zzz');
        async.elapse(SavedSearchesController.undoWindow);

        expect(repository.deleted, ['a']);
        expect(list()!.map((s) => s.id), ['b', 'c']);
      });
    });
  });

  group('save search', () {
    const criteria = SearchCriteria(query: 'iphone');

    Future<SaveSearchOutcome?> save(ProviderContainer container) =>
        container.read(saveSearchControllerProvider.notifier).save(criteria);

    test('saved: sends the criteria and refreshes the list', () {
      fakeAsync((async) {
        repository.onCreate = (c) async => SaveResult(_search('n'), alreadySaved: false);
        final container = makeContainer();
        open(async, container);
        SaveSearchOutcome? outcome;

        save(container).then((value) => outcome = value);
        async.elapse(const Duration(milliseconds: 1));

        expect(outcome!.status, SaveSearchStatus.saved);
        expect(repository.created, [criteria]);
        expect(repository.listCalls, 2);
      });
    });

    test('already saved is reported as such', () {
      fakeAsync((async) {
        repository.onCreate = (c) async => SaveResult(_search('n'), alreadySaved: true);
        final container = makeContainer();
        SaveSearchOutcome? outcome;

        save(container).then((value) => outcome = value);
        async.flushMicrotasks();

        expect(outcome!.status, SaveSearchStatus.alreadySaved);
      });
    });

    test('the limit carries the allowed number', () {
      fakeAsync((async) {
        repository.onCreate = (c) async => throw const SavedSearchLimitReached(10);
        final container = makeContainer();
        SaveSearchOutcome? outcome;

        save(container).then((value) => outcome = value);
        async.flushMicrotasks();

        expect(outcome!.status, SaveSearchStatus.limitReached);
        expect(outcome!.max, 10);
      });
    });

    test('invalid criteria and any other failure have their own outcome', () {
      fakeAsync((async) {
        final container = makeContainer();
        final outcomes = <SaveSearchOutcome?>[];

        repository.onCreate = (c) async => throw const SavedSearchInvalidCriteria();
        save(container).then(outcomes.add);
        async.flushMicrotasks();
        repository.onCreate = (c) async => throw _offline;
        save(container).then(outcomes.add);
        async.flushMicrotasks();

        expect(outcomes.map((o) => o!.status), [SaveSearchStatus.invalid, SaveSearchStatus.failed]);
      });
    });

    test('a second tap while saving does nothing', () {
      fakeAsync((async) {
        final gate = Completer<SaveResult>();
        repository.onCreate = (c) => gate.future;
        final container = makeContainer();
        container.listen(saveSearchControllerProvider, (previous, next) {});
        final outcomes = <SaveSearchOutcome?>[];

        save(container).then(outcomes.add);
        async.flushMicrotasks();
        expect(container.read(saveSearchControllerProvider), isTrue);
        save(container).then(outcomes.add);
        async.flushMicrotasks();
        expect(outcomes, [null]);
        expect(repository.created, hasLength(1));

        gate.complete(SaveResult(_search('n'), alreadySaved: false));
        async.flushMicrotasks();
        expect(container.read(saveSearchControllerProvider), isFalse);
        expect(outcomes.last!.status, SaveSearchStatus.saved);
      });
    });
  });
}
