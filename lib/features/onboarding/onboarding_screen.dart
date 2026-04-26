import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/household_provider.dart';
import '../../core/providers/sync_provider.dart';
import '../../core/sync/cloud_provider.dart';
import '../../core/sync/google_drive_provider.dart';
import '../../core/sync/invite_code.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/currency_picker_field.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Step 3 fields
  final _nameController = TextEditingController();
  String _baseCurrency = 'USD';
  int _periodStartDay = 1;
  bool _loading = false;

  final _currencies = [
    'USD', 'EUR', 'GBP', 'LBP', 'AED', 'CAD', 'AUD', 'JPY',
    'CHF', 'TRY', 'SAR', 'EGP', 'INR', 'BRL',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
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
              const Color(0xFF312E81), // Indigo 900
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
                    4,
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
                    _HowItWorksPage(onNext: _nextPage),
                    _TipsPage(onNext: _nextPage),
                    _SetupPage(
                      nameController: _nameController,
                      baseCurrency: _baseCurrency,
                      periodStartDay: _periodStartDay,
                      currencies: _currencies,
                      loading: _loading,
                      onCurrencyChanged: (v) =>
                          setState(() => _baseCurrency = v ?? 'USD'),
                      onDayChanged: (v) =>
                          setState(() => _periodStartDay = v ?? 1),
                      onSubmit: _submit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(householdServiceProvider).createHousehold(
            name: _nameController.text.trim(),
            baseCurrency: _baseCurrency,
            periodStartDay: _periodStartDay,
            deviceId: 'local',
          );
      if (mounted) context.go('/guided-setup');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Page 1: Welcome ─────────────────────────────────────────────────────────

class _WelcomePage extends StatefulWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  State<_WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<_WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIcon, _fadeTitle, _fadeSub, _fadeBtn;
  late final Animation<Offset> _slideIcon, _slideTitle;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIcon = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.0, 0.4, curve: Curves.easeOut));
    _fadeTitle = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.15, 0.55, curve: Curves.easeOut));
    _fadeSub = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.3, 0.7, curve: Curves.easeOut));
    _fadeBtn = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.5, 1.0, curve: Curves.easeOut));
    _slideIcon = Tween(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOut)));
    _slideTitle = Tween(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SlideTransition(
            position: _slideIcon,
            child: FadeTransition(
              opacity: _fadeIcon,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    size: 48, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SlideTransition(
            position: _slideTitle,
            child: FadeTransition(
              opacity: _fadeTitle,
              child: Text(
                'Welcome to\nPocket Plan',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _fadeSub,
            child: Text(
              'The envelope budgeting app that helps you\ngive every dollar a purpose.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 48),
          FadeTransition(
            opacity: _fadeBtn,
            child: _OnboardingButton(label: 'Get Started', onTap: widget.onNext),
          ),
          const SizedBox(height: 14),
          FadeTransition(
            opacity: _fadeBtn,
            child: _RestoreFromCloudButton(),
          ),
          const SizedBox(height: 10),
          FadeTransition(
            opacity: _fadeBtn,
            child: _JoinHouseholdButton(),
          ),
        ],
      ),
    );
  }
}

// ─── Page 2: How it works ────────────────────────────────────────────────────

class _HowItWorksPage extends StatelessWidget {
  final VoidCallback onNext;
  const _HowItWorksPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'How it works',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          _StepRow(
            number: '1',
            title: 'Add your accounts',
            subtitle: 'Bank, cash, wallet — track where your money lives',
            icon: Icons.account_balance_rounded,
          ),
          const SizedBox(height: 16),
          _StepRow(
            number: '2',
            title: 'Create envelopes',
            subtitle: 'Groceries, Rent, Fun — set a budget for each',
            icon: Icons.mail_rounded,
          ),
          const SizedBox(height: 16),
          _StepRow(
            number: '3',
            title: 'Fund your envelopes',
            subtitle: 'When you get paid, distribute money into envelopes',
            icon: Icons.savings_rounded,
          ),
          const SizedBox(height: 16),
          _StepRow(
            number: '4',
            title: 'Spend with confidence',
            subtitle: 'Record expenses — each one draws from its envelope',
            icon: Icons.check_circle_rounded,
          ),
          const SizedBox(height: 40),
          _OnboardingButton(label: 'Continue', onTap: onNext),
        ],
      ),
    );
  }
}

class _TipsPage extends StatelessWidget {
  final VoidCallback onNext;
  const _TipsPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Good to know',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          _StepRow(
            number: '💡',
            title: 'Split bills with friends',
            subtitle:
                'Scan a receipt and assign items to people. '
                'Find it on the Dashboard or long-press the + button',
            icon: Icons.call_split_rounded,
          ),
          const SizedBox(height: 16),
          _StepRow(
            number: '💡',
            title: 'Customize your dashboard',
            subtitle:
                'Tap the tune icon on the Home screen to show, '
                'hide, or reorder sections',
            icon: Icons.tune_rounded,
          ),
          const SizedBox(height: 16),
          _StepRow(
            number: '💡',
            title: 'Bulk actions',
            subtitle:
                'Long-press a transaction to select it, '
                'then tap others to select more. Delete in bulk',
            icon: Icons.checklist_rounded,
          ),
          const SizedBox(height: 16),
          _StepRow(
            number: '💡',
            title: 'Health Check',
            subtitle:
                'Go to More > Health Check to verify your data '
                'integrity and repair any issues',
            icon: Icons.monitor_heart_rounded,
          ),
          const SizedBox(height: 40),
          _OnboardingButton(label: 'Continue', onTap: onNext),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final IconData icon;

  const _StepRow({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(number,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ),
          ),
          const SizedBox(width: 14),
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
        ],
      ),
    );
  }
}

