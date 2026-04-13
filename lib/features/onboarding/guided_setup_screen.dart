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
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/calculator_amount_field.dart';

/// Post-household-creation guided setup.
/// Steps: Account → Categories → Entry Mode → Feature Tour → Done
class GuidedSetupScreen extends ConsumerStatefulWidget {
  const GuidedSetupScreen({super.key});

  @override
  ConsumerState<GuidedSetupScreen> createState() =>
      _GuidedSetupScreenState();
}

class _GuidedSetupScreenState extends ConsumerState<GuidedSetupScreen> {
  final _pageCtrl = PageController();
  int _step = 0;
  static const _totalSteps = 5;

  // Step 1: Account
  final _acctNameCtrl = TextEditingController(text: 'Cash');
  String _acctType = 'cash';
  String _acctCurrency = 'USD';
  bool _acctCreated = false;

  double _acctInitialBalance = 0;

  // Step 2: Categories
  String? _selectedPack; // 'essential', 'detailed', null
  bool _catsCreated = false;

  @override
  void initState() {
    super.initState();
    final baseCurrency =
        ref.read(householdProvider).value?.baseCurrency ?? 'USD';
    _acctCurrency = baseCurrency;
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _acctNameCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _step++);
    }
  }

  void _finish() => context.go('/');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.accent,
              AppColors.accent.withValues(alpha: 0.85),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Row(
                  children: List.generate(_totalSteps, (i) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i <= _step
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // Skip button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text('Skip',
                      style: GoogleFonts.inter(
                          color: Colors.white70, fontSize: 14)),
                ),
              ),
              // Pages
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildAccountStep(),
                    _buildCategoryStep(),
                    _buildEntryModeStep(),
                    _buildFeatureTour(),
                    _buildDoneStep(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 1: Create Account ─────────────────────────────────

  Widget _buildAccountStep() {
    final accountTypes = [
      ('cash', 'Cash', Icons.wallet),
      ('bank', 'Bank', Icons.account_balance),
      ('credit', 'Credit Card', Icons.credit_card),
      ('wallet', 'Digital Wallet', Icons.account_balance_wallet),
    ];

    return _StepContainer(
      icon: Icons.account_balance_rounded,
      title: 'Create your first account',
      subtitle: 'Where does your money live?',
      child: Column(
        children: [
          // Account name
          TextField(
            controller: _acctNameCtrl,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: _whiteInputDecoration('Account name'),
          ),
          const SizedBox(height: 16),
          // Type chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: accountTypes.map((t) {
              final isSelected = _acctType == t.$1;
              return GestureDetector(
                onTap: () => setState(() => _acctType = t.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.$3,
                          size: 18,
                          color: isSelected
                              ? AppColors.accent
                              : Colors.white70),
                      const SizedBox(width: 8),
                      Text(t.$2,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.accent
                                : Colors.white70,
                            fontWeight: FontWeight.w500,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Initial balance
          Text('Opening balance',
              style: GoogleFonts.inter(
                  color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Text('$_acctCurrency  ',
                    style: const TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
                Expanded(
                  child: CalculatorAmountField(
                    value: _acctInitialBalance,
                    fontSize: 20,
                    hintText: '0',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    onChanged: (v) =>
                        setState(() => _acctInitialBalance = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _WhiteButton(
            label: _acctCreated ? 'Account Created ✓' : 'Create Account',
            enabled: !_acctCreated,
            onTap: () async {
              final name = _acctNameCtrl.text.trim();
              if (name.isEmpty) return;
              final householdId =
                  ref.read(currentHouseholdIdProvider);
              if (householdId == null) return;

              final db = ref.read(databaseProvider);
              await db.into(db.accounts).insert(
                    AccountsCompanion.insert(
                      id: const Uuid().v4(),
                      householdId: householdId,
                      name: name,
                      type: _acctType,
                      currency: _acctCurrency,
                      initialBalance: Value(_acctInitialBalance),
                      deviceId: 'local',
                    ),
                  );
              setState(() => _acctCreated = true);
              Future.delayed(
                  const Duration(milliseconds: 500), _next);
            },
          ),
        ],
      ),
    );
  }

  // ── Step 2: Category Presets ────────────────────────────────

  Widget _buildCategoryStep() {
    return _StepContainer(
      icon: Icons.category_rounded,
      title: 'Set up categories',
      subtitle: 'Choose a starter pack or create your own later',
      child: Column(
        children: [
          _PackOption(
            title: 'Essential',
            description: '8 categories: Food, Transport, Shopping, Bills, Health, Entertainment, Income',
            count: 13,
            isSelected: _selectedPack == 'essential',
            onTap: () => setState(() => _selectedPack = 'essential'),
          ),
          const SizedBox(height: 10),
          _PackOption(
            title: 'Detailed',
            description: 'Everything in Essential + Home, Personal, Education, Travel with subcategories',
            count: 30,
            isSelected: _selectedPack == 'detailed',
            onTap: () => setState(() => _selectedPack = 'detailed'),
          ),
          const SizedBox(height: 10),
          _PackOption(
            title: 'Custom',
            description: 'Start empty — create your own categories in Settings',
            count: 0,
            isSelected: _selectedPack == 'custom',
            onTap: () => setState(() => _selectedPack = 'custom'),
          ),
          const SizedBox(height: 24),
          _WhiteButton(
            label: _catsCreated
                ? 'Categories Created ✓'
                : 'Continue',
            enabled: _selectedPack != null && !_catsCreated,
            onTap: () async {
              if (_selectedPack == 'custom') {
                _next();
                return;
              }
              final presets = _selectedPack == 'detailed'
                  ? detailedPresets
                  : essentialPresets;
              final householdId =
                  ref.read(currentHouseholdIdProvider);
              if (householdId == null) return;

              final db = ref.read(databaseProvider);

              // Guard: skip seeding if categories already exist
              final existing = await (db.select(db.categories)
                    ..where((c) => c.householdId.equals(householdId)))
                  .get();
              if (existing.isNotEmpty) {
                setState(() => _catsCreated = true);
                Future.delayed(
                    const Duration(milliseconds: 500), _next);
                return;
              }

              final groupIds = <String, String>{};

              // Create groups first
              for (final p in presets.where((p) => p.parentName == null)) {
                final id = const Uuid().v4();
                groupIds[p.name] = id;
                await db.into(db.categories).insert(
                      CategoriesCompanion.insert(
                        id: id,
                        householdId: householdId,
                        name: p.name,
                        icon: Value(p.emoji),
                        colorHex: Value(p.colorHex),
                        transactionType: Value(p.type),
                      ),
                    );
              }
              // Create subcategories
              for (final p
                  in presets.where((p) => p.parentName != null)) {
                final parentId = groupIds[p.parentName];
                await db.into(db.categories).insert(
                      CategoriesCompanion.insert(
                        id: const Uuid().v4(),
                        householdId: householdId,
                        name: p.name,
                        parentId: Value(parentId),
                        icon: Value(p.emoji),
                        colorHex: Value(p.colorHex),
                        transactionType: Value(p.type),
                      ),
                    );
              }
              setState(() => _catsCreated = true);
              Future.delayed(
                  const Duration(milliseconds: 500), _next);
            },
          ),
        ],
      ),
    );
  }

  // ── Step 3: Entry Mode ─────────────────────────────────────

  Widget _buildEntryModeStep() {
    final currentMode = ref.watch(entryModeProvider);

    return _StepContainer(
      icon: Icons.touch_app_rounded,
      title: 'How do you want to add transactions?',
      subtitle: 'You can change this anytime in Settings',
      child: Column(
        children: [
          _ModeOption(
            title: 'Assisted',
            description:
                'Step-by-step: enter title → pick category → enter amount. Fast for daily use.',
            icon: Icons.auto_awesome_rounded,
            isSelected: currentMode == 'assisted',
            onTap: () =>
                ref.read(entryModeProvider.notifier).setMode('assisted'),
          ),
          const SizedBox(height: 10),
          _ModeOption(
            title: 'Classic',
            description:
                'Single form with all fields. Better for complex entries (multi-account, splits, transfers).',
            icon: Icons.list_alt_rounded,
            isSelected: currentMode == 'classic',
            onTap: () =>
                ref.read(entryModeProvider.notifier).setMode('classic'),
          ),
          const SizedBox(height: 24),
          _WhiteButton(label: 'Continue', onTap: _next),
        ],
      ),
    );
  }

  // ── Step 4: Feature Tour ───────────────────────────────────

  Widget _buildFeatureTour() {
    final features = [
      (Icons.account_balance_wallet_rounded, 'Envelopes',
          'Set a monthly budget for each category. Track what\'s left.'),
      (Icons.repeat_rounded, 'Recurring',
          'Automate salary, rent, subscriptions. Set once, forget.'),
      (Icons.bolt_rounded, 'Templates',
          'Save frequent transactions. One tap to re-use.'),
      (Icons.bar_chart_rounded, 'Reports',
          'Charts, trends, spending by category. Know where your money goes.'),
      (Icons.currency_exchange_rounded, 'Multi-Currency',
          'Live exchange rates. Mix accounts in different currencies.'),
      (Icons.backup_rounded, 'Backup',
          'Export your data anytime. Never lose your records.'),
    ];

    return _StepContainer(
      icon: Icons.explore_rounded,
      title: 'What you can do',
      subtitle: 'All of these are in Settings → Tools',
      bottomWidget: _WhiteButton(label: 'Almost done!', onTap: _next),
      child: Column(
        children: features
            .map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(f.$1,
                            size: 22, color: Colors.white70),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(f.$2,
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(f.$3,
                                  style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ── Step 5: Done ───────────────────────────────────────────

  Widget _buildDoneStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.check_rounded,
                  size: 48, color: Colors.white),
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
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            _WhiteButton(
              label: 'Start Using Pocket Plan',
              onTap: _finish,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _whiteInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.07),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
    );
  }
}

// ── Shared Widgets ──────────────────────────────────────────────────────────

class _StepContainer extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? bottomWidget;

  const _StepContainer({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 36, color: Colors.white),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7))),
          const SizedBox(height: 24),
          child,
          if (bottomWidget != null) ...[
            const SizedBox(height: 24),
            bottomWidget!,
          ],
        ],
      ),
    );
  }
}

class _WhiteButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const _WhiteButton({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: enabled ? onTap : null,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.accent,
          disabledBackgroundColor:
              Colors.white.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _PackOption extends StatelessWidget {
  final String title;
  final String description;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _PackOption({
    required this.title,
    required this.description,
    required this.count,
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
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      if (count > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('$count',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(description,
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
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.title,
    required this.description,
    required this.icon,
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
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(description,
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
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
