import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/utils/provider_retry.dart';
import '../../../search/domain/search_criteria.dart';
import '../../data/saved_searches_repository.dart';
import '../../domain/saved_search.dart';

class _PendingDelete {
  final SavedSearch search;
  final int index;
  final Timer timer;
  final void Function()? onFailed;

  const _PendingDelete(this.search, this.index, this.timer, this.onFailed);
}

/// The Saved Searches page: the account's searches, newest first, with the alert switch and
/// delete (with an undo window, so a slip of the finger costs nothing).
class SavedSearchesController extends AsyncNotifier<List<SavedSearch>> {
  /// How long a delete can be undone; the request is sent only when it has passed.
  static const Duration undoWindow = Duration(seconds: 5);

  final Map<String, _PendingDelete> _pending = {};
  SavedSearchesRepository? _repository;

  @override
  Future<List<SavedSearch>> build() async {
    final repository = ref.watch(savedSearchesRepositoryProvider);
    _repository = repository;
    // Leaving the page must not lose a delete that was still waiting out its undo window.
    ref.onDispose(() => _flushPending(repository));
    return repository.list();
  }

  /// Switches alerts on or off at once and puts the switch back if the server refuses.
  /// Returns false in that case.
  Future<bool> toggleAlerts(String id) async {
    final current = state.value;
    final target = current?.where((s) => s.id == id).firstOrNull;
    if (current == null || target == null) return false;
    final enabled = !target.alertsEnabled;
    state = AsyncData(_withAlerts(current, id, enabled));
    try {
      await _repository!.setAlerts(id, enabled: enabled);
      return true;
    } on Object {
      if (ref.mounted) state = AsyncData(_withAlerts(state.value ?? current, id, !enabled));
      return false;
    }
  }

  /// Hides the search now and deletes it when [undoWindow] has passed, unless [undoDelete] is
  /// called first. [onFailed] runs when the server refuses and the search comes back.
  void deleteWithUndo(String id, {void Function()? onFailed}) {
    final current = state.value;
    if (current == null || _pending.containsKey(id)) return;
    final index = current.indexWhere((s) => s.id == id);
    if (index < 0) return;
    state = AsyncData([...current]..removeAt(index));
    _pending[id] = _PendingDelete(
      current[index],
      index,
      Timer(undoWindow, () => unawaited(_commit(id))),
      onFailed,
    );
  }

  /// Puts a search that is waiting to be deleted back where it was. False when it is too late.
  bool undoDelete(String id) {
    final pending = _pending.remove(id);
    if (pending == null) return false;
    pending.timer.cancel();
    _restore(pending);
    return true;
  }

  Future<void> _commit(String id) async {
    final pending = _pending.remove(id);
    if (pending == null) return;
    try {
      await _repository!.delete(id);
    } on ApiError catch (error) {
      // Already gone on the server is as good as deleted.
      if (error.statusCode == 404) return;
      _failed(pending);
    } on Object {
      _failed(pending);
    }
  }

  void _failed(_PendingDelete pending) {
    if (!ref.mounted) return;
    _restore(pending);
    pending.onFailed?.call();
  }

  void _restore(_PendingDelete pending) {
    if (!ref.mounted) return;
    final current = state.value ?? const <SavedSearch>[];
    if (current.any((s) => s.id == pending.search.id)) return;
    final at = pending.index > current.length ? current.length : pending.index;
    state = AsyncData([...current]..insert(at, pending.search));
  }

  void _flushPending(SavedSearchesRepository repository) {
    for (final entry in _pending.entries) {
      entry.value.timer.cancel();
      unawaited(repository.delete(entry.key).then<void>((_) {}, onError: (Object _) {}));
    }
    _pending.clear();
  }

  static List<SavedSearch> _withAlerts(List<SavedSearch> list, String id, bool enabled) => [
        for (final search in list)
          search.id == id ? search.copyWith(alertsEnabled: enabled) : search,
      ];
}

final savedSearchesControllerProvider =
    AsyncNotifierProvider.autoDispose<SavedSearchesController, List<SavedSearch>>(
  SavedSearchesController.new,
  retry: noAutoRetry,
);

/// What the Save Search button did.
enum SaveSearchStatus { saved, alreadySaved, limitReached, invalid, failed }

class SaveSearchOutcome {
  final SaveSearchStatus status;

  /// The allowed number of searches, for [SaveSearchStatus.limitReached] when the server said.
  final int? max;

  const SaveSearchOutcome(this.status, {this.max});
}

/// Saves the criteria on screen. The state is true while the request is running, so a second
/// tap does nothing.
class SaveSearchController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Null when a save is already running.
  Future<SaveSearchOutcome?> save(SearchCriteria criteria) async {
    if (state) return null;
    state = true;
    try {
      final result = await ref.read(savedSearchesRepositoryProvider).create(criteria);
      ref.invalidate(savedSearchesControllerProvider);
      return SaveSearchOutcome(
        result.alreadySaved ? SaveSearchStatus.alreadySaved : SaveSearchStatus.saved,
      );
    } on SavedSearchLimitReached catch (limit) {
      return SaveSearchOutcome(SaveSearchStatus.limitReached, max: limit.max);
    } on SavedSearchInvalidCriteria {
      return const SaveSearchOutcome(SaveSearchStatus.invalid);
    } on Object {
      return const SaveSearchOutcome(SaveSearchStatus.failed);
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

final saveSearchControllerProvider =
    NotifierProvider.autoDispose<SaveSearchController, bool>(SaveSearchController.new);
