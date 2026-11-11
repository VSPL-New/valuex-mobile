import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/search/data/search_repository.dart';
import 'package:valuex_mobile/features/search/domain/search_suggestion.dart';
import 'package:valuex_mobile/features/search/presentation/providers/search_suggestions_controller.dart';

import 'search_fixtures.dart';

const _offline = ApiError(type: ApiErrorType.network, message: 'offline');

const _phones = SearchSuggestion(
  text: 'Smartphones',
  type: SuggestionType.category,
  categoryCode: 'C1',
);
const _iphone = SearchSuggestion(text: 'iPhone 14', type: SuggestionType.listing);
const _ipad = SearchSuggestion(text: 'iPad', type: SuggestionType.listing);

void main() {
  late FakeSearchRepository repository;

  setUp(() {
    repository = FakeSearchRepository((criteria, page) async => listingsPage(0, 1));
    repository.suggestHandler = (query) async => [_phones, _iphone];
  });

  /// Keeps the controller alive, as the screen does.
  (SuggestionsState Function(), SearchSuggestionsController) open(FakeAsync async) {
    final container = ProviderContainer(
      overrides: [searchRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(searchSuggestionsControllerProvider, (previous, next) {});
    async.flushMicrotasks();
    return (
      () => container.read(searchSuggestionsControllerProvider),
      container.read(searchSuggestionsControllerProvider.notifier),
    );
  }

  const pause = Duration(milliseconds: 250);

  test('it asks once, 250 ms after the last key, and shows the answer', () {
    fakeAsync((async) {
      final (state, controller) = open(async);
      controller.onFocusChanged(true);

      controller.onTextChanged('ip');
      async.elapse(const Duration(milliseconds: 200));
      controller.onTextChanged('iph');
      async.elapse(const Duration(milliseconds: 200));
      expect(repository.suggestCalls, isEmpty);
      async.elapse(const Duration(milliseconds: 60));
      async.flushMicrotasks();

      expect(repository.suggestCalls, ['iph']);
      expect(state().items, [_phones, _iphone]);
      expect(state().query, 'iph');
      expect(state().isEmpty, isFalse);
    });
  });

  test('the text is trimmed before it is sent', () {
    fakeAsync((async) {
      final (state, controller) = open(async);
      controller.onFocusChanged(true);

      controller.onTextChanged('  iph ');
      async.elapse(pause);
      async.flushMicrotasks();

      expect(repository.suggestCalls, ['iph']);
      expect(state().query, 'iph');
    });
  });

  test('fewer than two characters ask nothing and clear what is shown', () {
    fakeAsync((async) {
      final (state, controller) = open(async);
      controller.onFocusChanged(true);
      controller.onTextChanged('ip');
      async.elapse(pause);
      async.flushMicrotasks();
      expect(state().items, isNotEmpty);

      controller.onTextChanged('i');
      expect(state().items, isEmpty);
      async.elapse(const Duration(seconds: 1));
      controller.onTextChanged(' i ');
      controller.onTextChanged('');
      async.elapse(const Duration(seconds: 1));

      expect(repository.suggestCalls, ['ip']);
      expect(state().items, isEmpty);
    });
  });

  test('a slow answer for an older text never replaces the newer one', () {
    fakeAsync((async) {
      final slow = Completer<List<SearchSuggestion>>();
      repository.suggestHandler = (query) => query == 'ip' ? slow.future : Future.value([_ipad]);
      final (state, controller) = open(async);
      controller.onFocusChanged(true);

      controller.onTextChanged('ip');
      async.elapse(pause);
      controller.onTextChanged('ipa');
      async.elapse(pause);
      async.flushMicrotasks();
      expect(state().items, [_ipad]);

      slow.complete([_iphone]);
      async.flushMicrotasks();

      expect(state().items, [_ipad]);
      expect(state().query, 'ipa');
    });
  });

  test('an answer that arrives after the text was cleared is dropped', () {
    fakeAsync((async) {
      final slow = Completer<List<SearchSuggestion>>();
      repository.suggestHandler = (query) => slow.future;
      final (state, controller) = open(async);
      controller.onFocusChanged(true);

      controller.onTextChanged('ip');
      async.elapse(pause);
      controller.onTextChanged('');
      slow.complete([_iphone]);
      async.flushMicrotasks();

      expect(state().items, isEmpty);
    });
  });

  test('a failure is silent: no list, and the next text still asks', () {
    fakeAsync((async) {
      var fail = true;
      repository.suggestHandler = (query) async {
        if (fail) throw _offline;
        return [_iphone];
      };
      final (state, controller) = open(async);
      controller.onFocusChanged(true);

      controller.onTextChanged('ip');
      async.elapse(pause);
      async.flushMicrotasks();
      expect(state().items, isEmpty);

      fail = false;
      controller.onTextChanged('iph');
      async.elapse(pause);
      async.flushMicrotasks();

      expect(state().items, [_iphone]);
    });
  });

  test('a failure after an answer removes the list', () {
    fakeAsync((async) {
      final (state, controller) = open(async);
      controller.onFocusChanged(true);
      controller.onTextChanged('ip');
      async.elapse(pause);
      async.flushMicrotasks();
      expect(state().items, isNotEmpty);

      repository.suggestHandler = (query) => throw StateError('broken');
      controller.onTextChanged('iph');
      async.elapse(pause);
      async.flushMicrotasks();

      expect(state().items, isEmpty);
    });
  });

  test('submitting clears the list and cancels a pending request', () {
    fakeAsync((async) {
      final (state, controller) = open(async);
      controller.onFocusChanged(true);
      controller.onTextChanged('ip');
      async.elapse(pause);
      async.flushMicrotasks();
      expect(state().items, isNotEmpty);

      controller.onSubmitted();
      expect(state().items, isEmpty);

      controller.onTextChanged('iph');
      controller.onSubmitted();
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();

      expect(repository.suggestCalls, ['ip']);
      expect(state().items, isEmpty);
    });
  });

  test('an answer in flight when the text is submitted is dropped', () {
    fakeAsync((async) {
      final slow = Completer<List<SearchSuggestion>>();
      repository.suggestHandler = (query) => slow.future;
      final (state, controller) = open(async);
      controller.onFocusChanged(true);

      controller.onTextChanged('ip');
      async.elapse(pause);
      controller.onSubmitted();
      slow.complete([_iphone]);
      async.flushMicrotasks();

      expect(state().items, isEmpty);
    });
  });

  test('typing again after a submit asks again', () {
    fakeAsync((async) {
      final (state, controller) = open(async);
      controller.onFocusChanged(true);
      controller.onTextChanged('ip');
      controller.onSubmitted();

      controller.onTextChanged('ipa');
      async.elapse(pause);
      async.flushMicrotasks();

      expect(repository.suggestCalls, ['ipa']);
      expect(state().items, isNotEmpty);
    });
  });

  test('nothing is asked while the field has no focus, and losing focus clears the list', () {
    fakeAsync((async) {
      final (state, controller) = open(async);

      controller.onTextChanged('ip');
      async.elapse(const Duration(seconds: 1));
      expect(repository.suggestCalls, isEmpty);

      controller.onFocusChanged(true);
      async.elapse(pause);
      async.flushMicrotasks();
      expect(state().items, isNotEmpty);

      controller.onFocusChanged(false);
      expect(state().items, isEmpty);
      async.elapse(const Duration(seconds: 1));
      expect(repository.suggestCalls, ['ip']);
    });
  });

  test('a request still waiting when the screen closes does nothing', () {
    fakeAsync((async) {
      final slow = Completer<List<SearchSuggestion>>();
      repository.suggestHandler = (query) => slow.future;
      final container = ProviderContainer(
        overrides: [searchRepositoryProvider.overrideWithValue(repository)],
      );
      final subscription = container.listen(searchSuggestionsControllerProvider, (p, n) {});
      final controller = container.read(searchSuggestionsControllerProvider.notifier);
      controller.onFocusChanged(true);
      controller.onTextChanged('ip');
      async.elapse(pause);

      subscription.close();
      container.dispose();
      slow.complete([_iphone]);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 1));

      expect(repository.suggestCalls, ['ip']);
    });
  });
}
