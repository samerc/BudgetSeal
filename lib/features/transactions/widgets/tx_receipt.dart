import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/engine/envelope_for_category.dart';
import '../../../core/providers/allocations_provider.dart';
import '../../../core/providers/date_format_provider.dart';
import '../../../core/providers/transactions_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_icons.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/utils/format_number.dart';
import '../../../shared/utils/note_text.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/tappable.dart';

/// Where an expense's envelope stands now (for the stamp and Cover).
typedef ReceiptEnvelope = ({
  String allocationId,
  String name,
  double balance,
  String currency,
});

/// The envelope of the expense's biggest categorised line, with its current
/// balance in that line's currency. Null for other types or no envelope.
ReceiptEnvelope? receiptEnvelope(
  TransactionEntry entry,
  Map<String, Category> categoryMap,
  List<AllocationWithBalance> allocations,
) {
  if (entry.tx.type != 'expense' || entry.tx.status != null) return null;
  final lines = entry.lines.where((l) => l.categoryId != null).toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
  final line = lines.firstOrNull;
  if (line == null) return null;
  final envId = envelopeForCategory(line.categoryId!,
      categoriesById: categoryMap,
      liveAllocations: allocations.map((a) => a.data.allocation));
  final env =
      allocations.where((a) => a.data.allocation.id == envId).firstOrNull;
  if (env == null) return null;
  // No entry for the line's currency means that side is back to 0
  // (an LBP expense covered exactly), not that there's nothing to say.
  final balance = env.balanceByCurrency[line.currency] ?? 0.0;
  return (
    allocationId: env.data.allocation.id,
    name: env.data.allocation.name,
    balance: balance,
    currency: line.currency,
  );
}

/// The transaction shown as a paper receipt: what and where at the top,
/// one line per item, the total, and a stamp with what it did to the
/// budget (the envelope's balance now, Ready to assign, planned…).
class TxReceipt extends ConsumerWidget {
  final TransactionEntry entry;
  final Map<String, Category> categoryMap;
  final String baseCurrency;

  const TxReceipt({
    super.key,
    required this.entry,
    required this.categoryMap,
    required this.baseCurrency,
  });

  static const _tabular = [FontFeature.tabularFigures()];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = S.of(context);
    final tx = entry.tx;
    final full = visibleNote(tx.note).trim();
    final dash = full.indexOf(' — ');
    final title = dash >= 0 ? full.substring(0, dash) : full;
    final note = dash >= 0 ? full.substring(dash + 3) : '';
    final primaryCat =
        tx.categoryId != null ? categoryMap[tx.categoryId] : null;
    final typeLabel = switch (tx.type) {
      'income' => tr.typeIncome,
      'transfer' => tr.typeTransfer,
      _ => tr.typeExpense,
    };
    final heading = title.isNotEmpty ? title : (primaryCat?.name ?? typeLabel);
    final date = tx.createdAt.toLocal();
    final accountId = entry.lines.isNotEmpty
        ? (entry.lines.first.accountId ?? tx.accountId)
        : tx.accountId;
    final accountNames = entry.involvedAccountNames;
    final accountName = accountNames.length > 1
        ? accountNames.join(', ')
        : (entry.accountName.isNotEmpty
            ? entry.accountName
            : tr.txDetailUnknownAccount);
    final where = switch (tx.type) {
      'transfer' =>
        '${entry.accountName} → ${entry.destinationAccountName ?? tr.txDetailUnknownAccount}',
      'income' => tr.txReceiptPaidInto(accountName),
      _ => tr.txReceiptPaidFrom(accountName),
    };

    final ts = AppColors.ts(context);
    final rule = AppColors.bd(context);
    final allocations =
        ref.watch(allocationsProvider).value ?? const <AllocationWithBalance>[];
    final total = _totalText();

