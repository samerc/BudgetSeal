// ignore_for_file: avoid_print
/// Converts docs/i18n_strings.csv → lib/l10n/app_{en,ar,fr}.arb
///
/// Usage:  dart run tool/csv_to_arb.dart
library;

import 'dart:convert';
import 'dart:io';

void main() {
  final csvFile = File('docs/i18n_strings.csv');
  if (!csvFile.existsSync()) {
    print('ERROR: docs/i18n_strings.csv not found');
    exit(1);
  }

  final lines = csvFile.readAsLinesSync();
  final entries = <_Entry>[];

  for (var i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty || line.startsWith('#')) continue;

    final fields = _parseCsvLine(line);
    if (fields.length < 5) {
      print('WARN: skipping line $i (only ${fields.length} fields): $line');
      continue;
    }

    final key = fields[0].trim();
    final context = fields[1].trim();
    final en = fields[2].trim();
    final ar = fields[3].trim();
    final fr = fields[4].trim();

    if (key.isEmpty) continue;

    entries.add(_Entry(
      key: _snakeToCamel(key),
      context: context,
      en: en,
      ar: ar,
      fr: fr,
    ));
  }

  print('Parsed ${entries.length} entries from CSV');

  _writeArb('lib/l10n/app_en.arb', 'en', entries, (e) => e.en);
  _writeArb('lib/l10n/app_ar.arb', 'ar', entries, (e) => e.ar);
  _writeArb('lib/l10n/app_fr.arb', 'fr', entries, (e) => e.fr);

  print('Done! Generated 3 ARB files in lib/l10n/');
}

/// Parse a CSV line respecting quoted fields (handles commas inside quotes).
List<String> _parseCsvLine(String line) {
  final fields = <String>[];
  var current = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (c == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        // Escaped quote inside quoted field
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

/// Convert snake_case to camelCase: "dashboard_welcome_title" → "dashboardWelcomeTitle"
String _snakeToCamel(String s) {
  final parts = s.split('_');
  if (parts.length <= 1) return s;
  return parts.first +
      parts.skip(1).map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1)).join();
}

/// Extract {param} placeholders from a string.
List<String> _extractPlaceholders(String s) {
  final regex = RegExp(r'\{(\w+)\}');
  return regex.allMatches(s).map((m) => m.group(1)!).toSet().toList();
}

void _writeArb(
  String path,
  String locale,
  List<_Entry> entries,
  String Function(_Entry) getText,
) {
  final map = <String, dynamic>{'@@locale': locale};

  for (final entry in entries) {
    final text = getText(entry);
    map[entry.key] = text;

    // Add @key metadata for context + placeholders
    final placeholders = _extractPlaceholders(text);
    // Also check English for placeholders (Arabic/French might use same params)
    final enPlaceholders = _extractPlaceholders(entry.en);
    final allPlaceholders = {...placeholders, ...enPlaceholders}.toList();

    final meta = <String, dynamic>{};
    if (entry.context.isNotEmpty) {
      meta['description'] = entry.context;
    }
    if (allPlaceholders.isNotEmpty) {
      final phMap = <String, dynamic>{};
      for (final ph in allPlaceholders) {
        // Guess type from name
        if (ph == 'count' || ph == 'n' || ph == 'days' || ph == 'detected' || ph == 'withPrice' || ph == 'page') {
          phMap[ph] = {'type': 'int'};
        } else if (ph == 'pct') {
          phMap[ph] = {'type': 'double'};
        } else {
          phMap[ph] = {'type': 'String'};
        }
      }
      meta['placeholders'] = phMap;
    }
    if (meta.isNotEmpty) {
      map['@${entry.key}'] = meta;
    }
  }

  final encoder = JsonEncoder.withIndent('  ');
  File(path).writeAsStringSync('${encoder.convert(map)}\n');
  print('  Wrote $path (${entries.length} entries)');
}

class _Entry {
  final String key;
  final String context;
  final String en;
  final String ar;
  final String fr;

  _Entry({
    required this.key,
    required this.context,
    required this.en,
    required this.ar,
    required this.fr,
  });
}
