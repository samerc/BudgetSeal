import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capture/capture_rules.dart';
import '../../core/capture/statement_match.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/ocr_service.dart';

/// Check an account against a screenshot of the bank's transaction list
/// (roadmap #2): rows read on the phone, matched by amount and direction
/// with what's recorded on the account in the last 90 days; the missing
/// ones can be added (filled in, rules applied).
class StatementCheckScreen extends ConsumerStatefulWidget {
  final String accountId;
  final String imagePath;
  const StatementCheckScreen(
      {super.key, required this.accountId, required this.imagePath});

  @override
  ConsumerState<StatementCheckScreen> createState() =>
      _StatementCheckScreenState();
}

class _StatementCheckScreenState extends ConsumerState<StatementCheckScreen> {
  List<StatementRow>? _rows;
  StatementMatch? _match;
  Account? _account;

  @override
  void initState() {
    super.initState();
    _read();
  }

  Future<void> _read() async {
    try {
      final db = ref.read(databaseProvider);
      _account = await (db.select(db.accounts)
            ..where((a) => a.id.equals(widget.accountId)))
          .getSingle();
      final ocr = await OcrService.scanReceipt(widget.imagePath,
          currency: _account!.currency);
      _rows = statementRows(ocr);
      await _rematch();
    } catch (e) {
      debugPrint('[StatementCheck] Reading failed: $e');
      if (mounted) setState(() => _rows = const []);
    }
  }

  Future<void> _rematch() async {
    final booked = await bookedOnAccount(ref.read(databaseProvider),
        widget.accountId, DateTime.now().subtract(const Duration(days: 90)));
    if (mounted) setState(() => _match = matchStatement(_rows!, booked));
  }

  /// The form, filled in from the row (a rule for its name gives the
  /// category and title); back here, the match is redone.
  Future<void> _add(StatementRow row) async {
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null || _account == null) return;
    final rule =
        await findCaptureRule(ref.read(databaseProvider), householdId, row.name);
    if (!mounted) return;
    await context.push('/add-transaction', extra: {
      'editType': row.income ? 'income' : 'expense',
      'editNote': rule?.title ?? row.name,
      'editLines': [
        {
          'amount': row.amount,
          'currency': _account!.currency,
          'accountId': _account!.id,
          'categoryId': rule?.categoryId,
          'note': '',
        },
      ],
      'capture': {'shop': row.name},
    });
    await _rematch();
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final match = _match;
    final cur = _account?.currency;
    String money(StatementRow r) => formatSignedAmount(r.amount,
        currency: cur ?? '', type: r.income ? 'income' : 'expense');

    Widget header(String text) => Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 16, 4, 8),
          child: Text(text,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        );

    return Scaffold(
      appBar: AppBar(title: Text(tr.shotTitle)),
      body: match == null && (_rows == null || _rows!.isNotEmpty)
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(tr.shotReading,
                    style: TextStyle(color: AppColors.ts(context))),
              ]),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                  child: Text(tr.shotIntro(_account?.name ?? ''),
                      style: TextStyle(
                          fontSize: 13.5, color: AppColors.ts(context))),
                ),
                if (_rows!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(tr.shotNone,
                        style: TextStyle(color: AppColors.ts(context))),
                  )
                else ...[
                  header(tr.shotMissing),
                  if (match!.missing.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(children: [
                        const Icon(AppIcons.checkCircle,
                            size: 18, color: AppColors.healthy),
                        const SizedBox(width: 8),
                        Expanded(child: Text(tr.shotAllMatched)),
                      ]),
                    )
                  else
                    Container(
                      decoration: AppColors.card(context),
                      clipBehavior: Clip.antiAlias,
                      child: Column(children: [
                        for (final r in match.missing)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                            child: Row(children: [
                              Expanded(
                                child: Text(r.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 8),
                              Text(money(r),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () => _add(r),
                                style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 36)),
                                child: Text(tr.reviewAdd),
                              ),
                            ]),
                          ),
                      ]),
                    ),
                  if (match.matched.isNotEmpty) ...[
                    header(tr.shotMatched),
                    Container(
                      decoration: AppColors.card(context),
                      clipBehavior: Clip.antiAlias,
                      child: Column(children: [
                        for (final (r, b) in match.matched)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(children: [
                              const Icon(AppIcons.checkCircle,
                                  size: 18, color: AppColors.healthy),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                    b.title.isNotEmpty ? b.title : r.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Text(money(r),
                                  style: TextStyle(
                                      color: AppColors.ts(context))),
                            ]),
                          ),
                      ]),
                    ),
                  ],
                ],
              ],
            ),
    );
  }
}
