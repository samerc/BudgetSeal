import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/capture/bank_alerts.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/accent_color_provider.dart';
import '../../core/providers/biometric_provider.dart';
import '../../core/providers/hide_amounts_provider.dart';
import '../../core/providers/currency_symbol_provider.dart';
import '../../core/providers/database_provider.dart';
import 'package:intl/intl.dart';

import '../../core/providers/date_format_provider.dart';
import '../../core/providers/number_format_provider.dart';
import '../../core/sync/relay_provider.dart';
import '../../core/sync/sync_encryption.dart';
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
import '../../core/providers/member_names_provider.dart';
import '../../core/services/household_members.dart' show DeviceIdentity;
import '../../features/transactions/widgets/currency_sheet.dart';
import '../../shared/utils/search_match.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/large_title_header.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/utils/app_info.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/dispose_later.dart';
import '../../shared/theme/brand_palette.dart';
import '../../shared/widgets/tappable.dart';
import '../../shared/widgets/app_chip.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/settings_row.dart';
import '../../shared/widgets/sheet_title.dart';
import 'base_currency_flow.dart';
import 'member_name_dialog.dart';
import 'household_invite_sheet.dart';
import '../../shared/utils/biometric_errors.dart';
import '../../shared/theme/app_icons.dart';
import '../../core/services/crash_reports.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(householdProvider).value;
    final l = S.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Title: Cashew large title that collapses on scroll ──
          LargeTitleHeader(
            title: l.settingsMoreTitle,
            subtitle: household == null
                ? null
                : '${household.name} · ${household.baseCurrency} · v$appVersion',
          ),
          SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          sliver: SliverList(delegate: SliverChildListDelegate([
            // ── Backup Reminder Banner ──
            _SettingsBackupBanner(),

            // ── Grouped list: Money / Tools / App ──
            _MoreGroup(title: l.moreMoneySection, rows: [
              _MoreRow(icon: AppIcons.creditCard, title: l.navAccounts,
                  subtitle: l.settingsAccountsSub, hue: 215,
                  onTap: () => context.push('/accounts')),
              _MoreRow(icon: AppIcons.tag, title: l.navCategories,
                  subtitle: l.settingsCategoriesSub, hue: 285,
                  onTap: () => context.push('/categories')),
              _MoreRow(icon: AppIcons.repeat, title: l.tileRecurringBills,
                  subtitle: l.settingsRecurringSub, hue: 18,
                  onTap: () => context.push('/recurring')),
              _MoreRow(icon: AppIcons.playCircle, title: l.tileSubscriptions,
                  subtitle: l.settingsSubscriptionsSub, hue: 340,
                  onTap: () => context.push('/subscriptions')),
              _MoreRow(icon: AppIcons.calendarBlank, title: l.calendarTitle,
                  subtitle: l.settingsCalendarSub, hue: 190,
                  onTap: () => context.push('/calendar')),
              _MoreRow(icon: AppIcons.calendarDots, title: l.plannedTitle,
                  subtitle: l.plannedSubtitle, hue: 255,
                  onTap: () {
                    if (!checkPremiumAccess(context, ref, PremiumFeature.plannedPayments)) return;
                    context.push('/planned-payments');
                  }),
            ]),
            _MoreGroup(title: l.settingsToolsSection, rows: [
              _MoreRow(icon: AppIcons.flag, title: l.tileGoalsLoans,
                  subtitle: l.settingsGoalsSub, hue: 145,
                  onTap: () => context.push('/objectives')),
              _MoreRow(icon: AppIcons.arrowsSplit, title: l.tileBillSplitter,
                  subtitle: l.settingsBillSplitterSub, hue: 172,
                  onTap: () {
                    if (!checkPremiumAccess(context, ref, PremiumFeature.billSplitter)) return;
                    context.push('/bill-splitter');
                  }),
              _MoreRow(icon: AppIcons.airplaneTakeoff, title: l.tileTravelExchange,
                  subtitle: l.settingsTravelSub, hue: 198,
                  onTap: () {
                    if (!checkPremiumAccess(context, ref, PremiumFeature.travelExchange)) return;
                    context.push('/travel-exchange');
                  }),
              _MoreRow(icon: AppIcons.desktop, title: l.tileWebCompanion,
                  subtitle: l.settingsWebCompanionSub, hue: 232,
                  onTap: () {
                    if (!checkPremiumAccess(context, ref, PremiumFeature.webCompanion)) return;
                    context.push('/web-companion');
                  }),
            ]),
            _MoreGroup(title: l.moreAppSection, rows: [
              _MoreRow(icon: AppIcons.gear, title: l.settingsCustomization,
                  subtitle: l.settingsCustomizationSub, hue: 220, neutral: true,
                  onTap: () => context.push('/settings')),
              _MoreRow(icon: AppIcons.question, title: l.tileHelpGuide,
                  subtitle: l.settingsHelpSub, hue: 190,
                  onTap: () => context.push('/help')),
              _MoreRow(icon: AppIcons.info, title: l.settingsAbout,
                  subtitle: l.settingsVersionN(appVersion), hue: 220, neutral: true,
                  onTap: () => context.push('/about')),
            ]),
          ])),
          ),
        ],
      ),
    );
  }
}

/// A floating SnackBar for a settings action's outcome.
void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    behavior: SnackBarBehavior.floating,
  ));
}

/// A [SheetTitle] inside a sheet that already pads its content.
const _inSheetTitlePad = EdgeInsetsDirectional.only(bottom: 12);

// ═══════════════════════════════════════════════════════════════════════════
// Shared helper functions (used by both SettingsScreen and SettingsDetailScreen)
// ═══════════════════════════════════════════════════════════════════════════

