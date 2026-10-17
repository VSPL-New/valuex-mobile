import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/app_router.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/home/domain/entities/listing_category.dart';
import 'package:valuex_mobile/features/notifications/data/notifications_repository.dart';
import 'package:valuex_mobile/features/home/domain/entities/home_location.dart';
import 'package:valuex_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:valuex_mobile/features/listing/data/listing_repository.dart';
import 'package:valuex_mobile/features/listing/domain/listing_details.dart';
import 'package:valuex_mobile/features/listing/presentation/providers/item_details_controller.dart';
import 'package:valuex_mobile/features/listing/presentation/widgets/category_chips.dart';
import 'package:valuex_mobile/features/listing/presentation/widgets/option_chip.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fonts.dart';

class _MockNotifications extends Mock implements NotificationsRepository {}

class _MockRepository extends Mock implements ListingRepository {}

class _FakeLocation extends HomeLocationController {
  _FakeLocation(this.value);

  final HomeLocationState value;

  @override
  Future<HomeLocationState> build() async => value;
}

class _FakeDraft extends Fake implements ListingDetailsDraft {}

const _complete = ListingDetailsDraft(
  title: 'Sony headphones',
  categorySlug: 'electronics',
  condition: ListingCondition.good,
  description: 'Barely used',
  price: '1,299.50',
);

