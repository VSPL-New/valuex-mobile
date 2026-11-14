import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valuex_mobile/core/theme/app_theme.dart';
import 'package:valuex_mobile/features/listing_view/domain/public_listing.dart';
import 'package:valuex_mobile/features/listing_view/presentation/widgets/listing_attribute_table.dart';
import 'package:valuex_mobile/l10n/app_localizations.dart';

import '../../helpers/fonts.dart';

void main() {
  setUpAll(loadBrandFonts);

  test('attribute formatting preserves units, decimals, booleans and lists', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    for (final (value, unit, expected) in [
      (true, 'ignored', 'Yes'),
      (false, null, 'No'),
      (95.0, '%', '95 %'),
      (1.5, 'kg', '1.5 kg'),
      (['Box', 'Charger'], null, 'Box, Charger'),
      ('Original', '', 'Original'),
    ]) {
      expect(
        formatAttributeValue(
            l10n, ListingAttribute(key: 'k', label: 'Label', value: value, unit: unit)),
        expected,
      );
    }
    expect(
      formatAttributeValue(lookupAppLocalizations(const Locale('hi')),
          const ListingAttribute(key: 'k', label: 'Label', value: false)),
      lookupAppLocalizations(const Locale('hi')).itemNo,
    );
  });

  testWidgets('known schema keys have specific icons and unknown ones remain readable',
      (tester) async {
    const icons = {
      'model': Icons.label_outline_rounded,
      'battery_health_pct': Icons.battery_charging_full_rounded,
      'has_box': Icons.inventory_2_outlined,
      'accessories': Icons.cable_rounded,
      'storage_gb': Icons.storage_rounded,
      'property_area': Icons.tune_rounded,
    };
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ListingAttributeTable(attributes: [
          for (final key in icons.keys) ListingAttribute(key: key, label: key, value: 'Value'),
        ]),
      ),
    ));
    for (final entry in icons.entries) {
      expect(find.byIcon(entry.value), findsOneWidget);
      expect(find.text(entry.key), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
