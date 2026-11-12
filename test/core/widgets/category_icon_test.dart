import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/constants/app_assets.dart';
import 'package:valuex_mobile/core/theme/category_icon_catalog.g.dart';
import 'package:valuex_mobile/core/widgets/category_icon.dart';

void main() {
  test('all approved taxonomy levels have non-placeholder bundled icons', () {
    expect(categoryIconsByCode.keys.where((code) => code.startsWith('L1-')), hasLength(39));
    expect(categoryIconsByCode.keys.where((code) => code.startsWith('L2-')), hasLength(157));
    expect(categoryIconsByCode.keys.where((code) => code.startsWith('CAT-')), hasLength(907));
    expect(categoryIconsByCode.values, isNot(contains(Icons.category_outlined)));
    for (final entry in categoryIconsByCode.entries) {
      expect(categoryIconFor(name: 'Renamed category', code: entry.key), entry.value);
    }
  });

  test('legacy Home aliases remain compatible with the catalog', () {
    for (final code in AppAssets.homeCategoryArtworkCodes.keys) {
      expect(categoryIconsByCode.containsKey(code), isTrue, reason: code);
      expect(
        categoryIconFor(name: 'Renamed category', code: code),
        isNot(Icons.category_outlined),
        reason: code,
      );
    }
  });

  test('exact matching avoids phones for headphones, and laptops for books', () {
    expect(categoryIconFor(name: 'Smartphones'), Icons.smartphone_rounded);
    expect(categoryIconFor(name: 'Feature Phones'), Icons.dialpad_rounded);
    expect(categoryIconFor(name: 'Foldable Phones'), Icons.devices_fold_rounded);
    expect(categoryIconFor(name: 'Wireless Headphones'), Icons.headphones_rounded);
    expect(categoryIconFor(name: 'Books'), Icons.menu_book_rounded);
    expect(categoryIconFor(name: '  CAMERAS  '), Icons.photo_camera_rounded);
    expect(categoryIconFor(name: 'Laptops'), Icons.laptop_mac_rounded);
  });

  test('ambiguous accessory names use their taxonomy path codes', () {
    expect(
      categoryIconFor(
        name: 'Accessories',
        code: 'L2-MUSICAL_INSTRUMENTS_PRO_AUDIO-ACCESSORIES',
      ),
      Icons.music_note_rounded,
    );
    expect(
      categoryIconFor(name: 'Accessories', code: 'L2-BICYCLES_MICRO_MOBILITY-ACCESSORIES'),
      Icons.pedal_bike_rounded,
    );
    expect(
      categoryIconFor(
        name: 'Accessories',
        code: 'L2-WATCHES_JEWELLERY_FASHION_ACCESSORIES-ACCESSORIES',
      ),
      Icons.watch_rounded,
    );
  });

  test('future categories inherit a parent icon, or an intentional neutral glyph', () {
    expect(
      categoryIconFor(name: 'New model', code: 'NEW-1', fallback: Icons.smartphone_rounded),
      Icons.smartphone_rounded,
    );
    expect(categoryIconFor(name: 'New root'), Icons.category_outlined);
  });

  testWidgets('icon is decorative, with its size independent of text scaling', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: CategoryIcon(name: 'Feature Phones', size: 64),
      ),
    ));
    expect(find.byIcon(Icons.dialpad_rounded), findsOneWidget);
    expect(tester.getSize(find.byType(CategoryIcon)), const Size(64, 64));
    final exclusion = find
        .descendant(
          of: find.byType(CategoryIcon),
          matching: find.byType(ExcludeSemantics),
        )
        .first;
    expect(tester.widget<ExcludeSemantics>(exclusion).excluding, isTrue);
  });
}
