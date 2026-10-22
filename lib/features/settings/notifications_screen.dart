import 'package:flutter/material.dart';

import '../../core/services/daily_reminder_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/icon_header_card.dart';
import '../../shared/widgets/settings_row.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _dailyEnabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 0);
  String _message = '';
  late final TextEditingController _messageCtrl;
  // Settings load before the cards show (no default-then-flip flash).
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _messageCtrl = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final enabled = await DailyReminderService.isEnabled();
      final time = await DailyReminderService.getTime();
      final message = await DailyReminderService.getMessage();
      if (mounted) {
        setState(() {
          _dailyEnabled = enabled;
          _time = time;
          _message = message;
          _messageCtrl.text = message;
          _loading = false;
          _loadFailed = false;
        });
      }
    } catch (e) {
      debugPrint('[Notifications] Loading settings failed: $e');
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

  /// Saves one reminder setting and reports the outcome.
  Future<void> _save(
      Future<void> Function() save, VoidCallback apply, String success) async {
    try {
      await save();
      if (!mounted) return;
      setState(apply);
      _snack(success);
    } catch (e) {
      debugPrint('[Notifications] Saving failed: $e');
      if (mounted) _snack(S.of(context).commonSomethingWentWrong);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).notifTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
              ? ErrorRetry(onRetry: () {
                  setState(() => _loading = true);
                  _loadSettings();
                })
              : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Daily Reminder ──
          IconHeaderCard(
            icon: AppIcons.bellRinging,
            iconColor: SettingsRowStyle.hue(36),
            title: S.of(context).notifDailyTitle,
            children: [
              SettingsSwitchRow(
                title: S.of(context).notifDailyEnable,
                subtitle: _dailyEnabled
                    ? S.of(context).notifEveryDayAt(_time.format(context))
                    : S.of(context).notifDailyDisabled,
                value: _dailyEnabled,
                onChanged: (v) => _save(
                    () => DailyReminderService.setEnabled(v),
                    () => _dailyEnabled = v,
                    v
                        ? S.of(context).notifReminderOnSnack
                        : S.of(context).notifReminderOffSnack),
              ),
              if (_dailyEnabled) ...[
                const SizedBox(height: 8),
                // Time picker
                Row(
                  children: [
                    Icon(AppIcons.clock,
                        size: 16, color: AppColors.ts(context)),
                    const SizedBox(width: 8),
                    Text(S.of(context).notifTime,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.ts(context))),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _time,
                        );
                        if (picked != null && context.mounted) {
                          await _save(
                              () => DailyReminderService.setTime(picked),
                              () => _time = picked,
                              S.of(context).notifReminderSaved);
                        }
                      },
                      child: Text(_time.format(context)),
                    ),
                  ],
                ),
                // Custom message
                const SizedBox(height: 4),
                TextField(
                  controller: _messageCtrl,
                  style: TextStyle(
                      fontSize: 13, color: AppColors.tp(context)),
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: S.of(context).notifCustomMessage,
                    suffixIcon: _message.isNotEmpty
                        ? IconButton(
                            icon: Icon(AppIcons.x,
                                size: 16, color: AppColors.th(context)),
                            onPressed: () {
                              _messageCtrl.clear();
                              _save(
                                  () => DailyReminderService.setMessage(''),
                                  () => _message = '',
                                  S.of(context).notifReminderSaved);
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (v) => _save(
                      () => DailyReminderService.setMessage(v),
                      () => _message = v.trim(),
                      S.of(context).notifReminderSaved),
                ),
              ],
            ],
          ),
          const SizedBox(height: Spacing.md),

          // ── Envelope Alerts ──
          IconHeaderCard(
            icon: AppIcons.wallet,
            iconColor: AppColors.overspent,
            title: S.of(context).notifEnvelopeTitle,
            description: S.of(context).notifEnvelopeDesc,
          ),
          const SizedBox(height: Spacing.md),

          // ── Bill Reminders ──
          IconHeaderCard(
            icon: AppIcons.receipt,
            iconColor: AppColors.caution,
            title: S.of(context).notifBillsTitle,
            description: S.of(context).notifBillsDesc,
          ),
        ],
      ),
    );
  }
}