    return ClipPath(
      clipper: _TornEdge(),
      child: Container(
        color: AppColors.sf(context),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: primaryCat != null
                  ? Hero(
                      tag: 'tx_${tx.id}',
                      child: CategoryIcon(
                        categoryName: primaryCat.name,
                        emoji: primaryCat.icon,
                        color: AppColors.fromHex(primaryCat.colorHex),
                        size: 48,
                        circular: true,
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.pastel(context, AppColors.accent),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                          tx.type == 'transfer'
                              ? AppIcons.arrowsLeftRight
                              : AppIcons.receipt,
                          color: AppColors.accentText(context)),
                    ),
            ),
            const SizedBox(height: 10),
            Text(heading,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: TypographyTokens.displayFamily,
                    fontSize: 24,
                    height: 1.15,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              '${formatDate(date)} · ${TimeOfDay.fromDateTime(date).format(context)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: ts),
            ),
            Tappable(
              onTap: () => context.push('/accounts/$accountId'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('$where ›',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: ts)),
              ),
            ),
            _Dashes(color: rule),
            ..._lineRows(context, tr),
            if (entry.lines.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(tr.txReceiptItems(entry.lines.length),
                    style: TextStyle(fontSize: 12, color: ts)),
              ),
            _Dashes(color: rule),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(tr.txReceiptTotal.toUpperCase(),
                    style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                        color: ts)),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: total));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(tr.txDetailCopied(total)),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ));
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(total,
                          style: const TextStyle(
                              fontFamily: TypographyTokens.displayFamily,
                              fontSize: 36,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5)),
                    ),
                  ),
                ),
              ],
            ),
            if (entry.lines.length == 1 &&
                entry.lines.first.currency != baseCurrency &&
                tx.type != 'transfer')
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text('= ${formatAmount(tx.amount, currency: baseCurrency)}',
                    style: TextStyle(fontSize: 13, color: ts)),
              ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(note,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: AppColors.tp(context))),
            ],
            _stamp(context, tr,
                receiptEnvelope(entry, categoryMap, allocations)),
          ],
        ),
      ),
    );
  }

  /// Paper receipts show the amount plain; only income keeps its "+".
  String _totalText() {
    final tx = entry.tx;
    String fmt(double v, String cur) => tx.type == 'income'
        ? formatSignedAmount(v, currency: cur, type: tx.type)
        : formatAmount(v, currency: cur);
    if (entry.lines.length == 1) {
      return fmt(entry.lines.first.amount, entry.lines.first.currency);
    }
    if (entry.lines.isEmpty) {
      return fmt(tx.amount, tx.currency);
    }
    // Several lines: the base total, skipping lines with no real rate.
    double baseTotal = 0;
    for (final l in entry.lines) {
      if (l.currency == baseCurrency) {
        baseTotal += l.amount;
      } else if (isRealRate(l.currency, baseCurrency, l.exchangeRateToBase)) {
        baseTotal += l.amount * l.exchangeRateToBase;
      }
    }
    return fmt(baseTotal, baseCurrency);
  }

  List<Widget> _lineRows(BuildContext context, S tr) {
    final tx = entry.tx;
    final ts = AppColors.ts(context);
    Widget row(String label, String? sub, String amount, {String? converted}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  if (sub != null && sub.isNotEmpty)
                    Text(sub,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: ts)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amount,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFeatures: _tabular)),
                if (converted != null)
                  Text(converted,
                      style: TextStyle(
                          fontSize: 12, color: ts, fontFeatures: _tabular)),
              ],
            ),
          ],
        ),
      );
    }

    if (tx.type == 'transfer' || entry.lines.isEmpty) {
      final destCur = entry.destinationAccountCurrency;
      final crossCurrency = tx.type == 'transfer' &&
          destCur != null &&
          destCur != tx.currency &&
          tx.exchangeRateToBase > 0;
      return [
        row(
          tx.type == 'transfer' ? tr.typeTransfer : tr.txDetailUncategorized,
          null,
          formatAmount(tx.amount, currency: tx.currency),
          converted: crossCurrency
              ? '= ${formatAmount(tx.amount * tx.exchangeRateToBase, currency: destCur)}'
              : null,
        ),
      ];
    }
    final mainAccount = entry.lines.first.accountId ?? tx.accountId;
    return [
      for (final l in entry.lines)
        row(
          l.categoryId != null
              ? (categoryMap[l.categoryId]?.name ?? tr.txDetailUncategorized)
              : tr.txDetailUncategorized,
          [
            if (entry.lines.length > 1 && l.note.isNotEmpty) l.note,
            if ((l.accountId ?? tx.accountId) != mainAccount)
              entry.lineAccountNames[l.accountId ?? tx.accountId] ?? '',
          ].where((s) => s.isNotEmpty).join(' · '),
          formatAmount(l.amount, currency: l.currency),
          converted: entry.lines.length > 1 &&
                  l.currency != baseCurrency &&
                  isRealRate(l.currency, baseCurrency, l.exchangeRateToBase)
              ? '= ${formatAmount(l.amount * l.exchangeRateToBase, currency: baseCurrency)}'
              : null,
        ),
    ];
  }

  /// A rubber stamp, tilted, in one ink: what the transaction did.
  Widget _stamp(BuildContext context, S tr, ReceiptEnvelope? env) {
    final tx = entry.tx;
    String? top;
    String? bottom;
    Color ink = AppColors.ts(context);
    if (tx.status == 'upcoming') {
      top = tr.txStampNotPaid;
    } else if (tx.status == 'skipped') {
      top = tr.txStampSkipped;
    } else if (tx.type == 'transfer') {
      top = tr.txStampEnvelopesSame;
    } else if (tx.type == 'income') {
      top = tr.allocReadyToAssign;
      ink = AppColors.healthy;
    } else if (env != null) {
      final over = env.balance < -0.005;
      top = env.name;
      bottom = over
          ? tr.quickOverBy(formatAmount(-env.balance, currency: env.currency))
          : tr.quickLeft(formatAmount(env.balance, currency: env.currency));
      ink = over
          ? (AppColors.isDark
              ? AppColors.lightenPastel(AppColors.overspent, 0.35)
              : AppColors.overspent)
          : AppColors.accentText(context);
    }
    if (top == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Center(
        child: Transform.rotate(
          angle: -0.08,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: ink.withValues(alpha: 0.85), width: 2.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(top.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w900,
                        color: ink)),
                if (bottom != null)
                  Text(bottom.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w800,
                          color: ink,
                          fontFeatures: _tabular)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A dashed rule between the receipt's parts.
class _Dashes extends StatelessWidget {
  final Color color;
  const _Dashes({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: CustomPaint(
        size: const Size(double.infinity, 2),
        painter: _DashPainter(color),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  _DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 6.0, gap = 5.0;
    for (var x = 1.0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, 1), Offset((x + dash).clamp(0, size.width), 1),
          paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// Torn-paper bottom edge.
class _TornEdge extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const tooth = 12.0, depth = 8.0;
    final n = (size.width / tooth).ceil();
    final w = size.width / n;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - depth);
    for (var i = n; i > 0; i--) {
      path
        ..lineTo(w * i - w / 2, size.height)
        ..lineTo(w * (i - 1), size.height - depth);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_TornEdge old) => false;
}
