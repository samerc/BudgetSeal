import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/daos/ledger_dao.dart';
import '../../core/engine/period_engine.dart' show budgetPeriodFor;
import '../../core/engine/spending_average.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/sinking_fund_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../shared/widgets/section_header.dart';
import 'sinking_fund_widgets.dart' show fundStatusLine;
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/budget_progress.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/haptics.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/currency_display.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/bottom_action_bar.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/tappable.dart';

class FundingScreen extends ConsumerStatefulWidget {
  const FundingScreen({super.key});

  @override
  ConsumerState<FundingScreen> createState() => _FundingScreenState();
}

class _FundingScreenState extends ConsumerState<FundingScreen> {
  final Map<String, double> _amounts = {};
  /// Sinking funds: one amount per currency (fund → currency → amount).
  final Map<String, Map<String, double>> _fundAmounts = {};
  bool _isFunding = false;
  bool _instructionsExpanded = false;

  /// Last budget period, per envelope and currency (for the presets).
  Map<String, Map<String, double>> _lastFunded = const {};
  Map<String, Map<String, double>> _lastSpent = const {};
  /// Average spending per period over the last [_avgPeriods] (from the
  /// first of them with any spending), rounded up to whole units.
  Map<String, Map<String, double>> _avgSpent = const {};
  static const _avgPeriods = 3;

  @override
  void initState() {
    super.initState();
    _loadLastPeriod();
  }

  Future<void> _loadLastPeriod() async {
    try {
      final household = ref.read(householdProvider).value;
      if (household == null) return;
      final current = budgetPeriodFor(household.periodStartDay);
      final last = budgetPeriodFor(household.periodStartDay,
          current.start.subtract(const Duration(days: 1)));
      final dao = LedgerDao(ref.read(databaseProvider));
      final funded =
          await dao.fundedInPeriod(household.id, last.start, last.end);
      final spent = await dao
          .watchSpendingInPeriod(household.id, last.start, last.end)
          .first;
      final avg = await recentAverageSpending(
          dao, household.id, household.periodStartDay,
          periods: _avgPeriods);
      if (mounted) {
        setState(() {
          _lastFunded = funded;
          _lastSpent = spent;
          _avgSpent = avg;
        });
      }
    } catch (e) {
      debugPrint('[Funding] Error loading last period: $e');
    }
  }

  /// Presets: fill each envelope from [source] (allocation → currency →
  /// amount), in the envelope's own currency.
  void _applyPreset(List<AllocationWithBalance> allocations,
      String baseCurrency, Map<String, Map<String, double>> source) {
    hapticSelection();
    setState(() {
      for (final a in allocations) {
        final alloc = a.data.allocation;
        if (alloc.type == 'sinking') continue;
        final currency = alloc.targetCurrency ?? baseCurrency;
        final v = source[alloc.id]?[currency] ?? 0;
        if (v > 0) {
          _amounts[alloc.id] = double.parse(v.toStringAsFixed(2));
        } else {
          _amounts.remove(alloc.id);
        }
      }
    });
  }

  double _parsedAmount(String allocationId) {
    return _amounts[allocationId] ?? 0.0;
  }

  /// Returns total distributed amounts grouped by currency.
  Map<String, double> _totalDistributedByCurrency(
      List<AllocationWithBalance> allocations, String baseCurrency) {
    final totals = <String, double>{};
    for (final m in _fundAmounts.values) {
      m.forEach((c, v) {
        if (v > 0) totals[c] = (totals[c] ?? 0) + v;
      });
    }
    for (final a in allocations) {
      if (a.data.allocation.type == 'sinking') continue;
      final amount = _parsedAmount(a.data.allocation.id);
      if (amount <= 0) continue;
      final currency = a.data.allocation.targetCurrency ?? baseCurrency;
      totals[currency] = (totals[currency] ?? 0.0) + amount;
    }
    return totals;
  }

