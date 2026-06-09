import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/accent_color_provider.dart';
import '../../core/providers/biometric_provider.dart';
import '../../core/providers/currency_symbol_provider.dart';
import '../../core/providers/database_provider.dart';
import 'package:intl/intl.dart';

import '../../core/providers/date_format_provider.dart';
import '../../core/providers/number_format_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/autofill_provider.dart';
import '../../core/providers/entry_mode_provider.dart';
import '../../core/providers/home_tab_provider.dart';
import '../../core/providers/font_provider.dart';
import '../../core/providers/arabic_digits_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/text_scale_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/receipt_sync_provider.dart';
import '../../core/providers/sync_provider.dart';
import '../../core/providers/backup_reminder_provider.dart';
import '../../core/providers/premium_provider.dart';
import '../../core/providers/tx_colors_provider.dart';
import '../../core/services/daily_reminder_service.dart';
import '../../core/sync/google_drive_provider.dart';
import '../../core/sync/invite_code.dart';
import '../../features/transactions/widgets/currency_sheet.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/app_info.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/utils/format_number.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(householdProvider).value;
    final l = S.of(context);

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.settingsMoreTitle,
                          style: TextStyle(
                              fontSize: TypographyTokens.screenTitleSize,
                              fontWeight: TypographyTokens.screenTitleWeight,
                              color: AppColors.tp(context))),
                      if (household != null)
                        Text(
                          '${household.name} · ${household.baseCurrency}',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.ts(context)),
                        ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/about'),
                    child: Text('v$appVersion',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.th(context))),
                  ),
                ],
              ),
            ),

            // ── Backup Reminder Banner ──
            _SettingsBackupBanner(),

            // ── Essentials (used weekly) ──
            _SettingsTile(icon: Icons.credit_card_rounded, title: l.navAccounts,
                subtitle: l.settingsAccountsSub,
                iconColor: const Color(0xFF1565C0),
                onTap: () => context.push('/accounts')),
            _SettingsTile(icon: Icons.label_rounded, title: l.navCategories,
                subtitle: l.settingsCategoriesSub,
                iconColor: const Color(0xFFBA68C8),
                onTap: () => context.push('/categories')),
            const SizedBox(height: 20),

            // ── Tools ──
            _SectionHeader(title: l.settingsToolsSection),
            const SizedBox(height: 8),
            _SettingsTile(icon: Icons.repeat_rounded, title: l.tileRecurringBills,
                subtitle: l.settingsRecurringSub,
                iconColor: const Color(0xFFFF7043),
                onTap: () => context.push('/recurring')),
            _SettingsTile(icon: Icons.subscriptions_rounded, title: l.tileSubscriptions,
                subtitle: l.settingsSubscriptionsSub,
                iconColor: AppColors.accent,
                onTap: () => context.push('/subscriptions')),
            _SettingsTile(icon: Icons.flag_rounded, title: l.tileGoalsLoans,
                subtitle: l.settingsGoalsSub,
                iconColor: const Color(0xFF22C55E),
                onTap: () => context.push('/objectives')),
            _SettingsTile(icon: Icons.event_note_rounded, title: l.plannedTitle,
                subtitle: l.plannedSubtitle,
                iconColor: const Color(0xFF7E57C2),
                onTap: () {
                  if (!checkPremiumAccess(context, ref, PremiumFeature.plannedPayments)) return;
                  context.push('/planned-payments');
                }),
            _SettingsTile(icon: Icons.call_split_rounded, title: l.tileBillSplitter,
                subtitle: l.settingsBillSplitterSub,
                iconColor: const Color(0xFF26A69A),
                onTap: () {
                  if (!checkPremiumAccess(context, ref, PremiumFeature.billSplitter)) return;
                  context.push('/bill-splitter');
                }),
            _SettingsTile(icon: Icons.flight_takeoff_rounded, title: l.tileTravelExchange,
                subtitle: l.settingsTravelSub,
                iconColor: const Color(0xFF42A5F5),
                onTap: () {
                  if (!checkPremiumAccess(context, ref, PremiumFeature.travelExchange)) return;
                  context.push('/travel-exchange');
                }),
            _SettingsTile(icon: Icons.computer_rounded, title: l.tileWebCompanion,
                subtitle: l.settingsWebCompanionSub,
                iconColor: const Color(0xFF0EA5E9),
                onTap: () {
                  if (!checkPremiumAccess(context, ref, PremiumFeature.webCompanion)) return;
                  context.push('/web-companion');
                }),
            const SizedBox(height: 20),

            // ── Settings (navigates to dedicated screen) ──
            _SettingsTile(icon: Icons.settings_rounded, title: l.settingsCustomization,
                subtitle: l.settingsCustomizationSub,
                iconColor: AppColors.ts(context),
                onTap: () => context.push('/settings')),
            const SizedBox(height: 8),
            _SettingsTile(icon: Icons.help_outline_rounded, title: l.tileHelpGuide,
                subtitle: l.settingsHelpSub,
                iconColor: const Color(0xFF0EA5E9),
                onTap: () => context.push('/help')),
            const SizedBox(height: 8),
            _SettingsTile(icon: Icons.info_outline_rounded, title: l.settingsAbout,
                subtitle: l.settingsVersionN(appVersion), iconColor: AppColors.th(context),
                onTap: () => context.push('/about')),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared helper functions (used by both SettingsScreen and SettingsDetailScreen)
