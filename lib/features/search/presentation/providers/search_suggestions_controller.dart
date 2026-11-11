import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/search_repository.dart';
import '../../domain/search_suggestion.dart';

/// The suggestions shown for [query], the text they were asked for.
@immutable
class SuggestionsState {
  final String query;
  final List<SearchSuggestion> items;

  const SuggestionsState({this.query = '', this.items = const []});

  bool get isEmpty => items.isEmpty;
}

/// Auto-complete for the search field. It asks only while the field is focused, holds at least
/// two characters and has not been submitted, waits 250 ms after typing, and ignores a response
/// that belongs to an older request. A failure is silent: there is just no list, and the search
/// itself is never held up by it.
class SearchSuggestionsController extends Notifier<SuggestionsState> {
  static const Duration debounce = Duration(milliseconds: 250);
  static const int minLength = 2;

  Timer? _timer;
  int _request = 0;
  String _text = '';
  bool _focused = false;
  bool _submitted = false;

  SearchRepository get _repository => ref.read(searchRepositoryProvider);

  @override
  SuggestionsState build() {
    ref.onDispose(() => _timer?.cancel());
    return const SuggestionsState();
  }

  /// The text of the field changed.
  void onTextChanged(String text) {
    _text = text.trim();
    _submitted = false;
    _schedule();
  }

  void onFocusChanged(bool focused) {
    _focused = focused;
    _schedule();
  }

  /// The search was submitted, by the keyboard or by choosing a suggestion.
  void onSubmitted() {
    _submitted = true;
    _clear();
  }

  bool get _wanted => _focused && !_submitted && _text.length >= minLength;

  void _schedule() {
    if (!_wanted) {
      _clear();
      return;
    }
    final query = _text;
    _timer?.cancel();
    final request = ++_request;
    _timer = Timer(debounce, () => unawaited(_fetch(query, request)));
  }

  void _clear() {
    _timer?.cancel();
    _request++;
    if (!state.isEmpty) state = const SuggestionsState();
  }

  Future<void> _fetch(String query, int request) async {
    List<SearchSuggestion> items;
    try {
      items = await _repository.suggest(query);
    } on Object {
      items = const [];
    }
    if (!ref.mounted || request != _request) return;
    state = SuggestionsState(query: query, items: items);
  }
}

final searchSuggestionsControllerProvider =
    NotifierProvider.autoDispose<SearchSuggestionsController, SuggestionsState>(
  SearchSuggestionsController.new,
);
