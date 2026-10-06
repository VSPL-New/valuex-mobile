import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/widgets/otp_input.dart';

Widget _wrap(ValueChanged<String> onChanged, {bool enabled = true}) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: OtpInput(semanticLabel: 'code', onChanged: onChanged, enabled: enabled),
      ),
    ),
  );
}

void main() {
  testWidgets('reports typed digits and fills the boxes', (tester) async {
    String? latest;
    await tester.pumpWidget(_wrap((value) => latest = value));

    await tester.enterText(find.byType(TextField), '123');
    await tester.pump();

    expect(latest, '123');
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('ignores non-digits', (tester) async {
    String? latest;
    await tester.pumpWidget(_wrap((value) => latest = value));

    await tester.enterText(find.byType(TextField), '1a2b3');
    await tester.pump();

    expect(latest, '123');
  });

  testWidgets('a pasted code longer than six digits is cut to six', (tester) async {
    String? latest;
    await tester.pumpWidget(_wrap((value) => latest = value));

    await tester.enterText(find.byType(TextField), '12345678');
    await tester.pump();

    expect(latest, '123456');
  });

  testWidgets('backspace removes the last digit', (tester) async {
    String? latest;
    await tester.pumpWidget(_wrap((value) => latest = value));

    await tester.enterText(find.byType(TextField), '1234');
    await tester.enterText(find.byType(TextField), '123');
    await tester.pump();

    expect(latest, '123');
  });

  testWidgets('a disabled input does not accept text', (tester) async {
    await tester.pumpWidget(_wrap((_) {}, enabled: false));

    final field = tester.widget<TextField>(find.byType(TextField));

    expect(field.enabled, isFalse);
  });

  testWidgets('is exposed as a labelled text field', (tester) async {
    await tester.pumpWidget(_wrap((_) {}));

    expect(find.bySemanticsLabel('code'), findsWidgets);
  });
}
