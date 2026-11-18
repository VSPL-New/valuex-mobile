import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/features/chat/domain/chat.dart';
import 'package:valuex_mobile/features/chat/presentation/widgets/system_card.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../helpers/fonts.dart';

ChatMessage _card(Map<String, dynamic> payload, {String type = 'OFFER_EVENT'}) =>
    ChatMessage.fromJson({
      'id': 'm1',
      'seq': 2,
      'type': type,
      'fromMe': false,
      'payload': payload,
      'createdAt': '2026-11-17T10:00:00Z',
    });

void main() {
  setUpAll(loadBrandFonts);

  Future<void> pump(
    WidgetTester tester,
    ChatMessage message, {
    bool viewerIsBuyer = true,
    ValueChanged<String>? onOpen,
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SystemCard(message: message, viewerIsBuyer: viewerIsBuyer, onOpenNegotiation: onOpen),
      ),
    ));
  }

  const base = {'negotiationId': 'n1', 'amount': 12000, 'round': 1};

  testWidgets('says who offered, from the point of view of the viewer', (tester) async {
    await pump(tester, _card({...base, 'kind': 'OFFER_RECEIVED', 'by': 'BUYER'}));
    expect(find.text('You offered ₹12,000'), findsOneWidget);

    await pump(tester, _card({...base, 'kind': 'OFFER_RECEIVED', 'by': 'BUYER'}),
        viewerIsBuyer: false);
    expect(find.text('The buyer offered ₹12,000'), findsOneWidget);

    await pump(tester, _card({...base, 'kind': 'OFFER_COUNTERED', 'by': 'SELLER'}));
    expect(find.text('The seller countered with ₹12,000'), findsOneWidget);
  });

  testWidgets('says what the answer was', (tester) async {
    await pump(tester, _card({...base, 'kind': 'OFFER_ACCEPTED', 'by': 'SELLER'}));
    expect(find.text('The seller accepted ₹12,000'), findsOneWidget);

    await pump(tester, _card({...base, 'kind': 'OFFER_REJECTED', 'by': 'SELLER'}),
        viewerIsBuyer: false);
    expect(find.text('You declined ₹12,000'), findsOneWidget);
  });

  testWidgets('says a withdrawal or an end without an amount', (tester) async {
    await pump(tester, _card({'negotiationId': 'n1', 'kind': 'OFFER_WITHDRAWN', 'by': 'BUYER'}));
    expect(find.text('The buyer withdrew the offer'), findsOneWidget);

    await pump(tester, _card({'negotiationId': 'n1', 'kind': 'NEGOTIATION_CANCELLED'}));
    expect(find.text('Negotiation ended: the item is no longer available'), findsOneWidget);
  });

  testWidgets('opens the negotiation when tapped', (tester) async {
    String? opened;
    await pump(tester, _card({...base, 'kind': 'OFFER_RECEIVED', 'by': 'BUYER'}),
        onOpen: (id) => opened = id);

    expect(find.text('View offer'), findsOneWidget);
    await tester.tap(find.text('You offered ₹12,000'));

    expect(opened, 'n1');
  });

  testWidgets('is not tappable without a negotiation id or an opener', (tester) async {
    await pump(tester, _card({'amount': 12000, 'kind': 'OFFER_RECEIVED', 'by': 'BUYER'}),
        onOpen: (id) {});
    expect(find.text('View offer'), findsNothing);

    await pump(tester, _card({...base, 'kind': 'OFFER_RECEIVED', 'by': 'BUYER'}));
    expect(find.text('View offer'), findsNothing);
  });

  testWidgets('shows the neutral line for a kind this version does not know', (tester) async {
    await pump(tester, _card({...base, 'kind': 'SOMETHING_NEW'}));

    expect(find.text('Conversation update'), findsOneWidget);
  });

  testWidgets('keeps the neutral line for a call card and the listing card as before',
      (tester) async {
    await pump(tester, _card({'x': 1}, type: 'CALL_SUMMARY'));
    expect(find.text('Conversation update'), findsOneWidget);

    await pump(tester, _card({'title': 'Apple Watch', 'price': 14500}, type: 'LISTING_CONTEXT'));
    expect(find.text('Apple Watch'), findsOneWidget);
  });

  testWidgets('is spoken in Hindi', (tester) async {
    await pump(tester, _card({...base, 'kind': 'OFFER_RECEIVED', 'by': 'BUYER'}),
        locale: const Locale('hi'));

    expect(find.text('आपने ₹12,000 का ऑफ़र दिया'), findsOneWidget);
  });
}
