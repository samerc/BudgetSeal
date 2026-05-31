import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/engine/balance_calculator.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/currency_display.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/skeleton_loader.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  bool _showArchived = false;
  String _sortBy = 'name'; // 'name', 'balance', 'type'

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsWithBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).acctTitle),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded,
                color: AppColors.tp(context)),
            onSelected: (v) {
              if (v == 'archived') {
                setState(() => _showArchived = !_showArchived);
              } else if (v == 'sort_name' || v == 'sort_balance' || v == 'sort_type') {
                setState(() => _sortBy = v.replaceFirst('sort_', ''));
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'archived',
                child: Row(children: [
                  Icon(
                    _showArchived
                        ? Icons.visibility_off_rounded
                        : Icons.archive_rounded,
                    size: 18,
                    color: AppColors.ts(context),
                  ),
                  const SizedBox(width: 10),
                  Text(_showArchived
                      ? S.of(context).acctHideArchived
                      : S.of(context).acctShowArchived),
                ]),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'sort_name',
                child: Row(children: [
                  Icon(Icons.sort_by_alpha_rounded, size: 18,
                      color: _sortBy == 'name' ? AppColors.accent : AppColors.ts(context)),
                  const SizedBox(width: 10),
                  Text(S.of(context).acctSortByName,
                      style: TextStyle(
                        fontWeight: _sortBy == 'name' ? FontWeight.w700 : FontWeight.w400,
                      )),
                ]),
              ),
              PopupMenuItem(
                value: 'sort_balance',
                child: Row(children: [
                  Icon(Icons.account_balance_wallet_rounded, size: 18,
                      color: _sortBy == 'balance' ? AppColors.accent : AppColors.ts(context)),
                  const SizedBox(width: 10),
                  Text(S.of(context).acctSortByBalance,
                      style: TextStyle(
                        fontWeight: _sortBy == 'balance' ? FontWeight.w700 : FontWeight.w400,
                      )),
                ]),
              ),
              PopupMenuItem(
                value: 'sort_type',
                child: Row(children: [
                  Icon(Icons.category_rounded, size: 18,
                      color: _sortBy == 'type' ? AppColors.accent : AppColors.ts(context)),
                  const SizedBox(width: 10),
                  Text(S.of(context).acctSortByType,
                      style: TextStyle(
                        fontWeight: _sortBy == 'type' ? FontWeight.w700 : FontWeight.w400,
                      )),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(accountsWithBalanceProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: accountsAsync.when(
          data: (accounts) {
            if (accounts.isEmpty && !_showArchived) {
              return ListView(
                children: [
                  const SizedBox(height: 200),
                  EmptyState(
                    icon: Icons.credit_card_rounded,
                    title: S.of(context).acctNoYet,
                    subtitle: S.of(context).acctTapPlus,
                  ),
                ],
              );
            }

            // Compute total balance per currency (active accounts only)
            final Map<String, double> totals = {};
            for (final ab in accounts) {
              totals[ab.account.currency] =
                  (totals[ab.account.currency] ?? 0) + ab.balance;
            }

            // Apply sort
            final sorted = List.of(accounts);
            switch (_sortBy) {
              case 'balance':
                sorted.sort((a, b) => b.balance.compareTo(a.balance));
              case 'type':
                sorted.sort((a, b) => a.account.type.compareTo(b.account.type));
              default:
                // already sorted by name from provider
                break;
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
              children: [
                // Total balance header
                _TotalBalanceCard(totals: totals),
                const SizedBox(height: 16),
                ...sorted.map((ab) => _AccountTile(
                      accountWithBalance: ab,
                      onTap: () => context.push('/accounts/${ab.account.id}'),
                    )),
                if (_showArchived) _ArchivedSection(ref: ref),
              ],
            );
          },
          loading: () => const SkeletonList(),
          error: (e, _) => ErrorRetry(
            message: S.of(context).acctCouldntLoad,
            details: '$e',
            onRetry: () => ref.invalidate(accountsWithBalanceProvider),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_accounts',
        tooltip: S.of(context).acctAddTooltip,
        onPressed: () => context.push('/accounts/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Shows archived accounts in a separate section below active ones.
class _ArchivedSection extends ConsumerWidget {
  final WidgetRef ref;
  const _ArchivedSection({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final householdId = ref.watch(currentHouseholdIdProvider);
    if (householdId == null) return const SizedBox.shrink();

    return FutureBuilder<List<AccountWithBalance>>(
      future: _loadArchived(db, householdId),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.accent),
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Center(
              child: Text(S.of(context).acctNoArchived,
                  style: TextStyle(
                      color: AppColors.ts(context), fontSize: 13)),
            ),
          );
        }

        final archived = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(S.of(context).acctArchived,
                  style: TextStyle(
                    fontSize: TypographyTokens.sectionHeaderSize,
                    fontWeight: TypographyTokens.sectionHeaderWeight,
                    letterSpacing: TypographyTokens.sectionHeaderLetterSpacing,
                    color: AppColors.th(context),
                  )),
            ),
            ...archived.map((ab) => _ArchivedAccountTile(
                  accountWithBalance: ab,
                  onTap: () =>
                      context.push('/accounts/${ab.account.id}'),
                  onUnarchive: () => _unarchive(context, ref, ab.account),
                )),
          ],
        );
      },
    );
  }

  Future<List<AccountWithBalance>> _loadArchived(
      AppDatabase db, String householdId) async {
    final accounts = await (db.select(db.accounts)
          ..where((t) =>
              t.householdId.equals(householdId) & t.archived.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    if (accounts.isEmpty) return [];
    final calculator = BalanceCalculator(db);
    final balances = await calculator.allAccountBalances(householdId);
    return [
      for (final acc in accounts)
        AccountWithBalance(
            account: acc, balance: balances[acc.id] ?? 0),
    ];
  }

  Future<void> _unarchive(
      BuildContext context, WidgetRef ref, Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).acctUnarchiveTitle),
        content: Text(
            S.of(context).acctUnarchiveMsg(account.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.of(context).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.of(context).acctUnarchive),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final db = ref.read(databaseProvider);
    await (db.update(db.accounts)
          ..where((a) => a.id.equals(account.id)))
        .write(AccountsCompanion(
      archived: const Value(false),
      lastModified: Value(DateTime.now()),
    ));
    ref.invalidate(accountsWithBalanceProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).acctUnarchived(account.name)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _TotalBalanceCard extends StatelessWidget {
  final Map<String, double> totals;
  const _TotalBalanceCard({required this.totals});

  @override
  Widget build(BuildContext context) {
    if (totals.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF2A3F6A)],
        ),
        borderRadius: BorderRadius.circular(CardTokens.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.of(context).acctTotalBalance,
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 10),
          ...totals.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e.key,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        formatAmount(e.value),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final AccountWithBalance accountWithBalance;
  final VoidCallback onTap;

  const _AccountTile({
    required this.accountWithBalance,
    required this.onTap,
  });

  IconData _accountIcon(String type) => switch (type) {
        'bank' => Icons.account_balance_rounded,
        'credit' => Icons.credit_card_rounded,
        'wallet' => Icons.account_balance_wallet_rounded,
        _ => Icons.money_rounded,
      };

  Color _typeColor(String type) => switch (type) {
        'bank' => const Color(0xFF1565C0),
        'credit' => const Color(0xFFE65100),
        'wallet' => AppColors.accent,
        _ => AppColors.healthy,
      };

  @override
  Widget build(BuildContext context) {
    final acc = accountWithBalance.account;
    final balance = accountWithBalance.balance;
    final color = _typeColor(acc.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_accountIcon(acc.type), color: color, size: 20),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                acc.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.tp(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (acc.isTravel) ...[
              const SizedBox(width: 6),
              Icon(Icons.flight_rounded, size: 14,
                  color: AppColors.accent),
            ],
          ],
        ),
        subtitle: Text(
          acc.isTravel
              ? S.of(context).acctTravelWallet(acc.currency)
              : '${acc.type[0].toUpperCase()}${acc.type.substring(1)} \u00b7 ${acc.currency}',
          style:
              TextStyle(color: AppColors.ts(context), fontSize: 12),
        ),
        trailing: CurrencyDisplay(
          amount: balance,
          currency: acc.currency,
        ),
      ),
    );
  }
}

class _ArchivedAccountTile extends StatelessWidget {
  final AccountWithBalance accountWithBalance;
  final VoidCallback onTap;
  final VoidCallback onUnarchive;

  const _ArchivedAccountTile({
    required this.accountWithBalance,
    required this.onTap,
    required this.onUnarchive,
  });

  IconData _accountIcon(String type) => switch (type) {
        'bank' => Icons.account_balance_rounded,
        'credit' => Icons.credit_card_rounded,
        'wallet' => Icons.account_balance_wallet_rounded,
        _ => Icons.money_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final acc = accountWithBalance.account;
    final balance = accountWithBalance.balance;

    return Opacity(
      opacity: 0.6,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: BorderRadius.circular(CardTokens.radius),
          border: Border.all(color: AppColors.bd(context)),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          onTap: onTap,
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.ts(context).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_accountIcon(acc.type),
                color: AppColors.ts(context), size: 20),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  acc.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.tp(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.archive_rounded, size: 14,
                  color: AppColors.th(context)),
              if (acc.isTravel) ...[
                const SizedBox(width: 4),
                Icon(Icons.flight_rounded, size: 14,
                    color: AppColors.th(context)),
              ],
            ],
          ),
          subtitle: Text(
            '${acc.type[0].toUpperCase()}${acc.type.substring(1)} · ${acc.currency}',
            style: TextStyle(color: AppColors.ts(context), fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CurrencyDisplay(
                amount: balance,
                currency: acc.currency,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.unarchive_rounded,
                    size: 20, color: AppColors.accent),
                tooltip: S.of(context).acctUnarchive,
                onPressed: onUnarchive,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
