import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/features/listing/domain/listing_schema.dart';
import 'package:valuex_mobile/features/listing/presentation/widgets/schema_field_input.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../helpers/fonts.dart';

SchemaField _field(
  String type, {
  List<SchemaOption> options = const [],
  Map<String, dynamic> validation = const {},
}) =>
    SchemaField.fromJson({
      'key': 'k',
      'label': 'Label',
      'type': type,
      'options': [
        for (final option in options) {'code': option.code, 'label': option.label},
      ],
      'validation': validation,
    });

List<SchemaOption> _options(int count) => [
      for (var i = 0; i < count; i++) SchemaOption(code: 'C$i', label: 'Option $i'),
    ];

void main() {
  setUpAll(loadBrandFonts);

  /// Shows one input and keeps the value it reports, like the page does.
  Future<ValueNotifier<Object?>> show(
    WidgetTester tester,
    SchemaField field, {
    Object? initial,
  }) async {
    final value = ValueNotifier<Object?>(initial);
    final widgetKey = UniqueKey();
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ValueListenableBuilder<Object?>(
            valueListenable: value,
            builder: (context, current, _) => SchemaFieldInput(
              key: widgetKey,
              field: field,
              value: current,
              onChanged: (next) => value.value = next,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return value;
  }

  testWidgets('text and long text report what is typed', (tester) async {
    var value = await show(tester, _field('TEXT'), initial: 'Sony');
    expect(find.text('Sony'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Apple');
    expect(value.value, 'Apple');

    value = await show(tester, _field('LONG_TEXT'));
    await tester.enterText(find.byType(TextField), 'Line one\nLine two');
    expect(value.value, 'Line one\nLine two');
  });

  testWidgets('numbers accept digits only and keep what was typed', (tester) async {
    final integer = await show(tester, _field('INTEGER'));
    await tester.enterText(find.byType(TextField), '1a2,0');
    expect(integer.value, '12,0');

    final decimal = await show(tester, _field('DECIMAL'), initial: 4.5);
    expect(find.text('4.5'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '99.50x');
    expect(decimal.value, '99.50');
  });

  testWidgets('yes or no sets a boolean', (tester) async {
    final value = await show(tester, _field('BOOLEAN'));
    await tester.tap(find.text('No'));
    expect(value.value, isFalse);
    await tester.tap(find.text('Yes'));
    expect(value.value, isTrue);
  });

  testWidgets('a date is picked and reported as an ISO date', (tester) async {
    final value = await show(tester, _field('DATE'));
    expect(find.text('Select date'), findsOneWidget);

    await tester.tap(find.text('Select date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(value.value, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    expect(find.text(value.value! as String), findsOneWidget);
  });

  testWidgets('a short option list is shown as chips and one is chosen', (tester) async {
    final value = await show(tester, _field('OPTION', options: _options(3)));
    await tester.tap(find.text('Option 1'));
    expect(value.value, 'C1');
    await tester.tap(find.text('Option 2'));
    expect(value.value, 'C2');
  });

  testWidgets('a short multi-select toggles options on and off', (tester) async {
    final value = await show(tester, _field('MULTI_OPTION', options: _options(3)));
    await tester.tap(find.text('Option 0'));
    await tester.pump();
    await tester.tap(find.text('Option 2'));
    await tester.pump();
    expect(value.value, ['C0', 'C2']);
    await tester.tap(find.text('Option 0'));
    await tester.pump();
    expect(value.value, ['C2']);
  });

  testWidgets('a long option list opens a searchable sheet', (tester) async {
    final value = await show(tester, _field('OPTION', options: _options(12)));
    expect(find.text('Select'), findsOneWidget);

    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Option 11');
    await tester.pumpAndSettle();
    expect(find.text('Option 3'), findsNothing);
    await tester.tap(find.widgetWithText(ListTile, 'Option 11'));
    await tester.pumpAndSettle();

    expect(value.value, 'C11');
    expect(find.text('Option 11'), findsOneWidget, reason: 'the button shows the choice');
  });

  testWidgets('a long multi-select collects choices and reports them on Done', (tester) async {
    final value =
        await show(tester, _field('MULTI_OPTION', options: _options(12)), initial: ['C1']);
    expect(find.text('Option 1'), findsOneWidget);

    await tester.tap(find.text('Option 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Option 2'));
    await tester.pump();
    await tester.tap(find.text('Option 3'));
    await tester.pump();
    await tester.tap(find.text('Option 2'));
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(value.value, ['C1', 'C3']);
  });

  testWidgets('option or text offers quick picks and takes free text', (tester) async {
    final value = await show(tester, _field('OPTION_OR_TEXT', options: _options(3)));
    await tester.tap(find.text('Option 1'));
    expect(value.value, 'C1');
    expect(find.text('Option 1'), findsNWidgets(2), reason: 'chip and the filled-in text');

    await tester.enterText(find.byType(TextField), 'Teal');
    expect(value.value, 'Teal');
  });

  testWidgets('a text list is split on commas', (tester) async {
    final value = await show(tester, _field('TEXT_LIST'), initial: ['a', 'b']);
    expect(find.text('a, b'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'x, ,y ,z');
    expect(value.value, ['x', 'y', 'z']);
  });

  testWidgets('dimensions report only the sizes that were entered', (tester) async {
    final value = await show(tester, _field('OBJECT'), initial: {'length': 30});
    expect(find.text('30'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Width (cm)').first, '12.5');
    expect(value.value, {'length': 30, 'width': 12.5});
    await tester.enterText(find.byType(TextField).first, '');
    expect(value.value, {'width': 12.5});
  });

  testWidgets('key and value details can be added, edited and removed', (tester) async {
    final value = await show(tester, _field('JSON', validation: {'maxItems': 2}));
    expect(find.text('Add detail'), findsOneWidget);

    await tester.tap(find.text('Add detail'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(0), 'Year');
    await tester.enterText(find.byType(TextField).at(1), '1962');
    expect(value.value, {'Year': '1962'});

    await tester.tap(find.text('Add detail'));
    await tester.pump();
    expect(find.text('Add detail'), findsNothing, reason: 'the limit is reached');
    await tester.enterText(find.byType(TextField).at(2), 'Make');
    expect(value.value, {'Year': '1962'}, reason: 'a pair without a value is not sent');

    await tester.tap(find.byTooltip('Remove detail').first);
    await tester.pump();
    expect(value.value, isEmpty);
    expect(find.text('Add detail'), findsOneWidget);
  });
}