/// In a household: its invite. Otherwise Cloud Sync, where one is started.
Future<void> _showShareHousehold(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(syncProvider.notifier);
    if (ref.read(syncProvider).activeProvider is RelayProvider) {
      final key = await notifier.relay.key;
      if (key != null && context.mounted) {
        await showHouseholdInviteSheet(context, key);
      }
      return;
    }
    if (!checkPremiumAccess(context, ref, PremiumFeature.sync)) return;
    context.push('/sync');
  }

  void _showAutofillSettings(BuildContext context, WidgetRef ref) {
    // Strings captured before the sheet (S.of inside a sheet builder is the
    // _dependents.isEmpty crash pattern); a Consumer rebuilds the switches.
    final al = S.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (ctx, sheetRef, _) {
            final settings = sheetRef.watch(autofillProvider);
            final notifier = sheetRef.read(autofillProvider.notifier);

            void toggle(AutofillSettings Function(AutofillSettings) update) {
              notifier.update(update(settings));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SheetTitle(al.autofillTitle,
                      subtitle: al.autofillDesc, padding: _inSheetTitlePad),
                  SettingsSwitchRow(
                    title: al.autofillAccount,
                    subtitle: al.autofillAccountSub,
                    value: settings.account,
                    onChanged: (v) => toggle((s) => s.copyWith(account: v)),
                  ),
                  SettingsSwitchRow(
                    title: al.autofillTitleToggle,
                    subtitle: al.autofillTitleSub,
                    value: settings.title,
                    onChanged: (v) => toggle((s) => s.copyWith(title: v)),
                  ),
                  SettingsSwitchRow(
                    title: al.autofillAmountToggle,
                    subtitle: al.autofillAmountSub,
                    value: settings.amount,
                    onChanged: (v) => toggle((s) => s.copyWith(amount: v)),
                  ),
                  SettingsSwitchRow(
                    title: al.autofillCategoryToggle,
                    subtitle: al.autofillCategorySub,
                    value: settings.category,
                    onChanged: (v) => toggle((s) => s.copyWith(category: v)),
                  ),
                  Divider(color: AppColors.bd(ctx)),
                  SettingsSwitchRow(
                    title: al.autofillOverride,
                    subtitle: al.autofillOverrideSub,
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
    final confirmed = await showConfirmDialog(
      context,
      title: l.resetConfirmTitle,
      message: l.resetContent,
      confirmLabel: l.resetButton,
    );

    if (confirmed && context.mounted) {
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
        batch.deleteAll(db.captureRules);
        batch.deleteAll(db.moneyRequests);
        batch.deleteAll(db.monthReviews);
        batch.deleteAll(db.fxRates);
        batch.deleteAll(db.users);
        batch.deleteAll(db.households);
        // The change log holds a copy of every row: erase it too, and the
        // sync bookkeeping (files read, entries written), or a sync set up
        // for the new budget believes it already read/wrote them.
        batch.customStatement('DELETE FROM sync_ops');
        batch.customStatement('DELETE FROM sync_files');
        batch.customStatement('DELETE FROM sync_meta');
      });

      // Leave sync: the active provider (Drive sign-in, folder), the
      // household key and the sync password. Each on its own, so one
      // failing doesn't keep the others.
      final sync = ref.read(syncProvider.notifier);
      for (final step in <Future<void> Function()>[
        sync.disconnectProvider,
        sync.relay.disconnect,
        SyncEncryption.clearPassword,
      ]) {
        try {
          await step();
        } catch (e) {
          debugPrint('[Reset] Leaving sync: $e');
        }
      }

      // Clear preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      // The router sends onboarding back to Home while a household is set.
      ref.read(currentHouseholdIdProvider.notifier).set(null);

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
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).viewPadding.bottom + 20),
        decoration: BoxDecoration(
          color: AppColors.popup(ctx),
          borderRadius: BorderRadius.vertical(top: Radius.circular(RadiusTokens.sheet)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetTitle(title,
                subtitle: description, padding: _inSheetTitlePad),
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
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text(S.of(ctx).commonSave),
            ),
          ],
        ),
      ),
    );
    disposeAfterRouteAnimation(ctrl);
    if (result != null && result.isNotEmpty && result != currentValue) {
      await onSave(result);
    }
  }

  void _showColorConfig(BuildContext context, WidgetRef ref) {
    final current = ref.read(txColorsProvider);
    final tr = S.of(context);
    final base = ref.read(householdProvider).value?.baseCurrency ?? 'USD';
    const defaults = TxColors();

    final presets = [
      (tr.txColorRed, const Color(0xFFEF4444)),
      (tr.txColorOrange, const Color(0xFFF97316)),
      (tr.txColorAmber, const Color(0xFFF59E0B)),
      (tr.txColorGreen, const Color(0xFF10B981)),
      (tr.txColorTeal, const Color(0xFF14B8A6)),
      (tr.txColorBlue, const Color(0xFF3B82F6)),
      (tr.txColorIndigo, const Color(0xFF6366F1)),
      (tr.txColorPurple, const Color(0xFF8B5CF6)),
      (tr.txColorPink, const Color(0xFFEC4899)),
      (tr.txColorSlate, const Color(0xFF64748B)),
    ];

    // null = the theme-adaptive default (strong green/red, lifted in dark).
    Color? income = current.customIncome;
    Color? expense = current.customExpense;
    Color? transfer = current.customTransfer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetTitle(tr.txColorsTitle,
                      subtitle: tr.txColorsDesc, padding: _inSheetTitlePad),
                  // Preview
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.sfv(ctx),
                      borderRadius: CardTokens.borderRadius,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _colorPreviewChip(
                            tr.typeIncome,
                            formatSignedAmount(500,
                                currency: base, type: 'income'),
                            income ?? defaults.income,
                            ctx),
                        _colorPreviewChip(
                            tr.typeExpense,
                            formatSignedAmount(120,
                                currency: base, type: 'expense'),
                            expense ?? defaults.expense,
                            ctx),
                        _colorPreviewChip(
                            tr.typeTransfer,
                            formatAmount(200, currency: base),
                            transfer ?? defaults.transfer,
                            ctx),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _colorPickerRow(tr.typeExpense, expense, defaults.expense,
                      tr.txColorDefault, presets, (c) {
                    setSheetState(() => expense = c);
                  }, AppIcons.arrowUp, ctx),
                  const SizedBox(height: 16),
                  _colorPickerRow(tr.typeIncome, income, defaults.income,
                      tr.txColorDefault, presets, (c) {
                    setSheetState(() => income = c);
                  }, AppIcons.arrowDown, ctx),
                  const SizedBox(height: 16),
                  _colorPickerRow(tr.typeTransfer, transfer, defaults.transfer,
                      tr.txColorDefault, presets, (c) {
                    setSheetState(() => transfer = c);
                  }, AppIcons.arrowsLeftRight, ctx),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      ref.read(txColorsProvider.notifier).update(TxColors(
                          income: income,
                          expense: expense,
                          transfer: transfer));
                      Navigator.pop(ctx);
                    },
                    child: Text(tr.commonSave),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      // Clear the custom colors so all three follow the
                      // theme-adaptive defaults again.
                      ref
                          .read(txColorsProvider.notifier)
                          .update(const TxColors());
                      Navigator.pop(ctx);
                    },
                    child: Text(tr.txColorsReset),
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
            color: AppColors.pastel(context, color, light: 0.85, dark: 0.78),
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
          child: Text(amount,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: TypographyTokens.overlineSize,
                color: AppColors.ts(context))),
      ],
    );
  }

  /// One type's colors: a "Default" swatch (null) then the presets — all
  /// circles, like the accent swatches.
  Widget _colorPickerRow(
      String label,
      Color? selected,
      Color defaultColor,
      String defaultLabel,
      List<(String, Color)> presets,
      ValueChanged<Color?> onChanged,
      IconData icon,
      BuildContext context) {
    final shown = selected ?? defaultColor;
    Widget swatch(String name, Color color, bool isSelected, Color? value) {
      return Tappable(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(RadiusTokens.sm),
        child: SizedBox(
          width: 52,
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isSelected
                          ? AppColors.tp(context)
                          : AppColors.bd(context),
                      width: isSelected ? 2.5 : 1),
                ),
                child: isSelected
                    ? Icon(AppIcons.check,
                        size: 18, color: AppColors.inkOn(color))
                    : null,
              ),
              const SizedBox(height: 3),
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: TypographyTokens.miniSize,
                      color: isSelected
                          ? AppColors.tp(context)
                          : AppColors.ts(context))),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.pastel(context, shown, light: 0.85, dark: 0.78),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: shown),
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
          spacing: 4,
          runSpacing: 8,
          children: [
            swatch(defaultLabel, defaultColor, selected == null, null),
            for (final p in presets)
              swatch(
                  p.$1,
                  p.$2,
                  selected != null && p.$2.toARGB32() == selected.toARGB32(),
                  p.$2),
          ],
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
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).viewPadding.bottom + 20),
        decoration: BoxDecoration(
          color: AppColors.popup(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(RadiusTokens.sheet)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetTitle(title,
                subtitle: description, padding: _inSheetTitlePad),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '$min–$max',
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
              child: Text(S.of(context).commonSave),
            ),
          ],
        ),
      ),
    );
    disposeAfterRouteAnimation(ctrl);
    if (result != null && result != currentValue) {
      await onSave(result);
    }
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) async {
    final mode = ref.read(themeModeProvider);
    // Capture localized strings + colors before the sheet (avoids the
    // _dependents.isEmpty pattern from using the outer context in the builder).
    final tr = S.of(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SheetTitle(tr.themeTitle),
          for (final entry in [
            ('system', tr.themeSystem, tr.themeFollowDevice),
            ('light', tr.themeLight, null),
            ('dark', tr.themeDark, null),
            ('black', tr.themeBlack, tr.themeAmoled),
          ])
            ListTile(
              leading: Icon(mode == entry.$1
                  ? AppIcons.radioButtonFill : AppIcons.circle,
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
    final tr = S.of(context);
    final tpColor = AppColors.tp(context);
    final ringBg = AppColors.popup(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SheetTitle(tr.accentColorTitle,
                  subtitle: tr.accentColorPairHint,
                  padding: const EdgeInsetsDirectional.only(bottom: 20)),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 8,
                childAspectRatio: 0.85,
                children: [
                  for (final p in brandPalette)
                    _AccentSwatch(
                      pair: p,
                      label: accentPairName(tr, p.id),
                      selected: current == p.id,
                      ringBg: ringBg,
                      ringColor: tpColor,
                      onTap: () => Navigator.pop(ctx, p.id),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                    current == 'system'
                        ? AppIcons.radioButtonFill
                        : AppIcons.circle,
                    color: AppColors.accent),
                title: Text(tr.accentColorSystem),
                subtitle: Text(tr.accentColorSystemSub),
                onTap: () => Navigator.pop(ctx, 'system'),
              ),
            ],
          ),
        ),
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
    final tr = S.of(context);
    final tsColor = AppColors.ts(context);
    // Localized tab labels (homeTabLabels is English-only, used for storage).
    final labels = [tr.tabHome, tr.tabActivity, tr.tabBudget, tr.tabReports, tr.tabMore];
    // The nav bar's icons (main_screen.dart), so the choice is recognisable.
    final icons = [AppIcons.house, AppIcons.arrowsDownUp,
        AppIcons.wallet, AppIcons.chartPie,
        AppIcons.squaresFour];
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SheetTitle(tr.startScreenTitle, subtitle: tr.startScreenDesc),
          for (var i = 0; i < labels.length; i++)
            ListTile(
              leading: Icon(i == homeTab
                  ? AppIcons.radioButtonFill : AppIcons.circle,
                  color: AppColors.accent),
              title: Text(labels[i]),
              trailing: Icon(icons[i], size: 20, color: tsColor),
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
    final tr = S.of(context);
    final tsColor = AppColors.ts(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SheetTitle(tr.chooseFontTitle),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...appFonts.keys.map((font) => ListTile(
                        leading: Icon(font == currentFont
                            ? AppIcons.radioButtonFill : AppIcons.circle,
                            color: AppColors.accent),
                        title: Text(font, style: fontStyle(font, fontSize: 16)),
                        subtitle: Text(tr.fontPreview,
                            style: fontStyle(font, fontSize: 12,
                                color: tsColor)),
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
    final tr = S.of(context);
    final tsColor = AppColors.ts(context);
    // Localized labels (textScaleOptions values are English-only fallbacks).
    final scaleLabels = <double, String>{
      0.85: tr.textScaleSmall,
      1.0: tr.textScaleDefault,
      1.15: tr.textScaleLarge,
      1.3: tr.textScaleExtraLarge,
    };
    final picked = await showModalBottomSheet<double>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SheetTitle(tr.textSizeTitle),
          ...textScaleOptions.entries.map((e) => ListTile(
                leading: Icon(
                    (e.key - current).abs() < 0.01
                        ? AppIcons.radioButtonFill
                        : AppIcons.circle,
                    color: AppColors.accent),
                title: Text(scaleLabels[e.key] ?? e.value),
                subtitle: Text(tr.textSizePreview,
                    style: TextStyle(fontSize: 14 * e.key,
                        color: tsColor)),
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
          SheetTitle(tr.languagePickerTitle),
          for (final (code, label, subtitle) in options)
            ListTile(
              leading: Icon(
                  current == code
                      ? AppIcons.radioButtonFill
                      : AppIcons.circle,
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.popup(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(RadiusTokens.sheet)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(S.of(context).entryModeTitle,
              subtitle: S.of(context).entryModeDesc,
              padding: const EdgeInsetsDirectional.only(bottom: 16)),
          _EntryModeCard(
            icon: AppIcons.lightning,
            title: S.of(context).entryModeOne,
            description: S.of(context).entryModeOneDesc,
            isSelected: currentMode == 'one',
            onTap: () {
              ref.read(entryModeProvider.notifier).setMode('one');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
          _EntryModeCard(
            icon: AppIcons.magicWand,
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
            icon: AppIcons.listBullets,
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
    return Tappable(
      onTap: onTap,
      borderRadius: CardTokens.borderRadius,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentLight
              : AppColors.sfv(context),
          borderRadius: CardTokens.borderRadius,
          border: isSelected
              ? Border.all(color: AppColors.accent, width: 1.5)
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsIcon(
                icon: icon,
                color: isSelected ? AppColors.accent : AppColors.ts(context)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: SettingsRowStyle.title(context)),
                      ),
                      if (isSelected)
                        Icon(AppIcons.checkCircleFill,
                            size: 20, color: AppColors.accent),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(description,
                      style: SettingsRowStyle.subtitle(context)
                          .copyWith(height: 1.4)),
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

class SettingsDetailScreen extends ConsumerStatefulWidget {
  const SettingsDetailScreen({super.key});

  @override
  ConsumerState<SettingsDetailScreen> createState() =>
      _SettingsDetailScreenState();
}

class _SettingsDetailScreenState extends ConsumerState<SettingsDetailScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(householdProvider).value;

    final l = S.of(context);
    final themeLabel = switch (ref.watch(themeModeProvider)) {
      'light' => l.themeLight,
      'dark' => l.themeDark,
      'black' => l.themeBlack,
      _ => l.themeSystem,
    };

    final query = SearchQuery.parse(_query);
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: _SettingsQuery(
        query: query,
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l.settingsSearchHint,
                prefixIcon: const Icon(AppIcons.magnifyingGlass, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l.txCloseSearch,
                        icon: const Icon(AppIcons.x, size: 18),
                        onPressed: () => setState(() {
                          _searchCtrl.clear();
                          _query = '';
                        }),
                      ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (!query.isEmpty)
            _SettingsNoMatch(query: query),
          // ── Appearance ──
          _Find.section(child: _SectionHeader(title: l.settingsAppearanceSection)),
          _Find(keys: (t) => [t.tileTheme, t.themeDark, t.themeLight],
              child: _SettingsTile(icon: AppIcons.circleHalf, title: l.tileTheme,
                subtitle: themeLabel, iconColor: AppColors.accent,
                onTap: () => _showThemePicker(context, ref))),
          _Find(keys: (t) => [t.tileAccentColor],
              child: Builder(builder: (context) {
              final accentVal = ref.watch(accentColorProvider);
              final accentLabel = accentVal == 'system'
                  ? S.of(context).accentColorSystemLabel
                  : accentPairName(S.of(context), accentVal);
              return _SettingsTile(icon: AppIcons.eyedropper, title: S.of(context).tileAccentColor,
                  subtitle: accentLabel, iconColor: AppColors.accent,
                  onTap: () => _showAccentColorPicker(context, ref));
            })),
          _Find(keys: (t) => [t.tileColors, t.tileColorsSub],
              child: _SettingsTile(icon: AppIcons.palette, title: l.tileColors,
                subtitle: l.tileColorsSub, iconColor: SettingsRowStyle.hue(340),
                onTap: () => _showColorConfig(context, ref))),
          _Find(keys: (t) => [t.tileEntryMode],
              child: Builder(builder: (context) {
              final mode = ref.watch(entryModeProvider);
              return _SettingsTile(icon: AppIcons.handTap, title: S.of(context).tileEntryMode,
                  subtitle: switch (mode) {
                    'one' => S.of(context).entryModeOne,
                    'assisted' => S.of(context).entryModeAssistedShort,
                    _ => S.of(context).entryModeClassicShort,
                  },
                  iconColor: SettingsRowStyle.hue(207),
                  onTap: () => _showEntryModePicker(context, ref));
            })),
          _Find(keys: (t) => [t.tileAutofill, t.tileAutofillSub],
              child: _SettingsTile(
              icon: AppIcons.magicWand,
              title: l.tileAutofill,
              subtitle: l.tileAutofillSub,
              iconColor: SettingsRowStyle.hue(174),
              onTap: () => _showAutofillSettings(context, ref),
            )),
          _Find(keys: (t) => [t.tileStartScreen],
              child: Builder(builder: (context) {
              final homeTab = ref.watch(homeTabProvider);
              final sl = S.of(context);
              final homeTabLabel = [sl.tabHome, sl.tabActivity, sl.tabBudget, sl.tabReports, sl.tabMore][homeTab];
              return _SettingsTile(icon: AppIcons.house, title: sl.tileStartScreen,
                  subtitle: homeTabLabel,
                  iconColor: SettingsRowStyle.hue(174),
                  onTap: () => _showHomeTabPicker(context, ref));
            })),
          _Find(keys: (t) => [t.tileFont],
              child: Builder(builder: (context) {
              final font = ref.watch(fontProvider);
              return _SettingsTile(icon: AppIcons.textAa, title: S.of(context).tileFont,
                  subtitle: font, iconColor: SettingsRowStyle.hue(262),
                  onTap: () => _showFontPicker(context, ref));
            })),
          _Find(keys: (t) => [t.tileTextSize],
              child: Builder(builder: (context) {
              final scale = ref.watch(textScaleProvider);
              final sl = S.of(context);
              final scaleLabels = <double, String>{0.85: sl.textScaleSmall, 1.0: sl.textScaleDefault, 1.15: sl.textScaleLarge, 1.3: sl.textScaleExtraLarge};
              final label = scaleLabels[scale] ?? '${(scale * 100).round()}%';
              return _SettingsTile(icon: AppIcons.textAa, title: sl.tileTextSize,
                  subtitle: label, iconColor: SettingsRowStyle.hue(231),
                  onTap: () => _showTextSizePicker(context, ref));
            })),
          _Find(keys: (t) => [t.tileLanguage],
              child: Builder(builder: (context) {
              final localeCode = ref.watch(localeProvider);
              final langLabel = switch (localeCode) {
                'en' => S.of(context).languageEnglish,
                'ar' => S.of(context).languageArabic,
                'fr' => S.of(context).languageFrench,
                _ => S.of(context).languageSystem,
              };
              return _SettingsTile(icon: AppIcons.globe, title: S.of(context).tileLanguage,
                  subtitle: langLabel, iconColor: SettingsRowStyle.hue(174),
                  onTap: () => _showLanguagePicker(context, ref));
            })),
          // Arabic-Indic digits toggle — only visible when Arabic locale
          _Find(keys: (t) => [t.tileArabicDigits],
              child: Builder(builder: (context) {
              final localeNow = ref.watch(localeProvider);
              final resolvedLocale = localeNow ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode;
              if (resolvedLocale != 'ar') return const SizedBox.shrink();
              final useArabic = ref.watch(arabicDigitsProvider);
              return SettingsSwitchRow(
                icon: AppIcons.listNumbers,
                iconColor: SettingsRowStyle.hue(174),
                title: S.of(context).tileArabicDigits,
                subtitle: useArabic ? '٠١٢٣٤٥٦٧٨٩' : '0123456789',
                value: useArabic,
                onChanged: (_) => ref.read(arabicDigitsProvider.notifier).toggle(),
              );
            })),
          _Find(keys: (t) => [t.tileTxList, t.tileTxListSub],
              child: _SettingsTile(icon: AppIcons.rows, title: l.tileTxList,
                subtitle: l.tileTxListSub,
                iconColor: SettingsRowStyle.hue(207),
                onTap: () => context.push('/tx-list-settings'))),
          _Find.section(child: const SizedBox(height: Spacing.sectionGap)),
          // ── Data & Sync ──
          _Find.section(child: _SectionHeader(title: l.settingsDataSection)),
          // Shows the live sync state instead of a fixed description.
          _Find(keys: (t) => [t.tileCloudSync],
              child: Builder(builder: (context) {
              final sync = ref.watch(syncProvider);
              final String subtitle;
              if (sync.activeProvider == null) {
                subtitle = l.tileCloudSyncSub;
              } else if (sync.status == SyncStatus.syncing) {
                subtitle = l.syncStatusSyncing;
              } else if (sync.status == SyncStatus.error) {
                subtitle = l.syncStatusFailed;
              } else if (sync.lastSyncTime != null) {
                subtitle = l.syncStatusLast(formatDateSmart(sync.lastSyncTime!.toLocal()));
              } else {
                subtitle = l.tileCloudSyncSub;
              }
              return _SettingsTile(icon: AppIcons.arrowsClockwise, title: l.tileCloudSync,
                  subtitle: subtitle,
                  iconColor: sync.status == SyncStatus.error
                      ? AppColors.overspent
                      : AppColors.accent,
                  onTap: () {
                    // Joining someone's household needs no premium of its own.
                    if (sync.activeProvider is! RelayProvider &&
                        !checkPremiumAccess(context, ref, PremiumFeature.sync)) {
                      return;
                    }
                    context.push('/sync');
                  });
            })),
          _Find(keys: (t) => [t.tileShareHousehold],
              child: Builder(builder: (context) {
              final syncState = ref.watch(syncProvider);
              final inHousehold = syncState.activeProvider is RelayProvider;
              return _SettingsTile(
                icon: AppIcons.users,
                title: S.of(context).tileShareHousehold,
                subtitle: inHousehold
                    ? S.of(context).tileShareHouseholdConnected
                    : S.of(context).householdStartSub,
                iconColor: SettingsRowStyle.hue(262),
                onTap: () => _showShareHousehold(context, ref),
              );
            })),
          // Who's on this device in a shared budget (shown next to what it
          // saves). Hidden until the budget syncs or someone has a name.
          _Find(keys: (t) => [t.memberYourName, t.memberTileSub],
              child: Builder(builder: (context) {
              final names = ref.watch(memberNamesProvider).value ?? const {};
              final synced = ref.watch(syncProvider).activeProvider != null;
              if (names.isEmpty && !synced) return const SizedBox.shrink();
              final mine = names[DeviceIdentity.id];
              return _SettingsTile(
                icon: AppIcons.user,
                title: l.memberYourName,
                subtitle: mine ?? l.memberTileSub,
                iconColor: SettingsRowStyle.hue(262),
                onTap: () => showMemberNameDialog(context, ref,
                    initial: mine ?? ''),
              );
            })),
          // Family: grown-ups and kids, once more than one member is named.
          _Find(keys: (t) => [t.tileMembers, t.tileMembersSub],
              child: Builder(builder: (context) {
              final names = ref.watch(memberNamesProvider).value ?? const {};
              if (names.length < 2) return const SizedBox.shrink();
              return _SettingsTile(
                icon: AppIcons.users,
                title: l.tileMembers,
                subtitle: l.tileMembersSub,
                iconColor: SettingsRowStyle.hue(262),
                onTap: () => context.push('/members'),
              );
            })),
          _Find(keys: (t) => [t.tileBackupRestore, t.tileBackupRestoreSub],
              child: _SettingsTile(icon: AppIcons.cloudArrowUp, title: l.tileBackupRestore,
                subtitle: l.tileBackupRestoreSub, iconColor: SettingsRowStyle.hue(207),
                onTap: () => context.push('/backup'))),
          _Find(keys: (t) => [t.tileImportExport, t.tileImportExportSub],
              child: _SettingsTile(icon: AppIcons.arrowsDownUp, title: l.tileImportExport,
                subtitle: l.tileImportExportSub, iconColor: SettingsRowStyle.hue(123),
                onTap: () => context.push('/import-export'))),
          _Find(keys: (t) => [t.tileNotifications, t.tileNotificationsSub],
              child: _SettingsTile(
                icon: AppIcons.bellRinging,
                title: l.tileNotifications,
                subtitle: l.tileNotificationsSub,
                iconColor: SettingsRowStyle.hue(36),
                onTap: () => context.push('/notifications'))),
          _Find(keys: (t) => [t.tileHealthCheck, t.tileHealthCheckSub],
              child: _SettingsTile(
                icon: AppIcons.heartbeat,
                title: l.tileHealthCheck,
                subtitle: l.tileHealthCheckSub,
                iconColor: SettingsRowStyle.hue(174),
                onTap: () => context.push('/health-check'))),
          _Find(keys: (t) => [t.tileChangeLog, t.tileChangeLogSub],
              child: _SettingsTile(
                icon: AppIcons.clockCounterClockwise,
                title: l.tileChangeLog,
                subtitle: l.tileChangeLogSub,
                iconColor: SettingsRowStyle.hue(40),
                onTap: () => context.push('/change-log'))),
          _Find(keys: (t) => [t.tileCrashReports, t.crashKeep],
              child: const _CrashReportsTile()),
          // ── Receipt Sync toggle ──
          _Find(keys: (t) => [t.tileSyncReceipts],
              child: Builder(builder: (context) {
              final syncState = ref.watch(syncProvider);
              final isCloudConnected = syncState.activeProvider != null;
              if (!isCloudConnected) return const SizedBox.shrink();
              final receiptSyncEnabled = ref.watch(receiptSyncProvider);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsSwitchRow(
                    icon: AppIcons.images,
                    iconColor: SettingsRowStyle.hue(262),
                    title: S.of(context).tileSyncReceipts,
                    subtitle: receiptSyncEnabled
                        ? S.of(context).tileSyncReceiptsOn
                        : S.of(context).tileSyncReceiptsOff,
                    value: receiptSyncEnabled,
                    onChanged: (_) =>
                        ref.read(receiptSyncProvider.notifier).toggle(),
                  ),
                  if (!receiptSyncEnabled)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                      child: Row(
                        children: [
                          Icon(AppIcons.warning,
                              size: 14, color: AppColors.caution),
                          const SizedBox(width: 6),
                          Text(S.of(context).tileSyncReceiptsOff,
                              style: TextStyle(
                                  fontSize: TypographyTokens.overlineSize,
                                  color: AppColors.caution)),
                        ],
                      ),
                    ),
                ],
              );
            })),
          _Find.section(child: const SizedBox(height: Spacing.sectionGap)),
          // ── Preferences ──
          _Find.section(child: _SectionHeader(title: l.settingsPreferencesSection)),
          _Find(keys: (t) => [t.householdNameTitle],
              child: _SettingsTile(
              icon: AppIcons.house,
              title: l.householdNameTitle,
              subtitle: household?.name ?? 'BudgetSeal',
              iconColor: AppColors.accent,
              onTap: () => _editText(context, ref,
                  title: l.householdNameTitle,
                  currentValue: household?.name ?? '',
                  onSave: (val) async {
                    final db = ref.read(databaseProvider);
                    try {
                      await (db.update(db.households)
                            ..where((h) => h.id.equals(household!.id)))
                          .write(HouseholdsCompanion(
                              name: Value(val),
                              lastModified: Value(DateTime.now())));
                      if (context.mounted) _snack(context, l.householdNameSaved);
                    } catch (e) {
                      debugPrint('[Settings] Rename household failed: $e');
                      if (context.mounted) {
                        _snack(context, l.commonSomethingWentWrong);
                      }
                    }
                  }),
            )),
          _Find(keys: (t) => [t.tileBaseCurrency],
              child: _SettingsTile(
              icon: AppIcons.coins,
              title: l.tileBaseCurrency,
              subtitle: household?.baseCurrency ?? 'USD',
              iconColor: SettingsRowStyle.hue(35),
              onTap: () async {
                final result = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CurrencySheet(
                      current: household?.baseCurrency ?? 'USD'),
                );
                if (result != null &&
                    household != null &&
                    result != household.baseCurrency &&
                    context.mounted) {
                  await changeBaseCurrencyFlow(
                      context, ref, household, result);
                }
              },
            )),
          _Find(keys: (t) => [t.tileExchangeRates, t.tileExchangeRatesSub],
              child: _SettingsTile(
              icon: AppIcons.currencyCircleDollar,
              title: l.tileExchangeRates,
              subtitle: l.tileExchangeRatesSub,
              iconColor: SettingsRowStyle.hue(35),
              onTap: () => context.push('/exchange-rates'),
            )),
          _Find(keys: (t) => [t.tileRules, t.tileRulesSub],
              child: _SettingsTile(
              icon: AppIcons.tag,
              title: l.tileRules,
              subtitle: l.tileRulesSub,
              iconColor: SettingsRowStyle.hue(35),
              onTap: () => context.push('/rules'),
            )),
          if (BankAlerts.supported)
            _Find(keys: (t) => [t.tileBankAlerts, t.tileBankAlertsSub],
                child: _SettingsTile(
                icon: AppIcons.bellRinging,
                title: l.tileBankAlerts,
                subtitle: l.tileBankAlertsSub,
                iconColor: SettingsRowStyle.hue(35),
                onTap: () => context.push('/bank-alerts'),
              )),
          _Find(keys: (t) => [t.tilePeriodStartDay],
              child: _SettingsTile(
              icon: AppIcons.calendarBlank,
              title: l.tilePeriodStartDay,
              subtitle: l.onboardDayN(household?.periodStartDay ?? 1),
              iconColor: SettingsRowStyle.hue(35),
              onTap: () => _editNumber(context, ref,
                  title: l.tilePeriodStartDay,
                  currentValue: household?.periodStartDay ?? 1,
                  min: 1, max: 28,
                  description: l.tilePeriodStartDayDesc,
                  onSave: (val) async {
                    final db = ref.read(databaseProvider);
                    await (db.update(db.households)
                          ..where((h) => h.id.equals(household!.id)))
                        .write(HouseholdsCompanion(
                            periodStartDay: Value(val),
                            lastModified: Value(DateTime.now())));
                  }),
            )),
          _Find(keys: (t) => [t.tileCurrencySymbols, t.tileCurrencySymbolsSub],
              child: _SettingsTile(
              icon: AppIcons.currencyDollar,
              title: l.tileCurrencySymbols,
              subtitle: l.tileCurrencySymbolsSub,
              iconColor: SettingsRowStyle.hue(174),
              onTap: () => _showCurrencySymbolEditor(context, ref),
            )),
          _Find(keys: (t) => [t.tileNumberFormat],
              child: Builder(builder: (context) {
              ref.watch(numberFormatProvider);
              final preview = formatAmount(1234567.89);
              return _SettingsTile(
                icon: AppIcons.listNumbers,
                title: l.tileNumberFormat,
                subtitle: l.settingsPreview(preview),
                iconColor: SettingsRowStyle.hue(231),
                onTap: () => _showNumberFormatEditor(context, ref),
              );
            })),
          _Find(keys: (t) => [t.tileDateFormat],
              child: Builder(builder: (context) {
              final dateFmt = ref.watch(dateFormatProvider);
              final preview = DateFormat(dateFmt).format(DateTime.now());
              return _SettingsTile(
                icon: AppIcons.calendar,
                title: l.tileDateFormat,
                subtitle: preview,
                iconColor: SettingsRowStyle.hue(262),
                onTap: () => _showDateFormatPicker(context, ref),
              );
            })),
          _Find.section(child: const SizedBox(height: Spacing.sectionGap)),
          // ── Security ──
          _Find.section(child: _SectionHeader(title: l.settingsSecuritySection)),
          _Find(keys: (t) => [t.tileBiometricLock, t.tileBiometricSub],
              child: _BiometricTile()),
          _Find(keys: (t) => [t.tileHideAmounts, t.tileHideAmountsSub],
              child: SettingsSwitchRow(
                icon: AppIcons.eyeSlash,
                iconColor: SettingsRowStyle.hue(256),
                title: l.tileHideAmounts,
                subtitle: l.tileHideAmountsSub,
                value: ref.watch(hideAmountsProvider),
                onChanged: (_) => ref.read(hideAmountsProvider.notifier).toggle(),
              )),
          _Find.section(child: const SizedBox(height: Spacing.sectionGap)),
          // ── Danger zone ──
          _Find(keys: (t) => [t.tileResetEverything, t.tileResetSub],
              child: _SettingsTile(icon: AppIcons.trash, title: l.tileResetEverything,
                subtitle: l.tileResetSub, iconColor: AppColors.overspent,
                onTap: () => _confirmReset(context, ref))),
        ],
        ),
      ),
    );
  }
}

/// Settings search: the parsed query for the [_Find] rows below it.
class _SettingsQuery extends InheritedWidget {
  final SearchQuery query;
  const _SettingsQuery({required this.query, required super.child});

  static SearchQuery of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SettingsQuery>()?.query ??
      const SearchQuery([], []);

  @override
  bool updateShouldNotify(_SettingsQuery old) =>
      old.query.words.join(' ') != query.words.join(' ');
}

/// Keywords of a settings row, in the current language.
typedef _Keys = List<String> Function(S t);

/// Every searchable settings row's keywords (same as its [_Find]), so the
/// screen can say when nothing matches.
final _settingsKeys = <_Keys>[
  (t) => [t.tileTheme, t.themeDark, t.themeLight],
  (t) => [t.tileAccentColor],
  (t) => [t.tileColors, t.tileColorsSub],
  (t) => [t.tileEntryMode],
  (t) => [t.tileAutofill, t.tileAutofillSub],
  (t) => [t.tileStartScreen],
  (t) => [t.tileFont],
  (t) => [t.tileTextSize],
  (t) => [t.tileLanguage],
  (t) => [t.tileArabicDigits],
  (t) => [t.tileTxList, t.tileTxListSub],
  (t) => [t.tileCloudSync],
  (t) => [t.tileShareHousehold],
  (t) => [t.memberYourName, t.memberTileSub],
  (t) => [t.tileBackupRestore, t.tileBackupRestoreSub],
  (t) => [t.tileImportExport, t.tileImportExportSub],
  (t) => [t.tileNotifications, t.tileNotificationsSub],
  (t) => [t.tileHealthCheck, t.tileHealthCheckSub],
  (t) => [t.tileChangeLog, t.tileChangeLogSub],
  (t) => [t.tileSyncReceipts],
  (t) => [t.householdNameTitle],
  (t) => [t.tileBaseCurrency],
  (t) => [t.tileExchangeRates, t.tileExchangeRatesSub],
  (t) => [t.tilePeriodStartDay],
  (t) => [t.tileCurrencySymbols, t.tileCurrencySymbolsSub],
  (t) => [t.tileNumberFormat],
  (t) => [t.tileDateFormat],
  (t) => [t.tileBiometricLock, t.tileBiometricSub],
  (t) => [t.tileHideAmounts, t.tileHideAmountsSub],
  (t) => [t.tileResetEverything, t.tileResetSub],
];

class _SettingsNoMatch extends StatelessWidget {
  final SearchQuery query;
  const _SettingsNoMatch({required this.query});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    if (_settingsKeys.any((k) => _Find.matches(query, t, k))) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(t.settingsSearchNone,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.ts(context))),
    );
  }
}

/// A settings row shown only when every search word is in its [keys]
/// (title, description); [_Find.section] (headers, gaps) hides while
/// searching.
class _Find extends StatelessWidget {
  final _Keys? keys;
  final Widget child;
  const _Find({required this.keys, required this.child});
  const _Find.section({required this.child}) : keys = null;

  static bool matches(SearchQuery q, S t, _Keys keys) =>
      q.matches(foldForSearch(keys(t).join(' ')), 0);

  @override
  Widget build(BuildContext context) {
    final q = _SettingsQuery.of(context);
    if (q.isEmpty) return child;
    final k = keys;
    if (k == null || !matches(q, S.of(context), k)) {
      return const SizedBox.shrink();
    }
    return child;
  }
}

/// Off, or On with how many reports are saved (updates as they change).
class _CrashReportsTile extends StatelessWidget {
  const _CrashReportsTile();

  @override
  Widget build(BuildContext context) {
    final l = S.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: CrashReports.changes,
      builder: (context, _, __) => FutureBuilder<List<CrashReport>>(
        future: CrashReports.enabled ? CrashReports.load() : null,
        builder: (context, snap) => _SettingsTile(
          icon: AppIcons.bug,
          title: l.tileCrashReports,
          subtitle: CrashReports.enabled
              ? l.tileCrashReportsOn(snap.data?.length ?? 0)
              : l.tileCrashReportsOff,
          iconColor: SettingsRowStyle.hue(8),
          onTap: () => context.push('/crash-reports'),
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
    return SectionHeader(title,
        padding: const EdgeInsetsDirectional.fromSTEB(
            4, 0, 4, Spacing.headerToCard));
  }
}

/// Cashew SettingsContainer: a flat row on the page background — pastel
/// icon circle, bold title, secondary description. The transparent Material
/// keeps the ripple visible (a colored DecoratedBox would hide it).
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
  Widget build(BuildContext context) => SettingsRow(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      onTap: onTap);
}

/// A titled, rounded card of related More-page rows with thin dividers.
class _MoreGroup extends StatelessWidget {
  final String title;
  final List<_MoreRow> rows;
  const _MoreGroup({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(RadiusTokens.hero);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(title: title),
          Container(
            decoration: AppColors.card(context, radius: RadiusTokens.hero),
            child: ClipRRect(
              borderRadius: radius,
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0)
                        Divider(
                            height: 1,
                            indent: 70,
                            endIndent: 16,
                            color: AppColors.bd(context)),
                      rows[i],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One More-page row: icon circle, name, one-line description, chevron.
/// Icon colors come from a hue at a shared saturation/lightness so the set
/// reads as one family (hand-picked colors drifted muddy as pastels).
class _MoreRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double hue;
  final bool neutral;
  final VoidCallback onTap;

  const _MoreRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.hue,
    this.neutral = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = SettingsRowStyle.hue(hue, neutral: neutral);
    return Tappable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 10, 12),
        child: Row(
          children: [
            SettingsIcon(icon: icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SettingsRowStyle.title(context)),
                  const SizedBox(height: 1),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SettingsRowStyle.subtitle(context)),
                ],
              ),
            ),
            Icon(AppIcons.caretRight,
                size: 20, color: AppColors.th(context)),
          ],
        ),
      ),
    );
  }
}