  /// Auto-fill periodic allocations that have a target: fill up to (target - balance).
  /// Then each sinking fund's share for this period, soonest due first, out
  /// of what the spending envelopes leave (spending comes first when money
  /// is short).
  void _quickFill(List<AllocationWithBalance> allocations, String baseCurrency) {
    for (final a in allocations) {
      final alloc = a.data.allocation;
      if (alloc.type == 'sinking') continue;
      if (alloc.periodicity == 'periodic' && alloc.targetAmount != null) {
        final currency = alloc.targetCurrency ?? baseCurrency;
        final currentBalance = a.balanceByCurrency[currency] ?? 0.0;
        final gap = (alloc.targetAmount! - currentBalance).clamp(0.0, double.infinity);
        if (gap > 0) {
          _amounts[alloc.id] = gap;
        }
      }
    }
    final left = Map.of(ref.read(unallocatedProvider).value ?? {});
    for (final a in allocations) {
      final alloc = a.data.allocation;
      if (alloc.type == 'sinking') continue;
      final amount = _amounts[alloc.id] ?? 0;
      if (amount <= 0) continue;
      final c = alloc.targetCurrency ?? baseCurrency;
      left[c] = (left[c] ?? 0) - amount;
    }
    final funds = (ref.read(sinkingFundsProvider).value ?? const {})
        .values
        .toList()
      ..sort((a, b) => (a.plan.next?.date ?? DateTime(9999))
          .compareTo(b.plan.next?.date ?? DateTime(9999)));
    _fundAmounts.clear();
    for (final f in funds) {
      final fill = <String, double>{};
      f.thisPeriod.forEach((c, v) {
        final room = left[c] ?? 0;
        final put = v < room ? v : room;
        if (put > 0.005) {
          fill[c] = put;
          left[c] = room - put;
        }
      });
      if (fill.isNotEmpty) _fundAmounts[f.allocation.id] = fill;
    }
    setState(() {});
  }

