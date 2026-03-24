import 'dart:convert';
import 'dart:io';

import '../lib/constants/translations.dart';

void main() {
  final outDir = Directory('lib/l10n');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  for (final entry in translations.entries) {
    final code = entry.key;
    final values = entry.value;

    final map = <String, dynamic>{'@@locale': code};
    map.addAll(values);

    final file = File('lib/l10n/app_${code}.arb');
    const encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync('${encoder.convert(map)}\n');
  }

  stdout.writeln('Generated ${translations.length} ARB files in lib/l10n');
}
