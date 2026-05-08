import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../shared/utils/format_number.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/ledger_dao.dart';
import '../../core/engine/balance_calculator.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/services/auto_backup_service.dart';
import '../../shared/theme/app_colors.dart';

class HealthCheckScreen extends ConsumerStatefulWidget {
  const HealthCheckScreen({super.key});

  @override
  ConsumerState<HealthCheckScreen> createState() => _HealthCheckScreenState();
}

class _HealthCheckScreenState extends ConsumerState<HealthCheckScreen> {
  bool _running = false;
  _HealthReport? _report;

  @override
  void initState() {
    super.initState();
    _runCheck();
  }

  Future<void> _runCheck() async {
    setState(() => _running = true);
    try {
      final db = ref.read(databaseProvider);
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) {
        if (mounted) setState(() => _running = false);
        return;
      }
      final report = await _diagnose(db, householdId);
      if (mounted) setState(() { _report = report; _running = false; });
    } catch (e) {
      debugPrint('[HealthCheck] Error: $e');
      if (mounted) setState(() => _running = false);
    }
  }

  // ─── Diagnosis ──────────────────────────────────────────────────────────

  Future<_HealthReport> _diagnose(AppDatabase db, String householdId) async {
    final calc = BalanceCalculator(db);
    final ledgerDao = LedgerDao(db);

    // 1. Account balances per currency
    final accounts = await (db.select(db.accounts)
          ..where((t) => t.householdId.equals(householdId))
          ..where((t) => t.archived.equals(false)))
        .get();
    final accountBalances = await calc.allAccountBalances(householdId);

    final Map<String, double> accountTotals = {};
    final List<_AccountInfo> accountInfos = [];
    for (final acc in accounts) {
      final bal = accountBalances[acc.id] ?? 0;
      accountTotals[acc.currency] =
          (accountTotals[acc.currency] ?? 0.0) + bal;
      accountInfos.add(_AccountInfo(
        name: acc.name,
        currency: acc.currency,
        balance: bal,
      ));
    }

    // 2. Allocation balances per currency
    final allocBalances =
        await calc.allAllocationBalancesByCurrency(householdId);
    final allocs = await (db.select(db.allocations)
          ..where((t) => t.householdId.equals(householdId))
          ..where((t) => t.archived.equals(false)))
        .get();

    final Map<String, double> allocTotals = {};
    final List<_AllocationInfo> allocInfos = [];
    for (final alloc in allocs) {
      final balMap = allocBalances[alloc.id] ?? {};
      for (final entry in balMap.entries) {
        allocTotals[entry.key] =
            (allocTotals[entry.key] ?? 0.0) + entry.value;
      }
      allocInfos.add(_AllocationInfo(
        name: alloc.name,
        balanceByCurrency: Map.from(balMap),
      ));
    }

    // 3. Unallocated per currency = accounts - allocations
    final allCurrencies = {...accountTotals.keys, ...allocTotals.keys};
    final Map<String, _CurrencyCheck> checks = {};
    for (final c in allCurrencies) {
      final acctTotal = accountTotals[c] ?? 0.0;
      final allocTotal = allocTotals[c] ?? 0.0;
      final unallocated = acctTotal - allocTotal;
      checks[c] = _CurrencyCheck(
        currency: c,
        accountTotal: acctTotal,
        allocationTotal: allocTotal,
        unallocated: unallocated,
        healthy: unallocated >= -0.01,
      );
    }

    // 4. Orphan ledger entries (linked to non-existent transactions)
    final allocIds = allocs.map((a) => a.id).toList();
    List<AllocationLedgerData> allEntries = [];
    if (allocIds.isNotEmpty) {
      allEntries = await ledgerDao.getAllForHousehold(allocIds);
    }
    int orphanCount = 0;
    if (allEntries.isNotEmpty) {
      final txIdsInLedger = allEntries
          .where((e) => e.sourceTransactionId != null)
          .map((e) => e.sourceTransactionId!)
          .toSet();
      if (txIdsInLedger.isNotEmpty) {
        final existingTxs = await (db.select(db.transactions)
              ..where((t) => t.id.isIn(txIdsInLedger.toList())))
            .get();
        final existingIds = existingTxs
            .where((t) => !t.deleted)
            .map((t) => t.id)
            .toSet();
        orphanCount = txIdsInLedger.difference(existingIds).length;
      }
    }

    // 5. Soft-deleted transaction count
    final deletedTxs = await (db.select(db.transactions)
          ..where((t) => t.householdId.equals(householdId))
          ..where((t) => t.deleted.equals(true)))
        .get();

    // 6. Last backup
    final lastBackup = await AutoBackupService.getLastBackupTime();

    // 7. Total transaction count
    final totalTxs = await (db.select(db.transactions)
          ..where((t) => t.householdId.equals(householdId))
          ..where((t) => t.deleted.equals(false)))
        .get();

    return _HealthReport(
      checks: checks,
      accounts: accountInfos,
      allocations: allocInfos,
      orphanLedgerCount: orphanCount,
      softDeletedCount: deletedTxs.length,
      totalTransactions: totalTxs.length,
      totalLedgerEntries: allEntries.length,
      lastBackup: lastBackup,
    );
  }

  // ─── Repair ─────────────────────────────────────────────────────────────

  Future<void> _repair() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Repair Balances'),
        content: const Text(
          'This will create adjustment ledger entries to bring '
          'allocation balances back in line with account balances. '
          'A backup is recommended before proceeding.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Repair'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _running = true);
    try {
      final db = ref.read(databaseProvider);
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) return;

      final report = _report;
      if (report == null) return;

      final ledgerDao = LedgerDao(db);
      final uuid = const Uuid();
      int adjustments = 0;

      for (final check in report.checks.values) {
        if (!check.healthy) {
          // The unallocated is negative — allocations claim more than
          // accounts have. Create a negative adjustment to allocations.
          // We distribute the adjustment to the largest allocation in
          // this currency.
          final biggest = report.allocations
              .where((a) => (a.balanceByCurrency[check.currency] ?? 0) > 0)
              .toList();
          if (biggest.isEmpty) continue;

          biggest.sort((a, b) =>
              (b.balanceByCurrency[check.currency] ?? 0)
                  .compareTo(a.balanceByCurrency[check.currency] ?? 0));

          // Find the allocation ID for the biggest one
          final allocs = await (db.select(db.allocations)
                ..where((t) => t.householdId.equals(householdId))
                ..where((t) => t.name.equals(biggest.first.name))
                ..where((t) => t.archived.equals(false))
                ..limit(1))
              .get();

          if (allocs.isEmpty) continue;

          await ledgerDao.appendEntry(AllocationLedgerCompanion.insert(
            id: uuid.v4(),
            allocationId: allocs.first.id,
            entryType: 'adjustment',
            amount: check.unallocated, // negative value corrects the overshoot
            currency: check.currency,
            note: const Value('Health check auto-adjustment'),
            deviceId: 'health-check',
          ));
          adjustments++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(adjustments > 0
              ? '$adjustments adjustment(s) created'
              : 'No adjustments needed'),
        ));
      }
      await _runCheck();
    } catch (e) {
      debugPrint('[HealthCheck] Repair error: $e');
      if (mounted) {
        setState(() => _running = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Repair failed: $e'),
        ));
      }
    }
  }

  // ─── Export ──────────────────────────────────────────────────────────────

  Future<void> _exportReport() async {
    final report = _report;
    if (report == null) return;

    final json = _reportToJson(report);
    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path,
        'health_check_${DateTime.now().millisecondsSinceEpoch}.json'));

    try {
      await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(json));
      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        title: 'PocketPlan Health Check Report',
      ));
    } finally {
      if (file.existsSync()) file.deleteSync();
    }
  }

  Map<String, dynamic> _reportToJson(_HealthReport report) {
    return {
      'generatedAt': DateTime.now().toIso8601String(),
      'totalTransactions': report.totalTransactions,
      'totalLedgerEntries': report.totalLedgerEntries,
      'softDeletedTransactions': report.softDeletedCount,
      'orphanLedgerEntries': report.orphanLedgerCount,
      'lastBackup': report.lastBackup?.toIso8601String(),
      'currencyChecks': report.checks.map((k, v) => MapEntry(k, {
            'accountTotal': v.accountTotal,
            'allocationTotal': v.allocationTotal,
            'unallocated': v.unallocated,
            'healthy': v.healthy,
          })),
      'accounts': report.accounts
          .map((a) => {
                'name': a.name,
                'currency': a.currency,
                'balance': a.balance,
              })
          .toList(),
      'allocations': report.allocations
          .map((a) => {
                'name': a.name,
                'balanceByCurrency': a.balanceByCurrency,
              })
          .toList(),
    };
  }

  // ─── Purge soft-deleted ─────────────────────────────────────────────────

  Future<void> _purgeSoftDeleted() async {
    final report = _report;
    if (report == null || report.softDeletedCount == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Purge Deleted Transactions'),
        content: Text(
          'Permanently remove ${report.softDeletedCount} soft-deleted '
          'transaction(s) and their lines from the database?\n\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.overspent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Purge'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final db = ref.read(databaseProvider);
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;

    final deleted = await (db.select(db.transactions)
          ..where((t) => t.householdId.equals(householdId))
          ..where((t) => t.deleted.equals(true)))
        .get();

    for (final tx in deleted) {
      await (db.delete(db.transactionLines)
            ..where((l) => l.transactionId.equals(tx.id)))
          .go();
      await (db.delete(db.transactions)..where((t) => t.id.equals(tx.id)))
          .go();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('${deleted.length} transaction(s) purged'),
      ));
    }
    await _runCheck();
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Check'),
        actions: [
          if (_report != null) ...[
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Export report',
              onPressed: _exportReport,
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Re-run check',
              onPressed: _running ? null : _runCheck,
            ),
          ],
        ],
      ),
      body: _running
          ? const Center(child: CircularProgressIndicator())
          : _report == null
              ? Center(
                  child: Text('No data',
                      style: TextStyle(color: AppColors.ts(context))))
              : _buildReport(context),
    );
  }

  Widget _buildReport(BuildContext context) {
    final report = _report!;
    final allHealthy = report.checks.values.every((c) => c.healthy) &&
        report.orphanLedgerCount == 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Overall status card ──
        _statusCard(context, allHealthy, report),
        const SizedBox(height: 16),

        // ── Balance invariant per currency ──
        _sectionHeader(context, 'Balance Invariant'),
        const SizedBox(height: 8),
        for (final check in report.checks.values) _invariantTile(context, check),
        const SizedBox(height: 16),

        // ── Accounts ──
        _sectionHeader(context, 'Account Balances'),
        const SizedBox(height: 8),
        _accountsCard(context, report.accounts),
        const SizedBox(height: 16),

        // ── Allocations ──
        _sectionHeader(context, 'Envelope Balances'),
        const SizedBox(height: 8),
        _allocationsCard(context, report.allocations),
        const SizedBox(height: 16),

        // ── Data quality ──
        _sectionHeader(context, 'Data Quality'),
        const SizedBox(height: 8),
        _dataCard(context, report),
        const SizedBox(height: 24),

        // ── Actions ──
        if (!allHealthy)
          FilledButton.icon(
            onPressed: _repair,
            icon: const Icon(Icons.build_rounded),
            label: const Text('Repair Balances'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.caution,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        if (!allHealthy) const SizedBox(height: 12),
        if (report.softDeletedCount > 0)
          OutlinedButton.icon(
            onPressed: _purgeSoftDeleted,
            icon: const Icon(Icons.delete_sweep_rounded),
            label: Text('Purge ${report.softDeletedCount} deleted transaction(s)'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _statusCard(
      BuildContext context, bool healthy, _HealthReport report) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: healthy
              ? [const Color(0xFF10B981), const Color(0xFF059669)]
              : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            healthy
                ? Icons.check_circle_rounded
                : Icons.warning_rounded,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            healthy ? 'All Clear' : 'Issues Found',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            healthy
                ? 'Your data is consistent and healthy'
                : 'Some balance discrepancies detected',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statBadge('Transactions', '${report.totalTransactions}'),
              _statBadge('Ledger', '${report.totalLedgerEntries}'),
              _statBadge(
                'Backup',
                report.lastBackup != null
                    ? _formatDate(report.lastBackup!)
                    : 'Never',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.ts(context),
          letterSpacing: 0.5,
        ));
  }

  Widget _invariantTile(BuildContext context, _CurrencyCheck check) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: check.healthy
              ? AppColors.healthy.withValues(alpha: 0.3)
              : AppColors.overspent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            check.healthy
                ? Icons.check_circle_rounded
                : Icons.error_rounded,
            color: check.healthy ? AppColors.healthy : AppColors.overspent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(check.currency,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  'Accounts: ${formatNumber(check.accountTotal)}  |  '
                  'Envelopes: ${formatNumber(check.allocationTotal)}',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.ts(context)),
                ),
              ],
            ),
          ),
          Text(
            'Unalloc: ${formatNumber(check.unallocated)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: check.healthy ? AppColors.healthy : AppColors.overspent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountsCard(BuildContext context, List<_AccountInfo> accounts) {
    if (accounts.isEmpty) {
      return _emptyCard(context, 'No accounts');
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < accounts.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 16, endIndent: 16,
                  color: AppColors.bd(context)),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(accounts[i].name,
                        style: const TextStyle(fontSize: 13)),
                  ),
                  Text(
                    '${accounts[i].currency} ${formatNumber(accounts[i].balance)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: accounts[i].balance >= 0
                          ? AppColors.tp(context)
                          : AppColors.overspent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _allocationsCard(
      BuildContext context, List<_AllocationInfo> allocations) {
    if (allocations.isEmpty) {
      return _emptyCard(context, 'No envelopes');
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < allocations.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 16, endIndent: 16,
                  color: AppColors.bd(context)),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(allocations[i].name,
                        style: const TextStyle(fontSize: 13)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final entry
                          in allocations[i].balanceByCurrency.entries)
                        Text(
                          '${entry.key} ${formatNumber(entry.value)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: entry.value >= 0
                                ? AppColors.tp(context)
                                : AppColors.overspent,
                          ),
                        ),
                      if (allocations[i].balanceByCurrency.isEmpty)
                        Text('0.00',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.th(context))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dataCard(BuildContext context, _HealthReport report) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _dataRow(
            context,
            icon: Icons.receipt_long_rounded,
            label: 'Transactions',
            value: '${report.totalTransactions}',
          ),
          Divider(height: 1, indent: 16, endIndent: 16,
              color: AppColors.bd(context)),
          _dataRow(
            context,
            icon: Icons.menu_book_rounded,
            label: 'Ledger entries',
            value: '${report.totalLedgerEntries}',
          ),
          Divider(height: 1, indent: 16, endIndent: 16,
              color: AppColors.bd(context)),
          _dataRow(
            context,
            icon: Icons.delete_outline_rounded,
            label: 'Soft-deleted',
            value: '${report.softDeletedCount}',
            valueColor: report.softDeletedCount > 0
                ? AppColors.caution
                : null,
          ),
          Divider(height: 1, indent: 16, endIndent: 16,
              color: AppColors.bd(context)),
          _dataRow(
            context,
            icon: Icons.link_off_rounded,
            label: 'Orphan ledger entries',
            value: '${report.orphanLedgerCount}',
            valueColor: report.orphanLedgerCount > 0
                ? AppColors.overspent
                : null,
          ),
          Divider(height: 1, indent: 16, endIndent: 16,
              color: AppColors.bd(context)),
          _dataRow(
            context,
            icon: Icons.backup_rounded,
            label: 'Last backup',
            value: report.lastBackup != null
                ? _formatDateTime(report.lastBackup!)
                : 'Never',
            valueColor:
                report.lastBackup == null ? AppColors.caution : null,
          ),
        ],
      ),
    );
  }

  Widget _dataRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.ts(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppColors.tp(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(message,
            style: TextStyle(color: AppColors.th(context), fontSize: 13)),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Data classes ──────────────────────────────────────────────────────────

class _HealthReport {
  final Map<String, _CurrencyCheck> checks;
  final List<_AccountInfo> accounts;
  final List<_AllocationInfo> allocations;
  final int orphanLedgerCount;
  final int softDeletedCount;
  final int totalTransactions;
  final int totalLedgerEntries;
  final DateTime? lastBackup;

  const _HealthReport({
    required this.checks,
    required this.accounts,
    required this.allocations,
    required this.orphanLedgerCount,
    required this.softDeletedCount,
    required this.totalTransactions,
    required this.totalLedgerEntries,
    required this.lastBackup,
  });
}

class _CurrencyCheck {
  final String currency;
  final double accountTotal;
  final double allocationTotal;
  final double unallocated;
  final bool healthy;

  const _CurrencyCheck({
    required this.currency,
    required this.accountTotal,
    required this.allocationTotal,
    required this.unallocated,
    required this.healthy,
  });
}

class _AccountInfo {
  final String name;
  final String currency;
  final double balance;

  const _AccountInfo({
    required this.name,
    required this.currency,
    required this.balance,
  });
}

class _AllocationInfo {
  final String name;
  final Map<String, double> balanceByCurrency;

  const _AllocationInfo({
    required this.name,
    required this.balanceByCurrency,
  });
}
