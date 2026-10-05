import 'package:flutter/services.dart';

/// Loads the bundled brand fonts so layout tests measure real glyph widths instead of the
/// default test font, which is much wider.
Future<void> loadBrandFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(rootBundle.load('assets/fonts/$file'));
    }
    await loader.load();
  }

  await load('Poppins', [
    'Poppins-Regular.ttf',
    'Poppins-Medium.ttf',
    'Poppins-SemiBold.ttf',
    'Poppins-Bold.ttf',
  ]);
  await load('DMSans', [
    'DMSans-Regular.ttf',
    'DMSans-Medium.ttf',
    'DMSans-SemiBold.ttf',
    'DMSans-Bold.ttf',
  ]);
}