class _BiometricTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(biometricLockProvider);

    return SettingsSwitchRow(
      icon: AppIcons.fingerprint,
      iconColor: SettingsRowStyle.hue(256),
      title: S.of(context).tileBiometricLock,
      subtitle: S.of(context).tileBiometricSub,
      value: enabled,
      onChanged: (value) => _toggle(context, ref, value),
    );
  }

  Future<void> _toggle(
      BuildContext context, WidgetRef ref, bool turning0n) async {
    final verifyReason = S.of(context).biometricVerify;
    if (!turning0n) {
      // Disabling — no verification needed.
      await ref.read(biometricLockProvider.notifier).disable();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.of(context).biometricOffSnack),
          behavior: SnackBarBehavior.floating,
        ));
      }
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
        localizedReason: verifyReason,
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );

      if (didAuth) {
        await ref.read(biometricLockProvider.notifier).enable();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(S.of(context).biometricOnSnack),
            behavior: SnackBarBehavior.floating,
          ));
        }
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
        final message = biometricErrorText(S.of(context), e,
            fallback: S.of(context).biometricError);
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
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      decoration: BoxDecoration(
        color: AppColors.popup(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(RadiusTokens.sheet)),
      ),
      child: Column(
        children: [
          SheetTitle(S.of(context).currencySymbolsTitle,
              subtitle: S.of(context).currencySymbolsDesc),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: AppColors.bd(context)),
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
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ts(context))),
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
                    width: SettingsRowStyle.iconSize,
                    height: SettingsRowStyle.iconSize,
                    decoration: BoxDecoration(
                      color: AppColors.pastel(context, AppColors.accent,
                          light: 0.82, dark: 0.7),
                      shape: BoxShape.circle,
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
                              fontSize: TypographyTokens.captionSize,
                              color: AppColors.ts(context)))
                      : null,
                  trailing: isOverridden
                      ? IconButton(
                          tooltip: S.of(context).commonReset,
                          onPressed: () => ref
                              .read(currencySymbolProvider.notifier)
                              .removeOverride(code),
                          icon: Icon(AppIcons.arrowCounterClockwise,
                              size: 18, color: AppColors.th(context)),
                        )
                      : Icon(AppIcons.pencilSimple,
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
        scrollable: true,
        title: Text(tr.currencySymbolFor(code)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: tr.currencySymbolExample(
                defaultCurrencySymbols[code] ?? ''),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr.commonCancel),
          ),
          FilledButton(
            style: DialogButtons.filled,
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(tr.commonSave),
          ),
        ],
      ),
    );
    disposeAfterRouteAnimation(ctrl);

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
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      decoration: BoxDecoration(
        color: AppColors.popup(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(RadiusTokens.sheet)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetTitle(S.of(context).numberFormatTitle,
                subtitle: S.of(context).numberFormatDesc,
                padding: _inSheetTitlePad),

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
                          fontSize: TypographyTokens.overlineSize,
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
                // Skip combinations where thousands == decimal
                final conflicts = (t == ThousandsSeparator.comma &&
                        _decimal == DecimalSeparator.comma) ||
                    (t == ThousandsSeparator.period &&
                        _decimal == DecimalSeparator.period);
                return _option(
                  _thousandsLabel(t),
                  t == _thousands,
                  conflicts
                      ? null
                      : () { setState(() => _thousands = t); _applyImmediately(); },
                );
              }).toList(),
            ),
            if (ThousandsSeparator.values.any((t) =>
                (t == ThousandsSeparator.comma && _decimal == DecimalSeparator.comma) ||
                (t == ThousandsSeparator.period && _decimal == DecimalSeparator.period)))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(S.of(context).numberFormatConflict,
                    style: TextStyle(
                        fontSize: TypographyTokens.overlineSize,
                        color: AppColors.ts(context))),
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
                final conflicts = (d == DecimalSeparator.comma &&
                        _thousands == ThousandsSeparator.comma) ||
                    (d == DecimalSeparator.period &&
                        _thousands == ThousandsSeparator.period);
                return _option(
                  _decimalLabel(d),
                  d == _decimal,
                  conflicts
                      ? null
                      : () { setState(() => _decimal = d); _applyImmediately(); },
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
                return _option(
                  n.label,
                  n == _negative,
                  () { setState(() => _negative = n); _applyImmediately(); },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// One choice: an [AppChip]; a choice that clashes with the other
  /// separator is dimmed and can't be picked.
  Widget _option(String label, bool selected, VoidCallback? onTap) {
    final chip = AppChip(label: label, selected: selected, onTap: onTap);
    return onTap == null ? Opacity(opacity: 0.4, child: chip) : chip;
  }

  String _thousandsLabel(ThousandsSeparator t) {
    final s = S.of(context);
    return switch (t) {
      ThousandsSeparator.comma => s.nfThousandsComma,
      ThousandsSeparator.period => s.nfThousandsPeriod,
      ThousandsSeparator.space => s.nfThousandsSpace,
      ThousandsSeparator.none => s.nfThousandsNone,
    };
  }

  String _decimalLabel(DecimalSeparator d) {
    final s = S.of(context);
    return switch (d) {
      DecimalSeparator.period => s.nfDecimalPeriod,
      DecimalSeparator.comma => s.nfDecimalComma,
    };
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
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SheetTitle(S.of(context).dateFormatTitle),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final entry in dateFormatOptions.entries)
                  ListTile(
                    leading: Icon(
                        current == entry.key
                            ? AppIcons.radioButtonFill
                            : AppIcons.circle,
                        color: AppColors.accent),
                    title: Text(DateFormat(entry.key).format(now)),
                    subtitle: Text(entry.key,
                        style: TextStyle(
                            fontSize: 12, color: AppColors.ts(context))),
                    onTap: () {
                      ref.read(dateFormatProvider.notifier).setFormat(entry.key);
                      Navigator.pop(context);
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

        // One slim row: warning + "Back up now" + dismiss.
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 4, 6),
            decoration: BoxDecoration(
              color: AppColors.pastel(context, AppColors.caution,
                  light: 0.85, dark: 0.78),
              borderRadius: BorderRadius.circular(RadiusTokens.hero),
            ),
            child: Row(
              children: [
                Icon(AppIcons.cloudArrowUp,
                    size: 20, color: AppColors.caution),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tp(context),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/backup'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(l.backupNowButton),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(AppIcons.x,
                      size: 18, color: AppColors.ts(context)),
                  onPressed: () async {
                    await snoozeBackupReminder();
                    ref.invalidate(showBackupReminderProvider);
                  },
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

/// Translated name of a palette color id (see brandPalette).
String accentPairName(S l, String id) => switch (id) {
      'wax' => l.accentWax,
      'copper' => l.accentCopper,
      'sage' => l.accentSage,
      'teal' => l.accentTeal,
      'sapphire' => l.accentSapphire,
      'plum' => l.accentPlum,
      'rose' => l.accentRose,
      _ => l.accentGold,
    };

/// A palette color: a circle split into its bright (dark mode) and deep
/// (light mode) tones, ringed when selected.
class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.pair,
    required this.label,
    required this.selected,
    required this.ringBg,
    required this.ringColor,
    required this.onTap,
  });

  final AccentPair pair;
  final String label;
  final bool selected;
  final Color ringBg;
  final Color ringColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tappable(
        onTap: onTap,
        borderRadius: CardTokens.borderRadius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ringBg,
                border: Border.all(
                    color: selected ? ringColor : Colors.transparent,
                    width: 2.5),
              ),
              child: ClipOval(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(child: ColoredBox(color: pair.bright)),
                  Expanded(child: ColoredBox(color: pair.deep)),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: AppColors.tp(context))),
          ],
        ),
      ),
    );
  }
}
