import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/core/routing/app_router.dart';
import 'package:valuex_mobile/core/routing/route_names.dart';
import 'package:valuex_mobile/features/auth/domain/entities/account_status.dart';
import 'package:valuex_mobile/features/home/domain/entities/home_location.dart';
import 'package:valuex_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:valuex_mobile/features/listing/data/listing_repository.dart';
import 'package:valuex_mobile/features/listing/domain/category.dart';
import 'package:valuex_mobile/features/listing/domain/listing_details.dart';
import 'package:valuex_mobile/features/listing/domain/listing_schema.dart';
import 'package:valuex_mobile/features/listing/domain/restricted_check.dart';
import 'package:valuex_mobile/features/listing/presentation/listing_plan_screen.dart';
import 'package:valuex_mobile/features/listing/presentation/providers/item_details_controller.dart';
import 'package:valuex_mobile/features/notifications/data/notifications_repository.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fonts.dart';
import 'listing_fixtures.dart';

class _MockNotifications extends Mock implements NotificationsRepository {}

class _MockRepository extends Mock implements ListingRepository {}

class _FakeLocation extends HomeLocationController {
  _FakeLocation(this.value);

  final HomeLocationState value;

  @override
  Future<HomeLocationState> build() async => value;
}

class _FakeDraft extends Fake implements ListingDetailsDraft {}

class _FakeSchema extends Fake implements ListingSchema {}

const _suggestion = AiSuggestion(
  id: 's1',
  categoryCode: 'CAT-1',
  title: 'Headphones',
  condition: ListingCondition.good,
  description: 'Over-ear',
);

const _l1 = CategoryNode(
    code: 'L1-M', name: 'Mobiles & Tablets', level: 1, hasChildren: true, popular: true);
const _l2 =
    CategoryNode(code: 'L2-S', name: 'Smartphones', level: 2, hasChildren: true, popular: true);
const _l3 = CategoryNode(code: 'CAT-1', name: 'Android Phones', level: 3, hasChildren: false);

