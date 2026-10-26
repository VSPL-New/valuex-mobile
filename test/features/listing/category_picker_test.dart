import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valuex_mobile/core/network/api_error.dart';
import 'package:valuex_mobile/features/listing/data/listing_repository.dart';
import 'package:valuex_mobile/features/listing/domain/category.dart';
import 'package:valuex_mobile/features/listing/presentation/category_picker_screen.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../helpers/fonts.dart';

class _MockRepository extends Mock implements ListingRepository {}

const _mobiles = CategoryNode(
    code: 'L1-M', name: 'Mobiles & Tablets', level: 1, hasChildren: true, popular: true);
const _books = CategoryNode(code: 'L1-B', name: 'Books', level: 1, hasChildren: true);
const _smartphones =
    CategoryNode(code: 'L2-S', name: 'Smartphones', level: 2, hasChildren: true, popular: true);
const _accessories = CategoryNode(code: 'L2-A', name: 'Accessories', level: 2, hasChildren: true);
const _android = CategoryNode(code: 'CAT-1', name: 'Android Phones', level: 3, hasChildren: false);

void main() {
  setUpAll(() {
    registerFallbackValue(CategoryScope.all);
    loadBrandFonts();
  });

  late _MockRepository repository;
  String? picked;
  bool returned = false;

  setUp(() {
    picked = null;
    returned = false;
    repository = _MockRepository();
    when(() => repository.categoryChildren(
          parentCode: any(named: 'parentCode'),
          scope: any(named: 'scope'),
        )).thenAnswer((invocation) async {
      final parent = invocation.namedArguments[#parentCode] as String?;
      final scope = invocation.namedArguments[#scope] as CategoryScope?;
      return switch ((parent, scope)) {
        (null, CategoryScope.popular) => [_mobiles],
        (null, CategoryScope.others) => [_books],
        ('L1-M', CategoryScope.popular) => [_smartphones],
        ('L1-M', CategoryScope.others) => [_accessories],
        ('L2-S', CategoryScope.all) => [_android],
        _ => <CategoryNode>[],
      };
    });
    when(() => repository.searchCategories(any())).thenAnswer((invocation) async {
      final query = invocation.positionalArguments.first as String;
      return query == 'zzz'
          ? <CategoryRef>[]
          : [
              const CategoryRef(
                code: 'CAT-1',
                name: 'Android Phones',
                path: [
                  CategoryPathItem(code: 'L1-M', name: 'Mobiles & Tablets', level: 1),
                  CategoryPathItem(code: 'L2-S', name: 'Smartphones', level: 2),
                  CategoryPathItem(code: 'CAT-1', name: 'Android Phones', level: 3),
                ],
              ),
            ];
    });
  });

  Future<void> open(WidgetTester tester, {String? selectedCode}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [listingRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                picked = await pickCategory(context, selectedCode: selectedCode);
                returned = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('lists the popular top-level categories and the rest on request', (tester) async {
    await open(tester);

    expect(find.text('Choose category'), findsOneWidget);
    expect(find.text('Mobiles & Tablets'), findsOneWidget);
    expect(find.text('Books'), findsNothing);

    await tester.tap(find.text('More categories'));
    await tester.pumpAndSettle();

    expect(find.text('Books'), findsOneWidget);
    expect(find.text('More categories'), findsNothing);
  });

  testWidgets('drills down to a leaf and returns its code', (tester) async {
    await open(tester);

    await tester.tap(find.text('Mobiles & Tablets'));
    await tester.pumpAndSettle();
    expect(find.text('Smartphones'), findsOneWidget);
    await tester.tap(find.text('More categories'));
    await tester.pumpAndSettle();
    expect(find.text('Accessories'), findsOneWidget);

    await tester.tap(find.text('Smartphones'));
    await tester.pumpAndSettle();
    expect(find.text('Android Phones'), findsOneWidget);
    expect(find.text('More categories'), findsNothing, reason: 'leaves are listed in full');

    await tester.tap(find.text('Android Phones'));
    await tester.pumpAndSettle();

    expect(returned, isTrue);
    expect(picked, 'CAT-1');
  });

  testWidgets('back goes up one level, then leaves the picker without a choice', (tester) async {
    await open(tester);
    await tester.tap(find.text('Mobiles & Tablets'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Choose category'), findsOneWidget);
    expect(find.text('Mobiles & Tablets'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(returned, isTrue);
    expect(picked, isNull);
  });

  testWidgets('searches after a pause and returns the chosen leaf', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump(CategoryPickerScreen.searchDelay);
    await tester.pumpAndSettle();
    expect(find.text('Type at least 2 letters to search'), findsOneWidget);
    verifyNever(() => repository.searchCategories(any()));

    await tester.enterText(find.byType(TextField), 'andr');
    await tester.pump(const Duration(milliseconds: 100));
    verifyNever(() => repository.searchCategories(any()));
    await tester.pump(CategoryPickerScreen.searchDelay);
    await tester.pumpAndSettle();
    verify(() => repository.searchCategories('andr')).called(1);
    expect(find.text('Mobiles & Tablets > Smartphones'), findsOneWidget);

    await tester.tap(find.text('Android Phones'));
    await tester.pumpAndSettle();
    expect(picked, 'CAT-1');
  });

  testWidgets('says when nothing matches and returns to browsing when the text is cleared',
      (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(CategoryPickerScreen.searchDelay);
    await tester.pumpAndSettle();
    expect(find.text('No categories match'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump(CategoryPickerScreen.searchDelay);
    await tester.pumpAndSettle();
    expect(find.text('Mobiles & Tablets'), findsOneWidget);
  });

  testWidgets('marks the current choice and offers Retry when loading fails', (tester) async {
    var fail = true;
    when(() => repository.categoryChildren(
          parentCode: any(named: 'parentCode'),
          scope: any(named: 'scope'),
        )).thenAnswer((_) async {
      if (fail) throw const ApiError(type: ApiErrorType.network, message: 'x');
      return [_mobiles];
    });
    await open(tester, selectedCode: 'L1-M');

    expect(find.text('Retry'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Mobiles & Tablets'), findsOneWidget);
    expect(tester.widget<ListTile>(find.widgetWithText(ListTile, 'Mobiles & Tablets')).selected,
        isTrue);
  });
}
