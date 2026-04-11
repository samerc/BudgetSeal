import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/biometric_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/entry_mode_provider.dart';
import '../../core/providers/font_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/tx_colors_provider.dart';
import '../../features/transactions/widgets/currency_sheet.dart';
import '../../shared/theme/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(householdProvider).value;

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader(title: 'HOUSEHOLD'),
          _SettingsTile(
            icon: Icons.home_rounded,
            title: 'Household name',
            subtitle: household?.name ?? '—',
            iconColor: AppColors.accent,
            onTap: () => _editText(
              context,
              ref,
              title: 'Household Name',
              currentValue: household?.name ?? '',
              onSave: (val) async {
                final db = ref.read(databaseProvider);
                await (db.update(db.households)
                      ..where((h) => h.id.equals(household!.id)))
                    .write(HouseholdsCompanion(name: Value(val)));
              },
            ),
          ),
          _SettingsTile(
            icon: Icons.monetization_on_rounded,
            title: 'Base currency',
            subtitle: household?.baseCurrency ?? '—',
            iconColor: AppColors.accent,
            onTap: () async {
              final result = await showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => CurrencySheet(
                    current: household?.baseCurrency ?? 'USD'),
              );
              if (result != null && household != null) {
                final db = ref.read(databaseProvider);
                await (db.update(db.households)
                      ..where((h) => h.id.equals(household.id)))
                    .write(HouseholdsCompanion(
                        baseCurrency: Value(result)));
              }
            },
          ),
          _SettingsTile(
            icon: Icons.calendar_today_rounded,
            title: 'Period start day',
            subtitle: 'Day ${household?.periodStartDay ?? 1}',
            iconColor: AppColors.caution,
            onTap: () => _editNumber(
              context,
              ref,
              title: 'Period Start Day',
              currentValue: household?.periodStartDay ?? 1,
              min: 1,
              max: 28,
              description:
                  'The day of the month when a new budget period starts. '
                  'Use 1 for the 1st, or pick your payday.',
              onSave: (val) async {
                final db = ref.read(databaseProvider);
                await (db.update(db.households)
                      ..where((h) => h.id.equals(household!.id)))
                    .write(HouseholdsCompanion(periodStartDay: Value(val)));
              },
            ),
          ),
          const SizedBox(height: 16),

          _SectionHeader(title: 'TOOLS'),
          _SettingsTile(
            icon: Icons.credit_card_rounded,
            title: 'Accounts',
            subtitle: 'Manage your accounts and balances',
            iconColor: const Color(0xFF1565C0),
            onTap: () => context.push('/accounts'),
          ),
          _SettingsTile(
            icon: Icons.label_outlined,
            title: 'Categories',
            subtitle: 'Manage groups and categories',
            iconColor: const Color(0xFFBA68C8),
            onTap: () => context.push('/categories'),
          ),
          _SettingsTile(
            icon: Icons.repeat_rounded,
            title: 'Recurring',
            subtitle: 'Manage recurring transactions',
            iconColor: const Color(0xFFFF7043),
            onTap: () => context.push('/recurring'),
          ),
          _SettingsTile(
            icon: Icons.bolt_rounded,
            title: 'Templates',
            subtitle: 'Save frequent transactions for quick use',
            iconColor: const Color(0xFFFFB74D),
            onTap: () => context.push('/templates'),
          ),
          _SettingsTile(
            icon: Icons.calendar_month_rounded,
            title: 'Bill Calendar',
            subtitle: 'View upcoming recurring bills',
            iconColor: const Color(0xFF66BB6A),
            onTap: () => context.push('/bill-calendar'),
          ),
          _SettingsTile(
            icon: Icons.currency_exchange_rounded,
            title: 'Exchange Rates',
            subtitle: 'View and refresh currency rates',
            iconColor: const Color(0xFF4DB6AC),
            onTap: () => context.push('/exchange-rates'),
          ),
          _SettingsTile(
            icon: Icons.refresh_rounded,
            title: 'Period Transition',
            subtitle: 'End period and resolve leftovers',
            iconColor: AppColors.accent,
            onTap: () => context.push('/period-transition'),
          ),
          const SizedBox(height: 16),

          _SectionHeader(title: 'APPEARANCE'),
          Builder(builder: (context) {
            final mode = ref.watch(themeModeProvider);
            final label = switch (mode) {
              ThemeMode.light => 'Light',
              ThemeMode.dark => 'Dark',
              ThemeMode.system => 'System',
            };
            return _SettingsTile(
              icon: Icons.palette_outlined,
              title: 'Theme',
              subtitle: label,
              iconColor: AppColors.accent,
              onTap: () async {
                final picked = await showModalBottomSheet<ThemeMode>(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Theme',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                        ),
                        ListTile(
                          leading: Icon(
                            mode == ThemeMode.system
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: AppColors.accent,
                          ),
                          title: const Text('System'),
                          subtitle: const Text(
                              'Follow your device settings'),
                          onTap: () =>
                              Navigator.pop(ctx, ThemeMode.system),
                        ),
                        ListTile(
                          leading: Icon(
                            mode == ThemeMode.light
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: AppColors.accent,
                          ),
                          title: const Text('Light'),
                          onTap: () =>
                              Navigator.pop(ctx, ThemeMode.light),
                        ),
                        ListTile(
                          leading: Icon(
                            mode == ThemeMode.dark
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: AppColors.accent,
                          ),
                          title: const Text('Dark'),
                          onTap: () =>
                              Navigator.pop(ctx, ThemeMode.dark),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
                if (picked != null) {
                  ref.read(themeModeProvider.notifier).setMode(picked);
                }
              },
            );
          }),
          _SettingsTile(
            icon: Icons.color_lens_outlined,
            title: 'Transaction Colors',
            subtitle: 'Customize income, expense & transfer colors',
            iconColor: const Color(0xFFEC407A),
            onTap: () => _showColorConfig(context, ref),
          ),
          // Entry mode
          Builder(builder: (context) {
            final mode = ref.watch(entryModeProvider);
            return _SettingsTile(
              icon: Icons.touch_app_outlined,
              title: 'Transaction Entry',
              subtitle: mode == 'assisted' ? 'Assisted (step-by-step)' : 'Classic (single form)',
              iconColor: const Color(0xFF42A5F5),
              onTap: () {
                final newMode =
                    mode == 'assisted' ? 'classic' : 'assisted';
                ref.read(entryModeProvider.notifier).setMode(newMode);
              },
            );
          }),
          // Font selector
          Builder(builder: (context) {
            final currentFont = ref.watch(fontProvider);
            return _SettingsTile(
              icon: Icons.text_fields_rounded,
              title: 'Font',
              subtitle: currentFont,
              iconColor: const Color(0xFF7E57C2),
              onTap: () async {
                final picked = await showModalBottomSheet<String>(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Choose Font',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                        ),
                        ...appFonts.keys.map((font) => ListTile(
                              leading: Icon(
                                font == currentFont
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: AppColors.accent,
                              ),
                              title: Text(font,
                                  style: fontStyle(font, fontSize: 16)),
                              subtitle: Text('The quick brown fox jumps over the lazy dog',
                                  style: fontStyle(font, fontSize: 12,
                                      color: AppColors.textSecondary)),
                              onTap: () => Navigator.pop(ctx, font),
                            )),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
                if (picked != null) {
                  ref.read(fontProvider.notifier).setFont(picked);
                }
              },
            );
          }),
          const SizedBox(height: 16),

          _SectionHeader(title: 'SECURITY'),
          _BiometricTile(),
          const SizedBox(height: 16),

          _SectionHeader(title: 'DATA'),
          _SettingsTile(
            icon: Icons.cloud_sync_rounded,
            title: 'Cloud Sync',
            subtitle: 'Sync your data across devices',
            iconColor: AppColors.accent,
            onTap: () => context.push('/sync'),
          ),
          _SettingsTile(
            icon: Icons.backup_rounded,
            title: 'Backup & Restore',
            subtitle: 'Export your database for safekeeping',
            iconColor: AppColors.accent,
            onTap: () => context.push('/backup'),
          ),
          _SettingsTile(
            icon: Icons.download_rounded,
            title: 'Export CSV',
            subtitle: 'Export transactions as spreadsheet',
            iconColor: const Color(0xFF42A5F5),
            onTap: () => context.push('/export'),
          ),
          _SettingsTile(
            icon: Icons.upload_file_rounded,
            title: 'Import CSV',
            subtitle: 'Import transactions from bank export',
            iconColor: const Color(0xFF26A69A),
            onTap: () => context.push('/import'),
          ),
          _SettingsTile(
            icon: Icons.picture_as_pdf_rounded,
            title: 'Export Report',
            subtitle: 'Generate a printable monthly report',
            iconColor: const Color(0xFFEF5350),
            onTap: () => context.push('/export-report'),
          ),
          const SizedBox(height: 16),

          _SectionHeader(title: 'ABOUT'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Pocket Plan',
            subtitle: 'Version 1.0.0',
            iconColor: AppColors.textSecondary,
            onTap: () => context.push('/about'),
          ),
          const SizedBox(height: 16),

          _SectionHeader(title: 'DANGER ZONE'),
          _SettingsTile(
            icon: Icons.delete_forever_rounded,
            title: 'Reset Everything',
            subtitle: 'Erase all data and start fresh',
            iconColor: AppColors.overspent,
            onTap: () => _confirmReset(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Everything'),
        content: const Text(
          'This will permanently delete ALL your data:\n\n'
          '• All accounts and balances\n'
          '• All transactions\n'
          '• All envelopes and categories\n'
          '• All settings\n\n'
          'This cannot be undone. Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.overspent),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Delete the database file
      final db = ref.read(databaseProvider);
      await db.close();

      final dir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dir.path, 'pocketplan.db'));
      if (dbFile.existsSync()) dbFile.deleteSync();

      // Clear preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Restart app
      if (context.mounted) {
        context.go('/onboarding');
      }
    }
  }

  Future<void> _editText(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String currentValue,
    String? hint,
    String? description,
    bool capitalize = false,
    required Future<void> Function(String) onSave,
  }) async {
    final ctrl = TextEditingController(text: currentValue);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(description,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: capitalize
                  ? TextCapitalization.characters
                  : TextCapitalization.words,
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: AppColors.sfv(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Save',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
    if (result != null && result.isNotEmpty && result != currentValue) {
      await onSave(result);
    }
  }

  void _showColorConfig(BuildContext context, WidgetRef ref) {
    final current = ref.read(txColorsProvider);

    final presets = [
      ('Red', const Color(0xFFEF4444)),
      ('Orange', const Color(0xFFF97316)),
      ('Amber', const Color(0xFFF59E0B)),
      ('Green', const Color(0xFF10B981)),
      ('Teal', const Color(0xFF14B8A6)),
      ('Blue', const Color(0xFF3B82F6)),
      ('Indigo', const Color(0xFF6366F1)),
      ('Purple', const Color(0xFF8B5CF6)),
      ('Pink', const Color(0xFFEC4899)),
      ('Slate', const Color(0xFF64748B)),
    ];

    Color incomeColor = current.income;
    Color expenseColor = current.expense;
    Color transferColor = current.transfer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Transaction Colors',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                _colorRow('Expense', expenseColor, presets, (c) {
                  setSheetState(() => expenseColor = c);
                }, currentLabel: 'Current'),
                const SizedBox(height: 16),
                _colorRow('Income', incomeColor, presets, (c) {
                  setSheetState(() => incomeColor = c);
                }, currentLabel: 'Current'),
                const SizedBox(height: 16),
                _colorRow('Transfer', transferColor, presets, (c) {
                  setSheetState(() => transferColor = c);
                }, currentLabel: 'Current'),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    ref.read(txColorsProvider.notifier).update(TxColors(
                      income: incomeColor,
                      expense: expenseColor,
                      transfer: transferColor,
                    ));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    setSheetState(() {
                      incomeColor = const Color(0xFF10B981);
                      expenseColor = const Color(0xFFEF4444);
                      transferColor = const Color(0xFF6366F1);
                    });
                  },
                  child: const Text('Reset to Defaults'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _colorRow(String label, Color selected,
      List<(String, Color)> presets, ValueChanged<Color> onChanged,
      {String? currentLabel}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (currentLabel != null)
                  Text(currentLabel,
                      style: const TextStyle(
                          fontSize: 10, color: Colors.grey)),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: selected,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((p) {
            final isSelected = p.$2.toARGB32() == selected.toARGB32();
            return GestureDetector(
              onTap: () => onChanged(p.$2),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: p.$2,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                  boxShadow: isSelected
                      ? [BoxShadow(
                          color: p.$2.withValues(alpha: 0.5),
                          blurRadius: 4)]
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _editNumber(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required int currentValue,
    required int min,
    required int max,
    String? description,
    required Future<void> Function(int) onSave,
  }) async {
    final ctrl = TextEditingController(text: currentValue.toString());
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(description,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '$min–$max',
                filled: true,
                fillColor: AppColors.sfv(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final val = int.tryParse(ctrl.text.trim());
                if (val != null && val >= min && val <= max) {
                  Navigator.pop(ctx, val);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Save',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
    if (result != null && result != currentValue) {
      await onSave(result);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        title: Text(title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        trailing: onTap != null
            ? const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textHint)
            : null,
        onTap: onTap,
      ),
    );
  }
}

class _BiometricTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(biometricLockProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.fingerprint_rounded,
              color: Color(0xFF7C4DFF), size: 18),
        ),
        title: const Text('Biometric Lock',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: const Text('Require fingerprint or face to open',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: Switch.adaptive(
          value: enabled,
          activeTrackColor: AppColors.accent,
          onChanged: (value) => _toggle(context, ref, value),
        ),
        onTap: () => _toggle(context, ref, !enabled),
      ),
    );
  }

  Future<void> _toggle(
      BuildContext context, WidgetRef ref, bool turning0n) async {
    if (!turning0n) {
      // Disabling — no verification needed.
      await ref.read(biometricLockProvider.notifier).disable();
      return;
    }

    // Enabling — verify biometrics work first.
    final auth = LocalAuthentication();
    try {
      final canAuth =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!canAuth) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication is not available on this device'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final didAuth = await auth.authenticate(
        localizedReason: 'Verify to enable biometric lock',
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );

      if (didAuth) {
        await ref.read(biometricLockProvider.notifier).enable();
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed — biometric lock not enabled'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        String message = 'Authentication error — biometric lock not enabled';
        final errorStr = e.toString();
        if (errorStr.contains('NotAvailable') || errorStr.contains('NotEnrolled')) {
          message =
              'No biometrics enrolled on this device. '
              'Please set up fingerprint or face unlock in your device settings, '
              'then try again.';
        } else if (errorStr.contains('LockedOut')) {
          message = 'Too many attempts. Please wait and try again.';
        } else if (errorStr.contains('PasscodeNotSet')) {
          message =
              'No screen lock is set up on this device. '
              'Please set up a PIN, pattern, or password first.';
        } else {
          message = 'Authentication error: $errorStr\n\n'
              'Make sure biometric or screen lock is configured in device settings.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