// ═══════════════════════════════════════════════════════════════════════════

void _showShareHousehold(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(syncProvider.notifier);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareHouseholdSettingsSheet(
        googleDrive: notifier.googleDrive,
      ),
    );
  }

  void _showAutofillSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final settings = ref.watch(autofillProvider);
            final notifier = ref.read(autofillProvider.notifier);

            void toggle(AutofillSettings Function(AutofillSettings) update) {
              notifier.update(update(settings));
              setSheetState(() {}); // force sheet rebuild
            }

            final al = S.of(ctx);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.th(ctx),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(al.autofillTitle,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tp(ctx))),
                  const SizedBox(height: 4),
                  Text(
                    al.autofillDesc,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.ts(ctx)),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(al.autofillAccount, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(al.autofillAccountSub,
                        style: const TextStyle(fontSize: 11)),
                    value: settings.account,
                    onChanged: (v) => toggle((s) => s.copyWith(account: v)),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(al.autofillTitleToggle, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(al.autofillTitleSub,
                        style: const TextStyle(fontSize: 11)),
                    value: settings.title,
                    onChanged: (v) => toggle((s) => s.copyWith(title: v)),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(al.autofillAmountToggle, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(al.autofillAmountSub,
                        style: const TextStyle(fontSize: 11)),
                    value: settings.amount,
                    onChanged: (v) => toggle((s) => s.copyWith(amount: v)),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(al.autofillCategoryToggle, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(al.autofillCategorySub,
                        style: const TextStyle(fontSize: 11)),
                    value: settings.category,
                    onChanged: (v) => toggle((s) => s.copyWith(category: v)),
                  ),
                  const Divider(),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(al.autofillOverride,
                        style: const TextStyle(fontSize: 14)),
                    subtitle: Text(
                        al.autofillOverrideSub,
                        style: const TextStyle(fontSize: 11)),
                    value: settings.overrideExisting,
                    onChanged: (v) =>
                        toggle((s) => s.copyWith(overrideExisting: v)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEntryModePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EntryModeSheet(),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final l = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l.resetTitle),
        content: Text(l.resetContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.overspent),
            child: Text(l.resetButton),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final db = ref.read(databaseProvider);

      // Delete all rows from all tables (keeps DB connection alive for providers)
      await db.batch((batch) {
        batch.deleteAll(db.allocationLedger);
        batch.deleteAll(db.transactionLines);
        batch.deleteAll(db.transactions);
        batch.deleteAll(db.allocations);
        batch.deleteAll(db.categories);
        batch.deleteAll(db.accounts);
        batch.deleteAll(db.recurringTransactions);
        batch.deleteAll(db.transactionTemplates);
        batch.deleteAll(db.objectives);
        batch.deleteAll(db.fxRates);
        batch.deleteAll(db.users);
        batch.deleteAll(db.households);
      });

      // Clear preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Navigate to onboarding — DB stays open so providers won't crash
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
                  style: TextStyle(
                      fontSize: 13, color: AppColors.ts(context))),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLength: 100,
              textCapitalization: capitalize
                  ? TextCapitalization.characters
                  : TextCapitalization.words,
              decoration: InputDecoration(
                counterText: '',
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
                    borderRadius: BorderRadius.circular(CardTokens.radius)),
              ),
              child: Text(S.of(context).commonSave,
                  style: const
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

    final tr = S.of(context);
    final colorSurface = AppColors.sf(context);
    final colorSurfaceVariant = AppColors.sfv(context);
    final colorTextPrimary = AppColors.tp(context);
    final colorTextSecondary = AppColors.ts(context);
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
            color: colorSurface,
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
                        color: colorSurfaceVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(tr.txColorsTitle,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: colorTextPrimary)),
                  const SizedBox(height: 6),
                  Text(
                    tr.txColorsDesc,
                    style: TextStyle(
                        fontSize: 13,
                        color: colorTextSecondary,
                        height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  // Preview
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorSurfaceVariant,
                      borderRadius: BorderRadius.circular(CardTokens.radius),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _colorPreviewChip(
                            tr.typeIncome, '+\$500', incomeColor, ctx),
                        _colorPreviewChip(
                            tr.typeExpense, '-\$120', expenseColor, ctx),
                        _colorPreviewChip(
                            tr.typeTransfer, '\$200', transferColor, ctx),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Color pickers
                  _colorPickerRow(tr.typeExpense, expenseColor, presets, (c) {
                    setSheetState(() => expenseColor = c);
                  }, Icons.arrow_upward_rounded, ctx),
                  const SizedBox(height: 16),
                  _colorPickerRow(tr.typeIncome, incomeColor, presets, (c) {
                    setSheetState(() => incomeColor = c);
                  }, Icons.arrow_downward_rounded, ctx),
                  const SizedBox(height: 16),
                  _colorPickerRow(tr.typeTransfer, transferColor, presets, (c) {
                    setSheetState(() => transferColor = c);
                  }, Icons.swap_horiz_rounded, ctx),
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
                    child: Text(tr.commonSave,
                        style: const TextStyle(
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
                    child: Text(tr.txColorsReset,
                        style: TextStyle(
                            color: colorTextSecondary, fontSize: 13)),
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
                  style: TextStyle(
                      fontSize: 13, color: AppColors.ts(context))),
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
                    borderRadius: BorderRadius.circular(CardTokens.radius)),
              ),
              child: Text(S.of(context).commonSave,
                  style: const
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
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(16),
              child: Text(S.of(context).themeTitle, style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w700, color: AppColors.tp(context)))),
          for (final entry in [
            ('system', S.of(context).themeSystem, S.of(context).themeFollowDevice),
            ('light', S.of(context).themeLight, null),
            ('dark', S.of(context).themeDark, null),
            ('black', S.of(context).themeBlack, S.of(context).themeAmoled),
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

  void _showAccentColorPicker(BuildContext context, WidgetRef ref) async {
    final current = ref.read(accentColorProvider);
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(16),
              child: Text(S.of(context).accentColorTitle, style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w700, color: AppColors.tp(context)))),
          // System option
          ListTile(
            leading: Icon(current == 'system'
                ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: AppColors.accent),
            title: Text(S.of(context).accentColorSystem),
            subtitle: Text(S.of(context).accentColorSystemSub),
            onTap: () => Navigator.pop(ctx, 'system'),
          ),
          // Default
          ListTile(
            leading: Icon(current == 'default'
                ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: const Color(0xFF2563EB)),
            title: Text(S.of(context).accentColorRoyalBlue),
            subtitle: Text(S.of(context).accentColorDefault),
            trailing: Container(width: 24, height: 24,
                decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle)),
            onTap: () => Navigator.pop(ctx, 'default'),
          ),
          // Color grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(spacing: 12, runSpacing: 12,
              children: accentColorOptions.entries
                  .where((e) => e.key != 'default')
                  .map((e) {
                final color = AppColors.fromHex(e.value);
                final isSelected = current == e.key;
                return GestureDetector(
                  onTap: () => Navigator.pop(ctx, e.key),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: AppColors.tp(context), width: 3) : null,
                      boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)] : null,
                    ),
                    child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ]),
      ),
    );
    if (picked != null) ref.read(accentColorProvider.notifier).setColor(picked);
  }

  void _showDateFormatPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _DateFormatSheet(),
    );
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
              child: Text(S.of(context).startScreenTitle, style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w700, color: AppColors.tp(context)))),
          Text(S.of(context).startScreenDesc,
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
              child: Text(S.of(context).chooseFontTitle, style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w700, color: AppColors.tp(context)))),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...appFonts.keys.map((font) => ListTile(
                        leading: Icon(font == currentFont
                            ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: AppColors.accent),
                        title: Text(font, style: fontStyle(font, fontSize: 16)),
                        subtitle: Text(S.of(context).fontPreview,
                            style: fontStyle(font, fontSize: 12,
                                color: AppColors.ts(context))),
                        onTap: () => Navigator.pop(ctx, font),
                      )),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
    if (picked != null) ref.read(fontProvider.notifier).setFont(picked);
  }

  void _showTextSizePicker(BuildContext context, WidgetRef ref) async {
    final current = ref.read(textScaleProvider);
    final picked = await showModalBottomSheet<double>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(16),
              child: Text(S.of(context).textSizeTitle, style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w700, color: AppColors.tp(context)))),
          ...textScaleOptions.entries.map((e) => ListTile(
                leading: Icon(
                    (e.key - current).abs() < 0.01
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: AppColors.accent),
                title: Text(e.value),
                subtitle: Text(S.of(context).textSizePreview,
                    style: TextStyle(fontSize: 14 * e.key,
                        color: AppColors.ts(context))),
                onTap: () => Navigator.pop(ctx, e.key),
              )),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (picked != null) ref.read(textScaleProvider.notifier).setScale(picked);
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) async {
    final current = ref.read(localeProvider);
    // Capture all context-dependent values before the sheet to avoid
    // _dependents.isEmpty crash when locale change rebuilds MaterialApp.
    final tr = S.of(context);
    final titleColor = AppColors.tp(context);
    final subtitleColor = AppColors.ts(context);
    final options = <(String?, String, String?)>[
      (null, tr.languageSystem, tr.languageSystemDesc),
      ('en', tr.languageEnglish, null),
      ('ar', tr.languageArabic, null),
      ('fr', tr.languageFrench, null),
    ];
    final picked = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(16),
              child: Text(tr.languagePickerTitle, style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w700, color: titleColor))),
          for (final (code, label, subtitle) in options)
            ListTile(
              leading: Icon(
                  current == code
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: AppColors.accent),
              title: Text(label),
              subtitle: subtitle != null ? Text(subtitle,
                  style: TextStyle(fontSize: 12, color: subtitleColor)) : null,
              onTap: () => Navigator.pop(ctx, code ?? '__system__'),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (picked != null) {
      ref.read(localeProvider.notifier).setLocale(
          picked == '__system__' ? null : picked);
    }
  }

