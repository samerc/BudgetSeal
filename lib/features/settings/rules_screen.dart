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
import '../../core/providers/transactions_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/bottom_action_bar.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/tappable.dart';
import '../transactions/widgets/category_sheet.dart';
import '../transactions/widgets/tx_ui.dart';

/// Settings › Rules (roadmap #2): "when the text contains X → this
/// category, account and title", for shared payments and bank alerts.
/// Learned ones come from saving a captured payment with a category.
class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = S.of(context);
    final db = ref.watch(databaseProvider);
    final householdId = ref.watch(currentHouseholdIdProvider);
    final cats = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c.name
    };
    final accounts = {
      for (final a in ref.watch(accountsProvider).value ?? const <Account>[])
        a.id: a.name
    };
    return Scaffold(
      appBar: AppBar(title: Text(tr.tileRules)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/rules/edit'),
        icon: const Icon(AppIcons.plus),
        label: Text(tr.rulesAdd),
      ),
      body: StreamBuilder<List<CaptureRule>>(
        stream: (db.select(db.captureRules)
              ..where((r) =>
                  r.householdId.equals(householdId ?? '') &
                  r.deleted.equals(false))
              ..orderBy([(r) => OrderingTerm.asc(r.match)]))
            .watch(),
        builder: (context, snap) {
          final rules = snap.data ?? const <CaptureRule>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Text(tr.rulesIntro,
                    style:
                        TextStyle(fontSize: 13.5, color: AppColors.ts(context))),
              ),
              if (snap.hasData && rules.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: EmptyState(icon: AppIcons.tag, title: tr.rulesEmpty),
                )
              else if (rules.isNotEmpty)
                Container(
                  decoration: AppColors.card(context),
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    for (final r in rules)
                      Tappable(
                        onTap: () => context.push('/rules/edit', extra: r.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('“${r.match}”',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700)),
                                  Text(
                                    [
                                      if (r.title != null) r.title!,
                                      cats[r.categoryId] ?? tr.rulesKeep,
                                      if (accounts[r.accountId] case final a?) a,
                                    ].join(' · '),
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.ts(context)),
                                  ),
                                  Text(
                                    [
                                      if (r.learned) tr.rulesLearned,
                                      if (r.uses > 0) tr.rulesUsed(r.uses),
                                    ].join(' · '),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.th(context)),
                                  ),
                                ],
                              ),
                            ),
                            Icon(AppIcons.caretRight,
                                size: 18, color: AppColors.th(context)),
                          ]),
                        ),
                      ),
                  ]),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Add or edit one rule ([ruleId] null = new).
class RuleEditScreen extends ConsumerStatefulWidget {
  final String? ruleId;
  const RuleEditScreen({super.key, this.ruleId});

  @override
  ConsumerState<RuleEditScreen> createState() => _RuleEditScreenState();
}

class _RuleEditScreenState extends ConsumerState<RuleEditScreen> {
  final _matchCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  String? _categoryId;
  String? _accountId;
  CaptureRule? _rule;

  @override
  void initState() {
    super.initState();
    if (widget.ruleId != null) _load();
  }

  Future<void> _load() async {
    try {
      final db = ref.read(databaseProvider);
      final r = await (db.select(db.captureRules)
            ..where((x) => x.id.equals(widget.ruleId!)))
          .getSingleOrNull();
      if (r == null || !mounted) return;
      setState(() {
        _rule = r;
        _matchCtrl.text = r.match;
        _titleCtrl.text = r.title ?? '';
        _categoryId = r.categoryId;
        _accountId = r.accountId;
      });
    } catch (e) {
      debugPrint('[Rules] Load failed: $e');
    }
  }

