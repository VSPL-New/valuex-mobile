import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/features/auth/presentation/widgets/state_picker_field.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

void main() {
  testWidgets('lists the states and reports the chosen one', (tester) async {
    String? chosen;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => StatePickerField(
              value: chosen,
              onChanged: (value) => setState(() => chosen = value),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Select your state'), findsOneWidget);
    await tester.tap(find.byType(StatePickerField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assam'));
    await tester.pumpAndSettle();

    expect(chosen, 'Assam');
    expect(find.text('Assam'), findsOneWidget);
  });
}
