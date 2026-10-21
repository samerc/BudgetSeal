import 'dart:io';

import 'package:budgetseal/core/data/category_presets.dart';
import 'package:budgetseal/shared/widgets/category_icon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every preset emoji has a bundled Fluent PNG', () {
    for (final p in [...essentialPresets, ...detailedPresets]) {
      final file = categoryIconFile(p.fallbackName, p.emoji);
      expect(file, isNotNull, reason: '${p.fallbackName} ${p.emoji}');
      expect(File('assets/categories/$file').existsSync(), isTrue,
          reason: file);
    }
  });

  test('variation selector is ignored', () {
    expect(categoryIconFile('x', '✈️'), '2708.png');
    expect(categoryIconFile('x', '✈'), '2708.png');
  });

  test('name keywords: longest match wins', () {
    // "personal care" must not resolve to the car icon.
    expect(categoryIconFile('Personal care', null),
        categoryIconFile('x', '🧴'));
    expect(categoryIconFile('Car', null), categoryIconFile('x', '🚗'));
    expect(categoryIconFile('Zzz', null), isNull);
  });
}
