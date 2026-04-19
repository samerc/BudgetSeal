import 'package:flutter/material.dart';

import '../../core/services/daily_reminder_service.dart';
import '../../shared/theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _dailyEnabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 0);
  String _message = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Daily Reminder ──
          _card(
            context,
            icon: Icons.notifications_active_rounded,
            iconColor: const Color(0xFFFF9800),
            title: 'Daily Reminder',
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable daily reminder',
                    style: TextStyle(fontSize: 14)),
                subtitle: Text(
                  _dailyEnabled
                      ? 'Every day at ${_time.format(context)}'
                      : 'Remind me to log transactions',
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
                    Text('Time',
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
                  controller: TextEditingController(text: _message),
                  style: TextStyle(
                      fontSize: 13, color: AppColors.tp(context)),
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Custom message (optional)',
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
            title: 'Envelope Alerts',
            children: [
              Text(
                'You\'ll receive a notification when envelopes are overspent. '
                'These check on app startup, at most once every 6 hours.',
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
            title: 'Upcoming Bills',
            children: [
              Text(
                'You\'ll receive a notification when recurring transactions '
                'are due within 2 days. Checks on app startup.',
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
        borderRadius: BorderRadius.circular(14),
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
