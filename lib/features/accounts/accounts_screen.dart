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
import '../../core/providers/premium_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/large_title_header.dart';
import '../../shared/widgets/section_header.dart';
import 'account_type.dart';
import 'widgets/balance_hero.dart';

export 'account_type.dart' show accountTypeLabel;

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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(accountsWithBalanceProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: CustomScrollView(
          slivers: [
            LargeTitleHeader(
              title: S.of(context).acctTitle,
              back: true,
              actions: [_menu(context)],
            ),
            ...accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty && !_showArchived) {
                  return [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: AppIcons.creditCard,
                        title: S.of(context).acctNoYet,
                        subtitle: S.of(context).acctTapPlus,
                      ),
                    ),
                  ];
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
                    sorted.sort(
                        (a, b) => a.account.type.compareTo(b.account.type));
                  default:
                    // already sorted by name from provider
                    break;
                }

                return [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Total balance header
                        _TotalBalanceCard(totals: totals),
                        const SizedBox(height: 16),
                        ...sorted.map((ab) => _AccountTile(
                              accountWithBalance: ab,
                              onTap: () =>
                                  context.push('/accounts/${ab.account.id}'),
                            )),
                        if (_showArchived) _ArchivedSection(ref: ref),
                      ]),
                    ),
                  ),
                ];
              },
              loading: () =>
                  [const SliverToBoxAdapter(child: SkeletonList())],
              error: (e, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorRetry(
                    message: S.of(context).commonCouldntLoadData,
                    details: '$e',
                    onRetry: () => ref.invalidate(accountsWithBalanceProvider),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_accounts',
        tooltip: S.of(context).acctAddTooltip,
        onPressed: () {
          final accounts = ref.read(accountsWithBalanceProvider).value ?? [];
          if (!checkFreeLimit(context, ref, accounts.length, FreeLimits.maxAccounts, 'accounts')) return;
          context.push('/accounts/new');
        },
        child: const Icon(AppIcons.plus),
      ),
    );
  }

  Widget _menu(BuildContext context) {
    PopupMenuItem<String> sortItem(String value, IconData icon, String label) {
      final on = _sortBy == value.replaceFirst('sort_', '');
      return PopupMenuItem(
        value: value,
        child: Row(children: [
          Icon(icon,
              size: 18, color: on ? AppColors.accent : AppColors.ts(context)),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontWeight: on ? FontWeight.w700 : FontWeight.w400)),
        ]),
      );
    }

    return PopupMenuButton<String>(
      icon: Icon(AppIcons.dotsThreeVertical, color: AppColors.ts(context)),
      onSelected: (v) {
        if (v == 'archived') {
          setState(() => _showArchived = !_showArchived);
        } else if (v.startsWith('sort_')) {
          setState(() => _sortBy = v.replaceFirst('sort_', ''));
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'archived',
          child: Row(children: [
            Icon(
              _showArchived ? AppIcons.eyeSlash : AppIcons.archive,
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
        sortItem('sort_name', AppIcons.sortAscending,
            S.of(context).acctSortByName),
        sortItem('sort_balance', AppIcons.wallet,
            S.of(context).acctSortByBalance),
        sortItem('sort_type', AppIcons.squaresFour,
            S.of(context).acctSortByType),
      ],
    );
  }
}

//// Shows archived accounts in a separate section below active ones.
class _ArchivedSection extends ConsumerWidget {
  final WidgetRef ref;
  const _ArchivedSection({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final householdId = ref.watch(currentHouseholdIdProvider);
    if (householdId == null) return const SizedBox.shrink();

    return FutureBuilder<List<AccountWithBalance>>(
      future: _loadArchived(db, householdId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting &&
            !snap.hasData) {
          return const SkeletonList(count: 2);
        }
        if (snap.hasError) {
          return ErrorRetry(
            message: S.of(context).commonCouldntLoadAccounts,
            details: '${snap.error}',
            onRetry: () => ref.invalidate(accountsWithBalanceProvider),
          );
        }
        if (!snap.hasData || snap.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: Spacing.sm),
            child: EmptyState(
              icon: AppIcons.archive,
              title: S.of(context).acctNoArchived,
            ),
          );
        }

        final archived = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: Spacing.lg),
            SectionHeader(S.of(context).acctArchived,
                padding: const EdgeInsetsDirectional.only(
                    start: 4, bottom: Spacing.headerToCard)),
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
              t.householdId.equals(householdId) &
              t.archived.equals(true) &
              t.deleted.equals(false))
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
    final tr = S.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: tr.acctUnarchiveConfirmTitle,
      message: tr.acctUnarchiveMsg(account.name),
      confirmLabel: tr.acctUnarchive,
      destructive: false,
    );
    if (!confirmed || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final db = ref.read(databaseProvider);
      await (db.update(db.accounts)
            ..where((a) => a.id.equals(account.id)))
          .write(AccountsCompanion(
        archived: const Value(false),
        lastModified: Value(DateTime.now()),
      ));
      ref.invalidate(accountsWithBalanceProvider);
      messenger.showSnackBar(SnackBar(
        content: Text(tr.acctUnarchived(account.name)),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      debugPrint('[Accounts] Unarchive failed: $e');
      messenger.showSnackBar(SnackBar(
        content: Text(tr.commonSomethingWentWrong),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

class _TotalBalanceCard extends StatelessWidget {
  final Map<String, double> totals;
  const _TotalBalanceCard({required this.totals});

  @override
  Widget build(BuildContext context) {
    if (totals.isEmpty) return const SizedBox.shrink();

    return BalanceHero(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.of(context).acctTotalBalance,
              style: balanceHeroLabelStyle(context)),
          const SizedBox(height: Spacing.sm),
          ...totals.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: Spacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: balanceHeroLabelStyle(context)),
                    const SizedBox(width: Spacing.sm),
                    // Large amounts shrink to one line instead of wrapping.
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(
                          formatAmount(e.value, currency: e.key),
                          style:
                              balanceHeroAmountStyle(context, value: e.value),
                          maxLines: 1,
                        ),
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

  @override
  Widget build(BuildContext context) {
    final acc = accountWithBalance.account;
    return AppCard(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: _AccountRow(
        account: acc,
        balance: accountWithBalance.balance,
        subtitle: acc.isTravel
            ? S.of(context).acctTravelWallet(acc.currency)
            : '${accountTypeLabel(S.of(context), acc.type)} · ${acc.currency}',
        badges: [
          if (acc.isTravel)
            Icon(AppIcons.airplane, size: 14, color: AppColors.accent),
        ],
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

  @override
  Widget build(BuildContext context) {
    final acc = accountWithBalance.account;
    return Opacity(
      opacity: 0.6,
      child: AppCard(
        margin: const EdgeInsets.only(bottom: Spacing.sm),
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: _AccountRow(
          account: acc,
          balance: accountWithBalance.balance,
          muted: true,
          subtitle:
              '${accountTypeLabel(S.of(context), acc.type)} · ${acc.currency}',
          badges: [
            Icon(AppIcons.archive, size: 14, color: AppColors.th(context)),
            if (acc.isTravel)
              Icon(AppIcons.airplane, size: 14, color: AppColors.th(context)),
          ],
          trailing: IconButton(
            icon: Icon(AppIcons.boxArrowUp, size: 20, color: AppColors.accent),
            tooltip: S.of(context).acctUnarchive,
            onPressed: onUnarchive,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    );
  }
}

/// One account row: type badge, name (+ small badges), type · currency,
/// balance on the end.
class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.balance,
    required this.subtitle,
    this.badges = const [],
    this.muted = false,
    this.trailing,
  });

  final Account account;
  final double balance;
  final String subtitle;
  final List<Widget> badges;
  final bool muted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
          CardTokens.paddingH, 12, CardTokens.paddingH - 4, 12),
      child: Row(
        children: [
          AccountTypeBadge(account.type,
              size: CategoryIconTokens.compactSize, muted: muted),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        account.name,
                        style: TextStyle(
                          fontWeight: TypographyTokens.txTitleWeight,
                          fontSize: TypographyTokens.txTitleSize,
                          color: AppColors.tp(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    for (final b in badges) ...[
                      const SizedBox(width: Spacing.xs + 2),
                      b,
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                      color: AppColors.ts(context),
                      fontSize: TypographyTokens.txSubtitleSize),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          CurrencyDisplay(amount: balance, currency: account.currency),
          if (trailing != null) ...[const SizedBox(width: 4), trailing!],
        ],
      ),
    );
  }
}