// ─── Entry Mode Selection Sheet ───────────────────────────────────────────

class _EntryModeSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(entryModeProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          Text(S.of(context).entryModeTitle,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.tp(context))),
          const SizedBox(height: 6),
          Text(S.of(context).entryModeDesc,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.ts(context),
                  height: 1.4)),
          const SizedBox(height: 20),
          _EntryModeCard(
            icon: Icons.auto_fix_high_rounded,
            title: S.of(context).entryModeAssisted,
            description: S.of(context).entryModeAssistedDesc,
            isSelected: currentMode == 'assisted',
            onTap: () {
              ref.read(entryModeProvider.notifier).setMode('assisted');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
          _EntryModeCard(
            icon: Icons.list_alt_rounded,
            title: S.of(context).entryModeClassic,
            description: S.of(context).entryModeClassicDesc,
            isSelected: currentMode == 'classic',
            onTap: () {
              ref.read(entryModeProvider.notifier).setMode('classic');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _EntryModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _EntryModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.sfv(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : AppColors.bd(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : AppColors.th(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.ts(context)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.tp(context))),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded,
                            size: 20, color: AppColors.accent),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(description,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.ts(context),
                          height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Settings Detail Screen — all configuration options
// ═══════════════════════════════════════════════════════════════════════════

class SettingsDetailScreen extends ConsumerWidget {
  const SettingsDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(householdProvider).value;

    final l = S.of(context);
    final themeLabel = switch (ref.watch(themeModeProvider)) {
      'light' => l.themeLight,
      'dark' => l.themeDark,
      'black' => l.themeBlack,
      _ => l.themeSystem,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Appearance ──
          _SectionHeader(title: l.settingsAppearanceSection),
          const SizedBox(height: 8),
          _SettingsTile(icon: Icons.palette_outlined, title: l.tileTheme,
              subtitle: themeLabel, iconColor: AppColors.accent,
              onTap: () => _showThemePicker(context, ref)),
          Builder(builder: (context) {
            final accentVal = ref.watch(accentColorProvider);
            final accentLabel = accentVal == 'system' ? S.of(context).accentColorSystemLabel
                : accentVal == 'default' ? S.of(context).accentColorRoyalBlue : accentVal;
            return _SettingsTile(icon: Icons.colorize_rounded, title: S.of(context).tileAccentColor,
                subtitle: accentLabel, iconColor: ref.read(accentColorProvider.notifier).resolve() ?? AppColors.accent,
                onTap: () => _showAccentColorPicker(context, ref));
          }),
          _SettingsTile(icon: Icons.color_lens_outlined, title: l.tileColors,
              subtitle: l.tileColorsSub, iconColor: const Color(0xFFEC407A),
              onTap: () => _showColorConfig(context, ref)),
          Builder(builder: (context) {
            final mode = ref.watch(entryModeProvider);
            return _SettingsTile(icon: Icons.touch_app_outlined, title: S.of(context).tileEntryMode,
                subtitle: mode == 'assisted' ? S.of(context).entryModeAssistedShort : S.of(context).entryModeClassicShort,
                iconColor: const Color(0xFF42A5F5),
                onTap: () => _showEntryModePicker(context, ref));
          }),
          _SettingsTile(
            icon: Icons.auto_fix_high_rounded,
            title: l.tileAutofill,
            subtitle: l.tileAutofillSub,
            iconColor: const Color(0xFF26A69A),
            onTap: () => _showAutofillSettings(context, ref),
          ),
          Builder(builder: (context) {
            final homeTab = ref.watch(homeTabProvider);
            final sl = S.of(context);
            final homeTabLabel = [sl.tabHome, sl.tabActivity, sl.tabBudget, sl.tabReports, sl.tabMore][homeTab];
            return _SettingsTile(icon: Icons.home_outlined, title: sl.tileStartScreen,
                subtitle: homeTabLabel,
                iconColor: const Color(0xFF26A69A),
                onTap: () => _showHomeTabPicker(context, ref));
          }),
          Builder(builder: (context) {
            final font = ref.watch(fontProvider);
            return _SettingsTile(icon: Icons.text_fields_rounded, title: S.of(context).tileFont,
                subtitle: font, iconColor: const Color(0xFF7E57C2),
                onTap: () => _showFontPicker(context, ref));
          }),
          Builder(builder: (context) {
            final scale = ref.watch(textScaleProvider);
            final sl = S.of(context);
            final scaleLabels = <double, String>{0.85: sl.textScaleSmall, 1.0: sl.textScaleDefault, 1.15: sl.textScaleLarge, 1.3: sl.textScaleExtraLarge};
            final label = scaleLabels[scale] ?? '${(scale * 100).round()}%';
            return _SettingsTile(icon: Icons.format_size_rounded, title: sl.tileTextSize,
                subtitle: label, iconColor: const Color(0xFF5C6BC0),
                onTap: () => _showTextSizePicker(context, ref));
          }),
          Builder(builder: (context) {
            final localeCode = ref.watch(localeProvider);
            final langLabel = switch (localeCode) {
              'en' => S.of(context).languageEnglish,
              'ar' => S.of(context).languageArabic,
              'fr' => S.of(context).languageFrench,
              _ => S.of(context).languageSystem,
            };
            return _SettingsTile(icon: Icons.language_rounded, title: S.of(context).tileLanguage,
                subtitle: langLabel, iconColor: const Color(0xFF26A69A),
                onTap: () => _showLanguagePicker(context, ref));
          }),
          // Arabic-Indic digits toggle — only visible when Arabic locale
          Builder(builder: (context) {
            final localeNow = ref.watch(localeProvider);
            final resolvedLocale = localeNow ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode;
            if (resolvedLocale != 'ar') return const SizedBox.shrink();
            final useArabic = ref.watch(arabicDigitsProvider);
            return SwitchListTile(
              secondary: Icon(Icons.format_list_numbered_rounded, color: const Color(0xFF26A69A)),
              title: Text(S.of(context).tileArabicDigits),
              subtitle: Text(useArabic ? '٠١٢٣٤٥٦٧٨٩' : '0123456789'),
              value: useArabic,
              onChanged: (_) => ref.read(arabicDigitsProvider.notifier).toggle(),
            );
          }),
          _SettingsTile(icon: Icons.view_list_rounded, title: l.tileTxList,
              subtitle: l.tileTxListSub,
              iconColor: const Color(0xFF42A5F5),
              onTap: () => context.push('/tx-list-settings')),
          const SizedBox(height: 20),

          // ── Data & Sync ──
          _SectionHeader(title: l.settingsDataSection),
          const SizedBox(height: 8),
          _SettingsTile(icon: Icons.cloud_sync_rounded, title: l.tileCloudSync,
              subtitle: l.tileCloudSyncSub, iconColor: AppColors.accent,
              onTap: () {
                if (!checkPremiumAccess(context, ref, PremiumFeature.sync)) return;
                context.push('/sync');
              }),
          Builder(builder: (context) {
            final syncState = ref.watch(syncProvider);
            final isConnected = syncState.activeProvider is GoogleDriveProvider;
            return _SettingsTile(
              icon: Icons.people_outline_rounded,
              title: S.of(context).tileShareHousehold,
              subtitle: isConnected
                  ? S.of(context).tileShareHouseholdConnected
                  : S.of(context).tileShareHouseholdDisconnected,
              iconColor: const Color(0xFF7E57C2),
              onTap: () {
                if (isConnected) {
                  _showShareHousehold(context, ref);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(S.of(context).tileShareHouseholdSnackbar),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            );
          }),
          _SettingsTile(icon: Icons.backup_rounded, title: l.tileBackupRestore,
              subtitle: l.tileBackupRestoreSub, iconColor: const Color(0xFF42A5F5),
              onTap: () => context.push('/backup')),
          _SettingsTile(icon: Icons.import_export_rounded, title: l.tileImportExport,
              subtitle: l.tileImportExportSub, iconColor: const Color(0xFF66BB6A),
              onTap: () => context.push('/import-export')),
          _SettingsTile(
              icon: Icons.notifications_active_rounded,
              title: l.tileNotifications,
              subtitle: l.tileNotificationsSub,
              iconColor: const Color(0xFFFF9800),
              onTap: () => context.push('/notifications')),
          _SettingsTile(
              icon: Icons.monitor_heart_rounded,
              title: l.tileHealthCheck,
              subtitle: l.tileHealthCheckSub,
              iconColor: const Color(0xFF4DB6AC),
              onTap: () => context.push('/health-check')),
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
                    borderRadius: BorderRadius.circular(CardTokens.radius),
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
                    title: Text(S.of(context).tileSyncReceipts,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tp(context))),
                    subtitle: Text(
                      receiptSyncEnabled
                          ? S.of(context).tileSyncReceiptsOn
                          : S.of(context).tileSyncReceiptsOff,
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
                        Text(S.of(context).tileSyncReceiptsOff,
                            style: TextStyle(
                                fontSize: 11, color: AppColors.caution)),
                      ],
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: 20),

          // ── Preferences ──
          _SectionHeader(title: l.settingsPreferencesSection),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.home_rounded,
            title: l.householdNameTitle,
            subtitle: household?.name ?? 'BudgetSeal',
            iconColor: AppColors.accent,
            onTap: () => _editText(context, ref,
                title: l.householdNameTitle,
                currentValue: household?.name ?? '',
                onSave: (val) async {
                  final db = ref.read(databaseProvider);
                  await (db.update(db.households)
                        ..where((h) => h.id.equals(household!.id)))
                      .write(HouseholdsCompanion(name: Value(val)));
                }),
          ),
          _SettingsTile(
            icon: Icons.monetization_on_rounded,
            title: l.tileBaseCurrency,
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
            title: l.tilePeriodStartDay,
            subtitle: l.onboardDayN(household?.periodStartDay ?? 1),
            iconColor: AppColors.caution,
            onTap: () => _editNumber(context, ref,
                title: l.tilePeriodStartDay,
                currentValue: household?.periodStartDay ?? 1,
                min: 1, max: 28,
                description: l.tilePeriodStartDayDesc,
                onSave: (val) async {
                  final db = ref.read(databaseProvider);
                  await (db.update(db.households)
                        ..where((h) => h.id.equals(household!.id)))
                      .write(HouseholdsCompanion(periodStartDay: Value(val)));
                }),
          ),
          _SettingsTile(
            icon: Icons.attach_money_rounded,
            title: l.tileCurrencySymbols,
            subtitle: l.tileCurrencySymbolsSub,
            iconColor: const Color(0xFF4DB6AC),
            onTap: () => _showCurrencySymbolEditor(context, ref),
          ),
          Builder(builder: (context) {
            ref.watch(numberFormatProvider);
            final preview = formatAmount(1234567.89);
            return _SettingsTile(
              icon: Icons.format_list_numbered_rounded,
              title: l.tileNumberFormat,
              subtitle: l.settingsPreview(preview),
              iconColor: const Color(0xFF5C6BC0),
              onTap: () => _showNumberFormatEditor(context, ref),
            );
          }),
          Builder(builder: (context) {
            final dateFmt = ref.watch(dateFormatProvider);
            final preview = DateFormat(dateFmt).format(DateTime.now());
            return _SettingsTile(
              icon: Icons.date_range_rounded,
              title: l.tileDateFormat,
              subtitle: preview,
              iconColor: const Color(0xFF7E57C2),
              onTap: () => _showDateFormatPicker(context, ref),
            );
          }),
          const SizedBox(height: 20),

          // ── Security ──
          _SectionHeader(title: l.settingsSecuritySection),
          const SizedBox(height: 8),
          _BiometricTile(),
          const SizedBox(height: 20),

          // ── Danger zone ──
          _SettingsTile(icon: Icons.delete_forever_rounded, title: l.tileResetEverything,
              subtitle: l.tileResetSub, iconColor: AppColors.overspent,
              onTap: () => _confirmReset(context, ref)),
        ],
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
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: TypographyTokens.sectionHeaderSize,
          fontWeight: TypographyTokens.sectionHeaderWeight,
          letterSpacing: TypographyTokens.sectionHeaderLetterSpacing,
          color: AppColors.ts(context),
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
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
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
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.tp(context))),
        subtitle: Text(subtitle,
            style: TextStyle(
                fontSize: 12, color: AppColors.ts(context))),
        trailing: onTap != null
            ? Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.th(context))
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
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
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
        title: Text(S.of(context).tileBiometricLock,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(S.of(context).tileBiometricSub,
            style: TextStyle(fontSize: 12, color: AppColors.ts(context))),
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
            SnackBar(
              content: Text(S.of(context).biometricNotAvailable),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final didAuth = await auth.authenticate(
        localizedReason: S.of(context).biometricVerify,
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );

      if (didAuth) {
        await ref.read(biometricLockProvider.notifier).enable();
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).biometricFailed),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        String message = S.of(context).biometricError;
        final errorStr = e.toString();
        if (errorStr.contains('NotAvailable') || errorStr.contains('NotEnrolled')) {
          message = S.of(context).biometricNotEnrolled;
        } else if (errorStr.contains('LockedOut')) {
          message = S.of(context).biometricLockedOut;
        } else if (errorStr.contains('PasscodeNotSet')) {
          message = S.of(context).biometricPasscodeNotSet;
        } else {
          message = '${S.of(context).biometricError}: $errorStr';
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
    // Pin overridden currencies to the top, then alphabetical
    final allCurrencies = defaultCurrencySymbols.keys.toList()
      ..sort((a, b) {
        final aOver = overrides.containsKey(a);
        final bOver = overrides.containsKey(b);
        if (aOver && !bOver) return -1;
        if (!aOver && bOver) return 1;
        return a.compareTo(b);
      });

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
                Text(S.of(context).currencySymbolsTitle,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.tp(context))),
                const SizedBox(height: 6),
                Text(
                  S.of(context).currencySymbolsDesc,
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
              itemCount: allCurrencies.length + (overrides.isNotEmpty ? 1 : 0),
              itemBuilder: (_, i) {
                // Insert a divider after the pinned overrides
                if (overrides.isNotEmpty && i == overrides.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Expanded(child: Divider(color: AppColors.bd(context))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(S.of(context).currencySymbolsAllSection,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.th(context))),
                      ),
                      Expanded(child: Divider(color: AppColors.bd(context))),
                    ]),
                  );
                }
                final idx = overrides.isNotEmpty && i > overrides.length ? i - 1 : i;
                final code = allCurrencies[idx];
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
                      ? Text(S.of(context).currencySymbolDefault(defaultSymbol),
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
    final tr = S.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.currencySymbolFor(code)),
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
            child: Text(tr.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(tr.commonSave),
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

  void _applyImmediately() {
    final prefs = NumberFormatPrefs(
        thousands: _thousands, decimal: _decimal, negative: _negative);
    ref.read(numberFormatProvider.notifier).update(prefs);
  }

  String get _preview {
    // Temporarily apply to get a preview
    setNumberFormatPrefs(NumberFormatPrefs(
        thousands: _thousands, decimal: _decimal, negative: _negative));
    final pos = formatAmount(1234567.89, currency: 'USD');
    final neg = formatSignedAmount(500.00, currency: 'USD', type: 'expense');
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
            Text(S.of(context).numberFormatTitle,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.tp(context))),
            const SizedBox(height: 6),
            Text(S.of(context).numberFormatDesc,
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
                borderRadius: BorderRadius.circular(CardTokens.radius),
              ),
              child: Column(
                children: [
                  Text(S.of(context).numberFormatPreview,
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
            Text(S.of(context).numberFormatThousands,
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
                      : () { setState(() => _thousands = t); _applyImmediately(); },
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
            if (ThousandsSeparator.values.any((t) =>
                (t == ThousandsSeparator.comma && _decimal == DecimalSeparator.comma) ||
                (t == ThousandsSeparator.period && _decimal == DecimalSeparator.period)))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(S.of(context).numberFormatConflict,
                    style: TextStyle(fontSize: 11, color: AppColors.th(context))),
              ),
            const SizedBox(height: 20),

            // Decimal separator
            Text(S.of(context).numberFormatDecimal,
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
                      : () { setState(() => _decimal = d); _applyImmediately(); },
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
            Text(S.of(context).numberFormatNegative,
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
                  onTap: () { setState(() => _negative = n); _applyImmediately(); },
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Backup Reminder Banner (moved from dashboard) ──────────────────────────

// ─── Date Format Sheet ──────────────────────────────────────────────────────

class _DateFormatSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(dateFormatProvider);
    final now = DateTime.now();

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(S.of(context).dateFormatTitle,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tp(context))),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final entry in dateFormatOptions.entries)
                  ListTile(
                    leading: Icon(
                        current == entry.key
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: AppColors.accent),
                    title: Text(DateFormat(entry.key).format(now)),
                    subtitle: Text(entry.key,
                        style: TextStyle(
                            fontSize: 12, color: AppColors.ts(context))),
                    onTap: () {
                      ref.read(dateFormatProvider.notifier).setFormat(entry.key);
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// ─── Daily Reminder Tile ─────────────────────────────────────────────────────

class _DailyReminderTile extends StatefulWidget {
  const _DailyReminderTile();

  @override
  State<_DailyReminderTile> createState() => _DailyReminderTileState();
}

class _DailyReminderTileState extends State<_DailyReminderTile> {
  bool _enabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 0);
  String _message = '';
  final _messageCtrl = TextEditingController();

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
        _enabled = enabled;
        _time = time;
        _message = message;
        _messageCtrl.text = message;
      });
    }
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            secondary: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications_active_rounded,
                  size: 18, color: Color(0xFFFF9800)),
            ),
            title: Text(S.of(context).notifDailyTitle,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: Text(
              _enabled
                  ? 'Every day at ${_time.format(context)}'
                  : S.of(context).notifDailyDisabled,
              style: TextStyle(fontSize: 12, color: AppColors.ts(context)),
            ),
            value: _enabled,
            onChanged: (v) async {
              await DailyReminderService.setEnabled(v);
              setState(() => _enabled = v);
            },
            activeTrackColor: AppColors.accent,
          ),
          if (_enabled) ...[
            Divider(height: 1, color: AppColors.bd(context)),
            // Time picker
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16),
              dense: true,
              leading: Icon(Icons.schedule_rounded,
                  size: 18, color: AppColors.ts(context)),
              title: Text(S.of(context).notifTime,
                  style: TextStyle(
                      fontSize: 13, color: AppColors.tp(context))),
              trailing: TextButton(
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
            ),
            // Custom message
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
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
                            _messageCtrl.clear();
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
            ),
          ],
        ],
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
        final l = S.of(context);
        final message = days == -1
            ? l.backupBannerNoBackup
            : l.backupBannerDaysAgo(days);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.caution.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(CardTokens.radius),
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
                    label: Text(l.backupNowButton,
                        style: const TextStyle(fontSize: 12)),
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

