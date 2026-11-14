import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/widgets/app_image.dart';
import 'package:valuex_mobile/features/home/domain/entities/listing.dart';
import 'package:valuex_mobile/features/home/presentation/widgets/listing_card.dart';
import 'package:valuex_mobile/features/search/domain/search_listing.dart';
import 'package:valuex_mobile/features/search/presentation/search_labels.dart';
import 'package:valuex_mobile/features/listing_view/domain/public_listing.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../helpers/fonts.dart';

Future<void> _pump(WidgetTester tester, Listing listing, {Locale locale = const Locale('en')}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 200,
          height: 300,
          child: ListingCard(listing: listing, onTap: () {}),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(loadBrandFonts);

  for (final (area, city, expected) in [
    ('  Kothrud  ', ' Pune ', 'Kothrud, Pune'),
    (null, 'Pune', 'Pune'),
    ('  ', 'Pune', 'Pune'),
    ('pune', 'Pune', 'Pune'),
    ('Kothrud', '', 'Kothrud'),
    (null, '', ''),
  ]) {
    testWidgets('API area=$area city=$city formats consistently in tiles and details',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final json = <String, dynamic>{
        'listingId': 'l1',
        'title': 'Chair',
        'price': 100,
        'city': city,
        if (area != null) 'area': area,
      };
      final card = SearchListing.fromJson(json).toCardListing();
      final seller = ListingSeller.fromJson(json);
      expect(card.area, area);
      expect(card.locationLabel, expected);
      expect(seller.locationLabel, expected);
      await _pump(tester, card);
      expect(find.text(expected), findsOneWidget);
      expect(find.bySemanticsLabel('Chair, ₹100, $expected'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('long area stays one line visually and complete in accessible text', (tester) async {
    final semantics = tester.ensureSemantics();
    const area = 'A very long neighbourhood name with multiple words';
    final listing = SearchListing.fromJson({
      'listingId': 'l1',
      'title': 'Chair',
      'price': 100,
      'area': area,
      'city': 'Pune',
    }).toCardListing();
    await _pump(tester, listing, locale: const Locale('hi'));
    expect(tester.widget<Text>(find.text('$area, Pune')).overflow, TextOverflow.ellipsis);
    expect(find.bySemanticsLabel('Chair, ₹100, $area, Pune'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('a search card loads the network photo sized to the card, not at full size',
      (tester) async {
    await _pump(
      tester,
      const Listing(
        id: 'l1',
        title: 'Apple iPhone 14',
        priceInr: 42000,
        city: 'Pune',
        condition: ListingCondition.good,
        image: 'https://media.example/card-600.jpg',
      ),
    );

    final image = tester.widget<AppImage>(find.byType(AppImage));
    expect(image.source, 'https://media.example/card-600.jpg');
    expect(image.cacheWidth, 420);
    final network = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    expect(network.imageUrl, 'https://media.example/card-600.jpg');
    expect(network.memCacheWidth, 420);
  });

  testWidgets('a card without a photo shows the neutral placeholder', (tester) async {
    await _pump(
      tester,
      const Listing(
        id: 'l1',
        title: 'No photo',
        priceInr: 10,
        city: 'Pune',
        condition: ListingCondition.good,
        image: '',
      ),
    );

    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('prices keep their paise and whole rupees have none', (tester) async {
    await _pump(
      tester,
      const Listing(
        id: 'l1',
        title: 'Cheap',
        priceInr: 1299.5,
        city: 'Pune',
        condition: ListingCondition.good,
        image: '',
      ),
    );
    expect(find.text('\u20b91,299.50'), findsOneWidget);

    await _pump(
      tester,
      const Listing(
        id: 'l1',
        title: 'Whole',
        priceInr: 185000,
        city: 'Pune',
        condition: ListingCondition.good,
        image: '',
      ),
    );
    expect(find.text('\u20b91,85,000'), findsOneWidget);
  });

  testWidgets('a price qualifier shows Starting from above the price', (tester) async {
    await _pump(
      tester,
      const Listing(
        id: 'l1',
        title: 'Project',
        priceInr: 5000000,
        city: 'Pune',
        condition: null,
        image: '',
        startingFrom: true,
      ),
    );

    expect(find.text('Starting from'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Starting from')).dy,
      lessThan(tester.getTopLeft(find.text('\u20b950,00,000')).dy),
    );
  });

  testWidgets('the badge is BOOSTED, Featured, or none, and Featured wins', (tester) async {
    Listing listing({bool boosted = false, bool featured = false}) => Listing(
          id: 'l1',
          title: 'T',
          priceInr: 1,
          city: 'Pune',
          condition: ListingCondition.good,
          image: '',
          isBoosted: boosted,
          isFeatured: featured,
        );

    await _pump(tester, listing(boosted: true));
    expect(find.text('BOOSTED'), findsOneWidget);
    expect(find.text('Featured'), findsNothing);

    await _pump(tester, listing(featured: true));
    expect(find.text('Featured'), findsOneWidget);
    expect(find.text('BOOSTED'), findsNothing);

    await _pump(tester, listing(boosted: true, featured: true));
    expect(find.text('Featured'), findsOneWidget);
    expect(find.text('BOOSTED'), findsNothing);

    await _pump(tester, listing());
    expect(find.text('Featured'), findsNothing);
    expect(find.text('BOOSTED'), findsNothing);
  });

  testWidgets('a card without a price or condition leaves them out', (tester) async {
    await _pump(
      tester,
      const Listing(
        id: 'l1',
        title: 'Plot',
        priceInr: null,
        city: 'Pune',
        condition: null,
        image: '',
        startingFrom: true,
      ),
    );

    expect(find.text('Plot'), findsOneWidget);
    expect(find.text('Starting from'), findsNothing);
    expect(find.text('Good'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the card is announced in Hindi with the starting-from label', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      const Listing(
        id: 'l1',
        title: 'Flat',
        priceInr: 100,
        city: 'Pune',
        condition: null,
        image: '',
        startingFrom: true,
        isFeatured: true,
      ),
      locale: const Locale('hi'),
    );

    expect(find.bySemanticsLabel('Flat, शुरुआती कीमत \u20b9100, Pune, फ़ीचर्ड'), findsOneWidget);
    handle.dispose();
  });
}
