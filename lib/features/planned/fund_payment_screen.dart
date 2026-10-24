import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/engine/planned_engine.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/haptics.dart';
import '../../shared/utils/note_text.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/tappable.dart';
import '../transactions/widgets/tx_ui.dart' show showAccountPickerSheet;

class _Part {
  String accountId;
  double amount;
  _Part(this.accountId, this.amount);
}

/// One scheduled payment of a sinking fund (any planned expense): a name,
/// a due date and one part per currency, each from its own account, never
/// converted. [planId] edits an existing plan; else [categoryId] is the
/// fund's category and [title]/[date]/[parts] prefill a new one.
class FundPaymentScreen extends ConsumerStatefulWidget {
  final String? planId;
  final String? categoryId;
  final String? title;
  final DateTime? date;
  final List<PlanPart> parts;

  const FundPaymentScreen({
    super.key,
    this.planId,
    this.categoryId,
    this.title,
    this.date,
    this.parts = const [],
  });

  @override
  ConsumerState<FundPaymentScreen> createState() => _FundPaymentScreenState();
}

class _FundPaymentScreenState extends ConsumerState<FundPaymentScreen> {
  final _nameCtrl = TextEditingController();
  DateTime? _date;
  String? _categoryId;
  final List<_Part> _parts = [];
  bool _loading = false;
  String? _error;

  bool get _editing => widget.planId != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.title ?? '';
    _date = widget.date;
    _categoryId = widget.categoryId;
    for (final p in widget.parts) {
      _parts.add(_Part(p.accountId, p.amount));
    }
    if (_editing) _loadPlan();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPlan() async {
    try {
      final db = ref.read(databaseProvider);
      final tx = await (db.select(db.transactions)
            ..where((t) => t.id.equals(widget.planId!)))
          .getSingleOrNull();
      if (tx == null) return;
      final lines = await (db.select(db.transactionLines)
            ..where((l) => l.transactionId.equals(tx.id)))
          .get();
      if (!mounted) return;
      setState(() {
        _nameCtrl.text = visibleNote(tx.note);
        _date = tx.createdAt;
        _categoryId = lines.firstOrNull?.categoryId ?? tx.categoryId;
        _parts
          ..clear()
          ..addAll(lines.isEmpty
              ? [_Part(tx.accountId, tx.amount)]
              : [for (final l in lines) _Part(l.accountId ?? tx.accountId, l.amount)]);
      });
    } catch (e) {
      debugPrint('[FundPayment] load failed: $e');
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null && mounted) {
      setState(() {
        _date = picked;
        _error = null;
      });
    }
  }

  Future<void> _pickAccount(int index, List<Account> accounts) async {
    final tr = S.of(context);
    final id = await showAccountPickerSheet(context,
        accounts: accounts,
        title: tr.sinkFromAccount,
        selectedId: index < _parts.length ? _parts[index].accountId : null);
    if (id == null || !mounted) return;
    setState(() {
      if (index < _parts.length) {
        _parts[index].accountId = id;
      } else {
        _parts.add(_Part(id, 0));
      }
      _error = null;
    });
  }

