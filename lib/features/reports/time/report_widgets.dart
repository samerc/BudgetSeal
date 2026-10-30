import 'package:flutter/material.dart';

import '../../../core/providers/date_format_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/utils/format_number.dart';
import '../../../shared/widgets/section_header.dart';
import 'reports_home.dart';

/// A time report's screen: its title, the shared period chips, then its
/// cards.
class ReportScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool chips;
  const ReportScaffold(
      {super.key, required this.title, required this.children, this.chips = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: EdgeInsets.only(
            bottom: 32 + MediaQuery.viewPaddingOf(context).bottom),
        children: [
          if (chips) const ReportSpanChips(),
          ...children,
        ],
      ),
    );
  }
}

/// A white card with the report's usual margins.
class ReportCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const ReportCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 14)});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: padding,
      decoration: AppColors.card(context),
      child: child,
    );
  }
}

/// The big sentence a report card leads with, and the line under it.
class ReportHeadline extends StatelessWidget {
  final String text;
  final String? sub;
  const ReportHeadline(this.text, {super.key, this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text,
            style: const TextStyle(
                fontFamily: TypographyTokens.displayFamily,
                fontSize: 20,
                height: 1.25,
                fontWeight: FontWeight.w800)),
        if (sub != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(sub!,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ts(context))),
          ),
      ],
    );
  }
}

/// Section title between cards.
class ReportSection extends StatelessWidget {
  final String title;
  final String? note;
  const ReportSection(this.title, {super.key, this.note});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 0),
      child: Row(children: [
        Expanded(child: SectionHeader(title)),
        if (note != null)
          Text(note!,
              style: TextStyle(fontSize: 12, color: AppColors.ts(context))),
      ]),
    );
  }
}

/// One legend entry: a swatch (square, line or ring) and its label.
class LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool line;
  final bool ring;
  const LegendItem(this.color, this.label,
      {super.key, this.line = false, this.ring = false});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: line ? 14 : 12,
        height: line ? 3 : 12,
        decoration: BoxDecoration(
          color: ring ? null : color,
          border: ring ? Border.all(color: color, width: 2.5) : null,
          borderRadius: BorderRadius.circular(ring ? 6 : 3),
        ),
      ),
      const SizedBox(width: 6),
      Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ts(context))),
    ]);
  }
}

/// Short month name for an axis ("Oct").
String axisMonth(DateTime bucket) => formatMonth(bucket, short: true);

/// A compact amount for an axis: 1.6k, 800, 12k (localized digits).
String axisAmount(double v) {
  final a = v.abs();
  if (a >= 1000000) return '${formatNumber(v / 1000000, decimals: 1)}M';
  if (a >= 10000) return '${formatNumber(v / 1000, decimals: 0)}k';
  // "5k", not "5.0k"; "2.5k" keeps its decimal.
  if (a >= 1000) {
    return '${formatNumber(v / 1000, decimals: a % 1000 == 0 ? 0 : 1)}k';
  }
  return formatNumber(v, decimals: 0);
}

/// "Nice" top for a value axis: 1, 2, 2.5 or 5 times a power of ten.
double niceMax(double v) {
  if (v <= 0) return 1;
  var p = 1.0;
  while (p * 10 <= v) {
    p *= 10;
  }
  for (final m in [1.0, 2.0, 2.5, 5.0, 10.0]) {
    if (m * p >= v) return m * p;
  }
  return 10 * p;
}
