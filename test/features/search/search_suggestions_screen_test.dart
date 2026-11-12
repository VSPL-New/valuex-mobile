import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/listing/data/listing_repository.dart';
import 'package:valuex_mobile/features/listing/domain/category.dart';
import 'package:valuex_mobile/features/notifications/data/notifications_repository.dart';
import 'package:valuex_mobile/features/search/data/search_repository.dart';
import 'package:valuex_mobile/features/search/domain/search_page.dart';
import 'package:valuex_mobile/features/search/domain/search_suggestion.dart';
import 'package:valuex_mobile/features/search/domain/transaction_intent.dart';
import 'package:valuex_mobile/features/search/presentation/search_screen.dart';
import 'package:valuex_mobile/features/search/presentation/widgets/intent_sheet.dart';
import 'package:valuex_mobile/features/search/presentation/widgets/search_suggestions_list.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fonts.dart';
import 'search_fixtures.dart';

class _MockListingRepository extends Mock implements ListingRepository {}

class _MockNotifications extends Mock implements NotificationsRepository {}

const _mobiles = CategoryNode(
  code: 'L1-M',
  name: 'Mobiles & Tablets',
  level: 1,
  hasChildren: true,
  popular: true,
);

const _smartphones = SearchSuggestion(
  text: 'Smartphones',
  type: SuggestionType.category,
  categoryCode: 'CAT-0001',
);
const _apartments = SearchSuggestion(
  text: 'Apartments',
  type: SuggestionType.category,
  categoryCode: 'CAT-0099',
);
const _iphone = SearchSuggestion(text: 'iPhone 14 128GB', type: SuggestionType.listing);
const _iphoneCase = SearchSuggestion(text: 'iphone case', type: SuggestionType.listing);