// ─── Page 3: Setup ───────────────────────────────────────────────────────────

class _SetupPage extends StatelessWidget {
  final TextEditingController nameController;
  final String baseCurrency;
  final int periodStartDay;
  final List<String> currencies;
  final bool loading;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<int?> onDayChanged;
  final VoidCallback onSubmit;

  const _SetupPage({
    required this.nameController,
    required this.baseCurrency,
    required this.periodStartDay,
    required this.currencies,
    required this.loading,
    required this.onCurrencyChanged,
    required this.onDayChanged,
    required this.onSubmit,
  });

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.07),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Text(
            'Set up your\nhousehold',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can change these later in Settings.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: _inputDecoration('Household name'),
                ),
                const SizedBox(height: 20),
                CurrencyPickerField(
                  label: 'Base currency',
                  value: baseCurrency,
                  onChanged: (v) => onCurrencyChanged(v),
                  textColor: Colors.white,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  initialValue: periodStartDay,
                  dropdownColor: AppColors.primary,
                  style:
                      const TextStyle(color: Colors.white, fontSize: 16),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.white54),
                  decoration: _inputDecoration('Period start day'),
                  items: List.generate(28, (i) => i + 1)
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text('Day $d',
                                style:
                                    const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: onDayChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _OnboardingButton(
            label: loading ? null : 'Create Household',
            loading: loading,
            onTap: onSubmit,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Shared button ───────────────────────────────────────────────────────────

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
      height: 56,
      child: FilledButton(
        onPressed: loading ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.accent,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label ?? '',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

// ─── Restore from Cloud button ──────────────────────────────────────────────

class _RestoreFromCloudButton extends ConsumerWidget {
  const _RestoreFromCloudButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _showRestoreSheet(context, ref),
        icon: const Icon(Icons.cloud_download_rounded, size: 20),
        label: Text(
          'Restore from Cloud',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
      // Connect first
      final connected =
          await ref.read(syncProvider.notifier).connectProvider(provider);
      if (!connected) {
        setState(() {
          _loading = false;
          _error = 'Failed to connect to ${provider.displayName}';
        });
        return;
      }

      // Attempt restore
      await ref.read(syncProvider.notifier).restoreFromProvider(provider);

      final state = ref.read(syncProvider);
      if (state.status == SyncStatus.error) {
        setState(() {
          _loading = false;
          _error = state.lastError ?? 'No sync file found';
        });
        return;
      }

      // Load the restored household
      await ref.read(householdServiceProvider).loadSavedHousehold();

      if (mounted) {
        Navigator.pop(context); // close sheet
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
          Text(
            'Restore from Cloud',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.tp(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose where your backup is stored. '
            'This will replace any local data.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.ts(context),
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            )
          else ...[
            ...widget.providers.map((provider) {
              final isGoogle = provider is GoogleDriveProvider;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _restoreProviderButton(
                  icon: isGoogle
                      ? Icons.add_to_drive_rounded
                      : Icons.folder_open_rounded,
                  label: isGoogle ? 'Google Drive' : 'Pick a File',
                  onTap: () => _restore(provider),
                  context: context,
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
    );
  }

  Widget _restoreProviderButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.tp(context),
          side: BorderSide(color: AppColors.bd(context)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ─── Join a Household button ────────────────────────────────────────────────

class _JoinHouseholdButton extends ConsumerWidget {
  const _JoinHouseholdButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _showJoinSheet(context, ref),
        icon: const Icon(Icons.people_outline_rounded, size: 20),
        label: Text(
          'Join a Household',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _showJoinSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _JoinHouseholdSheet(),
    );
  }
}

// ─── Join Household Sheet ───────────────────────────────────────────────────

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

      // Connect to the shared folder
      final connected = await googleDrive.connectToSharedFolder(folderId);
      if (!connected) {
        setState(() {
          _loading = false;
          _error = 'Could not connect to Google Drive. '
              'Make sure you are signed in and have access to the shared folder.';
        });
        return;
      }

      // Set as active provider
      final providerOk = await notifier.connectProvider(googleDrive);
      if (!providerOk) {
        // connectProvider may re-authenticate; the folder ID is already set
        // from connectToSharedFolder, so try restoring directly.
      }

      // Download and restore data from the shared folder
      await notifier.restoreFromProvider(googleDrive);

      final syncState = ref.read(syncProvider);
      if (syncState.status == SyncStatus.error) {
        setState(() {
          _loading = false;
          _error = syncState.lastError ?? 'No sync file found in the shared folder';
        });
        return;
      }

      // Load the restored household
      await ref.read(householdServiceProvider).loadSavedHousehold();

      if (mounted) {
        Navigator.pop(context); // close sheet
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
              'Join a Household',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.tp(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the invite code shared with you to join an existing '
              'PocketPlan household. This will sign you into Google Drive '
              'and download the shared data.',
              style: TextStyle(fontSize: 13, color: AppColors.ts(context)),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                ),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _join,
                  icon: const Icon(Icons.login_rounded, size: 20),
                  label: const Text(
                    'Join Household',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
