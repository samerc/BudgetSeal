import 'package:flutter/material.dart';

import '../../core/providers/date_format_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';

/// Shared wording and widgets for recurring items (Recurring, Subscriptions,
/// Upcoming bills, Planned payments) so the same thing reads the same way
/// on every screen.

/// "Monthly", "Every 2 weeks"… An unknown frequency advances 30 days per
/// interval in the engine, so it reads as "Every 30 days".
String recurringFrequencyLabel(S tr, String frequency, int interval) {
  final n = interval > 0 ? interval : 1;
  if (n == 1) {
    return switch (frequency) {
      'daily' => tr.freqDaily,
      'weekly' => tr.freqWeekly,
      'monthly' => tr.freqMonthly,
      'yearly' => tr.freqYearly,
      _ => tr.freqEveryNDays(30),
    };
  }
  return switch (frequency) {
    'daily' => tr.freqEveryNDays(n),
    'weekly' => tr.freqEveryNWeeks(n),
    'monthly' => tr.freqEveryNMonths(n),
    'yearly' => tr.freqEveryNYears(n),
    _ => tr.freqEveryNDays(30 * n),
  };
}

/// The per-period suffix after a price: "/month", "/2 weeks"…
String recurringPriceSuffix(S tr, String frequency, int interval) {
  final n = interval > 0 ? interval : 1;
  if (n == 1) {
    return switch (frequency) {
      'daily' => tr.subFreqDay,
      'weekly' => tr.subFreqWeek,
      'yearly' => tr.subFreqYear,
      'monthly' => tr.subFreqMonth,
      _ => tr.subFreqDays(30),
    };
  }
  return switch (frequency) {
    'daily' => tr.subFreqDays(n),
    'weekly' => tr.subFreqWeeks(n),
    'monthly' => tr.subFreqMonths(n),
    'yearly' => tr.subFreqYears(n),
    _ => tr.subFreqDays(30 * n),
  };
}

/// The row subtitle: "Next: 5 Nov · Monthly" (just the frequency without a
/// next date).
String recurringNextLine(
    S tr, DateTime? nextDue, String frequency, int interval) {
  final freq = recurringFrequencyLabel(tr, frequency, interval);
  if (nextDue == null) return freq;
  return '${tr.recurringTileNext(formatDate(nextDue))} · $freq';
}

/// Average monthly cost of [amount] charged every [interval] [frequency].
double recurringMonthlyEquivalent(
    double amount, String frequency, int interval) {
  final iv = interval > 0 ? interval : 1; // guard malformed interval (÷0)
  return switch (frequency) {
    'daily' => amount * (30.0 / iv),
    'weekly' => amount * (52.0 / (12.0 * iv)),
    'monthly' => amount / iv,
    'yearly' => amount / (12.0 * iv),
    _ => amount,
  };
}

/// One stat in a summary strip: colored icon, bold number, caption.
class SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;

  const SummaryChip({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.tp(context))),
        const SizedBox(width: 4),
        Text(subtitle,
            style: TextStyle(
                fontSize: TypographyTokens.captionSize,
                color: AppColors.ts(context))),
      ],
    );
  }
}

/// The quiet surface-variant strip that holds [SummaryChip]s under a list
/// screen's header.
class SummaryStrip extends StatelessWidget {
  final List<Widget> chips;
  const SummaryStrip({super.key, required this.chips});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sfv(context),
        borderRadius: CardTokens.borderRadius,
      ),
      child: Wrap(spacing: 16, runSpacing: 8, children: chips),
    );
  }
}

/// A subscription's status: 'cancelled' once its end (cancellation) date has
/// passed, 'paused' while switched off, 'ending_soon' within 30 days of the
/// end date, else 'active'. Pausing is not cancelling.
String subscriptionStatus({required bool enabled, DateTime? endDate}) {
  final now = DateTime.now();
  if (endDate != null && endDate.isBefore(now)) return 'cancelled';
  if (!enabled) return 'paused';
  if (endDate != null && endDate.difference(now).inDays <= 30) {
    return 'ending_soon';
  }
  return 'active';
}

/// Dot color for a [subscriptionStatus] (paused is grey, like Recurring).
Color subscriptionStatusColor(BuildContext context, String status) =>
    switch (status) {
      'ending_soon' => AppColors.caution,
      'cancelled' => AppColors.overspent,
      'paused' => AppColors.th(context),
      _ => AppColors.healthy,
    };

/// Label for a [subscriptionStatus].
String subscriptionStatusLabel(S tr, String status) => switch (status) {
      'ending_soon' => tr.subEndingSoon,
      'cancelled' => tr.subCancelled,
      'paused' => tr.recurringStatusPaused,
      _ => tr.subActive,
    };

/// One recurring item as a card row (Recurring, Subscriptions): name and
/// amount on top, the next date under it at full width, a status line only
/// when it isn't simply active (paused, cancelled, ending soon), and the
/// pause/resume button at the end. Long amounts (LBP 1,800,000) shrink
/// instead of squeezing the name or the date.
class RecurringRow extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget amount;
  final String subtitle;
  final Widget? status;
  final Widget toggle;
  final VoidCallback onTap;

  const RecurringRow({
    super.key,
    required this.leading,
    required this.title,
    required this.amount,
    required this.subtitle,
    this.status,
    required this.toggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppColors.card(context, radius: CardTokens.radius),
      child: Material(
        // Transparent Material so the ripple paints above the card fill.
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: CardTokens.borderRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 6, 10),
            child: Row(children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: title),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: amount,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: TypographyTokens.txSubtitleSize,
                            color: AppColors.ts(context))),
                    if (status != null) ...[
                      const SizedBox(height: 4),
                      status!,
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              toggle,
            ]),
          ),
        ),
      ),
    );
  }
}
