import 'package:budgetseal/core/engine/sinking_fund.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // School tuition in two currencies, planned in November.
  final tuition = [
    FundPayment(
        title: '2nd installment',
        date: DateTime(2027, 1, 5),
        amounts: const {'USD': 1500, 'LBP': 45000000},
        planId: 'a'),
    FundPayment(
        title: '3rd installment',
        date: DateTime(2027, 4, 1),
        amounts: const {'USD': 1000, 'LBP': 30000000},
        planId: 'b'),
    FundPayment(
        title: '1st installment',
        date: DateTime(2027, 9, 1),
        amounts: const {'USD': 1500, 'LBP': 45000000},
        planId: 'c'),
  ];

  group('planSinkingFund', () {
    test('levels each currency to the payments ahead', () {
      final plan = planSinkingFund(
        payments: tuition,
        balanceAtStart: const {},
        funded: const {},
        anchor: DateTime(2026, 11, 1),
        balanceAtAnchor: const {},
        startDay: 1,
        now: DateTime(2026, 11, 3),
      );
      expect(plan.spread, {'USD': 500, 'LBP': 15000000});
      expect(plan.isBehind, isFalse);
      expect(plan.next?.title, '2nd installment');
      final steps = plan.steps(BehindMode.spread);
      expect(steps.map((s) => [s.from.month, s.to.month]).toList(), [
        [11, 1],
        [2, 4],
        [5, 9],
      ]);
      expect(steps[1].amounts, {'USD': 333.34, 'LBP': 10000000});
      expect(steps[2].amounts, {'USD': 300, 'LBP': 9000000});
    });

    test('what went in this period comes off the share', () {
      final plan = planSinkingFund(
        payments: tuition,
        balanceAtStart: const {},
        funded: const {'USD': 200},
        anchor: DateTime(2026, 11, 1),
        balanceAtAnchor: const {},
        startDay: 1,
        now: DateTime(2026, 11, 20),
      );
      expect(plan.remaining(BehindMode.spread),
          {'USD': 300, 'LBP': 15000000});
    });

    test('a payment made this period still counts this period', () {
      // January: 1,000 at the start, 500 funded, 1,500 paid on the 5th.
      final plan = planSinkingFund(
        payments: [
          FundPayment(
              title: 'paid',
              date: DateTime(2027, 1, 5),
              amounts: const {'USD': 1500},
              txId: 't'),
          FundPayment(
              title: 'next',
              date: DateTime(2027, 4, 1),
              amounts: const {'USD': 1000},
              planId: 'b'),
        ],
        balanceAtStart: const {'USD': 1000},
        funded: const {'USD': 500},
        anchor: DateTime(2027, 1, 1),
        balanceAtAnchor: const {'USD': 1000},
        startDay: 1,
        now: DateTime(2027, 1, 20),
      );
      expect(plan.remaining(BehindMode.spread), isEmpty);
      expect(plan.steps(BehindMode.spread).last.amounts, {'USD': 333.34});
    });

    test('behind: spread raises the share, top up catches up now', () {
      // $320 due Dec 1, saving since January, only $80 in.
      final plan = planSinkingFund(
        payments: [
          FundPayment(
              title: 'Car insurance',
              date: DateTime(2026, 12, 1),
              amounts: const {'USD': 320},
              recurringId: 'r'),
        ],
        balanceAtStart: const {'USD': 80},
        funded: const {},
        anchor: DateTime(2026, 1, 1),
        balanceAtAnchor: const {},
        startDay: 1,
        now: DateTime(2026, 11, 3),
      );
      expect(plan.isBehind, isTrue);
      expect(plan.behind['USD'], closeTo(186.67, 0.01));
      expect(plan.spread['USD'], 120);
      expect(plan.topUp['USD'], closeTo(213.34, 0.01));
    });

    test('topping up clears behind; the plan then runs steady', () {
      final plan = planSinkingFund(
        payments: [
          FundPayment(
              title: 'Car insurance',
              date: DateTime(2026, 12, 1),
              amounts: const {'USD': 320},
              recurringId: 'r'),
        ],
        balanceAtStart: const {'USD': 80},
        funded: const {'USD': 213.34},
        anchor: DateTime(2026, 1, 1),
        balanceAtAnchor: const {},
        startDay: 1,
        now: DateTime(2026, 11, 20),
      );
      expect(plan.isBehind, isFalse);
      expect(plan.remaining(BehindMode.topUp), isEmpty);
      expect(plan.steps(BehindMode.spread).last.amounts['USD'],
          closeTo(26.66, 0.01));
    });

    test('periods that start mid-month', () {
      final plan = planSinkingFund(
        payments: [
          FundPayment(
              title: 'x',
              date: DateTime(2027, 1, 5),
              amounts: const {'USD': 300},
              planId: 'a'),
        ],
        balanceAtStart: const {},
        funded: const {},
        anchor: DateTime(2026, 10, 25),
        balanceAtAnchor: const {},
        startDay: 25,
        now: DateTime(2026, 11, 3),
      );
      // Periods from Oct 25, Nov 25, Dec 25 (Jan 5 falls in the last).
      expect(plan.spread, {'USD': 100});
    });
  });

  test('fundBillDates: yearly and quarterly only', () {
    final until = DateTime(2027, 12, 31);
    expect(
        fundBillDates(
            frequency: 'monthly',
            interval: 1,
            next: DateTime(2026, 11, 25),
            until: until),
        isEmpty);
    expect(
        fundBillDates(
            frequency: 'monthly',
            interval: 3,
            next: DateTime(2026, 11, 30),
            until: DateTime(2027, 6, 1)),
        [DateTime(2026, 11, 30), DateTime(2027, 2, 28), DateTime(2027, 5, 30)]);
    expect(
        fundBillDates(
            frequency: 'yearly',
            interval: 1,
            next: DateTime(2027, 3, 15),
            until: until),
        [DateTime(2027, 3, 15)]);
  });

  test('copyFromLastYear: a year later, past ones dropped, duplicates marked',
      () {
    final now = DateTime(2027, 6, 10);
    final copies = copyFromLastYear([
      FundPayment(
          title: '1st',
          date: DateTime(2026, 9, 1),
          amounts: const {'USD': 1500},
          txId: 't1'),
      FundPayment(
          title: '2nd',
          date: DateTime(2027, 1, 5),
          amounts: const {'USD': 1500},
          txId: 't2'),
      FundPayment(
          title: 'old',
          date: DateTime(2026, 3, 1),
          amounts: const {'USD': 1},
          txId: 't0'),
      FundPayment(
          title: 'planned already',
          date: DateTime(2027, 9, 3),
          amounts: const {'USD': 1600},
          planId: 'p'),
    ], now: now);
    expect(copies.map((c) => c.payment.date).toList(),
        [DateTime(2027, 9, 1), DateTime(2028, 1, 5), DateTime(2028, 9, 3)]);
    expect(copies.first.alreadyPlanned, isTrue);
    expect(copies[1].alreadyPlanned, isFalse);
  });
}
