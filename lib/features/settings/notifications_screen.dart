import 'package:flutter/material.dart';

import '../../core/services/daily_reminder_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';

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
    final enabled = await DailyReminderService.isEnabled();
    final time = await DailyReminderService.getTime();
    final message = await DailyReminderService.getMessage();
    if (mounted) {
      setState(() {
        _dailyEnabled = enabled;
        _time = time;
        _message = message;
        _messageCtrl.text = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).notifTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Daily Reminder ──
          _card(
            context,
            icon: Icons.notifications_active_rounded,
            iconColor: const Color(0xFFFF9800),
            title: S.of(context).notifDailyTitle,
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(S.of(context).notifDailyEnable,
                    style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                  _dailyEnabled
                      ? 'Every day at ${_time.format(context)}'
                      : S.of(context).notifDailyDisabled,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.ts(context)),
                ),
                value: _dailyEnabled,
                onChanged: (v) async {
                  await DailyReminderService.setEnabled(v);
                  setState(() => _dailyEnabled = v);
                },
                activeTrackColor: AppColors.accent,
              ),
              if (_dailyEnabled) ...[
                const SizedBox(height: 8),
                // Time picker
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
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
                        if (picked != null) {
                          await DailyReminderService.setTime(picked);
                          setState(() => _time = picked);
                        }
                      },
                      child: Text(
                        _time.format(context),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
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
                    hintStyle: TextStyle(
                        fontSize: 13, color: AppColors.th(context)),
                    filled: true,
                    fillColor: AppColors.sfv(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    isDense: true,
                    suffixIcon: _message.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded,
                                size: 16, color: AppColors.th(context)),
                            onPressed: () async {
                              await DailyReminderService.setMessage('');
                              setState(() => _message = '');
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (v) async {
                    await DailyReminderService.setMessage(v);
                    setState(() => _message = v.trim());
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // ── Envelope Alerts ──
          _card(
            context,
            icon: Icons.account_balance_wallet_outlined,
            iconColor: AppColors.overspent,
            title: S.of(context).notifEnvelopeTitle,
            children: [
              Text(
                S.of(context).notifEnvelopeDesc,
                style: TextStyle(
                    fontSize: 12, color: AppColors.ts(context), height: 1.4),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Bill Reminders ──
          _card(
            context,
            icon: Icons.receipt_long_rounded,
            iconColor: AppColors.caution,
            title: S.of(context).notifBillsTitle,
            children: [
              Text(
                S.of(context).notifBillsDesc,
                style: TextStyle(
                    fontSize: 12, color: AppColors.ts(context), height: 1.4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tp(context))),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
