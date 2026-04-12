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
import '../../core/providers/currency_symbol_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/number_format_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/entry_mode_provider.dart';
import '../../core/providers/home_tab_provider.dart';
import '../../core/providers/font_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/receipt_sync_provider.dart';
import '../../core/providers/sync_provider.dart';
import '../../core/providers/backup_reminder_provider.dart';
import '../../core/providers/tx_colors_provider.dart';
import '../../features/transactions/widgets/currency_sheet.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/format_number.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(householdProvider).value;

    final themeLabel = switch (ref.watch(themeModeProvider)) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // ── Title ──
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
              child: Row(
                children: [
                  Text('More',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.tp(context))),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/about'),
                    child: Text('v1.0.0',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.th(context))),
                  ),
                ],
              ),
            ),

            // ── Backup Reminder Banner (moved from dashboard) ──
            _SettingsBackupBanner(),

            // ── Household banner ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accent, AppColors.accent.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.home_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(household?.name ?? 'PocketPlan',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700)),
                        Text(
                          '${household?.baseCurrency ?? 'USD'} · Day ${household?.periodStartDay ?? 1}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _editText(context, ref,
                        title: 'Household Name',
                        currentValue: household?.name ?? '',
                        onSave: (val) async {
                          final db = ref.read(databaseProvider);
                          await (db.update(db.households)
                                ..where((h) => h.id.equals(household!.id)))
                              .write(HouseholdsCompanion(name: Value(val)));
                        }),
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.white70, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Quick tools grid ──
            _SectionHeader(title: 'MANAGE'),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.85,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _GridTile(icon: Icons.credit_card_rounded, label: 'Accounts',
                    color: const Color(0xFF1565C0),
                    onTap: () => context.push('/accounts')),
                _GridTile(icon: Icons.label_rounded, label: 'Categories',
                    color: const Color(0xFFBA68C8),
                    onTap: () => context.push('/categories')),
                _GridTile(icon: Icons.repeat_rounded, label: 'Recurring',
                    color: const Color(0xFFFF7043),
                    onTap: () => context.push('/recurring')),
                _GridTile(icon: Icons.bolt_rounded, label: 'Templates',
                    color: const Color(0xFFFFB74D),
                    onTap: () => context.push('/templates')),
                _GridTile(icon: Icons.calendar_month_rounded, label: 'Bill Cal',
                    color: const Color(0xFF66BB6A),
                    onTap: () => context.push('/bill-calendar')),
                _GridTile(icon: Icons.currency_exchange_rounded, label: 'FX Rates',
                    color: const Color(0xFF4DB6AC),
                    onTap: () => context.push('/exchange-rates')),
                _GridTile(icon: Icons.refresh_rounded, label: 'Period',
                    color: AppColors.accent,
                    onTap: () => context.push('/period-transition')),
              ],
            ),
            const SizedBox(height: 20),

            // ── Appearance ──
            _SectionHeader(title: 'APPEARANCE'),
            const SizedBox(height: 8),
            _SettingsTile(icon: Icons.palette_outlined, title: 'Theme',
                subtitle: themeLabel, iconColor: AppColors.accent,
                onTap: () => _showThemePicker(context, ref)),
            _SettingsTile(icon: Icons.color_lens_outlined, title: 'Colors',
                subtitle: 'Income, expense & transfer', iconColor: const Color(0xFFEC407A),
                onTap: () => _showColorConfig(context, ref)),
            Builder(builder: (context) {
              final mode = ref.watch(entryModeProvider);
              return _SettingsTile(icon: Icons.touch_app_outlined, title: 'Entry Mode',
                  subtitle: mode == 'assisted' ? 'Assisted' : 'Classic',
                  iconColor: const Color(0xFF42A5F5),
                  onTap: () => ref.read(entryModeProvider.notifier).setMode(
                      mode == 'assisted' ? 'classic' : 'assisted'));
            }),
            Builder(builder: (context) {
              final homeTab = ref.watch(homeTabProvider);
              return _SettingsTile(icon: Icons.home_outlined, title: 'Start Screen',
                  subtitle: homeTabLabels[homeTab],
                  iconColor: const Color(0xFF26A69A),
                  onTap: () => _showHomeTabPicker(context, ref));
            }),
            Builder(builder: (context) {
              final font = ref.watch(fontProvider);
              return _SettingsTile(icon: Icons.text_fields_rounded, title: 'Font',
                  subtitle: font, iconColor: const Color(0xFF7E57C2),
                  onTap: () => _showFontPicker(context, ref));
            }),
            const SizedBox(height: 20),

            // ── Data & Sync ──
            _SectionHeader(title: 'DATA'),
            const SizedBox(height: 8),
            _SettingsTile(icon: Icons.cloud_sync_rounded, title: 'Cloud Sync',
                subtitle: 'Sync across devices', iconColor: AppColors.accent,
                onTap: () => context.push('/sync')),
            _SettingsTile(icon: Icons.backup_rounded, title: 'Backup & Restore',
                subtitle: 'Export or restore database', iconColor: const Color(0xFF42A5F5),
                onTap: () => context.push('/backup')),
            _SettingsTile(icon: Icons.download_rounded, title: 'Export CSV',
                subtitle: 'Transactions as spreadsheet', iconColor: const Color(0xFF66BB6A),
                onTap: () => context.push('/export')),
            _SettingsTile(icon: Icons.upload_file_rounded, title: 'Import CSV',
                subtitle: 'Import from bank export', iconColor: const Color(0xFF26A69A),
                onTap: () => context.push('/import')),
            _SettingsTile(icon: Icons.picture_as_pdf_rounded, title: 'Export Report',
                subtitle: 'Monthly PDF report', iconColor: const Color(0xFFEF5350),
                onTap: () => context.push('/export-report')),
            // ── Receipt Sync toggle ──
            Builder(builder: (context) {
              final syncState = ref.watch(syncProvider);
              final isCloudConnected = syncState.activeProvider != null;
              if (!isCloudConnected) return const SizedBox.shrink();
              final receiptSyncEnabled = ref.watch(receiptSyncProvider);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.sf(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.bd(context)),
                    ),
                    child: SwitchListTile(
                      secondary: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7E57C2).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.photo_library_rounded,
                            size: 18, color: Color(0xFF7E57C2)),
                      ),
                      title: Text('Sync Receipts',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.tp(context))),
                      subtitle: Text(
                        receiptSyncEnabled
                            ? 'Upload receipt photos to cloud storage'
                            : 'Receipts are stored on this device only',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.ts(context)),
                      ),
                      value: receiptSyncEnabled,
                      onChanged: (_) =>
                          ref.read(receiptSyncProvider.notifier).toggle(),
                      activeTrackColor: AppColors.accent,
                    ),
                  ),
                  if (!receiptSyncEnabled)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 14, color: AppColors.caution),
                          const SizedBox(width: 6),
                          Text('Receipts are stored on this device only',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.caution)),
                        ],
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: 20),

            // ── Security ──
            _SectionHeader(title: 'SECURITY'),
            const SizedBox(height: 8),
            _BiometricTile(),
            const SizedBox(height: 20),

            // ── Household settings ──
            _SectionHeader(title: 'HOUSEHOLD'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.monetization_on_rounded,
              title: 'Base Currency',
              subtitle: household?.baseCurrency ?? 'USD',
              iconColor: AppColors.caution,
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
                      .write(HouseholdsCompanion(baseCurrency: Value(result)));
                }
              },
            ),
            _SettingsTile(
              icon: Icons.calendar_today_rounded,
              title: 'Period Start Day',
              subtitle: 'Day ${household?.periodStartDay ?? 1}',
              iconColor: AppColors.caution,
              onTap: () => _editNumber(context, ref,
                  title: 'Period Start Day',
                  currentValue: household?.periodStartDay ?? 1,
                  min: 1, max: 28,
                  description: 'The day of the month when a new budget period starts.',
                  onSave: (val) async {
                    final db = ref.read(databaseProvider);
                    await (db.update(db.households)
                          ..where((h) => h.id.equals(household!.id)))
                        .write(HouseholdsCompanion(periodStartDay: Value(val)));
                  }),
            ),
            _SettingsTile(
              icon: Icons.attach_money_rounded,
              title: 'Currency Symbols',
              subtitle: 'Override how currencies are displayed',
              iconColor: const Color(0xFF4DB6AC),
              onTap: () => _showCurrencySymbolEditor(context, ref),
            ),
            Builder(builder: (context) {
              ref.watch(numberFormatProvider); // rebuild on change
              final preview = formatAmount(1234567.89);
              return _SettingsTile(
                icon: Icons.format_list_numbered_rounded,
                title: 'Number Format',
                subtitle: 'Preview: $preview',
                iconColor: const Color(0xFF5C6BC0),
                onTap: () => _showNumberFormatEditor(context, ref),
              );
            }),
            const SizedBox(height: 20),

            // ── About + Reset ──
            _SettingsTile(icon: Icons.info_outline_rounded, title: 'About PocketPlan',
                subtitle: 'Version 1.0.0', iconColor: AppColors.ts(context),
                onTap: () => context.push('/about')),
            const SizedBox(height: 8),
            _SettingsTile(icon: Icons.delete_forever_rounded, title: 'Reset Everything',
                subtitle: 'Erase all data and start fresh', iconColor: AppColors.overspent,
                onTap: () => _confirmReset(context, ref)),
          ],
        ),
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
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: AppColors.sf(context),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.sfv(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Transaction Colors',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.tp(context))),
                  const SizedBox(height: 6),
                  Text(
                    'Choose a color for each transaction type. '
                    'These colors are used throughout the app to '
                    'visually distinguish income, expenses, and transfers.',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.ts(context),
                        height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  // Preview
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.sfv(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _colorPreviewChip(
                            'Income', '+\$500', incomeColor, context),
                        _colorPreviewChip(
                            'Expense', '-\$120', expenseColor, context),
                        _colorPreviewChip(
                            'Transfer', '\$200', transferColor, context),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Color pickers
                  _colorPickerRow('Expense', expenseColor, presets, (c) {
                    setSheetState(() => expenseColor = c);
                  }, Icons.arrow_upward_rounded, context),
                  const SizedBox(height: 16),
                  _colorPickerRow('Income', incomeColor, presets, (c) {
                    setSheetState(() => incomeColor = c);
                  }, Icons.arrow_downward_rounded, context),
                  const SizedBox(height: 16),
                  _colorPickerRow('Transfer', transferColor, presets, (c) {
                    setSheetState(() => transferColor = c);
                  }, Icons.swap_horiz_rounded, context),
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
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      setSheetState(() {
                        incomeColor = const Color(0xFF10B981);
                        expenseColor = const Color(0xFFEF4444);
                        transferColor = const Color(0xFF6366F1);
                      });
                    },
                    child: Text('Reset to Defaults',
                        style: TextStyle(
                            color: AppColors.ts(context), fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _colorPreviewChip(
      String label, String amount, Color color, BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(amount,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: AppColors.ts(context))),
      ],
    );
  }

  Widget _colorPickerRow(String label, Color selected,
      List<(String, Color)> presets, ValueChanged<Color> onChanged,
      IconData icon, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: selected),
            ),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tp(context))),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((p) {
            final isSelected = p.$2.toARGB32() == selected.toARGB32();
            return GestureDetector(
              onTap: () => onChanged(p.$2),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: p.$2,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(
                              color: AppColors.tp(context), width: 2.5)
                          : Border.all(
                              color: AppColors.bd(context), width: 1),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: p.$2.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  spreadRadius: 1)
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            size: 18, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 3),
                  Text(p.$1,
                      style: TextStyle(
                          fontSize: 9,
                          color: isSelected
                              ? AppColors.tp(context)
                              : AppColors.th(context))),
                ],
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

  void _showThemePicker(BuildContext context, WidgetRef ref) async {
    final mode = ref.read(themeModeProvider);
    final picked = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(16),
              child: Text('Theme', style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w700, color: AppColors.tp(context)))),
          for (final entry in [
            (ThemeMode.system, 'System', 'Follow device settings'),
            (ThemeMode.light, 'Light', null),
            (ThemeMode.dark, 'Dark', null),
          ])
            ListTile(
              leading: Icon(mode == entry.$1
                  ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: AppColors.accent),
              title: Text(entry.$2),
              subtitle: entry.$3 != null ? Text(entry.$3!) : null,
              onTap: () => Navigator.pop(ctx, entry.$1),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (picked != null) ref.read(themeModeProvider.notifier).setMode(picked);
  }

  void _showHomeTabPicker(BuildContext context, WidgetRef ref) async {
    final homeTab = ref.read(homeTabProvider);
    final icons = [Icons.dashboard_rounded, Icons.receipt_long_rounded,
        Icons.account_balance_wallet_rounded, Icons.insights_rounded,
        Icons.more_horiz_rounded];
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(16),
              child: Text('Start Screen', style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w700, color: AppColors.tp(context)))),
          Text('Opens when you launch the app.',
              style: TextStyle(fontSize: 13, color: AppColors.ts(context))),
          const SizedBox(height: 8),
          for (var i = 0; i < homeTabLabels.length; i++)
            ListTile(
              leading: Icon(i == homeTab
                  ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: AppColors.accent),
              title: Text(homeTabLabels[i]),
              trailing: Icon(icons[i], size: 20, color: AppColors.ts(context)),
              onTap: () => Navigator.pop(ctx, i),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (picked != null) ref.read(homeTabProvider.notifier).set(picked);
  }

  void _showNumberFormatEditor(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NumberFormatSheet(),
    );
  }

  void _showCurrencySymbolEditor(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CurrencySymbolSheet(),
    );
  }

  void _showFontPicker(BuildContext context, WidgetRef ref) async {
    final currentFont = ref.read(fontProvider);
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(16),
              child: Text('Choose Font', style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w700, color: AppColors.tp(context)))),
          ...appFonts.keys.map((font) => ListTile(
                leading: Icon(font == currentFont
                    ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: AppColors.accent),
                title: Text(font, style: fontStyle(font, fontSize: 16)),
                subtitle: Text('The quick brown fox jumps over the lazy dog',
                    style: fontStyle(font, fontSize: 12,
                        color: AppColors.textSecondary)),
                onTap: () => Navigator.pop(ctx, font),
              )),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (picked != null) ref.read(fontProvider.notifier).setFont(picked);
  }
}

