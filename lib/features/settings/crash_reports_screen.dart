import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers/date_format_provider.dart';
import '../../core/services/crash_reports.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/icon_header_card.dart';
import '../../shared/widgets/settings_row.dart';
import '../../shared/widgets/tappable.dart';

/// Settings → Crash reports: the opt-in switch and the reports saved on
/// this phone (see [CrashReports]). Sharing goes through the system share
/// sheet; nothing is sent otherwise.
class CrashReportsScreen extends StatefulWidget {
  const CrashReportsScreen({super.key});

  @override
  State<CrashReportsScreen> createState() => _CrashReportsScreenState();
}

class _CrashReportsScreenState extends State<CrashReportsScreen> {
  List<CrashReport> _reports = const [];
  bool _loading = true;
  bool _loadFailed = false;
  final _open = <int>{};

  @override
  void initState() {
    super.initState();
    CrashReports.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    CrashReports.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final reports = await CrashReports.load();
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _open.clear();
        _loading = false;
        _loadFailed = false;
      });
    } catch (e) {
      debugPrint('[CrashReports] Loading failed: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _setEnabled(bool on) async {
    final tr = S.of(context);
    try {
      await CrashReports.setEnabled(await SharedPreferences.getInstance(), on);
      if (mounted) setState(() {});
      _snack(on ? tr.crashOnSnack : tr.crashOffSnack);
    } catch (e) {
      debugPrint('[CrashReports] Switching failed: $e');
      _snack(tr.commonSomethingWentWrong);
    }
  }

  Future<void> _share() async {
    final tr = S.of(context);
    try {
      await SharePlus.instance.share(ShareParams(
        text: CrashReports.shareText(_reports),
        subject: tr.crashShareSubject,
      ));
    } catch (e) {
      debugPrint('[CrashReports] Sharing failed: $e');
      _snack(tr.commonSomethingWentWrong);
    }
  }

  Future<void> _clear() async {
    final tr = S.of(context);
    try {
      await CrashReports.clear();
      _snack(tr.crashCleared);
    } catch (e) {
      debugPrint('[CrashReports] Clearing failed: $e');
      _snack(tr.commonSomethingWentWrong);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final on = CrashReports.enabled;
    return Scaffold(
      appBar: AppBar(title: Text(tr.tileCrashReports)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
              ? ErrorRetry(onRetry: () {
                  setState(() => _loading = true);
                  _load();
                })
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    IconHeaderCard(
                      icon: AppIcons.bug,
                      iconColor: SettingsRowStyle.hue(8),
                      title: tr.crashKeep,
                      description: tr.crashKeepSub,
                      trailing: Switch(value: on, onChanged: _setEnabled),
                      children: [
                        Text(tr.crashWhatsIn,
                            style: TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                                color: AppColors.th(context))),
                      ],
                    ),
                    const SizedBox(height: Spacing.sectionGap),
                    if (_reports.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: EmptyState(
                          icon: AppIcons.bug,
                          title: tr.crashEmpty,
                          subtitle: on
                              ? tr.crashEmptySubOn
                              : tr.crashEmptySubOff,
                        ),
                      )
                    else ...[
                      for (final (i, r) in _reports.indexed)
                        _ReportCard(
                          report: r,
                          open: _open.contains(i),
                          onTap: () => setState(() =>
                              _open.contains(i) ? _open.remove(i) : _open.add(i)),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _clear,
                              icon: const Icon(AppIcons.trash, size: 18),
                              label: Text(tr.crashClear),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _share,
                              icon: const Icon(AppIcons.shareNetwork, size: 18),
                              label: Text(tr.crashShare),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
    );
  }
}

/// One report: when, how often, the error's first line; tap for the rest.
class _ReportCard extends StatelessWidget {
  final CrashReport report;
  final bool open;
  final VoidCallback onTap;
  const _ReportCard(
      {required this.report, required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Tappable(
        onTap: onTap,
        child: AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.count > 1
                    ? '${formatDateTime(report.time)} · ${tr.crashTimes(report.count)}'
                    : formatDateTime(report.time),
                style: TextStyle(fontSize: 12.5, color: AppColors.ts(context)),
              ),
              const SizedBox(height: 4),
              Text(
                report.headline,
                maxLines: open ? null : 2,
                overflow: open ? null : TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tp(context)),
              ),
              if (open) ...[
                const SizedBox(height: 8),
                // Error text and stack read left to right in every language.
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: SelectableText(
                    report.toText(),
                    style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        fontFamily: 'monospace',
                        color: AppColors.ts(context)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
