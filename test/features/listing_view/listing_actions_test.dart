import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/features/listing_view/domain/public_listing.dart';
import 'package:valuex_mobile/features/listing_view/presentation/widgets/listing_actions.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../helpers/accessibility.dart';
import '../../helpers/fonts.dart';

const _available = Capability(available: true, reason: CapabilityReason.other);
const _soon = Capability(available: false, reason: CapabilityReason.comingSoon);

Capabilities _caps({
  Capability chat = _available,
  Capability call = _soon,
  Capability video = _soon,
  Capability offer = _soon,
  Capability cart = _soon,
  Capability buyNow = _soon,
}) =>
    Capabilities(chat: chat, call: call, video: video, offer: offer, cart: cart, buyNow: buyNow);

void main() {
  setUpAll(loadBrandFonts);

  Future<void> pump(
    WidgetTester tester,
    Capabilities capabilities, {
    VoidCallback? onChat,
    VoidCallback? onCall,
    VoidCallback? onVideo,
    bool callBusy = false,
    VoidCallback? onUnbuilt,
    VoidCallback? onBuyNow,
    bool buyNowBusy = false,
    bool hasChat = false,
    bool chatBusy = false,
    double textScale = 1,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ListingActions(
            capabilities: capabilities,
            onUnbuilt: onUnbuilt ?? () {},
            onChat: onChat ?? () {},
            onCall: onCall,
            onVideo: onVideo,
            callBusy: callBusy,
            onBuyNow: onBuyNow,
            buyNowBusy: buyNowBusy,
            hasChat: hasChat,
            chatBusy: chatBusy,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('Chat is enabled and opens the chat; Call, Video and Make an Offer stay disabled',
      (tester) async {
    final handle = tester.ensureSemantics();
    var chats = 0;
    var unbuilt = 0;
    await pump(tester, _caps(), onChat: () => chats++, onUnbuilt: () => unbuilt++);

    await tester.tap(find.text('Chat'));
    await tester.tap(find.text('Call'));
    await tester.tap(find.text('Make an Offer'));

    expect(chats, 1);
    expect(unbuilt, 0);
    expect(find.bySemanticsLabel('Call, Coming soon'), findsOneWidget);
    expect(find.bySemanticsLabel('Make an Offer, Coming soon'), findsOneWidget);
    expect(find.bySemanticsLabel('Chat'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('an existing chat still reads Chat', (tester) async {
    await pump(tester, _caps(), hasChat: true);

    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Open chat'), findsNothing);
  });

  testWidgets('a second tap while a chat is opening is ignored', (tester) async {
    var chats = 0;
    await pump(tester, _caps(), onChat: () => chats++, chatBusy: true);

    await tester.tap(find.text('Chat'));

    expect(chats, 0);
  });

  testWidgets('Call and Video ring the seller when the server offers them', (tester) async {
    var calls = 0;
    var videos = 0;
    var unbuilt = 0;
    await pump(
      tester,
      _caps(call: _available, video: _available),
      onCall: () => calls++,
      onVideo: () => videos++,
      onUnbuilt: () => unbuilt++,
    );

    await tester.tap(find.text('Call'));
    await tester.tap(find.text('Video'));

    expect([calls, videos, unbuilt], [1, 1, 0]);
  });

  testWidgets('a second tap while a call is being started is ignored', (tester) async {
    var calls = 0;
    var videos = 0;
    await pump(
      tester,
      _caps(call: _available, video: _available),
      onCall: () => calls++,
      onVideo: () => videos++,
      callBusy: true,
    );

    await tester.tap(find.text('Call'));
    await tester.tap(find.text('Video'));

    expect([calls, videos], [0, 0]);
  });

  testWidgets('a second tap while the chat is opening is ignored too', (tester) async {
    var chats = 0;
    await pump(tester, _caps(), onChat: () => chats++, chatBusy: true);

    await tester.tap(find.text('Chat'));

    expect(chats, 0);
  });

  testWidgets('a reason is spoken for each action the buyer cannot use', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      _caps(
        chat: const Capability(available: false, reason: CapabilityReason.unavailable),
        offer: const Capability(available: false, reason: CapabilityReason.notNegotiable),
        cart: const Capability(available: false, reason: CapabilityReason.identityRequired),
      ),
    );

    expect(find.bySemanticsLabel('Chat, Unavailable'), findsOneWidget);
    expect(find.bySemanticsLabel('Make an Offer, Not negotiable'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('on your own listing every action says so', (tester) async {
    const mine = Capability(available: false, reason: CapabilityReason.ownListing);
    await pump(
        tester, _caps(chat: mine, call: mine, video: mine, offer: mine, cart: mine, buyNow: mine));

    expect(find.text('Your listing'), findsNWidgets(5));
  });

  testWidgets('real estate shows Make an Offer alone in its row, without cart or buy now',
      (tester) async {
    const none = Capability.missing;
    await pump(tester, _caps(cart: none, buyNow: none));

    expect(find.text('Make an Offer'), findsOneWidget);
    expect(find.text('Add to Cart'), findsNothing);
    expect(find.text('Buy Now'), findsNothing);
  });

  testWidgets('an older server without the offer option shows no Make an Offer', (tester) async {
    await pump(
      tester,
      const Capabilities(chat: _available, call: _soon, video: _soon, cart: _soon, buyNow: _soon),
    );

    expect(find.text('Make an Offer'), findsNothing);
  });

  testWidgets('does not overflow at 320 px and 200 percent text and meets the guidelines',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, _caps(), textScale: 2, size: const Size(320, 640));

    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrast));
    handle.dispose();
  });

  group('Buy Now (US-068)', () {
    const enabled = Capability(available: true, reason: CapabilityReason.other);

    testWidgets('an available Buy Now starts the reservation and does not say coming soon',
        (tester) async {
      var buyNow = 0;
      var unbuilt = 0;
      await pump(tester, _caps(buyNow: enabled),
          onBuyNow: () => buyNow++, onUnbuilt: () => unbuilt++);

      await tester.tap(find.text('Buy Now'));

      expect(buyNow, 1);
      expect(unbuilt, 0);
    });

    testWidgets('a second tap while a Buy Now is starting is ignored', (tester) async {
      var buyNow = 0;
      await pump(tester, _caps(buyNow: enabled), onBuyNow: () => buyNow++, buyNowBusy: true);

      await tester.tap(find.text('Buy Now'));

      expect(buyNow, 0);
    });

    testWidgets('a caller without a Buy Now handler keeps the coming soon message', (tester) async {
      var unbuilt = 0;
      await pump(tester, _caps(buyNow: enabled), onUnbuilt: () => unbuilt++);

      await tester.tap(find.text('Buy Now'));

      expect(unbuilt, 1);
    });

    testWidgets('says why Buy Now cannot be used: switched off by the seller, or reserved',
        (tester) async {
      final handle = tester.ensureSemantics();
      var buyNow = 0;
      await pump(
        tester,
        _caps(
          buyNow: const Capability(available: false, reason: CapabilityReason.disabledBySeller),
        ),
        onBuyNow: () => buyNow++,
      );
      expect(find.bySemanticsLabel('Buy Now, Seller requires price negotiation for this item'),
          findsOneWidget);
      await tester.tap(find.text('Buy Now'));
      expect(buyNow, 0);

      await pump(
        tester,
        _caps(buyNow: const Capability(available: false, reason: CapabilityReason.reserved)),
      );
      expect(find.bySemanticsLabel('Buy Now, Reserved right now'), findsOneWidget);
      handle.dispose();
    });

    test('reads the new reason from the server', () {
      expect(CapabilityReason.from('DISABLED_BY_SELLER'), CapabilityReason.disabledBySeller);
    });
  });

  testWidgets(
      'Add to Cart is not offered here whatever the server says; it lives on the accepted offer',
      (tester) async {
    const enabled = Capability(available: true, reason: CapabilityReason.other);
    const needsOffer = Capability(available: false, reason: CapabilityReason.negotiationRequired);

    for (final cart in [enabled, needsOffer, _soon]) {
      await pump(tester, _caps(cart: cart, buyNow: enabled));

      expect(find.text('Add to Cart'), findsNothing);
      expect(find.text('Buy Now'), findsOneWidget);
    }
  });

  test('still reads the negotiation reason from the server', () {
    expect(CapabilityReason.from('NEGOTIATION_REQUIRED'), CapabilityReason.negotiationRequired);
  });
}