// ─── Grid tile for Manage section ──────────────────────────────────────────

class _GridTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GridTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.bd(context)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500,
                color: AppColors.tp(context)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
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

// ─── Currency Symbol Editor Sheet ──────────────────────────────────────────

class _CurrencySymbolSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CurrencySymbolSheet> createState() =>
      _CurrencySymbolSheetState();
}

class _CurrencySymbolSheetState extends ConsumerState<_CurrencySymbolSheet> {
  @override
  Widget build(BuildContext context) {
    final overrides = ref.watch(currencySymbolProvider);
    final allCurrencies = defaultCurrencySymbols.keys.toList()..sort();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.sfv(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Currency Symbols',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.tp(context))),
                const SizedBox(height: 6),
                Text(
                  'Tap any currency to change how its symbol is displayed. '
                  'For example, change ل.ل to LBP.',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.ts(context),
                      height: 1.4),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: AppColors.bd(context)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              itemCount: allCurrencies.length,
              itemBuilder: (_, i) {
                final code = allCurrencies[i];
                final defaultSymbol = defaultCurrencySymbols[code]!;
                final currentSymbol = overrides[code] ?? defaultSymbol;
                final isOverridden = overrides.containsKey(code);

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(currentSymbol,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent)),
                    ),
                  ),
                  title: Text(code,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.tp(context))),
                  subtitle: isOverridden
                      ? Text('Default: $defaultSymbol',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.ts(context)))
                      : null,
                  trailing: isOverridden
                      ? GestureDetector(
                          onTap: () => ref
                              .read(currencySymbolProvider.notifier)
                              .removeOverride(code),
                          child: Icon(Icons.restart_alt_rounded,
                              size: 18, color: AppColors.th(context)),
                        )
                      : Icon(Icons.edit_outlined,
                          size: 16, color: AppColors.th(context)),
                  onTap: () => _editSymbol(context, code, currentSymbol),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _editSymbol(
      BuildContext context, String code, String currentSymbol) async {
    final ctrl = TextEditingController(text: currentSymbol);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Symbol for $code'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. ${defaultCurrencySymbols[code]}',
            filled: true,
            fillColor: AppColors.sfv(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      ref.read(currencySymbolProvider.notifier).setOverride(code, result);
    }
  }
}

