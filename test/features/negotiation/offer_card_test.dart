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
    VoidCallback? onAddToCart,
    Locale locale = const Locale('en'),
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SystemCard(
          message: message,
          viewerIsBuyer: viewerIsBuyer,
          onOpenNegotiation: onOpen,
          onAddToCart: onAddToCart,
        ),
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

  testWidgets('tells a declined buyer neutrally, with no winner and no price', (tester) async {
    await pump(tester, _card({'negotiationId': 'n1', 'kind': 'OFFER_SUPERSEDED', 'round': 1}));
    expect(
      find.text(
          'The seller accepted another offer. You can make a new offer if it becomes available again'),
      findsOneWidget,
    );
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

  testWidgets('shows a call card with its own line and the listing card as before', (tester) async {
    await pump(
      tester,
      _card({'type': 'VOICE', 'outcome': 'COMPLETED', 'durationSeconds': 61}, type: 'CALL_SUMMARY'),
    );
    expect(find.text('voice call · 1:01'), findsOneWidget);

    await pump(tester, _card({'title': 'Apple Watch', 'price': 14500}, type: 'LISTING_CONTEXT'));
    expect(find.text('Apple Watch'), findsOneWidget);
  });

  group('an item added to the cart (US-019)', () {
    final added = {
      ...base,
      'kind': 'ADDED_TO_CART',
      'by': 'BUYER',
      'heldUntil': '2026-11-18T10:00:00Z',
    };

    testWidgets('tells the buyer "You added" and the seller "The buyer added"', (tester) async {
      await pump(tester, _card(added));
      expect(find.text('You added this to the cart at ₹12,000'), findsOneWidget);
      expect(find.textContaining('Price held until'), findsOneWidget);

      await pump(tester, _card(added), viewerIsBuyer: false);
      expect(find.text('The buyer added this to the cart at ₹12,000'), findsOneWidget);
    });

    testWidgets('leaves the held line out when the time is missing or unreadable', (tester) async {
      await pump(tester, _card({...added, 'heldUntil': null}));
      expect(find.textContaining('Price held until'), findsNothing);

      await pump(tester, _card({...added, 'heldUntil': 'soon'}));
      expect(find.textContaining('Price held until'), findsNothing);
    });

    testWidgets('is spoken in Hindi', (tester) async {
      await pump(tester, _card(added), locale: const Locale('hi'));

      expect(find.text('आपने इसे ₹12,000 पर कार्ट में जोड़ा'), findsOneWidget);
    });
  });

  group('Add to cart on an accepted offer (US-019)', () {
    final accepted = _card({...base, 'kind': 'OFFER_ACCEPTED', 'by': 'SELLER'});

    testWidgets('shows the button only when given a handler and runs it once per tap',
        (tester) async {
      var adds = 0;
      await pump(tester, accepted);
      expect(find.text('Add to cart'), findsNothing);

      await pump(tester, accepted, onAddToCart: () => adds++);
      await tester.tap(find.text('Add to cart'));

      expect(adds, 1);
    });

    testWidgets('has its own accessible button and does not overflow at 320 px and 200 percent',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, accepted, onAddToCart: () {}, size: const Size(320, 640), textScale: 2);

      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Add to cart'), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('is spoken in Hindi', (tester) async {
      await pump(tester, accepted, onAddToCart: () {}, locale: const Locale('hi'));

      expect(find.text('कार्ट में जोड़ें'), findsOneWidget);
    });
  });
  testWidgets('is spoken in Hindi', (tester) async {
    await pump(tester, _card({...base, 'kind': 'OFFER_RECEIVED', 'by': 'BUYER'}),
        locale: const Locale('hi'));

    expect(find.text('आपने ₹12,000 का ऑफ़र दिया'), findsOneWidget);
  });
}