  Future<void> _fundAll(
    List<AllocationWithBalance> allocations,
    String baseCurrency,
  ) async {
    // Check if funding exceeds unallocated — warn but allow
    final unallocated = ref.read(unallocatedProvider).value ?? {};
    final distributed = _totalDistributedByCurrency(allocations, baseCurrency);
    bool willExceed = false;
    String? exceedDetails;
    for (final entry in distributed.entries) {
      final available = unallocated[entry.key] ?? 0.0;
      if (entry.value > available + 0.01) {
        willExceed = true;
        final deficit = entry.value - available;
        exceedDetails = S.of(context).fundMoreThanAvailable(
            formatAmount(deficit, currency: entry.key), entry.key);
        break;
      }
    }

    if (willExceed && mounted) {
      final tr = S.of(context);
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(tr.fundOverfundingTitle),
          content: Text(
            tr.fundOverfundingMsg(exceedDetails!),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr.commonCancel),
            ),
            FilledButton(
              style: DialogButtons.filled,
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr.fundAnyway),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    final engine = ref.read(allocationEngineProvider);
    // Capture before the await loop — reading S.of(context) after the first
    // fundAllocation await would use a possibly-disposed context.
    final fundNote = S.of(context).fundNote;
    setState(() => _isFunding = true);

    try {
      // All or nothing: a failure halfway must not leave some envelopes
      // funded and the rest not.
      await ref.read(databaseProvider).transaction(() async {
        for (final f in _fundAmounts.entries) {
          for (final e in f.value.entries) {
            if (e.value <= 0) continue;
            await engine.fundAllocation(
              allocationId: f.key,
              amount: e.value,
              currency: e.key,
              deviceId: 'local',
              note: fundNote,
            );
          }
        }
        for (final a in allocations) {
          if (a.data.allocation.type == 'sinking') continue;
          final amount = _parsedAmount(a.data.allocation.id);
          if (amount <= 0) continue;
          final currency = a.data.allocation.targetCurrency ?? baseCurrency;
          await engine.fundAllocation(
            allocationId: a.data.allocation.id,
            amount: amount,
            currency: currency,
            deviceId: 'local',
            note: fundNote,
          );
        }
      });

      if (mounted) {
        hapticMedium();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).fundSuccess),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Invalidate to refresh data
        ref.invalidate(allocationsProvider);
        ref.invalidate(unallocatedProvider);
        context.pop();
      }
    } catch (e) {
      debugPrint('[Funding] Fund failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).fundFailed),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFunding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allocationsAsync = ref.watch(allocationsProvider);
    final unallocatedAsync = ref.watch(unallocatedProvider);
    final household = ref.watch(householdProvider).value;
    final baseCurrency = household?.baseCurrency ?? 'USD';

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).fundTitle),
      ),
      body: allocationsAsync.when(
        loading: () => const SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: 8),
              child: SkeletonList()),
        error: (e, _) => ErrorRetry(
          message: S.of(context).fundCouldntLoad,
          details: '$e',
          onRetry: () => ref.invalidate(allocationsProvider),
        ),
        data: (allocations) {
          final distributedByCurrency =
              _totalDistributedByCurrency(allocations, baseCurrency);
          final unallocated = unallocatedAsync.value ?? {};

          // Check if ANY currency exceeds its available unallocated amount
          bool exceeds = false;
          for (final entry in distributedByCurrency.entries) {
            final availableForCurrency = unallocated[entry.key] ?? 0.0;
            if (entry.value > availableForCurrency + 0.005) {
              exceeds = true;
              break;
            }
          }
          final available = unallocated[baseCurrency] ?? 0.0;

          // Count how many periodic envelopes have unfilled targets.
          final funds = ref.watch(sinkingFundsProvider).value ?? const {};
          final fillableCount = funds.values
                  .where((f) => f.thisPeriod.isNotEmpty)
                  .length +
              allocations.where((a) {
            final alloc = a.data.allocation;
            if (alloc.type == 'sinking') return false;
            if (alloc.periodicity != 'periodic' ||
                alloc.targetAmount == null) {
              return false;
            }
            final currency = alloc.targetCurrency ?? baseCurrency;
            final bal = a.balanceByCurrency[currency] ?? 0.0;
            return alloc.targetAmount! - bal > 0;
          }).length;

          final envelopes = [
            for (final a in allocations)
              if (a.data.allocation.type != 'sinking' ||
                  !funds.containsKey(a.data.allocation.id))
                a,
          ];
          final fundList = [
            for (final a in allocations)
              if (funds[a.data.allocation.id] case final f?) f,
          ];

          return Column(
            children: [
              // -- Collapsible instructions --
              _InstructionsPanel(
                expanded: _instructionsExpanded,
                onToggle: () => setState(
                    () => _instructionsExpanded = !_instructionsExpanded),
              ),

              // -- Funding banner with progress --
              _FundingBanner(
                available: available,
                distributedByCurrency: distributedByCurrency,
                baseCurrency: baseCurrency,
                unallocated: unallocated,
                exceeds: exceeds,
              ),

              // -- Allocation list --
              Expanded(
                child: allocations.isEmpty
                    ? EmptyState(
                        icon: AppIcons.envelopeSimple,
                        title: S.of(context).fundNoAllocations,
                        subtitle: S.of(context).allocCreateHelp,
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(allocationsProvider);
                          ref.invalidate(unallocatedProvider);
                          await Future.delayed(
                              const Duration(milliseconds: 300));
                        },
                        child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        // +1 for the quick-fill tile at the top; sinking
                        // funds after the envelopes, under their header.
                        itemCount: envelopes.length +
                            1 +
                            (fundList.isEmpty ? 0 : fundList.length + 1),
                        itemBuilder: (context, i) {
                          if (i > envelopes.length) {
                            final j = i - envelopes.length - 1;
                            if (j == 0) {
                              return Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    top: 10, bottom: 8, start: 4),
                                child: SectionHeader(
                                    S.of(context).sinkSection),
                              );
                            }
                            final f = fundList[j - 1];
                            return _SinkingFundingTile(
                              fund: f,
                              baseCurrency: baseCurrency,
                              amounts: _fundAmounts[f.allocation.id] ??
                                  const {},
                              onChanged: (c, v) => setState(() {
                                final m = _fundAmounts.putIfAbsent(
                                    f.allocation.id, () => {});
                                if (v > 0) {
                                  m[c] = v;
                                } else {
                                  m.remove(c);
                                }
                              }),
                            );
                          }
                          // First item: Quick Fill tile
                          if (i == 0) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _QuickFillTile(
                                  fillableCount: fillableCount,
                                  onQuickFill: () =>
                                      _quickFill(allocations, baseCurrency),
                                ),
                                // More presets, one tap each.
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (_lastFunded.isNotEmpty)
                                        ActionChip(
                                          avatar: const Icon(
                                              AppIcons.arrowCounterClockwise,
                                              size: 16),
                                          label: Text(S
                                              .of(context)
                                              .fundPresetLastPeriod),
                                          onPressed: () => _applyPreset(
                                              allocations,
                                              baseCurrency,
                                              _lastFunded),
                                        ),
                                      if (_lastSpent.isNotEmpty)
                                        ActionChip(
                                          avatar: const Icon(
                                              AppIcons.receipt,
                                              size: 16),
                                          label: Text(
                                              S.of(context).fundPresetSpent),
                                          onPressed: () => _applyPreset(
                                              allocations,
                                              baseCurrency,
                                              _lastSpent),
                                        ),
                                      if (_avgSpent.isNotEmpty)
                                        ActionChip(
                                          avatar: const Icon(
                                              AppIcons.chartBar,
                                              size: 16),
                                          label: Text(
                                              S.of(context).fundPresetAverage),
                                          onPressed: () => _applyPreset(
                                              allocations,
                                              baseCurrency,
                                              _avgSpent),
                                        ),
                                      if (_amounts.isNotEmpty ||
                                          _fundAmounts.isNotEmpty)
                                        ActionChip(
                                          avatar: const Icon(
                                              AppIcons.x,
                                              size: 16),
                                          label: Text(
                                              S.of(context).fundPresetClear),
                                          onPressed: () => setState(() {
                                            _amounts.clear();
                                            _fundAmounts.clear();
                                          }),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }

                          final idx = i - 1;
                          final a = envelopes[idx];
                          final alloc = a.data.allocation;
                          final currency =
                              alloc.targetCurrency ?? baseCurrency;
                          final currentBalance =
                              a.balanceByCurrency[currency] ?? 0.0;

                          // Compute suggested fill-up if target exists
                          double? suggestedAmount;
                          bool isFunded = false;
                          if (alloc.targetAmount != null) {
                            final gap = alloc.targetAmount! - currentBalance;
                            if (gap > 0) {
                              suggestedAmount = gap;
                            } else {
                              isFunded = true;
                            }
                          }

                          return _FundingAllocationTile(
                            name: alloc.name,
                            currentBalance: currentBalance,
                            currency: currency,
                            targetAmount: alloc.targetAmount,
                            suggestedAmount: suggestedAmount,
                            usualSpend: _avgSpent[alloc.id]?[currency],
                            isFunded: isFunded,
                            amount: _amounts[alloc.id] ?? 0.0,
                            onAmountChanged: (value) {
                              setState(() {
                                _amounts[alloc.id] = value;
                              });
                            },
                          );
                        },
                      ),
                      ),
              ),

              // -- Bottom action bar --
              _BottomFundBar(
                distributedByCurrency: distributedByCurrency,
                baseCurrency: baseCurrency,
                exceeds: exceeds,
                isFunding: _isFunding,
                hasAnyAmount: distributedByCurrency.isNotEmpty,
                onFund: () => _fundAll(allocations, baseCurrency),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Collapsible instructions panel
// ---------------------------------------------------------------------------

class _InstructionsPanel extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;

  const _InstructionsPanel({
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.sfv(context),
        borderRadius: CardTokens.borderRadius,
      ),
      child: Column(
        children: [
          Tappable(
            onTap: onToggle,
            borderRadius: expanded
                ? const BorderRadius.vertical(
                    top: Radius.circular(CardTokens.radius))
                : CardTokens.borderRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(AppIcons.question,
                      size: 18, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      S.of(context).fundHowTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tp(context),
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? AppIcons.caretUp
                        : AppIcons.caretDown,
                    size: 20,
                    color: AppColors.ts(context),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(height: 1, color: AppColors.bd(context)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                children: [
                  _InstructionStep(
                    number: '1',
                    text: S.of(context).fundStep1,
                  ),
                  const SizedBox(height: 8),
                  _InstructionStep(
                    number: '2',
                    text: S.of(context).fundStep2,
                  ),
                  const SizedBox(height: 8),
                  _InstructionStep(
                    number: '3',
                    text: S.of(context).fundStep3,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.pastel(context, AppColors.accent,
                light: 0.85, dark: 0.78),
            borderRadius: BorderRadius.circular(RadiusTokens.sm),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.ts(context),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Funding Banner (simplified — removed duplicate distributing/remaining box)
// ---------------------------------------------------------------------------

class _FundingBanner extends StatelessWidget {
  final double available;
  final Map<String, double> distributedByCurrency;
  final String baseCurrency;
  final Map<String, double> unallocated;
  final bool exceeds;

  const _FundingBanner({
    required this.available,
    required this.distributedByCurrency,
    required this.baseCurrency,
    required this.unallocated,
    required this.exceeds,
  });

  @override
  Widget build(BuildContext context) {
    final baseDistributed = distributedByCurrency[baseCurrency] ?? 0.0;
    final progress = available > 0
        ? (baseDistributed / available).clamp(0.0, 1.0)
        : 0.0;

    // Collect non-base currencies being distributed
    final otherDistributed = distributedByCurrency.entries
        .where((e) => e.key != baseCurrency && e.value > 0)
        .toList();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      // Cashew-style pastel card (red-tinted when over-allocating).
      decoration: BoxDecoration(
        color: AppColors.pastel(
            context, exceeds ? AppColors.overspent : AppColors.accent,
            light: 0.82, dark: 0.75),
        borderRadius: BorderRadius.circular(RadiusTokens.hero),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
               child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.of(context).fundAvailableToDistribute,
                      style: TextStyle(color: AppColors.ts(context), fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  // Large amounts shrink to one line instead of wrapping.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: CurrencyDisplay(
                      amount: available,
                      currency: baseCurrency,
                      amountStyle: TextStyle(
                        color: AppColors.tp(context),
                        fontSize: 26,
                        fontFamily: TypographyTokens.displayFamily,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
               ),
              ),
              // Other currencies (LBP 47,500,000…) shrink rather than push
              // the row past the card.
              if (unallocated.length > 1) ...[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: unallocated.entries
                        .where((e) => e.key != baseCurrency)
                        .map((e) => FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerEnd,
                              child: Text(
                                formatAmount(e.value, currency: e.key),
                                maxLines: 1,
                                style: TextStyle(
                                    color: AppColors.ts(context),
                                    fontSize: 12),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Progress indicator (base currency)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      S.of(context).fundDistributing(
                        formatAmount(baseDistributed, currency: baseCurrency),
                        formatAmount(available, currency: baseCurrency),
                      ),
                      style: TextStyle(
                        color: AppColors.ts(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (available > 0)
                    Text(
                      '${formatNumber(progress * 100, decimals: 0)}%',
                      style: TextStyle(
                        color: AppColors.ts(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              BudgetProgress(
                progress: progress,
                color: AppColors.accent,
                height: 12,
                overspent: exceeds,
              ),
              // Show per-currency distribution for non-base currencies
              for (final entry in otherDistributed)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            S.of(context).fundAmountOfAvailable(
                                entry.key,
                                formatAmount(entry.value, currency: entry.key),
                                formatAmount(unallocated[entry.key] ?? 0,
                                    currency: entry.key)),
                            maxLines: 1,
                            style: TextStyle(
                              color: AppColors.ts(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if ((unallocated[entry.key] ?? 0) > 0)
                        Text(
                          '${formatNumber(((entry.value / (unallocated[entry.key] ?? 1)) * 100).clamp(0, 999).toDouble(), decimals: 0)}%',
                          style: TextStyle(
                            color: AppColors.ts(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),

          if (exceeds) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(AppIcons.warning,
                    color: AppColors.overspent, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    S.of(context).fundExceedsWarning,
                    style: const TextStyle(color: AppColors.overspent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Fill tile (replaces the AppBar button)
// ---------------------------------------------------------------------------

class _QuickFillTile extends StatelessWidget {
  final int fillableCount;
  final VoidCallback onQuickFill;

  const _QuickFillTile({
    required this.fillableCount,
    required this.onQuickFill,
  });

  @override
  Widget build(BuildContext context) {
    final hasEnvelopes = fillableCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.pastel(context, AppColors.accent,
            light: 0.88, dark: 0.8),
        borderRadius: CardTokens.borderRadius,
      ),
      child: Tappable(
          onTap: hasEnvelopes ? onQuickFill : null,
          borderRadius: CardTokens.borderRadius,
          child: Padding(
            padding: CardTokens.padding,
            child: Row(
              children: [
                Container(
                  width: CategoryIconTokens.compactSize,
                  height: CategoryIconTokens.compactSize,
                  decoration: BoxDecoration(
                    color: AppColors.pastel(context, AppColors.accent,
                        light: 0.78, dark: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppIcons.magicWand,
                    size: 18,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context).fundQuickFill,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: hasEnvelopes
                              ? AppColors.accent
                              : AppColors.ts(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasEnvelopes
                            ? S.of(context).fundQuickFillDesc(fillableCount)
                            : S.of(context).fundAllAtTarget,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.ts(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasEnvelopes)
                  Icon(
                    AppIcons.caretRight,
                    size: 14,
                    color: AppColors.accent,
                  ),
              ],
            ),
          ),
        ),
    );
  }
}

// ---------------------------------------------------------------------------
// Allocation Funding Tile (redesigned — clean, minimal)
// ---------------------------------------------------------------------------

class _FundingAllocationTile extends StatelessWidget {
  final String name;
  final double currentBalance;
  final String currency;
  final double? targetAmount;
  final double? suggestedAmount;
  /// Average spending per period lately (null = none).
  final double? usualSpend;
  final bool isFunded;
  final double amount;
  final ValueChanged<double> onAmountChanged;

  const _FundingAllocationTile({
    required this.name,
    required this.currentBalance,
    required this.currency,
    required this.targetAmount,
    required this.suggestedAmount,
    this.usualSpend,
    this.isFunded = false,
    required this.amount,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasTarget = targetAmount != null && targetAmount! > 0;
    final targetProgress = hasTarget
        ? (currentBalance / targetAmount!).clamp(0.0, 1.0)
        : null;
    final hasSuggestion = suggestedAmount != null && suggestedAmount! > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppColors.card(context),
      child: Padding(
        padding: CardTokens.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: name + target or funded badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tp(context),
                    ),
                  ),
                ),
                if (isFunded)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.pastel(context, AppColors.healthy,
                          light: 0.85, dark: 0.78),
                      borderRadius: BorderRadius.circular(RadiusTokens.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(AppIcons.checkCircleFill,
                            size: 13, color: AppColors.healthy),
                        const SizedBox(width: 4),
                        Text(
                          S.of(context).fundFunded,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.healthy,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (hasTarget)
                  Text(
                    formatAmount(targetAmount!, currency: currency),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ts(context),
                    ),
                  ),
              ],
            ),

            // Row 2: progress bar + balance/target text
            if (hasTarget && targetProgress != null) ...[
              const SizedBox(height: 8),
              BudgetProgress(
                progress: targetProgress,
                height: 6,
                color: isFunded ? AppColors.healthy : AppColors.accent,
              ),
              const SizedBox(height: 4),
              Text(
                '${formatAmount(currentBalance, currency: currency)} / ${formatAmount(targetAmount!, currency: currency)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.ts(context),
                ),
              ),
            ] else ...[
              // No target — just show current balance
              const SizedBox(height: 4),
              Text(
                S.of(context).fundBalance(formatAmount(currentBalance, currency: currency)),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.ts(context),
                ),
              ),
            ],

            if (usualSpend != null && usualSpend! > 0) ...[
              const SizedBox(height: 6),
              Tappable(
                onTap: () => onAmountChanged(usualSpend!),
                borderRadius: BorderRadius.circular(RadiusTokens.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.chartBar,
                          size: 14, color: AppColors.accentText(context)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          S.of(context).fundUsually(
                              formatAmount(usualSpend!, currency: currency)),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentText(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Row 3: currency label + input + fill button — kept on funded
            // envelopes too, so extra money can still go in.
            ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  // Currency label (read-only, determined by envelope)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.sfv(context),
                      borderRadius: BorderRadius.circular(RadiusTokens.md),
                    ),
                    child: Text(
                      currency,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ts(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.sfv(context),
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                      ),
                      child: CalculatorAmountField(
                        value: amount,
                        onChanged: onAmountChanged,
                        hintText: S.of(context).commonAmount,
                        fontSize: 16,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tp(context),
                        ),
                      ),
                    ),
                  ),
                  if (hasSuggestion) ...[
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: () => onAmountChanged(suggestedAmount!),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        minimumSize: const Size(0, 44),
                      ),
                      child: Text(
                        S.of(context).fundFill(formatAmount(suggestedAmount!, currency: currency)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Fund Bar
// ---------------------------------------------------------------------------

class _BottomFundBar extends StatelessWidget {
  final Map<String, double> distributedByCurrency;
  final String baseCurrency;
  final bool exceeds;
  final bool isFunding;
  final bool hasAnyAmount;
  final VoidCallback onFund;

  const _BottomFundBar({
    required this.distributedByCurrency,
    required this.baseCurrency,
    required this.exceeds,
    required this.isFunding,
    required this.hasAnyAmount,
    required this.onFund,
  });

  String _fundLabel(BuildContext context) {
    final l = S.of(context);
    if (!hasAnyAmount) return l.fundEnterAmounts;
    // Build a label like "Fund All  ($500 + LBP 100,000)"
    final parts = <String>[];
    // Base currency first
    final baseAmount = distributedByCurrency[baseCurrency];
    if (baseAmount != null && baseAmount > 0) {
      parts.add(formatAmount(baseAmount, currency: baseCurrency));
    }
    // Other currencies
    for (final entry in distributedByCurrency.entries) {
      if (entry.key == baseCurrency || entry.value <= 0) continue;
      parts.add(formatAmount(entry.value, currency: entry.key));
    }
    return l.fundAllWithTotal(parts.join(' + '));
  }

  @override
  Widget build(BuildContext context) {
    final canFund = hasAnyAmount && !isFunding;

    return BottomActionBar(
      children: [
        FilledButton(
          onPressed: canFund ? onFund : null,
          child: isFunding
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.onAccent,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(AppIcons.wallet, size: 20),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _fundLabel(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sinking fund tile: one amount per currency, with this month's share
// ---------------------------------------------------------------------------

class _SinkingFundingTile extends StatelessWidget {
  final SinkingFund fund;
  final String baseCurrency;
  final Map<String, double> amounts;
  final void Function(String currency, double amount) onChanged;

  const _SinkingFundingTile({
    required this.fund,
    required this.baseCurrency,
    required this.amounts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final next = fund.plan.next;
    final share = fund.thisPeriod;
    final currencies = {...share.keys, ...amounts.keys, ...?next?.amounts.keys}
        .toList()
      ..sort((a, b) => a == baseCurrency
          ? -1
          : b == baseCurrency
              ? 1
              : a.compareTo(b));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppColors.card(context),
      padding: CardTokens.padding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(fund.allocation.name,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tp(context))),
          ),
          if (next != null)
            Text(formatDate(next.date),
                style: TextStyle(fontSize: 12, color: AppColors.ts(context))),
        ]),
        const SizedBox(height: 2),
        Text(fundStatusLine(tr, fund, baseCurrency),
            style: TextStyle(
                fontSize: 12,
                color: fund.plan.isBehind
                    ? AppColors.caution
                    : AppColors.ts(context))),
        for (final c in currencies) ...[
          const SizedBox(height: 10),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.sfv(context),
                borderRadius: BorderRadius.circular(RadiusTokens.md),
              ),
              child: Text(c,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ts(context))),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.sfv(context),
                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                ),
                child: CalculatorAmountField(
                  value: amounts[c] ?? 0,
                  onChanged: (v) => onChanged(c, v),
                  hintText: tr.commonAmount,
                  fontSize: 16,
                ),
              ),
            ),
            if ((share[c] ?? 0) > 0) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: FilledButton.tonal(
                onPressed: () => onChanged(c, share[c]!),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  minimumSize: const Size(0, 44),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(tr.fundFill(
                        formatAmount(share[c]!, currency: c))),
                  ),
                ),
              ),
              ),
            ],
          ]),
        ],
      ]),
    );
  }
}