// ─── Number Format Editor Sheet ────────────────────────────────────────────

class _NumberFormatSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_NumberFormatSheet> createState() => _NumberFormatSheetState();
}

class _NumberFormatSheetState extends ConsumerState<_NumberFormatSheet> {
  late ThousandsSeparator _thousands;
  late DecimalSeparator _decimal;
  late NegativeFormat _negative;

  @override
  void initState() {
    super.initState();
    final current = ref.read(numberFormatProvider);
    _thousands = current.thousands;
    _decimal = current.decimal;
    _negative = current.negative;
  }

  String get _preview {
    // Temporarily apply to get a preview
    final old = NumberFormatPrefs(
        thousands: _thousands, decimal: _decimal, negative: _negative);
    setNumberFormatPrefs(old);
    final pos = formatAmount(1234567.89, currency: 'USD');
    final neg = formatAmount(-500.00, currency: 'USD');
    return '$pos  |  $neg';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.sfv(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Number Format',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.tp(context))),
            const SizedBox(height: 6),
            Text('Choose how numbers are displayed throughout the app.',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.ts(context),
                    height: 1.4)),
            const SizedBox(height: 16),

            // Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.sfv(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text('Preview',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ts(context))),
                  const SizedBox(height: 6),
                  Text(_preview,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tp(context))),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Thousands separator
            Text('Thousands Separator',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tp(context))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ThousandsSeparator.values.map((t) {
                final selected = t == _thousands;
                // Skip combinations where thousands == decimal
                final conflicts = (t == ThousandsSeparator.comma &&
                        _decimal == DecimalSeparator.comma) ||
                    (t == ThousandsSeparator.period &&
                        _decimal == DecimalSeparator.period);
                return GestureDetector(
                  onTap: conflicts
                      ? null
                      : () => setState(() => _thousands = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : AppColors.sfv(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: selected
                              ? AppColors.accent
                              : AppColors.bd(context)),
                    ),
                    child: Text(t.label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                            color: conflicts
                                ? AppColors.th(context)
                                : selected
                                    ? AppColors.accent
                                    : AppColors.tp(context))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Decimal separator
            Text('Decimal Separator',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tp(context))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: DecimalSeparator.values.map((d) {
                final selected = d == _decimal;
                final conflicts = (d == DecimalSeparator.comma &&
                        _thousands == ThousandsSeparator.comma) ||
                    (d == DecimalSeparator.period &&
                        _thousands == ThousandsSeparator.period);
                return GestureDetector(
                  onTap: conflicts
                      ? null
                      : () => setState(() => _decimal = d),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : AppColors.sfv(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: selected
                              ? AppColors.accent
                              : AppColors.bd(context)),
                    ),
                    child: Text(d.label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                            color: conflicts
                                ? AppColors.th(context)
                                : selected
                                    ? AppColors.accent
                                    : AppColors.tp(context))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Negative format
            Text('Negative Numbers',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tp(context))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: NegativeFormat.values.map((n) {
                final selected = n == _negative;
                return GestureDetector(
                  onTap: () => setState(() => _negative = n),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : AppColors.sfv(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: selected
                              ? AppColors.accent
                              : AppColors.bd(context)),
                    ),
                    child: Text(n.label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected
                                ? AppColors.accent
                                : AppColors.tp(context))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: () {
                ref.read(numberFormatProvider.notifier).update(
                    NumberFormatPrefs(
                        thousands: _thousands,
                        decimal: _decimal,
                        negative: _negative));
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Backup Reminder Banner (moved from dashboard) ──────────────────────────

class _SettingsBackupBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showReminder = ref.watch(showBackupReminderProvider);
    final daysSince = ref.watch(daysSinceBackupProvider);

    return showReminder.when(
      data: (show) {
        if (!show) return const SizedBox.shrink();
        final days = daysSince.value ?? -1;
        final message = days == -1
            ? "You haven't backed up yet"
            : "You haven't backed up in $days days";

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.caution.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.caution.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.backup_rounded,
                        size: 18, color: AppColors.caution),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tp(context),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await snoozeBackupReminder();
                        ref.invalidate(showBackupReminderProvider);
                      },
                      child: Icon(Icons.close_rounded,
                          size: 18, color: AppColors.ts(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/backup'),
                    icon: const Icon(Icons.backup_rounded, size: 16),
                    label: const Text('Backup Now',
                        style: TextStyle(fontSize: 12)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.caution,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