final _apartmentSchema = ListingSchema.fromJson(schemaJson(
  code: 'CAT-7',
  group: 'REAL_ESTATE',
  profile: 'PROP_HOME',
  common: {
    'conditionVisible': false,
    'quantityVisible': false,
    'negotiableVisible': false,
    'priceDerived': true,
  },
  fields: [
    field('property_type', 'OPTION', required: true, prefillOption: 'APARTMENT', options: [
      {'code': 'APARTMENT', 'label': 'Apartment'},
      {'code': 'VILLA', 'label': 'Villa'},
    ]),
    field('keys_known', 'TEXT'),
  ],
));

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeDraft());
    registerFallbackValue(_FakeSchema());
    registerFallbackValue(CategoryScope.all);
    loadBrandFonts();
  });

  Finder byHint(String hint) =>
      find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == hint);
  Finder attributeField(String code, String key) => find.descendant(
        of: find.byKey(ValueKey('$code:$key')),
        matching: find.byType(TextField),
      );
  final titleField = byHint('e.g. iPhone 13 128GB');
  final notesField = byHint('Scratches, repairs or missing parts. Write none if there are none.');
  final descriptionField = byHint('Age, how it was used, accessories included');
  final priceField =
      find.byWidgetPredicate((w) => w is TextField && w.decoration?.prefixText == '₹ ');

  late _MockRepository repository;

  void stubRepository() {
    repository = _MockRepository();
    when(() => repository.setCategory(any(), any())).thenAnswer((_) async {});
    when(() => repository.listingSchema(any())).thenAnswer((invocation) async =>
        invocation.positionalArguments.first == 'CAT-7' ? _apartmentSchema : phoneSchema);
    when(() => repository.saveDetails(any(), any(), any(), city: any(named: 'city')))
        .thenAnswer((_) async {});
    when(() => repository.sendSuggestionFeedback(any(), any(), any())).thenAnswer((_) async {});
    when(() => repository.sellerPlans()).thenAnswer((_) async => []);
    when(() => repository.checkRestrictedItems(any())).thenAnswer(
        (_) async => const RestrictedCheck(checkId: 'c1', result: RestrictedResult.safe));
    when(() => repository.acceptCompliance(any(), any(), any())).thenAnswer((_) async {});
    when(() => repository.appealRestricted(any(), any(), any())).thenAnswer((_) async {});
    when(() => repository.categoryChildren(
          parentCode: any(named: 'parentCode'),
          scope: any(named: 'scope'),
        )).thenAnswer((invocation) async {
      final parent = invocation.namedArguments[#parentCode] as String?;
      final scope = invocation.namedArguments[#scope] as CategoryScope?;
      return switch ((parent, scope)) {
        (null, CategoryScope.popular) => [_l1],
        ('L1-M', CategoryScope.popular) => [_l2],
        ('L2-S', CategoryScope.all) => [_l3],
        _ => <CategoryNode>[],
      };
    });
  }

  group('ItemDetailsScreen', () {
    setUp(stubRepository);

    Future<AppHarness> open(
      WidgetTester tester, {
      ItemDetailsArgs args = const ItemDetailsArgs(listingId: 'l1'),
      HomeLocationState location = const LocationNeeded(LocationNeed.notAsked),
      double textScale = 1,
    }) async {
      final notifications = _MockNotifications();
      when(notifications.unreadCount).thenAnswer((_) async => 0);
      final harness = AppHarness(tester, extraOverrides: [
        notificationsRepositoryProvider.overrideWithValue(notifications),
        listingRepositoryProvider.overrideWithValue(repository),
        homeLocationControllerProvider.overrideWith(() => _FakeLocation(location)),
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

    Future<void> chooseCategory(WidgetTester tester, AppHarness harness) async {
      await tester.tap(find.text('Choose a category'));
      await harness.settle();
      await tester.tap(find.text('Mobiles & Tablets'));
      await harness.settle();
      await tester.tap(find.text('Smartphones'));
      await harness.settle();
      await tester.tap(find.text('Android Phones'));
      await harness.settle();
    }

    testWidgets('manual entry: pick a category, fill its form, then Continue saves',
        (tester) async {
      final harness = await open(
        tester,
        location: const LocationKnown(HomeLocation(city: 'Pune', area: 'Baner', state: 'MH')),
      );
      expect(find.text('Item Details'), findsOneWidget);
      expect(find.text('Fill in the details'), findsOneWidget);
      expect(find.textContaining('AI filled these'), findsNothing);
      expect(find.text('Good'), findsNothing, reason: 'the form follows the category');
      expect(find.text('Fill in the required fields to continue'), findsOneWidget);

      await chooseCategory(tester, harness);
      verify(() => repository.setCategory('l1', 'CAT-1')).called(1);
      expect(find.text('Android Phones'), findsOneWidget);
      expect(find.text('Mobiles & Tablets > Smartphones'), findsOneWidget);
      expect(find.text('Baner'), findsOneWidget);
      expect(find.text('ABOUT THIS ITEM'), findsOneWidget);

      await tester.enterText(titleField, '   ');
      await harness.settle();
      expect(find.text('Enter a title for your item'), findsOneWidget);

      await tester.enterText(titleField, 'Sony');
      await tester.tap(find.text('Good'));
      await tester.enterText(notesField, 'Small scratch');
      await tester.enterText(descriptionField, 'Used');
      await tester.enterText(attributeField('CAT-1', 'brand'), 'Sony');
      await tester.tap(find.text('64 GB'));
      await tester.tap(find.text('Yes'));
      await tester.enterText(priceField, '0');
      await harness.settle();
      expect(find.text('Enter a valid price'), findsOneWidget);
      await tester.tap(find.text('Choose Listing Plan'));
      await harness.settle();
      verifyNever(() => repository.saveDetails(any(), any(), any(), city: any(named: 'city')));

      await tester.enterText(priceField, '1,200');
      await harness.settle();
      expect(find.text('Fill in the required fields to continue'), findsNothing);
      await tester.tap(find.text('Choose Listing Plan'));
      await harness.settle();

      final saved = verify(() => repository.saveDetails(
            'l1',
            captureAny(),
            any(),
            city: 'Pune',
          )).captured.single as ListingDetailsDraft;
      expect(saved.categoryCode, 'CAT-1');
      expect(saved.attributes, {'brand': 'Sony', 'storage_gb': '64_GB'});
      expect(saved.negotiable, isTrue);
      expect(find.byType(ListingPlanScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('asks only what the form shows: a missing required value is hinted',
        (tester) async {
      final harness = await open(tester);
      await chooseCategory(tester, harness);

      await tester.enterText(attributeField('CAT-1', 'brand'), 'x');
      await tester.enterText(attributeField('CAT-1', 'brand'), '');
      await harness.settle();
      expect(find.text('brand is required'), findsOneWidget);

      await tester.enterText(attributeField('CAT-1', 'brand'), 'a' * 10);
      await harness.settle();
      expect(find.text('brand is required'), findsNothing);
      await harness.dispose();
    });

    testWidgets('optional and "more details" fields sit in an expandable section', (tester) async {
      final harness = await open(tester);
      await chooseCategory(tester, harness);

      expect(find.text('More details'), findsOneWidget);
      expect(find.text('age months'), findsNothing);

      await tester.tap(find.text('More details'));
      await harness.settle();
      expect(find.text('age months'), findsOneWidget);
      expect(find.text('battery health pct (%)'), findsOneWidget);

      await tester.enterText(attributeField('CAT-1', 'age_months'), '5000');
      await harness.settle();
      expect(find.text('Enter a valid age months'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('AI-filled entry loads the category form and shows the banner', (tester) async {
      final harness = await open(
        tester,
        args: const ItemDetailsArgs(listingId: 'l1', suggestion: _suggestion),
      );
      expect(find.text('AI filled these from your photos. Review and edit as needed.'),
          findsOneWidget);
      expect(find.text('Fill in the details'), findsNothing, reason: 'the AI notice replaces it');
      verify(() => repository.setCategory('l1', 'CAT-1')).called(1);
      expect(find.text('Headphones'), findsOneWidget);
      expect(find.text('Over-ear'), findsOneWidget);
      expect(find.text('AI generated'), findsNWidgets(4));

      await tester.enterText(titleField, 'Sony Headphones');
      await harness.settle();
      expect(find.text('AI generated'), findsNWidgets(3), reason: 'an edited field loses the mark');

      await tester.enterText(notesField, 'Fine');
      await tester.enterText(attributeField('CAT-1', 'brand'), 'Sony');
      await tester.tap(find.text('128 GB'));
      await tester.tap(find.text('No'));
      await tester.enterText(priceField, '500');
      await harness.settle();
      await tester.tap(find.text('Choose Listing Plan'));
      await harness.settle();
      verify(() => repository.sendSuggestionFeedback('l1', 's1', any())).called(1);
      await harness.dispose();
    });

    testWidgets('a server error is shown and the seller can try again', (tester) async {
      when(() => repository.saveDetails(any(), any(), any(), city: any(named: 'city'))).thenThrow(
        const ApiError(type: ApiErrorType.network, message: 'x'),
      );
      final harness = await open(
        tester,
        args: const ItemDetailsArgs(listingId: 'l1', suggestion: _suggestion),
      );
      await tester.enterText(notesField, 'Fine');
      await tester.enterText(attributeField('CAT-1', 'brand'), 'Sony');
      await tester.tap(find.text('128 GB'));
      await tester.tap(find.text('No'));
      await tester.enterText(priceField, '500');
      await harness.settle();
      await tester.tap(find.text('Choose Listing Plan'));
      await harness.settle();

      expect(find.byType(ListingPlanScreen), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      await harness.dispose();
    });

    Future<AppHarness> openAiFilled(WidgetTester tester) async {
      final harness = await open(
        tester,
        args: const ItemDetailsArgs(listingId: 'l1', suggestion: _suggestion),
      );
      await tester.enterText(notesField, 'Fine');
      await tester.enterText(attributeField('CAT-1', 'brand'), 'Sony');
      await tester.tap(find.text('128 GB'));
      await tester.tap(find.text('No'));
      await tester.enterText(priceField, '500');
      await harness.settle();
      return harness;
    }

    Future<void> continueToPlan(WidgetTester tester, AppHarness harness) async {
      await tester.tap(find.text('Choose Listing Plan'));
      await harness.settle();
    }

    void answerCheck(RestrictedResult result, {List<RestrictionPolicy> policies = const []}) {
      when(() => repository.checkRestrictedItems('l1')).thenAnswer(
          (_) async => RestrictedCheck(checkId: 'c1', result: result, policies: policies));
    }

    const drones = RestrictionPolicy(
      code: 'DRONES',
      title: 'Drones',
      message: 'Confirm the drone is legal to sell',
      titleHi: 'ड्रोन',
      messageHi: 'पुष्टि करें कि ड्रोन बेचना कानूनी है',
    );
    const realEstate = RestrictionPolicy(
      code: 'REAL_ESTATE',
      title: 'Real estate',
      message: 'Confirm you may list this property',
    );
    const alcohol = RestrictionPolicy(
      code: 'ALCOHOL_TOBACCO',
      title: 'Alcohol and tobacco',
      message: 'Alcohol cannot be listed',
    );

    testWidgets('a clean item goes straight to the plan page after the check', (tester) async {
      final harness = await openAiFilled(tester);

      await continueToPlan(tester, harness);

      verify(() => repository.checkRestrictedItems('l1')).called(1);
      verifyNever(() => repository.acceptCompliance(any(), any(), any()));
      expect(find.byType(ListingPlanScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a conditional item asks once for every row, then records them and goes on',
        (tester) async {
      answerCheck(RestrictedResult.complianceRequired, policies: [drones, realEstate]);
      final harness = await openAiFilled(tester);

      await continueToPlan(tester, harness);

      expect(find.text('Before you continue'), findsOneWidget);
      expect(find.text('Drones'), findsOneWidget);
      expect(find.text('Real estate'), findsOneWidget);
      expect(find.text('Confirm the drone is legal to sell'), findsOneWidget);
      expect(find.byType(ListingPlanScreen), findsNothing);

      await tester.tap(find.text('Agree & Continue'));
      await harness.settle();

      verify(() => repository.acceptCompliance('l1', 'c1', ['DRONES', 'REAL_ESTATE'])).called(1);
      expect(find.byType(ListingPlanScreen), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('Cancel on the compliance dialog stays on the page and records nothing',
        (tester) async {
      answerCheck(RestrictedResult.complianceRequired, policies: [drones]);
      final harness = await openAiFilled(tester);

      await continueToPlan(tester, harness);
      await tester.tap(find.text('Cancel'));
      await harness.settle();

      verifyNever(() => repository.acceptCompliance(any(), any(), any()));
      expect(find.byType(ListingPlanScreen), findsNothing);
      expect(find.text('Item Details'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('an acceptance the server refuses is shown and the plan page stays closed',
        (tester) async {
      answerCheck(RestrictedResult.complianceRequired, policies: [drones]);
      when(() => repository.acceptCompliance(any(), any(), any())).thenThrow(
        const ApiError(type: ApiErrorType.network, message: 'x'),
      );
      final harness = await openAiFilled(tester);

      await continueToPlan(tester, harness);
      await tester.tap(find.text('Agree & Continue'));
      await harness.settle();

      expect(find.byType(ListingPlanScreen), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a prohibited item is blocked with its rows and the plan page stays closed',
        (tester) async {
      answerCheck(RestrictedResult.restricted, policies: [alcohol]);
      final harness = await openAiFilled(tester);

      await continueToPlan(tester, harness);

      expect(find.text('This item cannot be listed'), findsOneWidget);
      expect(find.text('Alcohol and tobacco'), findsOneWidget);
      expect(find.text('Alcohol cannot be listed'), findsOneWidget);
      expect(find.text('Your account is suspended due to policy violations'), findsNothing);
      await tester.tap(find.text('Go Back'));
      await harness.settle();
      expect(find.byType(ListingPlanScreen), findsNothing);
      verifyNever(() => repository.appealRestricted(any(), any(), any()));
      await harness.dispose();
    });

    testWidgets('a severe violation also tells the seller the account is suspended',
        (tester) async {
      answerCheck(RestrictedResult.severeViolation, policies: [alcohol]);
      final harness = await openAiFilled(tester);

      await continueToPlan(tester, harness);

      expect(find.text('Your account is suspended due to policy violations'), findsOneWidget);
      expect(find.byType(ListingPlanScreen), findsNothing);
      await harness.dispose();
    });

    testWidgets('the seller can appeal a blocked item', (tester) async {
      answerCheck(RestrictedResult.restricted, policies: [alcohol]);
      final harness = await openAiFilled(tester);
      await continueToPlan(tester, harness);

      await tester.tap(find.text('Appeal'));
      await harness.settle();
      expect(find.text('Appeal this decision'), findsOneWidget);
      final send = find.widgetWithText(FilledButton, 'Send appeal');
      expect(tester.widget<FilledButton>(send).onPressed, isNull, reason: 'a reason is needed');
      await tester.enterText(find.byType(TextFormField).last, 'Empty decorative bottles');
      await harness.settle();
      await tester.tap(send);
      await harness.settle();

      verify(() => repository.appealRestricted('l1', 'c1', 'Empty decorative bottles')).called(1);
      expect(find.text('Appeal sent. We will review it.'), findsOneWidget);
      expect(find.byType(ListingPlanScreen), findsNothing);
      await harness.dispose();
    });

    testWidgets('an appeal the server refuses shows why and keeps the dialog open', (tester) async {
      answerCheck(RestrictedResult.restricted, policies: [alcohol]);
      when(() => repository.appealRestricted(any(), any(), any())).thenThrow(
        const ApiError(
          type: ApiErrorType.business,
          message: 'x',
          code: 'ERROR_APPEAL_ALREADY_SUBMITTED',
        ),
      );
      final harness = await openAiFilled(tester);
      await continueToPlan(tester, harness);

      await tester.tap(find.text('Appeal'));
      await harness.settle();
      await tester.enterText(find.byType(TextFormField).last, 'Please look again');
      await harness.settle();
      await tester.tap(find.widgetWithText(FilledButton, 'Send appeal'));
      await harness.settle();

      expect(find.text('You have already appealed this item'), findsOneWidget);
      expect(find.text('Appeal this decision'), findsOneWidget);
      await tester.tap(find.text('Go Back'));
      await harness.settle();
      expect(find.text('This item cannot be listed'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('an item that needs review is held with the review notice', (tester) async {
      answerCheck(RestrictedResult.unclear);
      final harness = await openAiFilled(tester);

      await continueToPlan(tester, harness);

      expect(find.text("Listing flagged for review. You'll be notified within 24 hours"),
          findsOneWidget);
      expect(find.byType(ListingPlanScreen), findsNothing);
      await harness.dispose();
    });

    testWidgets('a check that cannot be made shows an error and keeps the seller here',
        (tester) async {
      when(() => repository.checkRestrictedItems(any())).thenThrow(
        const ApiError(type: ApiErrorType.network, message: 'x'),
      );
      final harness = await openAiFilled(tester);

      await continueToPlan(tester, harness);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(ListingPlanScreen), findsNothing);
      await harness.dispose();
    });

    testWidgets('a form that cannot be loaded offers Retry', (tester) async {
      var fail = true;
      when(() => repository.listingSchema(any())).thenAnswer((_) async {
        if (fail) throw const ApiError(type: ApiErrorType.network, message: 'x');
        return phoneSchema;
      });
      final harness = await open(tester);
      await chooseCategory(tester, harness);

      expect(find.text('Unable to load the details for this category. Try again'), findsOneWidget);
      expect(find.text('Good'), findsNothing);

      fail = false;
      await tester.tap(find.text('Retry'));
      await harness.settle();
      expect(find.text('Good'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('a category the server refuses shows that it is not available', (tester) async {
      when(() => repository.setCategory(any(), any())).thenThrow(
        const ApiError(type: ApiErrorType.business, message: 'x', code: 'ERROR_CATEGORY_DISABLED'),
      );
      final harness = await open(tester);
      await chooseCategory(tester, harness);

      expect(find.text('This category is not available. Choose another one.'), findsOneWidget);
      await harness.dispose();
    });

    testWidgets('real estate has no condition, price or quantity of its own', (tester) async {
      final harness = await open(
        tester,
        args: const ItemDetailsArgs(
            listingId: 'l1', suggestion: AiSuggestion(id: 's', categoryCode: 'CAT-7')),
      );

      expect(find.text('CONDITION'), findsNothing);
      expect(find.text('PRICE'), findsNothing);
      expect(find.text('QUANTITY'), findsNothing);
      expect(find.text('PRICE IS NEGOTIABLE'), findsNothing);
      expect(find.text('Apartment'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget, reason: 'the type is prefilled');
      await harness.dispose();
    });

    testWidgets('lays out without overflow at 2x text size', (tester) async {
      final harness = await open(tester, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.text('Item Details'), findsOneWidget);
      await harness.dispose();
    });
  });

  group('ItemDetailsController', () {
    setUp(stubRepository);

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

    ItemDetailsController controllerOf(ProviderContainer c, [ItemDetailsArgs a = args]) =>
        c.read(itemDetailsControllerProvider(a).notifier);

    ItemDetailsState stateOf(ProviderContainer c, [ItemDetailsArgs a = args]) =>
        c.read(itemDetailsControllerProvider(a));

    Future<void> fill(ItemDetailsController c) async {
      await c.selectCategory('CAT-1');
      c
        ..setTitle(complete.title)
        ..setCondition(ListingCondition.good)
        ..setConditionNotes(complete.conditionNotes)
        ..setDescription(complete.description)
        ..setPrice(complete.price)
        ..setNegotiable(true)
        ..setQuantity('2')
        ..setAttribute('brand', 'Sony')
        ..setAttribute('storage_gb', '64_GB');
    }

    test('starts empty, not continuable, no hints', () {
      final state = stateOf(containerFor(args));
      expect(state.canContinue, isFalse);
      expect(state.aiFilled, isFalse);
      expect(state.visibleHints, isEmpty);
      expect(state.schemaStatus, SchemaStatus.none);
      expect(state.schema, isNull);
    });

    test('choosing a category files the draft and loads its form', () async {
      final container = containerFor(args);
      final future = controllerOf(container).selectCategory('CAT-1');
      expect(stateOf(container).schemaStatus, SchemaStatus.loading);
      expect(stateOf(container).draft.categoryCode, 'CAT-1');

      await future;

      final state = stateOf(container);
      expect(state.schemaStatus, SchemaStatus.ready);
      expect(state.schema, same(phoneSchema));
      expect(state.category!.name, 'Android Phones');
      verify(() => repository.setCategory('l1', 'CAT-1')).called(1);
    });

    test('a new category drops values its form does not ask and fills repeated names', () async {
      final container = containerFor(args);
      final controller = controllerOf(container);
      await controller.selectCategory('CAT-1');
      controller
        ..setAttribute('brand', 'Sony')
        ..setAttribute('age_months', '5');

      await controller.selectCategory('CAT-7');

      expect(stateOf(container).draft.attributes, {'property_type': 'APARTMENT'});
    });

    test('only the latest category choice is applied', () async {
      final slow = Completer<ListingSchema>();
      when(() => repository.listingSchema('CAT-1')).thenAnswer((_) => slow.future);
      final container = containerFor(args);
      final controller = controllerOf(container);

      final first = controller.selectCategory('CAT-1');
      await controller.selectCategory('CAT-7');
      slow.complete(phoneSchema);
      await first;

      expect(stateOf(container).schema, same(_apartmentSchema));
      expect(stateOf(container).draft.categoryCode, 'CAT-7');
    });

    test('a failed category choice can be retried', () async {
      var fail = true;
      when(() => repository.setCategory(any(), any())).thenAnswer((_) async {
        if (fail) throw const ApiError(type: ApiErrorType.network, message: 'x');
      });
      final container = containerFor(args);
      final controller = controllerOf(container);

      await controller.selectCategory('CAT-1');
      expect(stateOf(container).schemaStatus, SchemaStatus.failed);
      expect(stateOf(container).schemaError, isA<ApiError>());

      fail = false;
      await controller.retryCategory();
      expect(stateOf(container).schemaStatus, SchemaStatus.ready);
      expect(stateOf(container).schemaError, isNull);
    });

    test('retry does nothing before a category was chosen', () async {
      final container = containerFor(args);
      await controllerOf(container).retryCategory();
      verifyNever(() => repository.setCategory(any(), any()));
    });

    test('starts from an AI suggestion and loads its category', () async {
      const aiArgs = ItemDetailsArgs(listingId: 'l1', suggestion: _suggestion);
      final container = containerFor(aiArgs);
      expect(stateOf(container, aiArgs).aiFilled, isTrue);
      expect(stateOf(container, aiArgs).draft.title, 'Headphones');

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(stateOf(container, aiArgs).schemaStatus, SchemaStatus.ready);
      expect(stateOf(container, aiArgs).canContinue, isFalse, reason: 'the form is not filled');
    });

    test('isAiGenerated holds until the seller changes the field', () {
      const aiArgs = ItemDetailsArgs(listingId: 'l1', suggestion: _suggestion);
      final container = containerFor(aiArgs);
      for (final field in [
        DetailsField.title,
        DetailsField.category,
        DetailsField.condition,
        DetailsField.description,
      ]) {
        expect(stateOf(container, aiArgs).isAiGenerated(field), isTrue, reason: '$field');
      }
      expect(stateOf(container, aiArgs).isAiGenerated(DetailsField.price), isFalse);

      controllerOf(container, aiArgs)
        ..setTitle('Other')
        ..setCondition(ListingCondition.fair)
        ..setDescription('Changed');
      for (final field in [DetailsField.title, DetailsField.condition, DetailsField.description]) {
        expect(stateOf(container, aiArgs).isAiGenerated(field), isFalse, reason: '$field');
      }
    });

    test('isAiGenerated is false without an AI suggestion', () {
      expect(stateOf(containerFor(args)).isAiGenerated(DetailsField.title), isFalse);
    });

    test('shows hints only for fields the seller touched', () async {
      final container = containerFor(args);
      final controller = controllerOf(container);
      await controller.selectCategory('CAT-1');
      controller
        ..setTitle(' ')
        ..setPrice('0')
        ..setAttribute('brand', '');

      expect(stateOf(container).visibleHints, [DetailsField.title, DetailsField.price]);
      expect(stateOf(container).visibleAttributeHints, {'brand'});
    });

    test('setting a blank attribute removes it', () async {
      final container = containerFor(args);
      final controller = controllerOf(container);
      await controller.selectCategory('CAT-1');
      controller.setAttribute('brand', 'Sony');
      expect(stateOf(container).draft.attributes, {'brand': 'Sony'});
      controller.setAttribute('brand', '  ');
      expect(stateOf(container).draft.attributes, isEmpty);
    });

    test('args compare by listing and suggestion id', () {
      expect(const ItemDetailsArgs(listingId: 'a'), const ItemDetailsArgs(listingId: 'a'));
      expect(const ItemDetailsArgs(listingId: 'a'), isNot(const ItemDetailsArgs(listingId: 'b')));
      expect(const ItemDetailsArgs(listingId: 'a').hashCode,
          const ItemDetailsArgs(listingId: 'a').hashCode);
    });

    test('save does nothing while invalid', () async {
      final container = containerFor(args);
      final result = await controllerOf(container).save();
      expect(result.saved, isFalse);
      verifyNever(() => repository.saveDetails(any(), any(), any(), city: any(named: 'city')));
    });

    test('Continue stays off while another form is loading', () async {
      final container = containerFor(args);
      final controller = controllerOf(container);
      await fill(controller);
      expect(stateOf(container).canContinue, isTrue);

      final slow = Completer<ListingSchema>();
      when(() => repository.listingSchema('CAT-1')).thenAnswer((_) => slow.future);
      final pending = controller.selectCategory('CAT-1');
      expect(stateOf(container).canContinue, isFalse);

      slow.complete(phoneSchema);
      await pending;
      expect(stateOf(container).canContinue, isTrue);
    });
    test('save sends the details with only the chosen city', () async {
      final container = containerFor(
        args,
        location: const LocationKnown(HomeLocation(city: 'Pune', area: 'Baner')),
      );
      await container.read(homeLocationControllerProvider.future);
      final controller = controllerOf(container);
      await fill(controller);

      final result = await controller.save();

      expect(result.saved, isTrue);
      verify(() => repository.saveDetails('l1', any(), phoneSchema, city: 'Pune')).called(1);
      verifyNever(() => repository.sendSuggestionFeedback(any(), any(), any()));
      expect(stateOf(container).isSaving, isFalse);
    });

    test('save sends no city when the location is not known', () async {
      final container = containerFor(args);
      final controller = controllerOf(container);
      await fill(controller);
      await controller.save();
      verify(() => repository.saveDetails('l1', any(), any(), city: null)).called(1);
    });

    test('save returns the server error', () async {
      const error = ApiError(type: ApiErrorType.business, message: 'x', code: 'ERROR_X');
      when(() => repository.saveDetails(any(), any(), any(), city: any(named: 'city')))
          .thenThrow(error);
      final container = containerFor(args);
      final controller = controllerOf(container);
      await fill(controller);

      final result = await controller.save();

      expect(result.saved, isFalse);
      expect(result.error, error);
      expect(stateOf(container).isSaving, isFalse);
    });

    test('save reports AI feedback and ignores a feedback failure', () async {
      when(() => repository.sendSuggestionFeedback(any(), any(), any()))
          .thenThrow(const ApiError(type: ApiErrorType.network, message: 'x'));
      const aiArgs = ItemDetailsArgs(listingId: 'l1', suggestion: _suggestion);
      final container = containerFor(aiArgs);
      final controller = controllerOf(container, aiArgs);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      controller
        ..setConditionNotes('Fine')
        ..setNegotiable(false)
        ..setAttribute('brand', 'Sony')
        ..setAttribute('storage_gb', '64_GB')
        ..setPrice('500');

      final result = await controller.save();

      expect(result.saved, isTrue);
      verify(() => repository.sendSuggestionFeedback('l1', 's1', any())).called(1);
    });

    test('save skips feedback when the suggestion had nothing to report', () async {
      const aiArgs = ItemDetailsArgs(listingId: 'l1', suggestion: AiSuggestion(id: 'e'));
      final container = containerFor(aiArgs);
      final controller = controllerOf(container, aiArgs);
      await fill(controller);
      await controller.save();
      verifyNever(() => repository.sendSuggestionFeedback(any(), any(), any()));
    });
  });
}
