import 'package:flutter_test/flutter_test.dart';
import 'package:budgetseal/core/engine/spending_average.dart';

void main() {
  test('averages from the first period with spending, rounded up', () {
    final avg = averageSpending([
      {'food': {'USD': 100}},
      {'food': {'USD': 120, 'LBP': 900000}, 'new': {'USD': 30}},
      {'food': {'USD': 95.5}, 'new': {'USD': 40.2}},
    ]);
    expect(avg['food']!['USD'], 106); // (100 + 120 + 95.5) / 3 = 105.17
    expect(avg['food']!['LBP'], 300000); // per period, not per month seen
    expect(avg['new']!['USD'], 36); // (30 + 40.2) / 2
  });

  test('envelopes with no spending get no average', () {
    expect(averageSpending([{'x': {'USD': 0}}, {}]), isEmpty);
  });
}
