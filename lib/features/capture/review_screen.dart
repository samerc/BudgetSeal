import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/capture/bank_alerts.dart';
import '../../core/capture/capture_rules.dart';
import '../../core/capture/share_intake.dart';
import '../../core/capture/text_reader.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/save_errors.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/tappable.dart';

/// One alert as it will be filled in.
typedef _Row = ({AlertItem item, CaptureDraft draft, String? categoryId});

const _cardsKey = 'review_cards';

/// "To review" (roadmap #2): payments read from bank notifications.
/// One card at a time (the default): swipe right adds it as read
/// ([saveAlertAsRead]; the form opens instead when something is missing),
/// swipe left skips it (Undo), tap opens the form. The list (Add / Dismiss
/// per row) is one tap away in the app bar.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  bool _cards = true;

  /// Swiped away, waiting for the inbox to catch up (a dismissed
  /// Dismissible must leave the tree at once).
  final _gone = <String>{};
  bool _saving = false;

  List<AlertItem>? _rowsOf;
  Future<List<_Row>>? _rowsFuture;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final v = prefs.getBool(_cardsKey);
      if (v != null && mounted) setState(() => _cards = v);
    }).catchError((_) {});
  }

  Future<void> _setCards(bool v) async {
    setState(() => _cards = v);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cardsKey, v);
    } catch (_) {}
  }

  Future<List<_Row>> _rows(List<AlertItem> items) {
    if (!identical(items, _rowsOf)) {
      _rowsOf = items;
      _rowsFuture = _readRows(items);
    }
    return _rowsFuture!;
  }

  Future<List<_Row>> _readRows(List<AlertItem> items) async {
    final db = ref.read(databaseProvider);
    final householdId = ref.read(currentHouseholdIdProvider) ?? '';
    final base = ref.read(householdProvider).value?.baseCurrency ?? 'USD';
    return [
      for (final item in items)
        await () async {
          final draft = readCapturedText(item.fullText,
              fallbackCurrency: base,
              amountIndex: await BankAlerts.amountIndex(item.app));
          final rule = await findCaptureRule(db, householdId,
              [draft.merchant ?? '', item.fullText].join(' '));
          return (item: item, draft: draft, categoryId: rule?.categoryId);
        }(),
    ];
  }

  /// The form, filled in; saving it removes the alert.
  Future<void> _add(AlertItem item) async {
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;
    try {
      final args = await alertFormArgs(item,
          db: ref.read(databaseProvider),
          householdId: householdId,
          baseCurrency:
              ref.read(householdProvider).value?.baseCurrency ?? 'USD');
      if (mounted) await context.push('/add-transaction', extra: args);
      ref.invalidate(alertInboxProvider);
    } catch (e) {
      debugPrint('[Review] Opening failed: $e');
    }
  }

  /// Adds it as read; false (and the form) when it can't be.
  Future<bool> _addAsRead(_Row r, {required String? categoryName}) async {
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null || _saving) return false;
    final tr = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final engine = ref.read(allocationEngineProvider);
    final inbox = ref.read(alertInboxProvider.notifier);
    _saving = true;
    try {
      final txId = await saveAlertAsRead(r.item,
          db: ref.read(databaseProvider),
          engine: engine,
          fx: ref.read(fxServiceProvider),
          householdId: householdId,
          baseCurrency:
              ref.read(householdProvider).value?.baseCurrency ?? 'USD');
      if (txId == null) {
        await _add(r.item);
        return false;
      }
      if (mounted) setState(() => _gone.add(r.item.id));
      ref.invalidate(alertInboxProvider);
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(categoryName == null
              ? tr.txFormSaved
              : tr.reviewAddedTo(categoryName)),
          behavior: SnackBarBehavior.floating,
          persist: false,
          action: SnackBarAction(
            label: tr.txUndoAction,
            onPressed: () async {
              try {
                await engine.deleteTransaction(txId);
                await inbox.undoDismiss(r.item);
                if (mounted) setState(() => _gone.remove(r.item.id));
              } catch (e) {
                debugPrint('[Review] Undo failed: $e');
              }
            },
          ),
        ));
      return true;
    } catch (e) {
      debugPrint('[Review] Adding as read failed: $e');
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(txSaveErrorText(tr, e)),
          behavior: SnackBarBehavior.floating,
        ));
      return false;
    } finally {
      _saving = false;
    }
  }

  void _dismiss(AlertItem item) {
    final tr = S.of(context);
    final inbox = ref.read(alertInboxProvider.notifier);
    setState(() => _gone.add(item.id));
    inbox.dismiss(item);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(tr.reviewDismissed),
        behavior: SnackBarBehavior.floating,
        persist: false,
        action: SnackBarAction(
            label: tr.txUndoAction,
            onPressed: () async {
              await inbox.undoDismiss(item);
              if (mounted) setState(() => _gone.remove(item.id));
            }),
      ));
  }

  String _amountText(S tr, CaptureDraft d) => d.amount == null
      ? tr.reviewNoAmount
      : formatSignedAmount(d.amount!, currency: d.currency ?? '', type: d.type);

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final all = ref.watch(alertInboxProvider).value ?? const <AlertItem>[];
    // Forget swiped ids the inbox no longer has.
    _gone.retainAll({for (final i in all) i.id});
    final cats = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c.name
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(tr.reviewTitle),
        actions: [
          IconButton(
            tooltip: _cards ? tr.reviewShowList : tr.reviewShowCards,
            icon: Icon(_cards ? AppIcons.rows : AppIcons.cards),
            onPressed: () => _setCards(!_cards),
          ),
        ],
      ),
      body: FutureBuilder<List<_Row>>(
        future: _rows(all),
        builder: (context, snap) {
          final rows = [
            for (final r in snap.data ?? const <_Row>[])
              if (!_gone.contains(r.item.id)) r
          ];
          final empty = all.every((i) => _gone.contains(i.id));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Text(_cards ? tr.reviewSwipeHint : tr.reviewIntro,
                    style:
                        TextStyle(fontSize: 13.5, color: AppColors.ts(context))),
              ),
              if (empty)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child:
                      EmptyState(icon: AppIcons.tray, title: tr.reviewEmpty),
                )
              else if (_cards && rows.isNotEmpty)
                ..._cardView(tr, rows, cats)
              else if (!_cards)
                for (final r in rows) _listRow(tr, r, cats),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _cardView(S tr, List<_Row> rows, Map<String, String> cats) {
    final r = rows.first;
    final category = cats[r.categoryId];
    final next = rows.length > 1 ? rows[1] : null;
    return [
      Padding(
        padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
        child: Text(tr.reviewOneOf(1, rows.length),
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.th(context))),
      ),
      Dismissible(
        key: ValueKey('review-${r.item.id}'),
        background: _swipeBg(AppIcons.check, tr.reviewAdd, AppColors.healthy,
            AlignmentDirectional.centerStart),
        secondaryBackground: _swipeBg(AppIcons.x, tr.reviewSkip,
            AppColors.ts(context), AlignmentDirectional.centerEnd),
        confirmDismiss: (dir) async {
          if (dir == DismissDirection.endToStart) return true;
          return _addAsRead(r, categoryName: category);
        },
        onDismissed: (dir) {
          if (dir == DismissDirection.endToStart) _dismiss(r.item);
        },
        child: Tappable(
          onTap: () => _add(r.item),
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: AppColors.card(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${r.item.appName} · ${formatDateSmart(r.item.at)}',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.th(context))),
                const SizedBox(height: 10),
                if (r.draft.merchant != null)
                  Text(r.draft.merchant!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                Text(_amountText(tr, r.draft),
                    style: const TextStyle(
                        fontFamily: TypographyTokens.displayFamily,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        fontFeatures: [FontFeature.tabularFigures()])),
                const SizedBox(height: 8),
                Text(
                  category ?? tr.reviewNoCategory,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: category == null
                          ? AppColors.ts(context)
                          : AppColors.accentText(context)),
                ),
                const SizedBox(height: 10),
                Text(r.item.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 12.5, color: AppColors.ts(context))),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _dismiss(r.item),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            child: Text(tr.reviewSkip),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _add(r.item),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            child: Text(tr.commonEdit),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            onPressed: () => _addAsRead(r, categoryName: category),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            child: Text(tr.reviewAdd),
          ),
        ),
      ]),
      if (next != null)
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 14, 4, 0),
          child: Text(
            tr.reviewNext([
              if (next.draft.merchant != null) next.draft.merchant!,
              _amountText(tr, next.draft),
            ].join(' · ')),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: AppColors.th(context)),
          ),
        ),
    ];
  }

  Widget _swipeBg(
      IconData icon, String label, Color color, AlignmentDirectional align) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: align,
      decoration: BoxDecoration(
        color: AppColors.pastel(context, color, light: 0.86, dark: 0.74),
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }

  Widget _listRow(S tr, _Row r, Map<String, String> cats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      decoration: AppColors.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${r.item.appName} · ${formatDateSmart(r.item.at)}',
            style: TextStyle(fontSize: 12, color: AppColors.th(context)),
          ),
          const SizedBox(height: 4),
          Text(
            _amountText(tr, r.draft),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          Text(
            [
              if (r.draft.merchant != null) r.draft.merchant!,
              if (cats[r.categoryId] case final c?) c,
            ].join(' · '),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(r.item.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: AppColors.ts(context))),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _dismiss(r.item),
                style: TextButton.styleFrom(minimumSize: const Size(0, 40)),
                child: Text(tr.reviewDismiss),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _add(r.item),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                child: Text(tr.reviewAdd),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Home: "N payments to review" while bank alerts wait (Android).
class ReviewAlertsCard extends ConsumerWidget {
  const ReviewAlertsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!BankAlerts.supported) return const SizedBox.shrink();
    final n = ref.watch(alertInboxProvider).value?.length ?? 0;
    if (n == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Tappable(
        onTap: () => context.push('/review'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Icon(AppIcons.tray, size: 20, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(S.of(context).reviewCard(n),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent)),
            ),
            Icon(AppIcons.caretRight, size: 18, color: AppColors.accent),
          ]),
        ),
      ),
    );
  }
}
