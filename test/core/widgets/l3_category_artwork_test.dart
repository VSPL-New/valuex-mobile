import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/constants/app_assets.dart';
import 'package:valuex_mobile/core/constants/l3_category_artwork.g.dart';
import 'package:valuex_mobile/core/theme/category_icon_catalog.g.dart';
import 'package:valuex_mobile/core/widgets/category_icon.dart';
import 'package:valuex_mobile/features/listing/domain/category.dart';
import 'package:valuex_mobile/features/search/presentation/widgets/category_browser_tiles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('L3 coverage is explicit and every ready image is bundled, bounded and decodable', () async {
    final taxonomy = categoryIconsByCode.keys.where((code) => code.startsWith('CAT-')).toSet();
    const ready = AppAssets.l3CategoryArtwork;
    final manifest =
        jsonDecode(File('.figma/l3-artwork.json').readAsStringSync()) as Map<String, dynamic>;
    final records = manifest['categories'] as List<dynamic>;
    final pending = (manifest['pendingCodes'] as List<dynamic>).cast<String>().toSet();
    expect(taxonomy, hasLength(l3ArtworkTaxonomyCount));
    expect(ready.length, manifest['readyCount']);
    expect(manifest['taxonomyCount'], l3ArtworkTaxonomyCount);
    expect(records.map((record) => record['code']).toSet(), ready.keys.toSet());
    expect(ready.values.toSet(), hasLength(ready.length));
    expect(ready.keys.toSet().intersection(pending), isEmpty);
    expect({...ready.keys, ...pending}, taxonomy);
    expect(records.map((record) => record['webpSha256']).toSet(), hasLength(ready.length));
    final assets = await AssetManifest.loadFromAssetBundle(rootBundle);
    expect(
      assets.listAssets().where((path) => path.startsWith('assets/images/categories/l3/')).toSet(),
      ready.values.toSet(),
    );
    for (final record in records) {
      final code = record['code'] as String;
      final path = ready[code]!;
      expect(path, 'assets/images/categories/l3/$code.webp');
      expect(categoryArtworkFor(code: code), path);
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, record['bytes'], reason: code);
      expect(data.lengthInBytes, lessThanOrEqualTo(30 * 1024), reason: code);
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WEBP');
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      expect(Size(descriptor.width.toDouble(), descriptor.height.toDouble()), const Size(256, 256),
          reason: code);
      descriptor.dispose();
      buffer.dispose();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 192, targetHeight: 192);
      final frame = await codec.getNextFrame();
      expect(
          Size(frame.image.width.toDouble(), frame.image.height.toDouble()), const Size(192, 192),
          reason: code);
      frame.image.dispose();
      codec.dispose();
    }
  });

  test('pending, future and L2 codes retain glyphs instead of borrowing leaf artwork', () {
    for (final code in categoryIconsByCode.keys.where(
      (code) =>
          (code.startsWith('L2-') || code.startsWith('CAT-')) &&
          !AppAssets.l3CategoryArtwork.containsKey(code),
    )) {
      expect(categoryArtworkFor(code: code), isNull, reason: code);
      expect(categoryIconFor(name: 'Smartphones', code: code), categoryIconsByCode[code]);
    }
    for (final code in [null, '', 'CAT-9999', 'cat-0001', 'CAT-0001 ', 'L2-FUTURE']) {
      expect(categoryArtworkFor(code: code), isNull);
    }
    expect(categoryArtworkFor(code: 'CAT-0001'), isNot(categoryArtworkFor(code: 'CAT-0002')));
  });

  testWidgets('real L3 grid uses exact artwork at 64dp, preserves labels and selection',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      CategoryNode? selected;
      const nodes = [
        CategoryNode(code: 'CAT-0001', name: 'Renamed phone', level: 3, hasChildren: false),
        CategoryNode(code: 'CAT-0002', name: 'Feature Phones', level: 3, hasChildren: false),
      ];
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 3, textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SizedBox(
              width: 390,
              child: CategoryLeafGrid(
                nodes: nodes,
                fallbackIcon: Icons.devices_rounded,
                onSelected: (node) => selected = node,
              ),
            ),
          ),
        ),
      ));
      for (final node in nodes) {
        final tile = find.byWidgetPredicate(
          (widget) => widget is CategoryIcon && widget.code == node.code,
        );
        final image = tester.widget<Image>(find.descendant(of: tile, matching: find.byType(Image)));
        final provider = image.image as ResizeImage;
        expect((provider.imageProvider as AssetImage).assetName,
            AppAssets.l3CategoryArtwork[node.code]);
        expect(provider.width, 192);
        expect(provider.height, 192);
        expect(image.excludeFromSemantics, isTrue);
        expect(tester.getSize(tile), const Size(64, 64));
        expect(find.bySemanticsLabel(node.name), findsOneWidget);
      }
      expect(find.byIcon(Icons.devices_rounded), findsNothing);
      await tester.tap(find.text('Renamed phone'));
      expect(selected, nodes.first);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('approved L3 samples render at actual 64dp Search tile size', (tester) async {
    const codes = [
      'CAT-0001',
      'CAT-0002',
      'CAT-0003',
      'CAT-0004',
      'CAT-0009',
      'CAT-0025',
      'CAT-0026',
      'CAT-0027',
      'CAT-0029',
      'CAT-0206',
      'CAT-0207',
      'CAT-0208',
      'CAT-0209',
      'CAT-0344',
      'CAT-0345',
      'CAT-0367',
      'CAT-0376',
      'CAT-0428',
      'CAT-0445',
      'CAT-0667',
      'CAT-0668',
      'CAT-0212',
      'CAT-0869',
      'CAT-0870',
    ];
    await tester.binding.setSurfaceSize(const Size(480, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const galleryKey = Key('l3-gallery');
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 1),
        child: RepaintBoundary(
          key: galleryKey,
          child: ColoredBox(
            color: Colors.white,
            child: Wrap(children: [
              for (final code in codes)
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Center(child: CategoryIcon(name: code, code: code, size: 64)),
                ),
            ]),
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
    expect(find.byType(Image), findsNWidgets(24));
    expect(tester.takeException(), isNull);
    await expectLater(find.byKey(galleryKey), matchesGoldenFile('goldens/l3-category-artwork.png'));
  });
}
