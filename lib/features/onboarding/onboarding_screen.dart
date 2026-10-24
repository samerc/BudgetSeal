import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/data/category_presets.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/entry_mode_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/sync_provider.dart';
import '../../core/services/auto_backup_service.dart';
import '../../core/sync/cloud_provider.dart';
import '../../core/sync/google_drive_provider.dart';
import '../../core/sync/invite_code.dart';
import '../../l10n/generated/app_localizations.dart';
import '../transactions/widgets/currency_sheet.dart' show kCurrencies;
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/currency_picker_field.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chip.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/settings_row.dart';
import '../../shared/widgets/sheet_title.dart';
import '../../shared/widgets/tappable.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/seal_art.dart';


/// The phone's region currency (en_GB → GBP, fr_FR → EUR) when it's one
/// the app lists, else USD — a better first guess for global users.
String _localeCurrency() {
  try {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    if (locale.countryCode == null) return 'USD';
    final code =
        NumberFormat.simpleCurrency(locale: locale.toString()).currencyName;
    if (code != null && kCurrencies.any((c) => c.$1 == code)) return code;
  } catch (_) {}
  return 'USD';
}

/// Account types offered in setup: (type, label, icon). Same icons as the
/// account screen.
List<(String, String, IconData)> _accountTypes(S s) => [
      ('cash', s.onboardTypeCash, AppIcons.money),
      ('bank', s.onboardTypeBank, AppIcons.bank),
      ('credit', s.onboardTypeCredit, AppIcons.creditCard),
      ('wallet', s.onboardTypeDigital, AppIcons.wallet),
    ];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // ── Setup fields ──
  final _nameController = TextEditingController();
  final _nameKey = GlobalKey();
  String _baseCurrency = _localeCurrency();
  int _periodStartDay = 1;

  // Account
  final _acctNameCtrl = TextEditingController();
  final _acctNameKey = GlobalKey();
  bool _acctNameSet = false;
  String _acctType = 'cash';
  double _acctInitialBalance = 0;

  // Categories
  bool _seedCategories = true; // true = suggested set, false = none
  // Envelopes for the main spending groups, so a new budget isn't empty.
  bool _seedEnvelopes = true;

  bool _loading = false;
  String? _nameError;
  String? _acctNameError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_acctNameSet) {
      _acctNameCtrl.text = S.of(context).onboardTypeCash;
      _acctNameSet = true;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _acctNameCtrl.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  /// The account name follows the type while it's still the default
  /// (Cash → Bank renames "Cash" to "Bank", a typed name stays).
  void _changeAcctType(String type) {
    final labels = {for (final t in _accountTypes(S.of(context))) t.$1: t.$2};
    setState(() {
      if (_acctNameCtrl.text.trim() == labels[_acctType]) {
        _acctNameCtrl.text = labels[type] ?? _acctNameCtrl.text;
        if (_acctNameError != null) _acctNameError = null;
      }
      _acctType = type;
    });
  }

  // ── Submit: create household + account + categories + entry mode ──
  Future<void> _submit() async {
    final householdName = _nameController.text.trim();
    final acctName = _acctNameCtrl.text.trim();

    // Validate
    String? nameErr, acctErr;
    final s = S.of(context);
    if (householdName.isEmpty) nameErr = s.onboardHouseholdNameError;
    if (acctName.isEmpty) acctErr = s.onboardAccountNameError;
    if (nameErr != null || acctErr != null) {
      setState(() {
        _nameError = nameErr;
        _acctNameError = acctErr;
      });
      // The button sits below the fields: bring the first error into view.
      final key = nameErr != null ? _nameKey : _acctNameKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = key.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              alignment: 0.2);
        }
      });
      return;
    }

    setState(() {
      _nameError = null;
      _acctNameError = null;
      _loading = true;
    });
    try {
      // 1. Create household
      await ref.read(householdServiceProvider).createHousehold(
            name: householdName,
            baseCurrency: _baseCurrency,
            periodStartDay: _periodStartDay,
            deviceId: 'local',
          );

      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) return;
      final db = ref.read(databaseProvider);

      // 2. Create account + categories in a single batch (atomic)
      await db.batch((batch) {
        batch.insert(db.accounts, AccountsCompanion.insert(
          id: const Uuid().v4(),
          householdId: householdId,
          name: acctName,
          type: _acctType,
          currency: _baseCurrency,
          initialBalance: Value(_acctInitialBalance),
          deviceId: 'local',
        ));

        // 3. Seed categories (if selected)
        if (_seedCategories) {
          final presets = detailedPresets;
          final groupIds = <String, String>{};

          var order = 0;
          for (final p in presets.where((p) => p.parentKey == null)) {
            final id = const Uuid().v4();
            groupIds[p.nameKey] = id;
            // One spending envelope per main group (no target yet); its
            // subcategories spend from it.
            String? envelopeId;
            if (_seedEnvelopes && kEnvelopeGroupKeys.contains(p.nameKey)) {
              envelopeId = const Uuid().v4();
              batch.insert(db.allocations, AllocationsCompanion.insert(
                id: envelopeId,
                householdId: householdId,
                name: p.translatedName(s),
                categoryId: envelopeId, // legacy; the link is categories.allocationId
                icon: Value(p.emoji),
                targetCurrency: Value(_baseCurrency),
                sortOrder: Value(order++),
                deviceId: 'local',
              ));
            }
            batch.insert(db.categories, CategoriesCompanion.insert(
              id: id,
              householdId: householdId,
              name: p.translatedName(s),
              icon: Value(p.emoji),
              colorHex: Value(p.colorHex),
              transactionType: Value(p.type),
              allocationId: Value(envelopeId),
            ));
          }
          for (final p in presets.where((p) => p.parentKey != null)) {
            final parentId = groupIds[p.parentKey];
            batch.insert(db.categories, CategoriesCompanion.insert(
              id: const Uuid().v4(),
              householdId: householdId,
              name: p.translatedName(s),
              parentId: Value(parentId),
              icon: Value(p.emoji),
              colorHex: Value(p.colorHex),
              transactionType: Value(p.type),
            ));
          }
        }
      });

      // 4. Set entry mode (default: the one-screen add)
      ref.read(entryModeProvider.notifier).setMode('one');

      // 5. Go to done page
      if (mounted) _goTo(2);
    } catch (e) {
      debugPrint('[Onboarding] Error during setup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).commonErrorDesc),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back on the setup page returns to the welcome page; on the done
      // page the household exists, so back finishes onboarding.
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _loading) return;
        if (_currentPage == 1) _goTo(0);
        if (_currentPage == 2) context.go('/');
      },
      // System bars come from app.dart's AnnotatedRegion (theme-aware).
      child: Scaffold(
          backgroundColor: AppColors.bg(context),
          body: SafeArea(
            child: Column(
              children: [
                // Back (setup page) + progress dots
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_currentPage == 1)
                        PositionedDirectional(
                          start: 4,
                          child: IconButton(
                            onPressed: _loading ? null : () => _goTo(0),
                            tooltip: MaterialLocalizations.of(context)
                                .backButtonTooltip,
                            icon: const BackButtonIcon(),
                            color: AppColors.tp(context),
                          ),
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          3,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _currentPage ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _currentPage
                                  ? AppColors.accent
                                  : AppColors.th(context),
                              borderRadius: BorderRadius.circular(RadiusTokens.pill),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) {
                      // Don't carry the setup page's keyboard onto the next page.
                      FocusScope.of(context).unfocus();
                      setState(() => _currentPage = i);
                    },
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _WelcomePage(onNext: () => _goTo(1)),
                      _SetupPage(
                        nameController: _nameController,
                        nameKey: _nameKey,
                        baseCurrency: _baseCurrency,
                        periodStartDay: _periodStartDay,
                        acctNameCtrl: _acctNameCtrl,
                        acctNameKey: _acctNameKey,
                        acctType: _acctType,
                        acctInitialBalance: _acctInitialBalance,
                        seedCategories: _seedCategories,
                        seedEnvelopes: _seedEnvelopes,
                        loading: _loading,
                        nameError: _nameError,
                        acctNameError: _acctNameError,
                        onNameErrorClear: () =>
                            setState(() => _nameError = null),
                        onAcctNameErrorClear: () =>
                            setState(() => _acctNameError = null),
                        onCurrencyChanged: (v) =>
                            setState(() => _baseCurrency = v),
                        onDayChanged: (v) =>
                            setState(() => _periodStartDay = v ?? 1),
                        onAcctTypeChanged: _changeAcctType,
                        onAcctBalanceChanged: (v) =>
                            setState(() => _acctInitialBalance = v),
                        onSeedChanged: (v) =>
                            setState(() => _seedCategories = v),
                        onSeedEnvelopesChanged: (v) =>
                            setState(() => _seedEnvelopes = v),
                        onSubmit: _submit,
                      ),
                      _DonePage(onFinish: () => context.go('/')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

// ─── Shared pieces ──────────────────────────────────────────────────────────

/// Page title: the app's screen title (28 / w800, display face).
class _PageTitle extends StatelessWidget {
  final String text;
  final TextAlign? align;
  const _PageTitle(this.text, {this.align});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontSize: TypographyTokens.screenTitleSize,
        fontFamily: TypographyTokens.displayFamily,
        fontWeight: TypographyTokens.screenTitleWeight,
        color: AppColors.tp(context),
      ),
    );
  }
}

/// The app card, full width (onboarding's cards stretch).
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}

