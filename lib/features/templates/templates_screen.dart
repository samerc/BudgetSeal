import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/empty_state.dart';

class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  List<TransactionTemplate> _templates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;
    final items = await (db.select(db.transactionTemplates)
          ..where((t) => t.householdId.equals(householdId))
          ..orderBy([(t) => OrderingTerm.desc(t.useCount)]))
        .get();
    if (mounted) setState(() { _templates = items; _loading = false; });
  }

  Future<void> _useTemplate(TransactionTemplate t) async {
    final db = ref.read(databaseProvider);
    // Increment use count
    await (db.update(db.transactionTemplates)
          ..where((r) => r.id.equals(t.id)))
        .write(TransactionTemplatesCompanion(
      useCount: Value(t.useCount + 1),
      lastUsedAt: Value(DateTime.now()),
    ));

    final cats = ref.read(categoriesProvider).value ?? [];
    final cat = t.categoryId != null
        ? cats.where((c) => c.id == t.categoryId).firstOrNull
        : null;

    if (mounted) {
      // Pop back to the previous screen, then open add-transaction with pre-fill.
      context.pop();
      context.push('/add-transaction', extra: {
        'editType': t.type,
        'editNote': t.title,
        'editLines': [
          {
            'amount': t.amount,
            'currency': t.currency,
            'accountId': t.accountId,
            'categoryId': t.categoryId,
            'categoryName': cat?.name,
            'note': '',
          }
        ],
      });
    }
  }

  Future<void> _delete(String id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.transactionTemplates)
          ..where((t) => t.id.equals(id)))
        .go();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).value ?? [];
    final acctMap = {for (final a in accounts) a.id: a};
    final categories = ref.watch(categoriesProvider).value ?? [];
    final catMap = {for (final c in categories) c.id: c};

    return Scaffold(
      appBar: AppBar(title: const Text('Templates')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(accounts, categories),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? const EmptyState(
                  icon: Icons.bolt_rounded,
                  title: 'No templates yet',
                  subtitle: 'Save frequent transactions for quick re-use',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: _templates.length,
                  itemBuilder: (_, i) {
                    final t = _templates[i];
                    final acct = t.accountId != null ? acctMap[t.accountId] : null;
                    final cat = t.categoryId != null ? catMap[t.categoryId] : null;
                    final isIncome = t.type == 'income';
                    final color = isIncome ? AppColors.healthy : AppColors.overspent;

                    return Dismissible(
                      key: ValueKey(t.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.overspent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.delete_rounded, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            title: const Text('Delete template?'),
                            content: const Text(
                                'This template will be permanently removed.'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogCtx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogCtx, true),
                                style: TextButton.styleFrom(
                                    foregroundColor: AppColors.overspent),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ) ?? false;
                      },
                      onDismissed: (_) => _delete(t.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.sf(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.bd(context)),
                        ),
                        child: ListTile(
                          onTap: () => _useTemplate(t),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.bolt_rounded, color: color, size: 18),
                          ),
                          title: Text(t.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(
                            [
                              formatAmount(t.amount, currency: t.currency),
                              if (cat != null) cat.name,
                              if (acct != null) acct.name,
                            ].join(' · '),
                            style: TextStyle(
                                fontSize: 11, color: AppColors.th(context)),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded,
                              size: 18),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _showAddSheet(
      List<Account> accounts, List<Category> categories) async {
    final titleCtrl = TextEditingController();
    double calcAmount = 0;
    final formKey = GlobalKey<FormState>();
    String type = 'expense';
    String? accountId;
    String? categoryId;
    String currency = ref.read(householdProvider).value?.baseCurrency ?? 'USD';

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.sf(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('New Template',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: titleCtrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 12),
                  CalculatorAmountField(
                    value: calcAmount,
                    label: 'Amount',
                    fontSize: 20,
                    onChanged: (v) => setSheetState(() => calcAmount = v),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'expense', label: Text('Expense')),
                      ButtonSegment(value: 'income', label: Text('Income')),
                    ],
                    selected: {type},
                    onSelectionChanged: (s) =>
                        setSheetState(() => type = s.first),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: accountId,
                    decoration: const InputDecoration(labelText: 'Account'),
                    items: accounts
                        .map((a) => DropdownMenuItem(
                            value: a.id, child: Text('${a.name} (${a.currency})')))
                        .toList(),
                    onChanged: (v) => setSheetState(() {
                      accountId = v;
                      if (v != null) {
                        currency = accounts.firstWhere((a) => a.id == v).currency;
                      }
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: categoryId,
                    decoration: const InputDecoration(labelText: 'Category (optional)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ...categories.map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (v) => setSheetState(() => categoryId = v),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final title = titleCtrl.text.trim();
                      if (calcAmount <= 0) return;
                      final amount = calcAmount;
                      final householdId = ref.read(currentHouseholdIdProvider);
                      if (householdId == null) return;

                      final db = ref.read(databaseProvider);
                      await db.into(db.transactionTemplates).insert(
                            TransactionTemplatesCompanion.insert(
                              id: const Uuid().v4(),
                              householdId: householdId,
                              title: title,
                              type: type,
                              amount: amount,
                              currency: currency,
                              accountId: Value(accountId),
                              categoryId: Value(categoryId),
                            ),
                          );
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    },
                    child: const Text('Save Template'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (result == true) _load();
  }
}
