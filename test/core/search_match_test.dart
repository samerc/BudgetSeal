import 'package:flutter_test/flutter_test.dart';
import 'package:budgetseal/shared/utils/search_match.dart';

void main() {
  test('folds accents, Arabic variants, diacritics and digits', () {
    expect(foldForSearch('Café Crème'), 'cafe creme');
    expect(foldForSearch('قهوة'), foldForSearch('قهوه'));
    expect(foldForSearch('أحمد'), 'احمد');
    expect(foldForSearch('مُحَمَّد'), 'محمد');
    expect(foldForSearch('مــاء'), 'ماء');
    expect(foldForSearch('١٢٫٥'), startsWith('12'));
  });

  test('every word must match, in any order', () {
    final q = SearchQuery.parse('coffee CAFÉ');
    expect(q.matches(foldForSearch('Morning coffee · Cafe Nero'), 4.5), isTrue);
    expect(q.matches(foldForSearch('Morning coffee'), 4.5), isFalse);
  });

  test('amount conditions', () {
    final q = SearchQuery.parse('fuel >40 <=50');
    expect(q.words, ['fuel']);
    expect(q.matches('fuel', 45), isTrue);
    expect(q.matches('fuel', 40), isFalse);
    expect(q.matches('fuel', 50), isTrue);
    expect(q.matches('fuel', -45), isTrue, reason: 'sign ignored');
    expect(SearchQuery.parse('=12,5').matches('', 12.5), isTrue);
    expect(SearchQuery.parse('>١٠٠').matches('', 150), isTrue);
  });

  test('empty query', () {
    expect(SearchQuery.parse('   ').isEmpty, isTrue);
  });
}