  @override
  void dispose() {
    _matchCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

  Future<void> _pickCategory() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CategorySheet(
        categories: ref.read(categoriesProvider).value ?? const <Category>[],
        selectedId: _categoryId,
        householdId: ref.read(currentHouseholdIdProvider),
        recentIds: recentCategoryIds(
            ref.read(transactionEntriesProvider).value ?? const []),
        onSelected: (id, name, color, txType) {
          Navigator.of(ctx).pop();
          if (mounted) setState(() => _categoryId = id);
        },
        onCreated: (_) {},
      ),
    );
  }

  Future<void> _pickAccount() async {
    final tr = S.of(context);
    final picked = await showAccountPickerSheet(context,
        accounts: (ref.read(accountsProvider).value ?? const <Account>[])
            .where((a) => !a.archived)
            .toList(),
        selectedId: _accountId,
        allLabel: tr.rulesKeep);
    if (picked == null || !mounted) return;
    setState(() => _accountId = picked.isEmpty ? null : picked);
  }

  Future<void> _save() async {
    final tr = S.of(context);
    final match = _matchCtrl.text.trim();
    if (match.isEmpty) {
      _snack(tr.rulesNeedMatch);
      return;
    }
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;
    final db = ref.read(databaseProvider);
    final title = _titleCtrl.text.trim();
    try {
      if (_rule == null) {
        await db.into(db.captureRules).insert(CaptureRulesCompanion.insert(
              id: const Uuid().v4(),
              householdId: householdId,
              match: match,
              categoryId: Value(_categoryId),
              accountId: Value(_accountId),
              title: Value(title.isEmpty ? null : title),
            ));
      } else {
        await (db.update(db.captureRules)
              ..where((r) => r.id.equals(_rule!.id)))
            .write(CaptureRulesCompanion(
          match: Value(match),
          categoryId: Value(_categoryId),
          accountId: Value(_accountId),
          title: Value(title.isEmpty ? null : title),
          // Edited by hand: it's the user's rule now.
          learned: const Value(false),
          lastModified: Value(DateTime.now()),
        ));
      }
      if (!mounted) return;
      _snack(tr.rulesSaved);
      context.pop();
    } catch (e) {
      debugPrint('[Rules] Save failed: $e');
      if (mounted) _snack(tr.commonSomethingWentWrong);
    }
  }

  Future<void> _delete() async {
    final tr = S.of(context);
    final db = ref.read(databaseProvider);
    try {
      await (db.update(db.captureRules)..where((r) => r.id.equals(_rule!.id)))
          .write(CaptureRulesCompanion(
              deleted: const Value(true), lastModified: Value(DateTime.now())));
      if (!mounted) return;
      _snack(tr.rulesDeleted);
      context.pop();
    } catch (e) {
      debugPrint('[Rules] Delete failed: $e');
      if (mounted) _snack(tr.commonSomethingWentWrong);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final category = (ref.watch(categoriesProvider).value ?? const <Category>[])
        .where((c) => c.id == _categoryId)
        .firstOrNull;
    final account = (ref.watch(accountsProvider).value ?? const <Account>[])
        .where((a) => a.id == _accountId)
        .firstOrNull;

    Widget row(IconData icon, String label, String value, VoidCallback onTap) =>
        Tappable(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Icon(icon, size: 20, color: AppColors.ts(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 12.5, color: AppColors.ts(context))),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(AppIcons.caretRight,
                  size: 18, color: AppColors.th(context)),
            ]),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(_rule == null ? tr.rulesAdd : tr.rulesEdit),
        actions: [
          if (_rule != null)
            IconButton(
              tooltip: tr.commonDelete,
              icon: const Icon(AppIcons.trash),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextField(
            controller: _matchCtrl,
            autofocus: _rule == null,
            decoration: InputDecoration(
                labelText: tr.rulesMatch, hintText: tr.rulesMatchHint),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: tr.rulesTitleField),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: AppColors.card(context),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              row(AppIcons.tag, tr.commonCategory,
                  category?.name ?? tr.rulesKeep, _pickCategory),
              row(AppIcons.wallet, tr.commonAccount,
                  account?.name ?? tr.rulesKeep, _pickAccount),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(children: [
        FilledButton(onPressed: _save, child: Text(tr.commonSave)),
      ]),
    );
  }
}
