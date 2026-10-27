import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value, Variable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../shared/utils/format_number.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/ledger_dao.dart';
import '../../core/database/daos/transactions_dao.dart' show chunked;
import '../../shared/utils/receipt_helper.dart';
import '../../core/engine/balance_calculator.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/services/auto_backup_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../core/providers/date_format_provider.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/theme/app_icons.dart';

class HealthCheckScreen extends ConsumerStatefulWidget {
  const HealthCheckScreen({super.key});

  @override
  ConsumerState<HealthCheckScreen> createState() => _HealthCheckScreenState();
}

class _HealthCheckScreenState extends ConsumerState<HealthCheckScreen> {
  bool _running = false;
  bool _failed = false;
  _HealthReport? _report;

  @override
  void initState() {
    super.initState();
    _runCheck();
  }

  Future<void> _runCheck() async {
    setState(() {
      _running = true;
      _failed = false;
    });
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
      if (mounted) {
        setState(() {
          _running = false;
          _failed = true;
        });
      }
    }
  }

  // ─── Diagnosis ──────────────────────────────────────────────────────────

  Future<_HealthReport> _diagnose(AppDatabase db, String householdId) async {
    final calc = BalanceCalculator(db);

    // 1. Account balances per currency
    final accounts = await (db.select(db.accounts)
          ..where((t) => t.householdId.equals(householdId))
          ..where((t) => t.archived.equals(false))
          ..where((t) => t.deleted.equals(false)))
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
          ..where((t) => t.archived.equals(false))
          ..where((t) => t.deleted.equals(false)))
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

    // 4. Orphan ledger entries (linked to non-existent transactions),
    // counted in SQL: a long history has tens of thousands of rows.
    final ledgerRow = await db.customSelect(
      '''SELECT COUNT(*) AS entries,
                COUNT(DISTINCT CASE WHEN l.source_transaction_id IS NOT NULL
                  AND NOT EXISTS (SELECT 1 FROM transactions t
                                   WHERE t.id = l.source_transaction_id
                                     AND t.deleted = 0)
                  THEN l.source_transaction_id END) AS orphans
           FROM allocation_ledger l
           JOIN allocations a ON a.id = l.allocation_id
          WHERE a.household_id = ? AND a.archived = 0 AND a.deleted = 0''',
      variables: [Variable.withString(householdId)],
    ).getSingle();
    final orphanCount = ledgerRow.read<int>('orphans');

    // 5. Soft-deleted transaction count
    final deletedCount = await db.customSelect(
      'SELECT COUNT(*) AS c FROM transactions WHERE household_id = ? AND deleted = 1',
      variables: [Variable.withString(householdId)],
    ).getSingle().then((r) => r.read<int>('c'));

    // 6. Last backup
    final lastBackup = await AutoBackupService.getLastBackupTime();

    // 7. Total transaction count
    final totalTxCount = await db.customSelect(
      'SELECT COUNT(*) AS c FROM transactions WHERE household_id = ? AND deleted = 0',
      variables: [Variable.withString(householdId)],
    ).getSingle().then((r) => r.read<int>('c'));

    // 8. Total ledger entries count
    final ledgerCount = ledgerRow.read<int>('entries');

    return _HealthReport(
      checks: checks,
      accounts: accountInfos,
      allocations: allocInfos,
      orphanLedgerCount: orphanCount,
      softDeletedCount: deletedCount,
      totalTransactions: totalTxCount,
      totalLedgerEntries: ledgerCount,
      lastBackup: lastBackup,
    );
  }

  // ─── Repair ─────────────────────────────────────────────────────────────

  Future<void> _repair() async {
    final tr = S.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: tr.healthRepairConfirmTitle,
      message: tr.healthRepairMsg,
      confirmLabel: tr.healthRepairDone,
      destructive: false,
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
            note: Value(tr.healthAutoAdjustment),
            deviceId: 'health-check',
          ));
          adjustments++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(adjustments > 0
              ? S.of(context).healthAdjustmentsCreated(adjustments)
              : S.of(context).healthNoAdjustments),
        ));
      }
      await _runCheck();
    } catch (e) {
      debugPrint('[HealthCheck] Repair error: $e');
      if (mounted) {
        setState(() => _running = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(S.of(context).healthRepairFailed),
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
        title: S.of(context).healthReportTitle,
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

    final tr = S.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: tr.healthPurgeConfirmTitle,
      message:
          tr.healthPurgeContent(report.softDeletedCount, tr.healthPurgeSuffix),
      confirmLabel: tr.healthPurgeButton,
    );
    if (!confirmed || !mounted) return;

    final db = ref.read(databaseProvider);
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;

    final deleted = await (db.select(db.transactions)
          ..where((t) => t.householdId.equals(householdId))
          ..where((t) => t.deleted.equals(true)))
        .get();

    // Delete receipt files before purging DB rows — except files a live
    // transaction still uses (an edit re-saves the tx under a new id and
    // carries its receipts over).
    final live = await (db.select(db.transactions)
          ..where((t) => t.householdId.equals(householdId))
          ..where((t) => t.deleted.equals(false))
          ..where((t) => t.receiptPath.isNotNull()))
        .get();
    final inUse = {for (final t in live) ...parseReceiptPaths(t.receiptPath)};
    final receiptsDir = await getReceiptsDirectory();
    for (final tx in deleted) {
      final paths = parseReceiptPaths(tx.receiptPath);
      for (final filename in paths) {
        if (inUse.contains(filename)) continue;
        try {
          final file = File(p.join(receiptsDir.path, filename));
          if (file.existsSync()) await file.delete();
        } catch (_) {}
      }
    }

    // Batch delete DB rows
    final ids = deleted.map((t) => t.id).toList();
    await db.transaction(() async {
      // Ledger rows first: once the transaction row is gone their
      // source_transaction_id is nulled (FK SET NULL) and they would count
      // as manual adjustments, changing envelope balances.
      for (final chunk in chunked(ids)) {
        await (db.delete(db.allocationLedger)
              ..where((l) => l.sourceTransactionId.isIn(chunk)))
            .go();
        await (db.delete(db.transactionLines)
              ..where((l) => l.transactionId.isIn(chunk)))
            .go();
        await (db.delete(db.transactions)..where((t) => t.id.isIn(chunk)))
            .go();
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(S.of(context).healthPurged(deleted.length)),
      ));
    }
    await _runCheck();
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).healthTitle),
        actions: [
          if (_report != null) ...[
            IconButton(
              icon: const Icon(AppIcons.shareNetwork),
              tooltip: S.of(context).healthExportTooltip,
              onPressed: _exportReport,
            ),
            IconButton(
              icon: const Icon(AppIcons.arrowClockwise),
              tooltip: S.of(context).healthRerunTooltip,
              onPressed: _running ? null : _runCheck,
            ),
          ],
        ],
      ),
      body: _running
          ? const SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: 8),
              child: SkeletonList())
          : _failed
              ? ErrorRetry(onRetry: _runCheck)
              : _report == null
                  ? EmptyState(
                      icon: AppIcons.heartbeat,
                      title: S.of(context).commonNoData)
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
        const SizedBox(height: Spacing.sectionGap),

        // ── Balance invariant per currency ──
        _sectionHeader(context, S.of(context).healthBalanceInvariant),
        const SizedBox(height: Spacing.headerToCard),
        for (final check in report.checks.values) _invariantTile(context, check),
        const SizedBox(height: Spacing.sectionGap),

        // ── Accounts ──
        _sectionHeader(context, S.of(context).healthAccountBalances),
        const SizedBox(height: Spacing.headerToCard),
        _accountsCard(context, report.accounts),
        const SizedBox(height: Spacing.sectionGap),

        // ── Allocations ──
        _sectionHeader(context, S.of(context).healthEnvelopeBalances),
        const SizedBox(height: Spacing.headerToCard),
        _allocationsCard(context, report.allocations),
        const SizedBox(height: Spacing.sectionGap),

        // ── Data quality ──
        _sectionHeader(context, S.of(context).healthDataQuality),
        const SizedBox(height: Spacing.headerToCard),
        _dataCard(context, report),
        const SizedBox(height: 24),

        // ── Actions ──
        if (!allHealthy)
          FilledButton.icon(
            onPressed: _repair,
            icon: const Icon(AppIcons.wrench),
            label: Text(S.of(context).healthRepairButton),
          ),
        if (!allHealthy) const SizedBox(height: 12),
        if (report.softDeletedCount > 0)
          OutlinedButton.icon(
            onPressed: _purgeSoftDeleted,
            icon: const Icon(AppIcons.broom),
            label: Text(S.of(context).healthPurgeButtonN(report.softDeletedCount)),
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _statusCard(
      BuildContext context, bool healthy, _HealthReport report) {
    final tone = healthy ? AppColors.healthy : AppColors.overspent;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.pastel(context, tone, light: 0.85, dark: 0.75),
        borderRadius: BorderRadius.circular(CardTokens.radius),
      ),
      child: Column(
        children: [
          Icon(
            healthy
                ? AppIcons.checkCircleFill
                : AppIcons.warningFill,
            color: tone,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            healthy ? S.of(context).healthAllClear : S.of(context).healthIssuesFound,
            style: TextStyle(
              color: AppColors.tp(context),
              fontSize: 22,
              fontFamily: TypographyTokens.displayFamily,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            healthy
                ? S.of(context).healthDataConsistent
                : S.of(context).healthDiscrepancies,
            style: TextStyle(color: AppColors.ts(context), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statBadge(S.of(context).healthTransactionsStat, '${report.totalTransactions}'),
              _statBadge(S.of(context).healthLedgerStat, '${report.totalLedgerEntries}'),
              _statBadge(
                S.of(context).healthBackupStat,
                report.lastBackup != null
                    ? formatDate(report.lastBackup!)
                    : S.of(context).healthNever,
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
            style: TextStyle(
                color: AppColors.tp(context),
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(color: AppColors.ts(context), fontSize: 11)),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title) =>
      SectionHeader(title);

  Widget _invariantTile(BuildContext context, _CurrencyCheck check) {
    String n(double v) =>
        formatNumber(v, decimals: currencyDecimals(check.currency));
    // Stacked lines, full width: LBP totals don't fit side by side.
    return AppCard(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        children: [
          Icon(
            check.healthy
                ? AppIcons.checkCircleFill
                : AppIcons.warningCircleFill,
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
                  S.of(context).healthAccountsVsEnvelopes(
                      n(check.accountTotal), n(check.allocationTotal)),
                  style: TextStyle(
                      fontSize: TypographyTokens.captionSize,
                      color: AppColors.ts(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  S.of(context).healthUnallocShort(n(check.unallocated)),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: check.healthy
                        ? AppColors.healthy
                        : AppColors.overspent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountsCard(BuildContext context, List<_AccountInfo> accounts) {
    if (accounts.isEmpty) {
      return EmptyState(
          icon: AppIcons.creditCard, title: S.of(context).healthNoAccounts);
    }
    return AppCard(
      padding: EdgeInsets.zero,
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
                    '${accounts[i].currency} ${formatNumber(accounts[i].balance, decimals: currencyDecimals(accounts[i].currency))}',
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
      return EmptyState(
          icon: AppIcons.wallet, title: S.of(context).healthNoEnvelopes);
    }
    return AppCard(
      padding: EdgeInsets.zero,
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
                          '${entry.key} ${formatNumber(entry.value, decimals: currencyDecimals(entry.key))}',
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
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _dataRow(
            context,
            icon: AppIcons.receipt,
            label: S.of(context).healthTransactionsStat,
            value: '${report.totalTransactions}',
          ),
          Divider(height: 1, indent: 16, endIndent: 16,
              color: AppColors.bd(context)),
          _dataRow(
            context,
            icon: AppIcons.bookOpen,
            label: S.of(context).healthLedgerEntries,
            value: '${report.totalLedgerEntries}',
          ),
          Divider(height: 1, indent: 16, endIndent: 16,
              color: AppColors.bd(context)),
          _dataRow(
            context,
            icon: AppIcons.trash,
            label: S.of(context).healthSoftDeleted,
            value: '${report.softDeletedCount}',
            valueColor: report.softDeletedCount > 0
                ? AppColors.caution
                : null,
          ),
          Divider(height: 1, indent: 16, endIndent: 16,
              color: AppColors.bd(context)),
          _dataRow(
            context,
            icon: AppIcons.linkBreak,
            label: S.of(context).healthOrphanEntries,
            value: '${report.orphanLedgerCount}',
            valueColor: report.orphanLedgerCount > 0
                ? AppColors.overspent
                : null,
          ),
          Divider(height: 1, indent: 16, endIndent: 16,
              color: AppColors.bd(context)),
          _dataRow(
            context,
            icon: AppIcons.cloudArrowUp,
            label: S.of(context).healthLastBackup,
            value: report.lastBackup != null
                ? formatDateTime(report.lastBackup!)
                : S.of(context).healthNever,
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
