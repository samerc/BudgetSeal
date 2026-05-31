// ignore_for_file: avoid_print
/// Converts docs/i18n_strings.csv → assets/web/locale_{en,ar,fr}.json
/// Only includes keys starting with "web_", "nav_", "common_", "type_",
/// "month_", "theme_", "freq_" (strings used in the web SPA).
///
/// Usage:  dart run tool/csv_to_web_json.dart
library;

import 'dart:convert';
import 'dart:io';

/// Prefixes that are relevant to the web SPA.
const _webPrefixes = [
  'web_',
  'nav_',
  'common_',
  'type_',
  'month_',
  'theme_',
  'freq_',
];

void main() {
  final csvFile = File('docs/i18n_strings.csv');
  if (!csvFile.existsSync()) {
    print('ERROR: docs/i18n_strings.csv not found');
    exit(1);
  }

  final lines = csvFile.readAsLinesSync();
  final enMap = <String, String>{};
  final arMap = <String, String>{};
  final frMap = <String, String>{};

  for (var i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty || line.startsWith('#')) continue;

    final fields = _parseCsvLine(line);
    if (fields.length < 5) continue;

    final key = fields[0].trim();
    if (key.isEmpty) continue;

    // Only include web-relevant keys
    if (!_webPrefixes.any((p) => key.startsWith(p))) continue;

    enMap[key] = fields[2].trim();
    arMap[key] = fields[3].trim();
    frMap[key] = fields[4].trim();
  }

  print('Extracted ${enMap.length} web strings from CSV');

  final encoder = JsonEncoder.withIndent('  ');
  File('assets/web/locale_en.json').writeAsStringSync('${encoder.convert(enMap)}\n');
  File('assets/web/locale_ar.json').writeAsStringSync('${encoder.convert(arMap)}\n');
  File('assets/web/locale_fr.json').writeAsStringSync('${encoder.convert(frMap)}\n');

  print('Done! Generated 3 locale JSON files in assets/web/');
}

List<String> _parseCsvLine(String line) {
  final fields = <String>[];
  var current = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (c == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        current.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (c == ',' && !inQuotes) {
      fields.add(current.toString());
      current = StringBuffer();
    } else {
      current.write(c);
    }
  }
  fields.add(current.toString());
  return fields;
}
