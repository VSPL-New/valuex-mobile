import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/constants/app_assets.dart';
import 'package:valuex_mobile/core/theme/category_icon_catalog.g.dart';
import 'package:valuex_mobile/core/theme/spacing.dart';
import 'package:valuex_mobile/core/widgets/category_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all 39 roots have compact WebP artwork and original provenance', () async {
    final roots = categoryIconsByCode.keys.where((code) => code.startsWith('L1-')).toSet();
    expect(AppAssets.l1CategoryArtwork.keys.toSet(), roots);
    expect(AppAssets.l1CategoryArtwork.values.toSet(), hasLength(39));
    final manifest = File('.figma/l1-artwork.csv').readAsLinesSync().skip(1);
    expect(manifest, hasLength(39));
    expect(manifest.map((line) => line.split(',').first).toSet(), roots);
    for (final line in manifest) {
      final fields = line.split(',');
      expect(AppAssets.l1CategoryArtwork[fields[0]], endsWith('/${fields[1]}.webp'));
      expect(fields[4], matches(RegExp(r'^[a-f0-9]{64}$')));
      expect(fields[5], matches(RegExp(r'^[a-f0-9]{64}$')));
      expect(fields[6], '256');
      expect(fields[7], '85');
      expect(File('assets/images/categories/l1/${fields[1]}.png').existsSync(), isFalse);
    }
    for (final entry in AppAssets.l1CategoryArtwork.entries) {
      expect(categoryArtworkFor(code: entry.key), entry.value);
      final data = await rootBundle.load(entry.value);
      expect(data.lengthInBytes, lessThanOrEqualTo(30 * 1024), reason: entry.key);
      expect(String.fromCharCodes(data.buffer.asUint8List(0, 4)), 'RIFF');
      expect(String.fromCharCodes(data.buffer.asUint8List(8, 4)), 'WEBP');
      final buffer = await ui.ImmutableBuffer.fromUint8List(data.buffer.asUint8List());
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      expect(Size(descriptor.width.toDouble(), descriptor.height.toDouble()), const Size(256, 256),
          reason: entry.key);
      descriptor.dispose();
      buffer.dispose();
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: 48);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 48, reason: entry.key);
      frame.image.dispose();
      codec.dispose();
    }
  });

  testWidgets('artwork decode dimensions stay within the source pixel bounds', (tester) async {
    for (final (ratio, expected) in [(0.001, 1), (8.0, 256)]) {
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(devicePixelRatio: ratio),
          child: const Center(child: CategoryIcon(name: 'Cars', code: 'L1-CARS', size: 64)),
        ),
      ));
      final provider = tester.widget<Image>(find.byType(Image)).image as ResizeImage;
      expect(provider.width, expected);
      expect(provider.height, expected);
    }
  });

  test('legacy Home IDs remain compatible with root images', () {
    expect(AppAssets.homeCategoryArtworkCodes, hasLength(12));
    for (final code in AppAssets.homeCategoryArtworkCodes.keys) {
      expect(categoryArtworkFor(code: code), isIn(AppAssets.l1CategoryArtwork.values),
          reason: code);
    }
  });

  test('L2 and L3 codes never inherit L1 artwork', () {
    final children =
        categoryIconsByCode.keys.where((code) => code.startsWith('L2-') || code.startsWith('CAT-'));
    expect(children, hasLength(1064));
    for (final code in children) {
      expect(categoryArtworkFor(code: code), AppAssets.l3CategoryArtwork[code], reason: code);
      expect(AppAssets.l1CategoryArtwork.values, isNot(contains(categoryArtworkFor(code: code))));
      expect(categoryIconFor(name: 'Toys', code: code), categoryIconsByCode[code]);
    }
    for (final code in [null, '', 'L1-FUTURE', 'CAT-FUTURE', 'L2-FUTURE', 'unknown']) {
      expect(categoryArtworkFor(code: code), isNull);
    }
  });

  testWidgets('L1 image preserves size, rounded clipping, semantics and physical decode size',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(devicePixelRatio: 3, textScaler: TextScaler.linear(2)),
        child: Center(child: CategoryIcon(name: 'Renamed', code: 'L1-CARS', size: 64)),
      ),
    ));
    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as ResizeImage;
    expect(provider.width, 192);
    expect(provider.height, 192);
    expect(
        (provider.imageProvider as AssetImage).assetName, AppAssets.l1CategoryArtwork['L1-CARS']);
    expect(image.fit, BoxFit.cover);
    expect(image.excludeFromSemantics, isTrue);
    expect(tester.getSize(find.byType(CategoryIcon)), const Size(64, 64));
    final container = tester.widget<Container>(
        find.descendant(of: find.byType(CategoryIcon), matching: find.byType(Container)));
    expect(container.clipBehavior, Clip.antiAlias);
    expect(
        (container.decoration as BoxDecoration).borderRadius, BorderRadius.circular(AppRadius.xl));
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('a future leaf or name-only category never receives L1 artwork', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Column(children: [
        CategoryIcon(name: 'Toys', code: 'CAT-FUTURE'),
        CategoryIcon(name: 'Furniture', code: 'L2-FUTURE'),
        CategoryIcon(name: 'Mobiles & Tablets'),
      ]),
    ));
    expect(find.byType(Image), findsNothing);
    expect(find.byType(Icon), findsNWidgets(3));
  });

  testWidgets('all 39 L1 illustrations render at actual 48dp tile size', (tester) async {
    await tester.binding.setSurfaceSize(const Size(448, 384));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const galleryKey = Key('l1-gallery');
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 1),
        child: Center(
          child: RepaintBoundary(
            key: galleryKey,
            child: ColoredBox(
              color: Colors.white,
              child: SizedBox(
                width: 448,
                height: 384,
                child: Wrap(
                  children: [
                    for (final code in AppAssets.l1CategoryArtwork.keys)
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: Center(child: CategoryIcon(name: code, code: code)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    final context = tester.element(find.byKey(galleryKey));
    await tester.runAsync(() async {
      for (final image in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(image.image, context);
      }
    });
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNWidgets(39));
    expect(tester.takeException(), isNull);
    await expectLater(find.byKey(galleryKey), matchesGoldenFile('goldens/l1-category-artwork.png'));
  });
}
