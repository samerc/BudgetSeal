import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/biometric_errors.dart';
import '../../shared/theme/app_icons.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _auth = LocalAuthentication();
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);

    // Capture i18n strings before async gap
    final setupReason = S.of(context).lockSetupReason;
    final unlockReason = S.of(context).lockUnlockReason;

    try {
      final canAuth = await _auth.canCheckBiometrics ||
          await _auth.isDeviceSupported();
      if (!canAuth) {
        // Device has no biometrics and no credentials (PIN/pattern) set up.
        // Attempt device-credential auth anyway — local_auth will prompt
        // the user to set up a screen lock if none exists.
        final didAuth = await _auth.authenticate(
          localizedReason: setupReason,
          biometricOnly: false,
        );
        if (didAuth && mounted) widget.onUnlocked();
        return;
      }

      final didAuth = await _auth.authenticate(
        localizedReason: unlockReason,
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );

      if (didAuth && mounted) {
        widget.onUnlocked();
      }
    } catch (e) {
      // Auth failed or not available — show error and allow manual retry.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(biometricErrorText(S.of(context), e,
                fallback: S.of(context).lockUnlockFailed)),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _authenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        // Fixed night surface: light status bar icons in every theme.
        value: SystemUiOverlayStyle.light,
        child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Deliberately the fixed night brand surface in every theme
            // (it covers the app), so its colors are the dark-theme ones.
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(RadiusTokens.hero),
              ),
              child: Icon(AppIcons.lock,
                  size: 36, color: AppColors.accentBright),
            ),
            const SizedBox(height: 24),
            Text(
              S.of(context).appName,
              style: TextStyle(
                fontSize: 24,
                fontFamily: TypographyTokens.displayFamily,
                fontWeight: FontWeight.w800,
                color: AppColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context).lockTapToUnlock,
              style: const TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: AppColors.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _authenticating ? null : _authenticate,
              icon: const Icon(AppIcons.fingerprint, size: 22),
              label: Text(S.of(context).lockUnlockButton),
              // Theme filled button (accent fill, onAccent text); sized to
              // its label instead of the theme's full width.
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 52),
                padding: const EdgeInsets.symmetric(horizontal: 32),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
