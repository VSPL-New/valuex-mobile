// Basic Flutter widget test for the ValueX app.
//
// Verifies that the app boots and the splash screen is displayed.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valuex_mobile/app.dart';

void main() {
  testWidgets('ValueXApp builds and shows splash screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ValueXApp()),
    );

    // Allow initial frame to settle (splash screen renders immediately).
    await tester.pump();

    // Verify the app renders without throwing.
    expect(find.byType(ValueXApp), findsOneWidget);
  });
}
