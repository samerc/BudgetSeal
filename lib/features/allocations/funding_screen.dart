import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/allocations_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/currency_display.dart';
import '../../shared/widgets/error_retry.dart';

class FundingScreen extends ConsumerStatefulWidget {
  const FundingScreen({super.key});

  @override
  ConsumerState<FundingScreen> createState() => _FundingScreenState();
}

class _FundingScreenState extends ConsumerState<FundingScreen> {
  final Map<String, double> _amounts = {};
  bool _isFunding = false;
  bool _instructionsExpanded = false;

  double _parsedAmount(String allocationId) {
    return _amounts[allocationId] ?? 0.0;
  }

  /// Returns total distributed amounts grouped by currency.
  Map<String, double> _totalDistributedByCurrency(
      List<AllocationWithBalance> allocations, String baseCurrency) {
    final totals = <String, double>{};
    for (final a in allocations) {
      final amount = _parsedAmount(a.data.allocation.id);
      if (amount <= 0) continue;
      final currency = a.data.allocation.targetCurrency ?? baseCurrency;
      totals[currency] = (totals[currency] ?? 0.0) + amount;
    }
    return totals;
  }

  /// Auto-fill periodic allocations that have a target: fill up to (target - balance).
  void _quickFill(List<AllocationWithBalance> allocations, String baseCurrency) {
    for (final a in allocations) {
      final alloc = a.data.allocation;
      if (alloc.periodicity == 'periodic' && alloc.targetAmount != null) {
        final currency = alloc.targetCurrency ?? baseCurrency;
        final currentBalance = a.balanceByCurrency[currency] ?? 0.0;
        final gap = (alloc.targetAmount! - currentBalance).clamp(0.0, double.infinity);
        if (gap > 0) {
          _amounts[alloc.id] = gap;
        }
      }
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
        exceedDetails = '${formatAmount(deficit, currency: entry.key)} '
            'more than available in ${entry.key}';
        break;
      }
    }

