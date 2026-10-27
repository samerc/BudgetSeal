import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/bottom_action_bar.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/tappable.dart';

/// Banknotes in circulation, largest first, for the currencies where cash
/// is counted most. Others count with "Other" only.
const cashNotes = <String, List<double>>{
  'USD': [100, 50, 20, 10, 5, 2, 1],
  'EUR': [500, 200, 100, 50, 20, 10, 5],
  'GBP': [50, 20, 10, 5],
  'LBP': [100000, 50000, 20000, 10000, 5000, 1000],
  'SYP': [5000, 2000, 1000, 500],
  'IQD': [50000, 25000, 10000, 5000, 1000, 500, 250],
  'JOD': [50, 20, 10, 5, 1],
  'EGP': [200, 100, 50, 20, 10, 5],
  'SAR': [500, 200, 100, 50, 20, 10, 5],
  'AED': [1000, 500, 200, 100, 50, 20, 10, 5],
  'TRY': [200, 100, 50, 20, 10, 5],
  'MAD': [200, 100, 50, 20],
  'TND': [50, 20, 10],
  'XOF': [10000, 5000, 2000, 1000, 500],
  'NGN': [1000, 500, 200, 100, 50],
  'ZAR': [200, 100, 50, 20, 10],
  'INR': [500, 200, 100, 50, 20, 10],
  'ARS': [20000, 10000, 2000, 1000, 500, 200, 100],
  'BRL': [200, 100, 50, 20, 10, 5, 2],
  'MXN': [1000, 500, 200, 100, 50, 20],
  'CAD': [100, 50, 20, 10, 5],
  'AUD': [100, 50, 20, 10, 5],
  'CHF': [1000, 200, 100, 50, 20, 10],
  'JPY': [10000, 5000, 2000, 1000],
};

/// Count cash by notes (roadmap #3): how many of each note, plus "Other"
/// for coins, against what the app expects. Pops with the total, which
/// the account screen applies like Adjust balance (adjustment + marked
/// reconciled).
class CashCountScreen extends StatefulWidget {
  final String currency;
  final double? balance;

  const CashCountScreen({super.key, required this.currency, this.balance});

  @override
  State<CashCountScreen> createState() => _CashCountScreenState();
}

class _CashCountScreenState extends State<CashCountScreen> {
  late final List<double> _notes = cashNotes[widget.currency] ?? const [];
  late final List<int> _counts = List.filled(_notes.length, 0);
  double _other = 0;

  double get _total {
    var t = _other;
    for (var i = 0; i < _notes.length; i++) {
      t += _notes[i] * _counts[i];
    }
    return t;
  }

  String _note(double v) =>
      formatAmount(v, currency: widget.currency, decimals: 0);

  Future<void> _type(int i) async {
    final v = await showCalculatorSheet(context, _counts[i].toDouble(),
        title: S.of(context).cashCountHowMany(_note(_notes[i])));
    if (v == null || !mounted) return;
    setState(() => _counts[i] = v.round().clamp(0, 1000000));
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final total = _total;
    final diff = widget.balance == null ? null : total - widget.balance!;

    Widget step(IconData icon, VoidCallback? onTap) => Tappable(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.sf(context),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 18,
                color: onTap == null
                    ? AppColors.th(context)
                    : AppColors.accentText(context)),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(tr.cashCountTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(tr.cashCountIntro,
                style: TextStyle(fontSize: 13.5, color: AppColors.ts(context))),
          ),
          Container(
            decoration: AppColors.card(context),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < _notes.length; i++)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(children: [
                      Expanded(
                        child: Text(_note(_notes[i]),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                      step(AppIcons.minus,
                          _counts[i] == 0
                              ? null
                              : () => setState(() => _counts[i]--)),
                      Tappable(
                        onTap: () => _type(i),
                        child: SizedBox(
                          width: 52,
                          child: Text('${_counts[i]}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      step(AppIcons.plus, () => setState(() => _counts[i]++)),
                    ]),
                  ),
                Tappable(
                  onTap: () async {
                    final v = await showCalculatorSheet(context, _other,
                        title: tr.cashCountOther);
                    if (v != null && mounted) setState(() => _other = v);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(children: [
                      Expanded(
                        child: Text(tr.cashCountOther,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      Text(formatAmount(_other, currency: widget.currency),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        above: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tr.cashCountTotal(
                    formatAmount(total, currency: widget.currency)),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            if (widget.balance != null)
              Text(
                  tr.acctCurrentBalanceLabel(
                      formatAmount(widget.balance!, currency: widget.currency)),
                  style:
                      TextStyle(fontSize: 13, color: AppColors.ts(context))),
            if (diff != null)
              Text(
                diff.abs() < 0.005
                    ? tr.acctReconcileMatches
                    : tr.acctReconcileDiff(formatSignedAmount(diff,
                        currency: widget.currency,
                        type: diff > 0 ? 'income' : 'expense')),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: diff.abs() < 0.005
                      ? AppColors.healthy
                      : AppColors.caution,
                ),
              ),
          ],
        ),
        children: [
          FilledButton(
            onPressed: () => context.pop(total),
            child: Text(tr.cashCountUse),
          ),
        ],
      ),
    );
  }
}
