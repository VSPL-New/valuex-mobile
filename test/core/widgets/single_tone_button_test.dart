import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/core/widgets/single_tone_button.dart';

import '../../helpers/fonts.dart';

void main() {
  setUpAll(loadBrandFonts);

  for (final enabled in [true, false]) {
    for (final withIcon in [true, false]) {
      testWidgets('button enabled=$enabled icon=$withIcon preserves wrapping and tap behavior',
          (tester) async {
        var calls = 0;
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: SizedBox(
                width: 100,
                child: SingleToneButton(
                  label: 'Continue',
                  leadingIcon: withIcon ? Icons.chat_bubble_outline_rounded : null,
                  onPressed: enabled ? () => calls++ : null,
                ),
              ),
            ),
          ),
        ));
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(InkWell)).height, greaterThanOrEqualTo(48));
        await tester.tap(find.byType(InkWell));
        expect(calls, enabled ? 1 : 0);
        expect(find.byIcon(Icons.chat_bubble_outline_rounded),
            withIcon ? findsOneWidget : findsNothing);
      });
    }
  }
}