// ─── Page 1: Welcome + How it works ─────────────────────────────────────────

class _WelcomePage extends StatefulWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  State<_WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<_WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIcon, _fadeTitle, _fadeSub, _fadeContent;
  late final Animation<Offset> _slideIcon, _slideTitle;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIcon = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.0, 0.4, curve: Curves.easeOut));
    _fadeTitle = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOut));
    _fadeSub = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.3, 0.7, curve: Curves.easeOut));
    _fadeContent = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.5, 1.0, curve: Curves.easeOut));
    _slideIcon = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOut)));
    _slideTitle = Tween(begin: const Offset(0, 0.2), end: Offset.zero).animate(
        CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.15, 0.55, curve: Curves.easeOut)));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final steps = [s.onboardStep1, s.onboardStep2, s.onboardStep3, s.onboardStep4];
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                // ── The seal illustration: notes into a sealed envelope ──
                SlideTransition(
                  position: _slideIcon,
                  child: FadeTransition(
                    opacity: _fadeIcon,
                    child: const WelcomeArt(width: 200),
                  ),
                ),
                const SizedBox(height: 16),
                SlideTransition(
                  position: _slideTitle,
                  child: FadeTransition(
                    opacity: _fadeTitle,
                    child: _PageTitle(s.onboardWelcomeTitle,
                        align: TextAlign.center),
                  ),
                ),
                const SizedBox(height: 6),
                FadeTransition(
                  opacity: _fadeSub,
                  child: Text(
                    s.onboardTagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tp(context),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fadeContent,
                  child: Column(
                    children: [
                      Text(
                        s.onboardEnvelopeExplainer,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.ts(context),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ── How it works ──
                      _Card(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: Column(
                          children: [
                            for (var i = 0; i < steps.length; i++)
                              _Step(number: '${i + 1}', text: steps[i]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        // ── Actions: pinned, so they're reachable at any text size ──
        FadeTransition(
          opacity: _fadeContent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: widget.onNext,
                  child: Text(s.onboardGetStarted),
                ),
                const SizedBox(height: 8),
                const _RestoreButton(),
                const _JoinHouseholdButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              shape: BoxShape.circle,
            ),
            child: Text(number,
                style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: AppColors.tp(context), fontSize: 14, height: 1.3)),
          ),
        ],
      ),
    );
  }
}

// ─── Page 2: Setup (all-in-one) ─────────────────────────────────────────────

class _SetupPage extends StatelessWidget {
  final TextEditingController nameController;
  final GlobalKey nameKey;
  final String baseCurrency;
  final int periodStartDay;
  final TextEditingController acctNameCtrl;
  final GlobalKey acctNameKey;
  final String acctType;
  final double acctInitialBalance;
  final bool seedCategories;
  final bool seedEnvelopes;
  final bool loading;
  final String? nameError;
  final String? acctNameError;
  final VoidCallback? onNameErrorClear;
  final VoidCallback? onAcctNameErrorClear;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<int?> onDayChanged;
  final ValueChanged<String> onAcctTypeChanged;
  final ValueChanged<double> onAcctBalanceChanged;
  final ValueChanged<bool> onSeedChanged;
  final ValueChanged<bool> onSeedEnvelopesChanged;
  final VoidCallback onSubmit;

  const _SetupPage({
    required this.nameController,
    required this.nameKey,
    required this.baseCurrency,
    required this.periodStartDay,
    required this.acctNameCtrl,
    required this.acctNameKey,
    required this.acctType,
    required this.acctInitialBalance,
    required this.seedCategories,
    required this.seedEnvelopes,
    required this.loading,
    this.nameError,
    this.acctNameError,
    this.onNameErrorClear,
    this.onAcctNameErrorClear,
    required this.onCurrencyChanged,
    required this.onDayChanged,
    required this.onAcctTypeChanged,
    required this.onAcctBalanceChanged,
    required this.onSeedChanged,
    required this.onSeedEnvelopesChanged,
    required this.onSubmit,
  });

  static const _sectionPad = EdgeInsetsDirectional.fromSTEB(4, 0, 4, 8);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageTitle(s.onboardSetupTitle),
            const SizedBox(height: 4),
            Text(s.onboardChangeLater,
                style: TextStyle(fontSize: 14, color: AppColors.ts(context))),
            const SizedBox(height: Spacing.sectionGap),

            // ── Household ──
            SectionHeader(s.onboardHouseholdSection, padding: _sectionPad),
            _Card(
              child: Column(
                children: [
                  TextField(
                    key: nameKey,
                    controller: nameController,
                    maxLength: InputLimits.nameMaxLength,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: nameError != null
                        ? (_) => onNameErrorClear?.call()
                        : null,
                    decoration: InputDecoration(
                      labelText: s.onboardHouseholdName,
                      hintText: s.onboardHouseholdHint,
                      counterText: '',
                      errorText: nameError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CurrencyPickerField(
                    label: s.onboardBaseCurrency,
                    value: baseCurrency,
                    onChanged: onCurrencyChanged,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: periodStartDay,
                    icon: Icon(AppIcons.caretDown,
                        color: AppColors.th(context)),
                    decoration: InputDecoration(
                      labelText: s.onboardPeriodStart,
                      helperText: s.onboardPeriodHelp,
                    ),
                    items: List.generate(28, (i) => i + 1)
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(s.onboardDayN(d)),
                            ))
                        .toList(),
                    onChanged: onDayChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sectionGap),

            // ── First account ──
            SectionHeader(s.onboardFirstAccountSection, padding: _sectionPad),
            _Card(
              child: Column(
                children: [
                  TextField(
                    key: acctNameKey,
                    controller: acctNameCtrl,
                    maxLength: InputLimits.nameMaxLength,
                    textCapitalization: TextCapitalization.words,
                    onChanged: acctNameError != null
                        ? (_) => onAcctNameErrorClear?.call()
                        : null,
                    decoration: InputDecoration(
                      labelText: s.onboardAccountName,
                      counterText: '',
                      errorText: acctNameError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      for (final t in _accountTypes(s))
                        AppChip(
                          label: t.$2,
                          icon: t.$3,
                          selected: acctType == t.$1,
                          onTap: () => onAcctTypeChanged(t.$1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _BalanceField(
                    label: s.acctOpeningBalance,
                    currency: baseCurrency,
                    value: acctInitialBalance,
                    onChanged: onAcctBalanceChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sectionGap),

            // ── Categories ──
            SectionHeader(s.onboardCategoriesSection, padding: _sectionPad),
            _Card(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  SettingsSwitchRow(
                    value: seedCategories,
                    onChanged: onSeedChanged,
                    title: s.onboardSeedCategories,
                    subtitle: seedCategories
                        ? s.onboardFullSetSub
                        : s.onboardEmptySub,
                  ),
                  if (seedCategories) ...[
                    Divider(height: 1, color: AppColors.bd(context)),
                    SettingsSwitchRow(
                      value: seedEnvelopes,
                      onChanged: onSeedEnvelopesChanged,
                      title: s.onboardSeedEnvelopes,
                      subtitle: s.onboardSeedEnvelopesSub,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : onSubmit,
                child: loading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(s.onboardCreateStart),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Opening balance as a labelled input, matching the fields above it.
/// Tapping opens the calculator (never the keyboard).
class _BalanceField extends StatelessWidget {
  final String label;
  final String currency;
  final double value;
  final ValueChanged<double> onChanged;

  const _BalanceField({
    required this.label,
    required this.currency,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.bodyLarge;
    return Tappable(
      onTap: () async {
        final v = await showCalculatorSheet(context, value);
        if (v != null) onChanged(v);
      },
      borderRadius: BorderRadius.circular(RadiusTokens.input),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixText: currency,
          suffixStyle: text?.copyWith(color: AppColors.ts(context)),
        ),
        child: Text(
          value == 0 ? '0' : formatForDisplay(value),
          style: text?.copyWith(
              color: value == 0 ? AppColors.th(context) : AppColors.tp(context)),
        ),
      ),
    );
  }
}

// ─── Page 3: Done ───────────────────────────────────────────────────────────

class _DonePage extends StatelessWidget {
  final VoidCallback onFinish;
  const _DonePage({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // Centered in the page, scrolling only when large text needs it.
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: box.maxHeight - 56),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(AppIcons.check,
                    size: 48, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: 24),
            _PageTitle(s.onboardAllSet, align: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              s.onboardDoneSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.ts(context),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: onFinish,
              child: Text(s.onboardStartUsing),
            ),
            const SizedBox(height: 16),
            Text(
              s.onboardHelpHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.ts(context)),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ─── Sheets: shared layout ─────────────────────────────────────────────────

/// Sheet body in the app's sheet style (the theme gives radius 20 and no
/// drag handle): title, description, content, error.
class _SheetBody extends StatelessWidget {
  final String title;
  final String description;
  final List<Widget> children;
  final String? error;

  const _SheetBody({
    required this.title,
    required this.description,
    required this.children,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetTitle(title,
                  subtitle: description,
                  padding: const EdgeInsetsDirectional.only(bottom: 20)),
              ...children,
              if (error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.pastel(context, AppColors.overspent,
                        light: 0.85, dark: 0.78),
                    borderRadius: BorderRadius.circular(RadiusTokens.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(AppIcons.warningCircle,
                          color: AppColors.overspent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(error!,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.overspent)),
                      ),
                    ],
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

class _SheetSpinner extends StatelessWidget {
  const _SheetSpinner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
    );
  }
}

// ─── Restore my budget ─────────────────────────────────────────────────────

class _RestoreButton extends ConsumerWidget {
  const _RestoreButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () {
        final providers = ref.read(syncProvider.notifier).availableProviders;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => _RestoreSheet(providers: providers),
        );
      },
      icon: const Icon(AppIcons.clockCounterClockwise, size: 20),
      label: Text(S.of(context).onboardRestoreCloud),
    );
  }
}

class _RestoreSheet extends ConsumerStatefulWidget {
  final List<CloudProvider> providers;
  const _RestoreSheet({required this.providers});

  @override
  ConsumerState<_RestoreSheet> createState() => _RestoreSheetState();
}

class _RestoreSheetState extends ConsumerState<_RestoreSheet> {
  bool _loading = false;
  String? _error;

  void _fail(String message) {
    if (mounted) {
      setState(() {
        _loading = false;
        _error = message;
      });
    }
  }

  Future<void> _restore(CloudProvider provider) async {
    final s = S.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final connected =
          await ref.read(syncProvider.notifier).connectProvider(provider);
      if (!connected) {
        _fail(s.onboardConnectFailed(provider.displayName));
        return;
      }

      await ref.read(syncProvider.notifier).restoreFromProvider(provider);

      final state = ref.read(syncProvider);
      if (state.status == SyncStatus.error) {
        _fail(state.lastError ?? s.onboardNoSyncFile);
        return;
      }

      await ref.read(householdServiceProvider).loadSavedHousehold();

      if (mounted) {
        Navigator.pop(context);
        context.go('/');
      }
    } catch (e) {
      _fail(syncErrorText(e));
    }
  }

  /// A backup file made by Settings › Backup: checked, staged, and opened
  /// on the next launch (the database can't be swapped while it's open).
  Future<void> _restoreBackupFile() async {
    final s = S.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final file = await FilePicker.pickFile(type: FileType.any);
      final path = file?.path;
      if (path == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final householdId = await AutoBackupService.backupHouseholdId(path);
      if (householdId == null) {
        _fail(s.backupInvalid);
        return;
      }
      await AutoBackupService.restoreForNewInstall(path, householdId);
      if (!mounted) return;
      setState(() => _loading = false);
      final canClose = Platform.isAndroid;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(s.backupRestoreTitle),
          content: Text(s.backupRestored),
          actions: [
            if (canClose)
              FilledButton(
                style: DialogButtons.filled,
                onPressed: () => SystemNavigator.pop(),
                child: Text(s.backupCloseApp),
              )
            else
              FilledButton(
                style: DialogButtons.filled,
                onPressed: () => Navigator.pop(ctx),
                child: Text(s.commonOk),
              ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('[Onboarding] Backup restore failed: $e');
      _fail(s.backupRestoreFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return _SheetBody(
      title: s.onboardRestoreTitle,
      description: s.onboardRestoreDesc,
      error: _error,
      children: [
        if (_loading)
          const _SheetSpinner()
        else ...[
          for (final provider in widget.providers) ...[
            OutlinedButton.icon(
              onPressed: () => _restore(provider),
              icon: Icon(
                  provider is GoogleDriveProvider
                      ? AppIcons.googleDriveLogo
                      : AppIcons.folderOpen,
                  size: 20),
              label: Text(provider is GoogleDriveProvider
                  ? s.onboardGoogleDrive
                  : s.onboardPickFile),
            ),
            const SizedBox(height: 10),
          ],
          // A backup file (.db from Settings › Backup) — no sync needed.
          OutlinedButton.icon(
            onPressed: _restoreBackupFile,
            icon: const Icon(AppIcons.fileArrowDown, size: 20),
            label: Text(s.onboardRestoreBackupFile),
          ),
          const SizedBox(height: 4),
          Text(s.onboardRestoreBackupHint,
              style: TextStyle(fontSize: 12.5, color: AppColors.ts(context))),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

// ─── Join a household ──────────────────────────────────────────────────────

class _JoinHouseholdButton extends StatelessWidget {
  const _JoinHouseholdButton();

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const _JoinHouseholdSheet(),
      ),
      icon: const Icon(AppIcons.users, size: 20),
      label: Text(S.of(context).onboardJoinHousehold),
    );
  }
}

class _JoinHouseholdSheet extends ConsumerStatefulWidget {
  const _JoinHouseholdSheet();

  @override
  ConsumerState<_JoinHouseholdSheet> createState() =>
      _JoinHouseholdSheetState();
}

class _JoinHouseholdSheetState extends ConsumerState<_JoinHouseholdSheet> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _fail(String message) {
    if (mounted) {
      setState(() {
        _loading = false;
        _error = message;
      });
    }
  }

  Future<void> _join() async {
    final s = S.of(context);
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = s.onboardEnterCodeError);
      return;
    }

    final folderId = decodeInviteCode(code);
    if (folderId == null) {
      setState(() => _error = s.onboardInvalidCodeError);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final notifier = ref.read(syncProvider.notifier);
      final googleDrive = notifier.googleDrive;

      final connected = await googleDrive.connectToSharedFolder(folderId);
      if (!connected) {
        _fail(s.onboardDriveJoinFailed);
        return;
      }

      await notifier.connectProvider(googleDrive);
      await notifier.restoreFromProvider(googleDrive);

      final syncState = ref.read(syncProvider);
      if (syncState.status == SyncStatus.error) {
        _fail(syncState.lastError ?? s.onboardNoSyncFileShared);
        return;
      }

      await ref.read(householdServiceProvider).loadSavedHousehold();

      if (mounted) {
        Navigator.pop(context);
        context.go('/');
      }
    } catch (e) {
      _fail(syncErrorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return _SheetBody(
      title: s.onboardJoinHousehold,
      description: s.onboardJoinDesc,
      error: _error,
      children: [
        if (_loading)
          const _SheetSpinner()
        else ...[
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: s.onboardInviteCode,
              hintText: s.onboardInviteHint,
              prefixIcon: const Icon(AppIcons.key),
            ),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
            onSubmitted: (_) => _join(),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _join,
            icon: const Icon(AppIcons.signIn, size: 20),
            label: Text(s.onboardJoinButton),
          ),
        ],
      ],
    );
  }
}
