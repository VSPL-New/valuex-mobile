import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every word a user reads comes from the ARB files, so Hindi never falls back to English text
/// hard-coded in a widget. Add a key to `app_en.arb` and `app_hi.arb` instead of a literal.
void main() {
  // A literal with letters, no interpolation and no escapes (the flag emoji), for example Text('Save') or tooltip: 'Back'.
  final literal = RegExp(
    r"""(Text\(\s*(const )?|\b(label|hintText|labelText|tooltip|semanticLabel|helperText|errorText|content):\s*(const )?)(['"])[^'"$\\]*[A-Za-z]{2}[^'"$\\]*\5""",
  );

  test('no widget shows a hard-coded English string', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.contains('/l10n/') || entity.path.endsWith('.g.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (literal.hasMatch(lines[i])) {
          offenders.add('${entity.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