  Future<void> _save(List<Account> accounts) async {
    final tr = S.of(context);
    final currencyOf = {for (final a in accounts) a.id: a.currency};
    final parts = [
      for (final p in _parts)
        if (p.amount > 0 && currencyOf[p.accountId] != null)
          PlanPart(
              amount: p.amount,
              currency: currencyOf[p.accountId]!,
              accountId: p.accountId),
    ];
    final String? error = _date == null
        ? tr.sinkPickDate
        : parts.isEmpty
            ? tr.txFormEnterAmount
            : parts.map((p) => p.currency).toSet().length < parts.length
                ? tr.sinkOnePartPerCurrency
                : null;
    if (error != null) {
      hapticHeavy();
      setState(() => _error = error);
      return;
    }
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;
    setState(() => _loading = true);
    try {
      await PlannedEngine(ref.read(databaseProvider)).save(
        replaceId: widget.planId,
        householdId: householdId,
        type: 'expense',
        accountId: parts.first.accountId,
        amount: parts.first.amount,
        currency: parts.first.currency,
        categoryId: _categoryId,
        note: _nameCtrl.text.trim(),
        date: _date!,
        createdBy: 'user',
        deviceId: 'local',
        parts: parts,
      );
      if (!mounted) return;
      hapticMedium();
      final messenger = ScaffoldMessenger.maybeOf(context);
      context.pop(true);
      messenger?.showSnackBar(SnackBar(
        content: Text(tr.sinkPaymentSaved),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      debugPrint('[FundPayment] save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr.plannedSaveFailed),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final tr = S.of(context);
    final ok = await showConfirmDialog(context,
        title: tr.sinkDeletePaymentTitle,
        message: tr.sinkDeletePaymentMsg,
        confirmLabel: tr.commonDelete,
        destructive: true);
    if (ok != true || !mounted) return;
    try {
      await ref.read(allocationEngineProvider).deleteTransaction(widget.planId!);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      context.pop(true);
      messenger?.showSnackBar(SnackBar(
        content: Text(tr.sinkPaymentDeleted),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      debugPrint('[FundPayment] delete failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr.plannedSaveFailed),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final accounts = [
      for (final a in ref.watch(accountsProvider).value ?? const <Account>[])
        if (!a.archived) a,
    ];
    final byId = {for (final a in accounts) a.id: a};
    final category = (ref.watch(categoriesProvider).value ?? const <Category>[])
        .where((c) => c.id == _categoryId)
        .firstOrNull;
    final used = {for (final p in _parts) byId[p.accountId]?.currency};
    final unusedAccounts =
        accounts.where((a) => !used.contains(a.currency)).toList();

    final label = TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ts(context));
    BoxDecoration field() => BoxDecoration(
        color: AppColors.sfv(context),
        borderRadius: BorderRadius.circular(RadiusTokens.md));

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? tr.sinkEditPayment : tr.sinkAddPayment),
        actions: [
          if (_editing)
            IconButton(
              tooltip: tr.commonDelete,
              icon: Icon(AppIcons.trash, color: AppColors.overspent),
              onPressed: _delete,
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: FilledButton(
            onPressed: _loading ? null : () => _save(accounts),
            child: Text(tr.sinkSavePayment),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(tr.sinkPaymentName, style: label),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: tr.sinkPaymentNameHint),
          ),
          const SizedBox(height: 16),
          Text(tr.sinkDueOn, style: label),
          const SizedBox(height: 6),
          Tappable(
            onTap: _pickDate,
            color: AppColors.sfv(context),
            borderRadius: BorderRadius.circular(RadiusTokens.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Icon(AppIcons.calendarDots,
                    size: 18, color: AppColors.ts(context)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      _date == null ? tr.sinkPickDate : formatDate(_date!),
                      style: TextStyle(
                          fontSize: 15,
                          color: _date == null
                              ? AppColors.th(context)
                              : AppColors.tp(context))),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Text(tr.sinkAmountLabel, style: label),
          const SizedBox(height: 6),
          for (var i = 0; i < _parts.length; i++) ...[
            Container(
              decoration: field(),
              padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 4, 4),
              child: Row(children: [
                Tappable(
                  onTap: () => _pickAccount(i, accounts),
                  borderRadius: BorderRadius.circular(RadiusTokens.sm),
                  color: AppColors.sf(context),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(byId[_parts[i].accountId]?.currency ?? '—',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w800)),
                          Text(byId[_parts[i].accountId]?.name ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.ts(context))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CalculatorAmountField(
                    value: _parts[i].amount,
                    onChanged: (v) => setState(() {
                      _parts[i].amount = v;
                      _error = null;
                    }),
                    hintText: tr.commonAmount,
                    fontSize: 20,
                  ),
                ),
                if (_parts.length > 1)
                  IconButton(
                    tooltip: tr.sinkRemovePart,
                    icon: Icon(AppIcons.x, size: 18, color: AppColors.ts(context)),
                    onPressed: () => setState(() => _parts.removeAt(i)),
                  ),
              ]),
            ),
            const SizedBox(height: 8),
          ],
          if (_parts.isEmpty || unusedAccounts.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => _pickAccount(
                    _parts.length, _parts.isEmpty ? accounts : unusedAccounts),
                icon: const Icon(AppIcons.plus, size: 16),
                label: Text(_parts.isEmpty
                    ? tr.sinkAddAmount
                    : tr.sinkAddCurrency),
              ),
            ),
          Text(tr.sinkPartsNote,
              style: TextStyle(fontSize: 12, color: AppColors.ts(context))),
          if (category != null) ...[
            const SizedBox(height: 16),
            Container(
              decoration: field(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Text(tr.commonCategory,
                    style: TextStyle(fontSize: 14, color: AppColors.ts(context))),
                const Spacer(),
                Text(category.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.overspent)),
          ],
        ],
      ),
    );
  }
}
