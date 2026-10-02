import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/allocations_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/haptics.dart';
import '../../shared/widgets/calculator_amount_field.dart';

/// Sentinel for "Ready to assign" (Unallocated) in the From/To pickers.
const _readyToAssign = '';

/// Move money between envelopes (or to/from Ready to assign) — also used to
/// cover an overspent envelope ([toId] + [amount] prefilled). [fromId]/[toId]
/// null = Ready to assign. Returns true when money moved.
Future<bool> showMoveMoneySheet(
  BuildContext context,
  WidgetRef ref, {
  String? fromId,
  String? toId,
  String? currency,
  double amount = 0,
  bool cover = false,
}) async {
  // Capture before the sheet (S.of inside StatefulBuilder crashes).
  final tr = S.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final allocations = ref.read(allocationsProvider).value ?? const [];
  final unallocated = ref.read(unallocatedProvider).value ?? const {};
  final cur = currency ??
      ref.read(householdProvider).value?.baseCurrency ??
      'USD';
  final names = {
    _readyToAssign: tr.allocReadyToAssign,
    for (final a in allocations) a.data.allocation.id: a.data.allocation.name,
  };
  double balanceOf(String id) => id == _readyToAssign
      ? (unallocated[cur] ?? 0)
      : (allocations
              .where((a) => a.data.allocation.id == id)
              .firstOrNull
              ?.balanceByCurrency[cur] ??
          0);

  var from = fromId ?? _readyToAssign;
  var to = toId ?? _readyToAssign;
  // Covering: Ready to assign when it has enough, else the envelope with
  // the most money to spare.
  if (cover && fromId == null && (unallocated[cur] ?? 0) < amount) {
    final spare = [...allocations]
      ..removeWhere((a) => a.data.allocation.id == toId)
      ..sort((a, b) => (b.balanceByCurrency[cur] ?? 0)
          .compareTo(a.balanceByCurrency[cur] ?? 0));
    final best = spare.firstOrNull;
    final bestBal = best?.balanceByCurrency[cur] ?? 0;
    if (best != null && bestBal >= amount) {
      from = best.data.allocation.id;
    }
  }
  var value = amount;

  final surface = AppColors.sf(context);
  final secondary = AppColors.ts(context);

  final moved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        final fromBal = balanceOf(from);
        final short = from != _readyToAssign && value > fromBal + 0.005;
        Widget picker(String label, String selected, ValueChanged<String> on,
                {required String exclude}) =>
            DropdownButtonFormField<String>(
              initialValue: selected,
              isExpanded: true,
              decoration: InputDecoration(labelText: label),
              items: [
                for (final e in names.entries)
                  if (e.key != exclude)
                    DropdownMenuItem(
                      value: e.key,
                      child: Text(
                        '${e.value} · ${formatAmount(balanceOf(e.key), currency: cur)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
              ],
              onChanged: (v) => setSheet(() => on(v ?? _readyToAssign)),
            );
        return Container(
          padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom +
                  MediaQuery.of(ctx).viewPadding.bottom +
                  20),
          decoration: BoxDecoration(
            color: surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(cover ? tr.allocCoverTitle : tr.allocMoveTitle,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(cover ? tr.allocCoverDesc : tr.allocMoveDesc,
                  style: TextStyle(fontSize: 13, color: secondary)),
              const SizedBox(height: 16),
              picker(tr.allocMoveFrom, from, (v) => from = v, exclude: to),
              const SizedBox(height: 12),
              picker(tr.allocMoveTo, to, (v) => to = v, exclude: from),
              const SizedBox(height: 16),
              CalculatorAmountField(
                value: value,
                label: tr.commonAmount,
                currency: cur,
                fontSize: 22,
                onChanged: (v) => setSheet(() => value = v),
              ),
              if (short) ...[
                const SizedBox(height: 8),
                Text(
                  tr.allocMoveNotEnough(
                      names[from] ?? '', formatAmount(fromBal, currency: cur)),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.overspent),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: value > 0 && !short && from != to
                    ? () => Navigator.pop(ctx, true)
                    : null,
                child: Text(cover ? tr.allocCoverButton : tr.allocMoveButton),
              ),
            ],
          ),
        );
      },
    ),
  );

  if (moved != true) return false;
  try {
    await ref.read(allocationEngineProvider).moveMoney(
          fromAllocationId: from == _readyToAssign ? null : from,
          toAllocationId: to == _readyToAssign ? null : to,
          amount: value,
          currency: cur,
          fromNote: tr.allocMovedTo(names[to] ?? ''),
          toNote: tr.allocMovedFrom(names[from] ?? ''),
        );
    hapticMedium();
    ref.invalidate(allocationsProvider);
    ref.invalidate(unallocatedProvider);
    messenger.showSnackBar(SnackBar(
      content: Text(tr.allocMoveDone(formatAmount(value, currency: cur),
          names[from] ?? '', names[to] ?? '')),
      behavior: SnackBarBehavior.floating,
    ));
    return true;
  } catch (e) {
    debugPrint('[MoveMoney] Failed: $e');
    messenger.showSnackBar(SnackBar(
      content: Text(tr.commonSomethingWentWrong),
      behavior: SnackBarBehavior.floating,
    ));
    return false;
  }
}
