import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../core/data/category_presets.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/entry_mode_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/sync_provider.dart';
import '../../core/sync/cloud_provider.dart';
import '../../core/sync/google_drive_provider.dart';
import '../../core/sync/invite_code.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/currency_picker_field.dart';

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
  String _baseCurrency = 'USD';
  int _periodStartDay = 1;

  // Account
  final _acctNameCtrl = TextEditingController(text: 'Cash');
  String _acctType = 'cash';
  double _acctInitialBalance = 0;

  // Categories
  bool _seedCategories = true; // true = full set, false = empty

  // Entry mode
  String _entryMode = 'assisted';

  bool _loading = false;
  String? _nameError;
  String? _acctNameError;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _acctNameCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  // ── Submit: create household + account + categories + entry mode ──
  Future<void> _submit() async {
    final householdName = _nameController.text.trim();
    final acctName = _acctNameCtrl.text.trim();

    // Validate
    String? nameErr, acctErr;
    if (householdName.isEmpty) nameErr = 'Enter a household name';
    if (acctName.isEmpty) acctErr = 'Enter an account name';
    if (nameErr != null || acctErr != null) {
      setState(() {
        _nameError = nameErr;
        _acctNameError = acctErr;
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

          for (final p in presets.where((p) => p.parentName == null)) {
            final id = const Uuid().v4();
            groupIds[p.name] = id;
            batch.insert(db.categories, CategoriesCompanion.insert(
              id: id,
              householdId: householdId,
              name: p.name,
              icon: Value(p.emoji),
              colorHex: Value(p.colorHex),
              transactionType: Value(p.type),
            ));
          }
          for (final p in presets.where((p) => p.parentName != null)) {
            final parentId = groupIds[p.parentName];
            batch.insert(db.categories, CategoriesCompanion.insert(
              id: const Uuid().v4(),
              householdId: householdId,
              name: p.name,
              parentId: Value(parentId),
              icon: Value(p.emoji),
              colorHex: Value(p.colorHex),
              transactionType: Value(p.type),
            ));
          }
        }
      });

      // 4. Set entry mode
      ref.read(entryModeProvider.notifier).setMode(_entryMode);

      // 5. Go to done page
      if (mounted) _nextPage();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent,
              AppColors.accent.withValues(alpha: 0.8),
              const Color(0xFF312E81),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress dots
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _currentPage ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _currentPage
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _WelcomePage(onNext: _nextPage),
                    _SetupPage(
                      nameController: _nameController,
                      baseCurrency: _baseCurrency,
                      periodStartDay: _periodStartDay,
                      acctNameCtrl: _acctNameCtrl,
                      acctType: _acctType,
                      acctInitialBalance: _acctInitialBalance,
                      seedCategories: _seedCategories,
                      entryMode: _entryMode,
                      loading: _loading,
                      nameError: _nameError,
                      acctNameError: _acctNameError,
                      onNameErrorClear: () => setState(() => _nameError = null),
                      onAcctNameErrorClear: () => setState(() => _acctNameError = null),
                      onCurrencyChanged: (v) =>
                          setState(() => _baseCurrency = v ?? 'USD'),
                      onDayChanged: (v) =>
                          setState(() => _periodStartDay = v ?? 1),
                      onAcctTypeChanged: (v) =>
                          setState(() => _acctType = v),
                      onAcctBalanceChanged: (v) =>
                          setState(() => _acctInitialBalance = v),
                      onSeedChanged: (v) =>
                          setState(() => _seedCategories = v),
                      onEntryModeChanged: (v) =>
                          setState(() => _entryMode = v),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // ── Branding ──
          SlideTransition(
            position: _slideIcon,
            child: FadeTransition(
              opacity: _fadeIcon,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    size: 40, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SlideTransition(
            position: _slideTitle,
            child: FadeTransition(
              opacity: _fadeTitle,
              child: Text(
                'Pocket Plan',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FadeTransition(
            opacity: _fadeSub,
            child: Text(
              'Give every dollar a purpose.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── How it works (compact) ──
          FadeTransition(
            opacity: _fadeContent,
            child: Column(
              children: [
                _CompactStep(
                  number: '1',
                  text: 'Add accounts — where your money lives',
                ),
                const SizedBox(height: 8),
                _CompactStep(
                  number: '2',
                  text: 'Create envelopes — budget for each category',
                ),
                const SizedBox(height: 8),
                _CompactStep(
                  number: '3',
                  text: 'Fund envelopes — distribute your income',
                ),
                const SizedBox(height: 8),
                _CompactStep(
                  number: '4',
                  text: 'Spend — each expense draws from its envelope',
                ),
                const SizedBox(height: 32),
                _OnboardingButton(label: 'Get Started', onTap: widget.onNext),
                const SizedBox(height: 12),
                _RestoreFromCloudButton(),
                const SizedBox(height: 8),
                _JoinHouseholdButton(),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _CompactStep extends StatelessWidget {
  final String number;
  final String text;
  const _CompactStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(number,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 13, height: 1.3)),
          ),
        ],
      ),
    );
  }
}

// ─── Page 2: Setup (all-in-one) ─────────────────────────────────────────────

class _SetupPage extends StatelessWidget {
  final TextEditingController nameController;
  final String baseCurrency;
  final int periodStartDay;
  final TextEditingController acctNameCtrl;
  final String acctType;
  final double acctInitialBalance;
  final bool seedCategories;
  final String entryMode;
  final bool loading;
  final String? nameError;
  final String? acctNameError;
  final VoidCallback? onNameErrorClear;
  final VoidCallback? onAcctNameErrorClear;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<int?> onDayChanged;
  final ValueChanged<String> onAcctTypeChanged;
  final ValueChanged<double> onAcctBalanceChanged;
  final ValueChanged<bool> onSeedChanged;
  final ValueChanged<String> onEntryModeChanged;
  final VoidCallback onSubmit;

  const _SetupPage({
    required this.nameController,
    required this.baseCurrency,
    required this.periodStartDay,
    required this.acctNameCtrl,
    required this.acctType,
    required this.acctInitialBalance,
    required this.seedCategories,
    required this.entryMode,
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
    required this.onEntryModeChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final accountTypes = [
      ('cash', 'Cash', Icons.wallet),
      ('bank', 'Bank', Icons.account_balance),
      ('credit', 'Credit', Icons.credit_card),
      ('wallet', 'Digital', Icons.account_balance_wallet),
    ];

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Set up your household',
                style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text('You can change everything later in Settings.',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6))),
            const SizedBox(height: 20),

            // ── Household ──
            _SectionLabel('HOUSEHOLD'),
            const SizedBox(height: 8),
            _FormCard(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    onChanged: nameError != null ? (_) => onNameErrorClear?.call() : null,
                    decoration: _inputDeco('Household name').copyWith(
                      errorText: nameError,
                      errorStyle: TextStyle(color: Colors.amber.shade300, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  CurrencyPickerField(
                    label: 'Base currency',
                    value: baseCurrency,
                    onChanged: (v) => onCurrencyChanged(v),
                    textColor: Colors.white,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    initialValue: periodStartDay,
                    dropdownColor: AppColors.primary,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white54),
                    decoration: _inputDeco('Period start day'),
                    items: List.generate(28, (i) => i + 1)
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text('Day $d',
                                  style: const TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: onDayChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── First Account ──
            _SectionLabel('FIRST ACCOUNT'),
            const SizedBox(height: 8),
            _FormCard(
              child: Column(
                children: [
                  TextField(
                    controller: acctNameCtrl,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    onChanged: acctNameError != null ? (_) => onAcctNameErrorClear?.call() : null,
                    decoration: _inputDeco('Account name').copyWith(
                      errorText: acctNameError,
                      errorStyle: TextStyle(color: Colors.amber.shade300, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Type chips
                  Row(
                    children: accountTypes.map((t) {
                      final sel = acctType == t.$1;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onAcctTypeChanged(t.$1),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: sel
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Icon(t.$3,
                                    size: 18,
                                    color: sel
                                        ? AppColors.accent
                                        : Colors.white70),
                                const SizedBox(height: 4),
                                Text(t.$2,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: sel
                                          ? AppColors.accent
                                          : Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  // Balance
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Text('$baseCurrency  ',
                            style: const TextStyle(
                                color: Colors.white60,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                        Expanded(
                          child: CalculatorAmountField(
                            value: acctInitialBalance,
                            fontSize: 18,
                            hintText: '0',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            onChanged: onAcctBalanceChanged,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── More Options (collapsed by default) ──
            _ExpandableOptions(
              seedCategories: seedCategories,
              entryMode: entryMode,
              onSeedChanged: onSeedChanged,
              onEntryModeChanged: onEntryModeChanged,
            ),
            const SizedBox(height: 24),

            _OnboardingButton(
              label: loading ? null : 'Create & Start',
              loading: loading,
              onTap: onSubmit,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.07),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.5),
          letterSpacing: 1.0,
        ));
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;
  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: Colors.white,
              size: 20,
            ),
          ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(Icons.check_rounded,
                size: 44, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            'You\'re all set!',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start tracking your expenses.\nYour financial clarity begins now.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          _OnboardingButton(
            label: 'Start Using Pocket Plan',
            onTap: onFinish,
          ),
        ],
      ),
    );
  }
}

// ─── Shared button ──────────────────────────────────────────────────────────

class _OnboardingButton extends StatelessWidget {
  final String? label;
  final bool loading;
  final VoidCallback onTap;

  const _OnboardingButton({
    this.label,
    this.loading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: loading ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.accent,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CardTokens.radius),
          ),
        ),
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label ?? '',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

// ─── Restore from Cloud button ─────────────────────────────────────────────

class _RestoreFromCloudButton extends ConsumerWidget {
  const _RestoreFromCloudButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _showRestoreSheet(context, ref),
        icon: const Icon(Icons.cloud_download_rounded, size: 18),
        label: Text(
          'Restore from Cloud',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CardTokens.radius),
          ),
        ),
      ),
    );
  }

  void _showRestoreSheet(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(syncProvider.notifier);
    final providers = notifier.availableProviders;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RestoreSheet(providers: providers),
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

  Future<void> _restore(CloudProvider provider) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final connected =
          await ref.read(syncProvider.notifier).connectProvider(provider);
      if (!connected) {
        setState(() {
          _loading = false;
          _error = 'Failed to connect to ${provider.displayName}';
        });
        return;
      }

      await ref.read(syncProvider.notifier).restoreFromProvider(provider);

      final state = ref.read(syncProvider);
      if (state.status == SyncStatus.error) {
        setState(() {
          _loading = false;
          _error = state.lastError ?? 'No sync file found';
        });
        return;
      }

      await ref.read(householdServiceProvider).loadSavedHousehold();

      if (mounted) {
        Navigator.pop(context);
        context.go('/');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text('Restore from Cloud',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tp(context))),
          const SizedBox(height: 8),
          Text(
            'Choose where your backup is stored. '
            'This will replace any local data.',
            style: TextStyle(fontSize: 13, color: AppColors.ts(context)),
          ),
          const SizedBox(height: 20),
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            )
          else ...[
            ...widget.providers.map((provider) {
              final isGoogle = provider is GoogleDriveProvider;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => _restore(provider),
                    icon: Icon(
                        isGoogle
                            ? Icons.add_to_drive_rounded
                            : Icons.folder_open_rounded,
                        size: 20),
                    label: Text(isGoogle ? 'Google Drive' : 'Pick a File',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.tp(context),
                      side: BorderSide(color: AppColors.bd(context)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(CardTokens.radius),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
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
                    child: Text(_error!,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.overspent)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Join a Household button ───────────────────────────────────────────────

class _JoinHouseholdButton extends ConsumerWidget {
  const _JoinHouseholdButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _showJoinSheet(context),
        icon: const Icon(Icons.people_outline_rounded, size: 18),
        label: Text(
          'Join a Household',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CardTokens.radius),
          ),
        ),
      ),
    );
  }

  void _showJoinSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _JoinHouseholdSheet(),
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

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter an invite code');
      return;
    }

    final folderId = decodeInviteCode(code);
    if (folderId == null) {
      setState(() => _error = 'Invalid invite code. It should start with PP-');
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
        setState(() {
          _loading = false;
          _error = 'Could not connect to Google Drive. '
              'Make sure you are signed in and have access to the shared folder.';
        });
        return;
      }

      await notifier.connectProvider(googleDrive);
      await notifier.restoreFromProvider(googleDrive);

      final syncState = ref.read(syncProvider);
      if (syncState.status == SyncStatus.error) {
        setState(() {
          _loading = false;
          _error =
              syncState.lastError ?? 'No sync file found in the shared folder';
        });
        return;
      }

      await ref.read(householdServiceProvider).loadSavedHousehold();

      if (mounted) {
        Navigator.pop(context);
        context.go('/');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
            Text('Join a Household',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tp(context))),
            const SizedBox(height: 8),
            Text(
              'Enter the invite code shared with you to join an existing '
              'PocketPlan household.',
              style: TextStyle(fontSize: 13, color: AppColors.ts(context)),
            ),
            const SizedBox(height: 20),
            if (_loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              )
            else ...[
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Invite code',
                  hintText: 'PP-...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CardTokens.radius),
                  ),
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _join,
                  icon: const Icon(Icons.login_rounded, size: 20),
                  label: const Text('Join Household',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
                      child: Text(_error!,
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
    );
  }
}

class _ExpandableOptions extends StatefulWidget {
  final bool seedCategories;
  final String entryMode;
  final ValueChanged<bool> onSeedChanged;
  final ValueChanged<String> onEntryModeChanged;

  const _ExpandableOptions({
    required this.seedCategories,
    required this.entryMode,
    required this.onSeedChanged,
    required this.onEntryModeChanged,
  });

  @override
  State<_ExpandableOptions> createState() => _ExpandableOptionsState();
}

class _ExpandableOptionsState extends State<_ExpandableOptions> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              AnimatedRotation(
                turns: _expanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.chevron_right_rounded,
                    color: Colors.white54, size: 20),
              ),
              const SizedBox(width: 4),
              Text('More options',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54)),
              const Spacer(),
              Text(
                'Categories: ${widget.seedCategories ? "Full set" : "Empty"} · Entry: ${widget.entryMode == "assisted" ? "Assisted" : "Classic"}',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _SectionLabel('CATEGORIES'),
              const SizedBox(height: 8),
              _FormCard(
                child: Column(
                  children: [
                    _ToggleOption(
                      title: 'Full set',
                      subtitle: '30 categories with subcategories',
                      isSelected: widget.seedCategories,
                      onTap: () => widget.onSeedChanged(true),
                    ),
                    const SizedBox(height: 8),
                    _ToggleOption(
                      title: 'Empty',
                      subtitle: 'Create your own from scratch',
                      isSelected: !widget.seedCategories,
                      onTap: () => widget.onSeedChanged(false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionLabel('TRANSACTION ENTRY'),
              const SizedBox(height: 8),
              _FormCard(
                child: Column(
                  children: [
                    _ToggleOption(
                      title: 'Assisted',
                      subtitle: 'Step-by-step, fast for daily use',
                      isSelected: widget.entryMode == 'assisted',
                      onTap: () => widget.onEntryModeChanged('assisted'),
                    ),
                    const SizedBox(height: 8),
                    _ToggleOption(
                      title: 'Classic form',
                      subtitle: 'All fields at once, for complex entries',
                      isSelected: widget.entryMode == 'classic',
                      onTap: () => widget.onEntryModeChanged('classic'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }
}
