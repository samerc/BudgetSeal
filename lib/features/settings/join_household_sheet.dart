import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/household_provider.dart';
import '../../core/providers/sync_provider.dart';
import '../../core/sync/household_key.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/sheet_title.dart';

const _scan = 'scan';

/// Join a household from an invite code (typed or scanned). Used by the
/// welcome screen and Cloud Sync; the caller confirms first when this phone
/// already has a budget (joining replaces it, after a backup).
///
/// Scanning closes the sheet, opens `/scan-invite` and reopens the sheet
/// with the code, which then joins at once — a route pushed over a sheet
/// isn't safe with GoRouter.
Future<void> showJoinHouseholdSheet(BuildContext context) async {
  String? code;
  while (true) {
    if (!context.mounted) return;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => JoinHouseholdSheet(scannedCode: code),
    );
    if (result != _scan || !context.mounted) return;
    code = await context.push<String>('/scan-invite');
    if (code == null) return;
  }
}

class JoinHouseholdSheet extends ConsumerStatefulWidget {
  const JoinHouseholdSheet({super.key, this.scannedCode});

  /// From the scanner: filled in and joined straight away.
  final String? scannedCode;

  @override
  ConsumerState<JoinHouseholdSheet> createState() => _JoinHouseholdSheetState();
}

class _JoinHouseholdSheetState extends ConsumerState<JoinHouseholdSheet> {
  late final _codeController =
      TextEditingController(text: widget.scannedCode ?? '');
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.scannedCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _join());
    }
  }

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

    if (HouseholdKey.isOldInvite(code)) {
      setState(() => _error = s.joinOldCode);
      return;
    }
    final key = HouseholdKey.fromCode(code);
    if (key == null) {
      setState(() => _error = s.onboardInvalidCodeError);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final notifier = ref.read(syncProvider.notifier);
      await notifier.joinHousehold(key);

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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetTitle(s.onboardJoinHousehold,
                  subtitle: s.onboardJoinDesc,
                  padding: const EdgeInsetsDirectional.only(bottom: 20)),
              if (_loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                      child: CircularProgressIndicator(color: AppColors.accent)),
                )
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
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, _scan),
                  icon: const Icon(AppIcons.qrCode, size: 20),
                  label: Text(s.joinScanCode),
                ),
              ],
              if (_error != null) ...[
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
      ),
    );
  }
}
