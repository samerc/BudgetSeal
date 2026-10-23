import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../reports_hub_screen.dart' show LegacyReportPage;
import 'budget_report.dart';
import 'list_reports.dart';
import 'money_report.dart';
import 'places_report.dart';
import 'spending_report.dart';
import 'year_report.dart';

/// `/reports/view/:id` — one report from the Reports library.
class ReportView extends StatelessWidget {
  final String id;
  const ReportView({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    return switch (id) {
      'budget' => const BudgetReport(),
      'spending' => const SpendingReport(),
      'places' => const PlacesReport(),
      'biggest' => const BiggestReport(),
      'money' => const MoneyReport(),
      'accounts' => const AccountsReport(),
      'currencies' => const CurrenciesReport(),
      'subscriptions' => const SubscriptionsReport(),
      'year' => const YearReport(),
      'categories' => LegacyReportPage(id: id, title: tr.rptCategories),
      'insights' => LegacyReportPage(id: id, title: tr.rptInsights),
      'balance' => LegacyReportPage(id: id, title: tr.rptBalanceSheet),
      _ => LegacyReportPage(id: 'overview', title: tr.rptOverview),
    };
  }
}