// ── Share Household Sheet (settings) ─────────────────────────────────────────

class _ShareHouseholdSettingsSheet extends StatefulWidget {
  final GoogleDriveProvider googleDrive;

  const _ShareHouseholdSettingsSheet({required this.googleDrive});

  @override
  State<_ShareHouseholdSettingsSheet> createState() =>
      _ShareHouseholdSettingsSheetState();
}

class _ShareHouseholdSettingsSheetState
    extends State<_ShareHouseholdSettingsSheet> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _inviteCode;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = S.of(context).syncValidEmailError);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.googleDrive.shareFolder(email);
      final folderId = await widget.googleDrive.getFolderId();
      final code = generateInviteCode(folderId);
      setState(() {
        _inviteCode = code;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to share: ${e.toString()}';
      });
    }
  }

  void _shareCode() {
    if (_inviteCode == null) return;
    SharePlus.instance.share(
      ShareParams(
        text: S.of(context).syncShareInviteText(_inviteCode!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.th(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              S.of(context).syncShareHousehold,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.tp(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context).syncShareDesc,
              style: TextStyle(fontSize: 13, color: AppColors.ts(context)),
            ),
            const SizedBox(height: 20),
            if (_inviteCode == null) ...[
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: S.of(context).syncTheirEmail,
                  hintText: S.of(context).syncEmailHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CardTokens.radius),
                  ),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _share,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.share_rounded, size: 20),
                  label: Text(
                    _loading ? S.of(context).syncSharing : S.of(context).syncGenerateInvite,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7E57C2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(CardTokens.radius),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(CardTokens.radius),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).syncInviteCode,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ts(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _inviteCode!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        color: AppColors.tp(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _shareCode,
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: Text(
                    S.of(context).syncShareCode,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(CardTokens.radius),
                    ),
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.overspent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.overspent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.overspent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
