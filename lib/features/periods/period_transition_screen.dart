import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/engine/period_engine.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/error_retry.dart';

/// Tracks the user's chosen resolution for a single allocation + currency pair.
class _AllocationResolution {
  final String allocationId;
  final String allocationName;
  final String currency;
  final double balance;
  final bool rolloverDefault;
  LeftoverResolution resolution;
  String? targetAllocationId;

  _AllocationResolution({
    required this.allocationId,
    required this.allocationName,
    required this.currency,
    required this.balance,
    required this.rolloverDefault,
  }) : resolution = rolloverDefault
            ? LeftoverResolution.keep
            : LeftoverResolution.toUnallocated;
}

class PeriodTransitionScreen extends ConsumerStatefulWidget {
  const PeriodTransitionScreen({super.key});

  @override
  ConsumerState<PeriodTransitionScreen> createState() =>
      _PeriodTransitionScreenState();
}

class _PeriodTransitionScreenState
    extends ConsumerState<PeriodTransitionScreen> {
  List<_AllocationResolution> _resolutions = [];
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _buildResolutions();
  }

  void _buildResolutions() {
    // Defer to after first frame so providers are available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final allocationsAsync = ref.read(allocationsProvider);
      allocationsAsync.whenData((allocations) {
        final items = <_AllocationResolution>[];
        for (final a in allocations) {
          // Only periodic allocations participate in period transitions.
          if (a.data.allocation.periodicity != 'periodic') continue;

          for (final entry in a.balanceByCurrency.entries) {
            if (entry.value > 0) {
              items.add(_AllocationResolution(
                allocationId: a.data.allocation.id,
                allocationName: a.data.allocation.name,
                currency: entry.key,
                balance: entry.value,
                rolloverDefault: a.data.allocation.rollover,
              ));
            }
          }
        }
        if (mounted) setState(() => _resolutions = items);
      });
    });
  }

  Future<void> _completeTransition() async {
    setState(() => _completing = true);
    try {
      final engine = ref.read(periodEngineProvider);

      for (final r in _resolutions) {
        await engine.resolveLeftover(
          allocationId: r.allocationId,
          currency: r.currency,
          leftoverAmount: r.balance,
          resolution: r.resolution,
          deviceId: 'local',
          targetAllocationId: r.targetAllocationId,
        );
      }

      ref.invalidate(allocationsProvider);
      ref.invalidate(unallocatedProvider);

      if (mounted) {
        context.pop(); // close period transition
        context.push('/funding'); // open funding as a new route
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete transition: $e'),
            backgroundColor: AppColors.overspent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final householdAsync = ref.watch(householdProvider);
    final allocationsAsync = ref.watch(allocationsProvider);
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Period'),
        automaticallyImplyLeading: true,
      ),
      body: allocationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          message: "Couldn't load envelopes",
          details: '$e',
          onRetry: () => ref.invalidate(allocationsProvider),
        ),
        data: (_) => Column(
          children: [
            // Header banner
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF2A3F6A)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'New period starting',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat.yMMMd().format(now),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    householdAsync.whenOrNull(
                          data: (h) => h != null
                              ? 'Period start day: ${_ordinal(h.periodStartDay)} of each month'
                              : '',
                        ) ??
                        '',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Subheading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Resolve leftover balances',
                    style: textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Text(
                    '${_resolutions.length} items',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Allocation list
            Expanded(
              child: _resolutions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 56,
                              color: AppColors.healthy.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No leftover balances to resolve',
                              style: textTheme.titleMedium?.copyWith(
                                color: AppColors.ts(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All periodic allocations have zero or negative balances.',
                              style: textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _resolutions.length,
                      itemBuilder: (context, i) => _ResolutionCard(
                        resolution: _resolutions[i],
                        allAllocations: ref
                                .read(allocationsProvider)
                                .value
                                ?.where((a) =>
                                    a.data.allocation.id !=
                                    _resolutions[i].allocationId)
                                .toList() ??
                            [],
                        onChanged: () => setState(() {}),
                      ),
                    ),
            ),

            // Bottom action area
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: AppColors.sf(context),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: FilledButton(
                  onPressed: _completing ? null : _completeTransition,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _completing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Complete Period Transition',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    return switch (day % 10) {
      1 => '${day}st',
      2 => '${day}nd',
      3 => '${day}rd',
      _ => '${day}th',
    };
  }
}

// ---------------------------------------------------------------------------
// Resolution card for a single allocation + currency
// ---------------------------------------------------------------------------

class _ResolutionCard extends StatelessWidget {
  final _AllocationResolution resolution;
  final List<AllocationWithBalance> allAllocations;
  final VoidCallback onChanged;

  const _ResolutionCard({
    required this.resolution,
    required this.allAllocations,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: name + balance
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resolution.allocationName,
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        resolution.rolloverDefault
                            ? 'Rollover allocation'
                            : 'Periodic allocation',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.healthyLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${resolution.balance.toStringAsFixed(2)} ${resolution.currency}',
                    style: const TextStyle(
                      color: AppColors.healthy,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Resolution options
            _RadioOption(
              icon: Icons.replay_rounded,
              label: 'Return to Unallocated',
              description: 'Balance returns to the pool',
              value: LeftoverResolution.toUnallocated,
              groupValue: resolution.resolution,
              onChanged: (v) {
                resolution.resolution = v;
                resolution.targetAllocationId = null;
                onChanged();
              },
            ),
            _RadioOption(
              icon: Icons.forward_rounded,
              label: 'Carry Forward',
              description: 'Keep balance for next period',
              value: LeftoverResolution.keep,
              groupValue: resolution.resolution,
              onChanged: (v) {
                resolution.resolution = v;
                resolution.targetAllocationId = null;
                onChanged();
              },
            ),
            _RadioOption(
              icon: Icons.swap_horiz_rounded,
              label: 'Move to...',
              description: 'Transfer to another allocation',
              value: LeftoverResolution.toOtherAllocation,
              groupValue: resolution.resolution,
              onChanged: (v) {
                resolution.resolution = v;
                onChanged();
              },
            ),

            // Target allocation picker
            if (resolution.resolution == LeftoverResolution.toOtherAllocation)
              Padding(
                padding: const EdgeInsets.only(left: 40, top: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.sfv(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Select allocation'),
                      value: resolution.targetAllocationId,
                      items: allAllocations
                          .map((a) => DropdownMenuItem(
                                value: a.data.allocation.id,
                                child: Text(a.data.allocation.name),
                              ))
                          .toList(),
                      onChanged: (id) {
                        resolution.targetAllocationId = id;
                        onChanged();
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Styled radio option row
// ---------------------------------------------------------------------------

class _RadioOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final LeftoverResolution value;
  final LeftoverResolution groupValue;
  final ValueChanged<LeftoverResolution> onChanged;

  const _RadioOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.accent : AppColors.th(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? AppColors.tp(context)
                          : AppColors.ts(context),
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.th(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? AppColors.accent : AppColors.th(context),
            ),
          ],
        ),
      ),
    );
  }
}
