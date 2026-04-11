import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/format_number.dart';

enum BalanceStatus { healthy, caution, overspent, neutral }

class BalanceChip extends StatelessWidget {
  final double balance;
  final double? target;
  final String currency;

  const BalanceChip({
    super.key,
    required this.balance,
    this.target,
    required this.currency,
  });

  BalanceStatus get _status {
    if (balance < 0) return BalanceStatus.overspent;
    if (target != null && balance < target! * 0.2) return BalanceStatus.caution;
    return BalanceStatus.healthy;
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (_status) {
      BalanceStatus.healthy => (AppColors.healthyLight, AppColors.healthy),
      BalanceStatus.caution => (AppColors.cautionLight, AppColors.caution),
      BalanceStatus.overspent => (AppColors.overspentLight, AppColors.overspent),
      BalanceStatus.neutral => (AppColors.surfaceVariant, AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        formatAmount(balance, currency: currency),
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
