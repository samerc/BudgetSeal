import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/accounts_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/currency_display.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/skeleton_loader.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsWithBalanceProvider);

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Accounts'),
        
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(accountsWithBalanceProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: accountsAsync.when(
          data: (accounts) {
            if (accounts.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 200),
                  EmptyState(
                    icon: Icons.credit_card_rounded,
                    title: 'No accounts yet',
                    subtitle: 'Tap + to add one',
                  ),
                ],
              );
            }

            // Compute total balance per currency
            final Map<String, double> totals = {};
            for (final ab in accounts) {
              totals[ab.account.currency] =
                  (totals[ab.account.currency] ?? 0) + ab.balance;
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
              children: [
                // Total balance header
                _TotalBalanceCard(totals: totals),
                const SizedBox(height: 16),
                ...accounts.map((ab) => _AccountTile(
                      accountWithBalance: ab,
                      onTap: () => context.push('/accounts/${ab.account.id}'),
                    )),
              ],
            );
          },
          loading: () => const SkeletonList(),
          error: (e, _) => ErrorRetry(
            message: "Couldn't load your data",
            details: '$e',
            onRetry: () => ref.invalidate(accountsWithBalanceProvider),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_accounts',
        tooltip: 'Add account',
        onPressed: () => context.push('/accounts/new'),
        child: const Icon(Icons.add),
      ),
    );
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
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Balance',
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
        borderRadius: BorderRadius.circular(14),
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
        title: Text(
          acc.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.tp(context),
          ),
        ),
        subtitle: Text(
          '${acc.type[0].toUpperCase()}${acc.type.substring(1)} · ${acc.currency}',
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