    if (willExceed && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Over-funding'),
          content: Text(
            'You\'re assigning $exceedDetails. '
            'Your unallocated balance will go negative.\n\n'
            'Continue anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Fund Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    final engine = ref.read(allocationEngineProvider);
    setState(() => _isFunding = true);

    try {
      for (final a in allocations) {
        final amount = _parsedAmount(a.data.allocation.id);
        if (amount <= 0) continue;
        final currency = a.data.allocation.targetCurrency ?? baseCurrency;
        await engine.fundAllocation(
          allocationId: a.data.allocation.id,
          amount: amount,
          currency: currency,
          deviceId: 'local',
          note: 'Funded from Unallocated',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Allocations funded successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Invalidate to refresh data
        ref.invalidate(allocationsProvider);
        ref.invalidate(unallocatedProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error funding allocations: $e'),
            backgroundColor: AppColors.overspent,
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
        title: const Text('Fund Envelopes'),
      ),
      body: allocationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          message: "Couldn't load envelopes",
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
          final fillableCount = allocations.where((a) {
            final alloc = a.data.allocation;
            if (alloc.periodicity != 'periodic' ||
                alloc.targetAmount == null) {
              return false;
            }
            final currency = alloc.targetCurrency ?? baseCurrency;
            final bal = a.balanceByCurrency[currency] ?? 0.0;
            return alloc.targetAmount! - bal > 0;
          }).length;

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
                    ? Center(
                        child: Text(
                          'No allocations to fund.\nCreate allocations first.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.ts(context)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        // +1 for the quick-fill tile at the top
                        itemCount: allocations.length + 1,
                        itemBuilder: (context, i) {
                          // First item: Quick Fill tile
                          if (i == 0) {
                            return _QuickFillTile(
                              fillableCount: fillableCount,
                              onQuickFill: () =>
                                  _quickFill(allocations, baseCurrency),
                            );
                          }

                          final idx = i - 1;
                          final a = allocations[idx];
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
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: expanded
                ? const BorderRadius.vertical(top: Radius.circular(14))
                : BorderRadius.circular(CardTokens.radius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.help_outline_rounded,
                      size: 18, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'How does funding work?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tp(context),
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
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
                    text:
                        'Check your unallocated balance \u2014 this is money you haven\'t assigned to any envelope yet.',
                  ),
                  const SizedBox(height: 8),
                  _InstructionStep(
                    number: '2',
                    text:
                        'Enter how much to put in each envelope, or use "Quick Fill" to auto-fill periodic envelopes up to their target.',
                  ),
                  const SizedBox(height: 8),
                  _InstructionStep(
                    number: '3',
                    text:
                        'Tap "Fund All" to move the money into your envelopes.',
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
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: exceeds
              ? [AppColors.overspent, const Color(0xFFD32F2F)]
              : [AppColors.primary, const Color(0xFF2A3F6A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (exceeds ? AppColors.overspent : AppColors.primary)
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Available to distribute',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  CurrencyDisplay(
                    amount: available,
                    currency: baseCurrency,
                    amountStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (unallocated.length > 1)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: unallocated.entries
                      .where((e) => e.key != baseCurrency)
                      .map((e) => Text(
                            formatAmount(e.value, currency: e.key),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ))
                      .toList(),
                ),
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
                      'Distributing ${formatAmount(baseDistributed, currency: baseCurrency)}'
                      ' of ${formatAmount(available, currency: baseCurrency)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (available > 0)
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  color: exceeds
                      ? const Color(0xFFFFCDD2)
                      : const Color(0xFFA5D6A7),
                ),
              ),
              // Show per-currency distribution for non-base currencies
              for (final entry in otherDistributed)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${entry.key}: ${formatAmount(entry.value, currency: entry.key)}'
                        ' of ${formatAmount(unallocated[entry.key] ?? 0, currency: entry.key)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if ((unallocated[entry.key] ?? 0) > 0)
                        Text(
                          '${((entry.value / (unallocated[entry.key] ?? 1)) * 100).clamp(0, 999).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white70,
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
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFFFCDD2), size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Total exceeds available unallocated funds',
                    style: TextStyle(color: Color(0xFFFFCDD2), fontSize: 12),
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
        color: AppColors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(CardTokens.radius),
        child: InkWell(
          onTap: hasEnvelopes ? onQuickFill : null,
          borderRadius: BorderRadius.circular(CardTokens.radius),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_fix_high_rounded,
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
                        'Quick Fill',
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
                            ? 'Auto-fill $fillableCount periodic ${fillableCount == 1 ? 'envelope' : 'envelopes'} up to ${fillableCount == 1 ? 'its' : 'their'} target'
                            : 'All periodic envelopes are at their target',
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
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.accent.withValues(alpha: 0.6),
                  ),
              ],
            ),
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
  final bool isFunded;
  final double amount;
  final ValueChanged<double> onAmountChanged;

  const _FundingAllocationTile({
    required this.name,
    required this.currentBalance,
    required this.currency,
    required this.targetAmount,
    required this.suggestedAmount,
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
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                      color: AppColors.healthy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 13, color: AppColors.healthy),
                        SizedBox(width: 4),
                        Text(
                          'Funded',
                          style: TextStyle(
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
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: targetProgress,
                  minHeight: 5,
                  backgroundColor: AppColors.bd(context),
                  color: isFunded
                      ? AppColors.healthy
                      : AppColors.accent,
                ),
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
                'Balance: ${formatAmount(currentBalance, currency: currency)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.ts(context),
                ),
              ),
            ],

            // Row 3: currency label + input + fill button (hidden when fully funded)
            if (!isFunded) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  // Currency label (read-only, determined by envelope)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.sfv(context),
                      borderRadius: BorderRadius.circular(10),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CalculatorAmountField(
                        value: amount,
                        onChanged: onAmountChanged,
                        hintText: 'Amount',
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
                        backgroundColor:
                            AppColors.accent.withValues(alpha: 0.1),
                        foregroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(0, 0),
                      ),
                      child: Text(
                        'Fill ${formatAmount(suggestedAmount!, currency: currency)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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

  String _fundLabel() {
    if (!hasAnyAmount) return 'Enter amounts to fund';
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
    return 'Fund All  (${parts.join(' + ')})';
  }

  @override
  Widget build(BuildContext context) {
    final canFund = hasAnyAmount && !isFunding;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: canFund ? onFund : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              disabledBackgroundColor: AppColors.sfv(context),
              disabledForegroundColor: AppColors.th(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CardTokens.radius),
              ),
              elevation: canFund ? 2 : 0,
              shadowColor: AppColors.accent.withValues(alpha: 0.4),
            ),
            child: isFunding
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded,
                          size: 20),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _fundLabel(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