void main() {
  setUpAll(loadBrandFonts);

  late FakeSearchRepository search;
  late _MockListingRepository categories;
  late AppHarness harness;

  setUp(() {
    search = FakeSearchRepository(
      (criteria, page) async => SearchPage.fromJson(
        pageJson([listingJson('l1', title: 'Apple iPhone 14 128GB', cardUrl: null)]),
      ),
    );
    search.suggestHandler = (query) async => [_smartphones, _iphone, _iphoneCase];
    categories = _MockListingRepository();
    when(
      () => categories.categoryChildren(
        parentCode: any(named: 'parentCode'),
        scope: any(named: 'scope'),
      ),
    ).thenAnswer((_) async => [_mobiles]);
  });

  Future<void> open(WidgetTester tester) async {
    final notifications = _MockNotifications();
    when(notifications.unreadCount).thenAnswer((_) async => 0);
    harness = AppHarness(
      tester,
      extraOverrides: [
        searchRepositoryProvider.overrideWithValue(search),
        listingRepositoryProvider.overrideWithValue(categories),
        notificationsRepositoryProvider.overrideWithValue(notifications),
      ],
    )..signedInAs(AccountStatus.active);
    await harness.launch(location: '/search');
  }

  /// Types and waits for the suggestions only (250 ms), before the 400 ms search fires.
  Future<void> typeForSuggestions(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  Future<void> typeAndSettle(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(const Duration(milliseconds: 450));
    await harness.settle();
  }

  String fieldText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  testWidgets('suggestions replace the popular categories under the field', (tester) async {
    await open(tester);
    expect(find.text('Popular categories'), findsOneWidget);

    await typeForSuggestions(tester, 'iph');

    expect(search.suggestCalls, ['iph']);
    expect(find.byType(SuggestionRow), findsNWidgets(3));
    expect(find.text('Popular categories'), findsNothing);
    await harness.dispose();
  });

  testWidgets('a listing row has the search icon and the typed part in bold', (tester) async {
    await open(tester);

    await typeForSuggestions(tester, 'iph');

    final row = find.widgetWithText(SuggestionRow, 'iPhone 14 128GB');
    expect(find.descendant(of: row, matching: find.byIcon(Icons.search_rounded)), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('in Category')), findsNothing);
    final text = tester.widget<Text>(find.descendant(of: row, matching: find.byType(Text)));
    final spans = (text.textSpan! as TextSpan).children!.cast<TextSpan>();
    expect(spans[0].text, 'iPh');
    expect(spans[0].style!.fontWeight, FontWeight.w700);
    expect(spans[1].text, 'one 14 128GB');
    expect(spans[1].style, isNull);
    expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
    await harness.dispose();
  });

  testWidgets('a category row has the category icon, the name and a trailing label',
      (tester) async {
    await open(tester);

    await typeForSuggestions(tester, 'smart');

    final row = find.widgetWithText(SuggestionRow, 'Smartphones');
    expect(
      find.descendant(of: row, matching: find.byIcon(Icons.category_outlined)),
      findsOneWidget,
    );
    expect(find.descendant(of: row, matching: find.text('in Category')), findsOneWidget);
    expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
    await harness.dispose();
  });

  testWidgets('the rows speak as buttons with a label of their own', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester);

    await typeForSuggestions(tester, 'iph');

    expect(
      tester.getSemantics(find.widgetWithText(SuggestionRow, 'iPhone 14 128GB')),
      isSemantics(label: 'Search for iPhone 14 128GB', isButton: true, hasTapAction: true),
    );
    expect(
      tester.getSemantics(find.widgetWithText(SuggestionRow, 'Smartphones')),
      isSemantics(label: 'Browse category Smartphones', isButton: true, hasTapAction: true),
    );
    expect(find.bySemanticsLabel('Search suggestions'), findsOneWidget);
    handle.dispose();
    await harness.dispose();
  });

  testWidgets('tapping a listing row fills the field, closes the list and searches',
      (tester) async {
    await open(tester);
    await typeForSuggestions(tester, 'iph');

    await tester.tap(find.widgetWithText(SuggestionRow, 'iPhone 14 128GB'));
    await harness.settle();

    expect(fieldText(tester), 'iPhone 14 128GB');
    expect(find.byType(SuggestionRow), findsNothing);
    expect(search.calls, hasLength(1));
    expect(search.calls.single.criteria.query, 'iPhone 14 128GB');
    expect(find.text('Apple iPhone 14 128GB'), findsOneWidget);
    expect(search.suggestCalls, ['iph']);
    await harness.dispose();
  });

  testWidgets("tapping a category row opens that category's results", (tester) async {
    await open(tester);
    await typeForSuggestions(tester, 'smart');

    await tester.tap(find.widgetWithText(SuggestionRow, 'Smartphones'));
    await harness.settle();

    expect(find.byType(SearchScreen), findsOneWidget);
    final call = search.calls.last;
    expect(call.criteria.categoryCode, 'CAT-0001');
    expect(call.criteria.categoryName, 'Smartphones');
    expect(call.criteria.categoryLevel, 3);
    expect(call.criteria.isLeafCategory, isTrue);
    expect(call.criteria.query, isEmpty);
    expect(find.text('Apple iPhone 14 128GB'), findsOneWidget);
    await harness.dispose();
  });

  testWidgets('a category under Real Estate asks Buy, Rent or Lease when the server says so',
      (tester) async {
    search.suggestHandler = (query) async => [_apartments];
    search.handler =
        (criteria, page) async => criteria.categoryCode != null && criteria.intent == null
            ? throw const ApiError(
                type: ApiErrorType.business,
                message: 'x',
                code: 'ERROR_INTENT_REQUIRED',
                statusCode: 400,
              )
            : SearchPage.fromJson(pageJson([listingJson('l1', title: 'Flat for sale')]));
    await open(tester);
    await typeForSuggestions(tester, 'apart');

    await tester.tap(find.widgetWithText(SuggestionRow, 'Apartments'));
    await harness.settle();

    expect(find.byType(IntentSheet), findsOneWidget);
    await tester.tap(find.text('Buy'));
    await harness.settle();

    expect(search.calls.last.criteria.categoryCode, 'CAT-0099');
    expect(search.calls.last.criteria.intent, TransactionIntent.sale);
    expect(find.text('Flat for sale'), findsOneWidget);
    await harness.dispose();
  });

  testWidgets('the keyboard search action still submits the typed text', (tester) async {
    await open(tester);
    await typeForSuggestions(tester, 'iph');
    expect(find.byType(SuggestionRow), findsNWidgets(3));

    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await harness.settle();

    expect(find.byType(SuggestionRow), findsNothing);
    expect(search.calls, hasLength(1));
    expect(search.calls.single.criteria.query, 'iph');
    expect(find.text('Apple iPhone 14 128GB'), findsOneWidget);
    await harness.dispose();
  });

  testWidgets('one character shows no suggestions and clearing the text closes the list',
      (tester) async {
    await open(tester);

    await typeForSuggestions(tester, 'i');
    expect(search.suggestCalls, isEmpty);
    expect(find.byType(SuggestionRow), findsNothing);

    await typeForSuggestions(tester, 'iph');
    expect(find.byType(SuggestionRow), findsNWidgets(3));

    await tester.tap(find.byTooltip('Clear search text'));
    await tester.pump();

    expect(find.byType(SuggestionRow), findsNothing);
    expect(find.text('Popular categories'), findsOneWidget);
    await harness.dispose();
  });

  testWidgets('a failure shows nothing and the normal search still runs', (tester) async {
    search.suggestHandler = (query) async =>
        throw const ApiError(type: ApiErrorType.server, message: 'down', statusCode: 503);
    await open(tester);

    await typeAndSettle(tester, 'iphone');

    expect(search.suggestCalls, ['iphone']);
    expect(find.byType(SuggestionRow), findsNothing);
    expect(search.calls.single.criteria.query, 'iphone');
    expect(find.text('Apple iPhone 14 128GB'), findsOneWidget);
    await harness.dispose();
  });

  testWidgets('the debounced search runs as before while suggestions are shown', (tester) async {
    await open(tester);

    await typeAndSettle(tester, 'iph');

    expect(search.calls.single.criteria.query, 'iph');
    expect(find.byType(SuggestionRow), findsNWidgets(3));
    await harness.dispose();
  });

  test('the labels are in both languages', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final hi = lookupAppLocalizations(const Locale('hi'));

    expect(en.searchSuggestionCategoryTag, 'in Category');
    expect(hi.searchSuggestionCategoryTag, isNot(en.searchSuggestionCategoryTag));
    expect(hi.searchSuggestionsLabel, isNot(en.searchSuggestionsLabel));
    expect(hi.searchSuggestionListingLabel('x'), contains('x'));
    expect(hi.searchSuggestionCategoryLabel('x'), contains('x'));
  });
}