const _suggestion = AiSuggestion(
  id: 's1',
  categorySlug: 'electronics',
  title: 'Headphones',
  condition: ListingCondition.good,
  description: 'Over-ear',
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeDraft());
    loadBrandFonts();
  });

  group('category chips', () {
    test('chipRows wraps at the available width', () {
      expect(chipRows(const [], 320, 8), 0);
      expect(chipRows(const [100, 100, 100], 320, 8), 1);
      expect(chipRows(const [100, 100, 100, 100], 320, 8), 2);
      expect(chipRows(const [500], 320, 8), 1, reason: 'a long chip is capped to the line');
    });

    List<int> pick({int count = 12, int selected = -1, int maxRows = 3}) => visibleChipIndexes(
          widths: List.filled(count, 100),
          othersWidth: 100,
          maxWidth: 320,
          spacing: 8,
          selectedIndex: selected,
          maxRows: maxRows,
        );

    test('shows every category when they fit in three rows', () {
      expect(pick(count: 9), List.generate(9, (i) => i));
    });

    test('keeps room for Others when they do not fit', () {
      expect(pick(), [0, 1, 2, 3, 4, 5, 6, 7]);
    });

    test('keeps a selected category that would be hidden, last', () {
      expect(pick(selected: 11), [0, 1, 2, 3, 4, 5, 6, 11]);
      expect(pick(selected: 2), [0, 1, 2, 3, 4, 5, 6, 7]);
    });

    test('shows only Others when nothing fits', () {
      expect(pick(maxRows: 0), isEmpty);
    });
  });

  group('ItemDetailsScreen', () {
    late _MockRepository repository;

    setUp(() {
      repository = _MockRepository();
      when(() => repository.saveDetails(any(), any(), city: any(named: 'city')))
          .thenAnswer((_) async {});
      when(() => repository.sendSuggestionFeedback(any(), any(), any())).thenAnswer((_) async {});
    });

    Future<AppHarness> open(
      WidgetTester tester, {
      ItemDetailsArgs args = const ItemDetailsArgs(listingId: 'l1'),
      HomeLocationState location = const LocationNeeded(LocationNeed.notAsked),
      double textScale = 1,
      List<ListingCategory> categories = const [
        ListingCategory(id: 'electronics', name: 'Electronics'),
        ListingCategory(id: 'books', name: 'Books'),
      ],
    }) async {
      final notifications = _MockNotifications();
      when(notifications.unreadCount).thenAnswer((_) async => 0);
      final harness = AppHarness(tester, extraOverrides: [
        notificationsRepositoryProvider.overrideWithValue(notifications),
        listingRepositoryProvider.overrideWithValue(repository),
        homeLocationControllerProvider.overrideWith(() => _FakeLocation(location)),
        categoriesProvider.overrideWith((ref) async => categories),
      ])
        ..signedInAs(AccountStatus.active, aadhaarVerified: true);
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await harness.launch(location: RouteNames.home);
      // Tall screen so the whole form is built (the list builds lazily).
      tester.view.physicalSize = Size(1080, 1600 * textScale * 4);
      harness.container.read(appRouterProvider).go(RouteNames.sellDetails, extra: args);
      await harness.settle();
      return harness;
    }

    testWidgets('manual entry: Continue stays off until every field is valid, then saves',
        (tester) async {
      final harness = await open(
        tester,
        location: const LocationKnown(HomeLocation(city: 'Pune', area: 'Baner', state: 'MH')),
      );
      expect(find.text('Item Details'), findsOneWidget);
      expect(find.text('Fill in the details'), findsOneWidget);
      expect(find.textContaining('AI filled these'), findsNothing);
      expect(find.text('Baner'), findsOneWidget);
      expect(find.text('Fill in the required fields to continue'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), '   ');
      await harness.settle();
      expect(find.text('Enter a title for your item'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'Sony');
      await tester.tap(find.text('Electronics'));
      await tester.tap(find.text('Good'));
      await tester.enterText(find.byType(TextField).at(1), 'Used');
      await tester.enterText(find.byType(TextField).at(2), '0');
      await harness.settle();
      expect(find.text('Enter a valid price'), findsOneWidget);
      await tester.tap(find.text('Choose Listing Plan'));
      await harness.settle();
      verifyNever(() => repository.saveDetails(any(), any(), city: any(named: 'city')));

      await tester.enterText(find.byType(TextField).at(2), '1,200');
      await harness.settle();
      expect(find.text('Fill in the required fields to continue'), findsNothing);
      await tester.tap(find.text('Choose Listing Plan'));
      await harness.settle();

      verify(() => repository.saveDetails('l1', any(), city: 'Pune')).called(1);
      expect(find.text('Details saved. Choosing a plan is coming soon.'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('AI-filled entry shows the banner and prefilled values', (tester) async {
      final harness = await open(
        tester,
        args: const ItemDetailsArgs(listingId: 'l1', suggestion: _suggestion),
      );
      expect(find.text('AI filled these from your photos. Review and edit as needed.'),
          findsOneWidget);
      expect(find.text('Fill in the details'), findsNothing,
          reason: 'the AI notice replaces it');
      expect(find.text('Headphones'), findsOneWidget);
      expect(find.text('Over-ear'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(2), '500');
      await harness.settle();
      await tester.tap(find.text('Choose Listing Plan'));
      await harness.settle();
      verify(() => repository.sendSuggestionFeedback('l1', 's1', any())).called(1);
      await harness.dispose();
    });

    testWidgets('a server error is shown and the seller can try again', (tester) async {
      when(() => repository.saveDetails(any(), any(), city: any(named: 'city'))).thenThrow(
        const ApiError(type: ApiErrorType.network, message: 'x'),
      );
      final harness = await open(
        tester,
        args: const ItemDetailsArgs(listingId: 'l1', suggestion: _suggestion),
      );
      await tester.enterText(find.byType(TextField).at(2), '500');
      await harness.settle();
      await tester.tap(find.text('Choose Listing Plan'));
      await harness.settle();

      expect(find.text('Details saved. Choosing a plan is coming soon.'), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('categories take at most 3 rows; Others opens the rest in a pop-up',
        (tester) async {
      const names = [
        'Electronics',
        'Laptops',
        'Mobiles',
        'Cameras',
        'Vehicles',
        'Furniture',
        'Fashion',
        'Appliances',
        'Books',
        'Sports',
        'Toys',
        'Music',
      ];
      final harness = await open(tester, categories: [
        for (final name in names) ListingCategory(id: name.toLowerCase(), name: name),
      ]);

      final chips = find.descendant(
        of: find.byType(CategoryChips),
        matching: find.byType(OptionChip),
      );
      final rows = {
        for (final e in chips.evaluate()) tester.getTopLeft(find.byWidget(e.widget)).dy
      };
      expect(rows.length, lessThanOrEqualTo(3));
      expect(find.text('Electronics'), findsOneWidget);
      expect(find.descendant(of: find.byType(CategoryChips), matching: find.text('Music')),
          findsNothing);
      final others = find.descendant(of: find.byType(CategoryChips), matching: find.text('Others'));
      expect(others, findsOneWidget);
      expect(tester.getTopLeft(find.byWidget(chips.evaluate().last.widget)).dy,
          rows.reduce((a, b) => a > b ? a : b),
          reason: 'Others is the last chip');

      await tester.tap(others);
      await harness.settle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('Music')),
          findsOneWidget);

      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Music')));
      await harness.settle();
      expect(find.byType(AlertDialog), findsNothing);
      final selected =
          find.descendant(of: find.byType(CategoryChips), matching: find.text('Music'));
      expect(selected, findsOneWidget, reason: 'the chosen category is shown on the page');
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester
          .tap(find.descendant(of: find.byType(CategoryChips), matching: find.text('Others')));
      await harness.settle();
      await tester.tap(find.text('Close'));
      await harness.settle();
      expect(find.byType(AlertDialog), findsNothing);
      await harness.dispose();
    });

    testWidgets('lays out without overflow at 2x text size', (tester) async {
      final harness = await open(tester, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.text('Item Details'), findsOneWidget);
      await harness.dispose();
    });
  });

  group('ListingCondition', () {
    test('maps API values both ways', () {
      expect(ListingCondition.fromApi('LIKE_NEW'), ListingCondition.likeNew);
      expect(ListingCondition.fromApi('x'), isNull);
      expect(ListingCondition.fromApi(null), isNull);
      expect(ListingCondition.poor.apiValue, 'POOR');
    });
  });

  group('ListingDetailsDraft', () {
    test('an empty draft lists every field in page order', () {
      expect(const ListingDetailsDraft().invalidFields, DetailsField.values);
    });

    test('a complete draft is valid', () {
      expect(_complete.isValid, isTrue);
      expect(_complete.parsedPrice, 1299.5);
    });

    test('rejects blank, over-long text', () {
      expect(_complete.copyWith(title: '   ').invalidFields, [DetailsField.title]);
      expect(_complete.copyWith(title: 'a' * 101).invalidFields, [DetailsField.title]);
      expect(_complete.copyWith(title: 'a' * 100).isValid, isTrue);
      expect(_complete.copyWith(description: 'a' * 2001).invalidFields, [DetailsField.description]);
    });

    test('price accepts up to 2 decimals and the limit only', () {
      for (final bad in ['', '0', '0.00', 'abc', '-5', '1.234', '10000000.01', '1e3']) {
        expect(_complete.copyWith(price: bad).parsedPrice, isNull, reason: bad);
      }
      expect(_complete.copyWith(price: '10000000').parsedPrice, 10000000);
      expect(_complete.copyWith(price: ' 99.9 ').parsedPrice, 99.9);
    });
  });

  group('AiSuggestion and feedback', () {
    test('asDraft clips long text and leaves price empty', () {
      final draft = AiSuggestion(id: 'x', title: 'a' * 150, description: 'b' * 2500).asDraft;
      expect(draft.title.length, 100);
      expect(draft.description.length, 2000);
      expect(draft.price, isEmpty);
      expect(const AiSuggestion(id: 'y').asDraft.title, isEmpty);
    });

    test('reports accepted, edited and rejected fields only for suggested ones', () {
      final current = _complete.copyWith(title: 'Sony WH-1000', description: ' ');
      final feedback = suggestionFeedback(_suggestion, current);
      final actions = {for (final f in feedback) f.field: f.action};
      expect(actions, {
        'CATEGORY': SuggestionAction.accepted,
        'TITLE': SuggestionAction.edited,
        'CONDITION': SuggestionAction.accepted,
        'DESCRIPTION': SuggestionAction.rejected,
      });
      expect(feedback.firstWhere((f) => f.field == 'TITLE').toJson(), {
        'field': 'TITLE',
        'action': 'EDITED',
        'originalValue': 'Headphones',
        'finalValue': 'Sony WH-1000',
      });
      expect(suggestionFeedback(const AiSuggestion(id: 'z'), _complete), isEmpty);
    });
  });

  group('ItemDetailsController', () {
    late _MockRepository repository;

    setUp(() {
      repository = _MockRepository();
      when(() => repository.saveDetails(any(), any(), city: any(named: 'city')))
          .thenAnswer((_) async {});
      when(() => repository.sendSuggestionFeedback(any(), any(), any())).thenAnswer((_) async {});
    });

    ProviderContainer containerFor(ItemDetailsArgs args, {HomeLocationState? location}) {
      final container = ProviderContainer(overrides: [
        listingRepositoryProvider.overrideWithValue(repository),
        homeLocationControllerProvider.overrideWith(
          () => _FakeLocation(location ?? const LocationNeeded(LocationNeed.denied)),
        ),
      ]);
      addTearDown(container.dispose);
      container.listen(itemDetailsControllerProvider(args), (previous, next) {});
      return container;
    }

    const args = ItemDetailsArgs(listingId: 'l1');

    void fill(ItemDetailsController c) => c
      ..setTitle(_complete.title)
      ..setCategory('electronics')
      ..setCondition(ListingCondition.good)
      ..setDescription(_complete.description)
      ..setPrice(_complete.price);

    test('starts empty, not continuable, no hints', () {
      final state = containerFor(args).read(itemDetailsControllerProvider(args));
      expect(state.canContinue, isFalse);
      expect(state.aiFilled, isFalse);
      expect(state.visibleHints, isEmpty);
    });

    test('starts from an AI suggestion', () {
      const aiArgs = ItemDetailsArgs(listingId: 'l1', suggestion: _suggestion);
      final state = containerFor(aiArgs).read(itemDetailsControllerProvider(aiArgs));
      expect(state.aiFilled, isTrue);
      expect(state.draft.title, 'Headphones');
      expect(state.canContinue, isFalse, reason: 'price is still needed');
    });

    test('shows hints only for fields the seller touched', () {
      final container = containerFor(args);
      final controller = container.read(itemDetailsControllerProvider(args).notifier);
      controller.setTitle(' ');
      controller.setPrice('0');
      expect(
        container.read(itemDetailsControllerProvider(args)).visibleHints,
        [DetailsField.title, DetailsField.price],
      );
    });

    test('args compare by listing and suggestion id', () {
      expect(const ItemDetailsArgs(listingId: 'a'), const ItemDetailsArgs(listingId: 'a'));
      expect(const ItemDetailsArgs(listingId: 'a'), isNot(const ItemDetailsArgs(listingId: 'b')));
      expect(const ItemDetailsArgs(listingId: 'a').hashCode,
          const ItemDetailsArgs(listingId: 'a').hashCode);
    });

    test('save does nothing while invalid', () async {
      final container = containerFor(args);
      final result = await container.read(itemDetailsControllerProvider(args).notifier).save();
      expect(result.saved, isFalse);
      verifyNever(() => repository.saveDetails(any(), any(), city: any(named: 'city')));
    });

    test('save sends the details with only the chosen city', () async {
      final container = containerFor(
        args,
        location: const LocationKnown(HomeLocation(city: 'Pune', area: 'Baner')),
      );
      await container.read(homeLocationControllerProvider.future);
      final controller = container.read(itemDetailsControllerProvider(args).notifier);
      fill(controller);

      final result = await controller.save();

      expect(result.saved, isTrue);
      verify(() => repository.saveDetails('l1', any(), city: 'Pune')).called(1);
      verifyNever(() => repository.sendSuggestionFeedback(any(), any(), any()));
      expect(container.read(itemDetailsControllerProvider(args)).isSaving, isFalse);
    });

    test('save sends no city when the location is not known', () async {
      final container = containerFor(args);
      final controller = container.read(itemDetailsControllerProvider(args).notifier);
      fill(controller);
      await controller.save();
      verify(() => repository.saveDetails('l1', any(), city: null)).called(1);
    });

    test('save returns the server error', () async {
      const error = ApiError(type: ApiErrorType.business, message: 'x', code: 'ERROR_X');
      when(() => repository.saveDetails(any(), any(), city: any(named: 'city'))).thenThrow(error);
      final container = containerFor(args);
      final controller = container.read(itemDetailsControllerProvider(args).notifier);
      fill(controller);

      final result = await controller.save();

      expect(result.saved, isFalse);
      expect(result.error, error);
      expect(container.read(itemDetailsControllerProvider(args)).isSaving, isFalse);
    });

    test('save reports AI feedback and ignores a feedback failure', () async {
      when(() => repository.sendSuggestionFeedback(any(), any(), any()))
          .thenThrow(const ApiError(type: ApiErrorType.network, message: 'x'));
      const aiArgs = ItemDetailsArgs(listingId: 'l1', suggestion: _suggestion);
      final container = containerFor(aiArgs);
      final controller = container.read(itemDetailsControllerProvider(aiArgs).notifier);
      controller.setPrice('500');

      final result = await controller.save();

      expect(result.saved, isTrue);
      verify(() => repository.sendSuggestionFeedback('l1', 's1', any())).called(1);
    });

    test('save skips feedback when the suggestion had nothing to report', () async {
      const aiArgs = ItemDetailsArgs(listingId: 'l1', suggestion: AiSuggestion(id: 'e'));
      final container = containerFor(aiArgs);
      final controller = container.read(itemDetailsControllerProvider(aiArgs).notifier);
      fill(controller);
      await controller.save();
      verifyNever(() => repository.sendSuggestionFeedback(any(), any(), any()));
    });
  });
}
