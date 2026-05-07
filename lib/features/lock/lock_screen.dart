import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';

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

    try {
      final canAuth = await _auth.canCheckBiometrics ||
          await _auth.isDeviceSupported();
      if (!canAuth) {
        // Device has no biometrics and no credentials (PIN/pattern) set up.
        // Attempt device-credential auth anyway — local_auth will prompt
        // the user to set up a screen lock if none exists.
        final didAuth = await _auth.authenticate(
          localizedReason: 'Set up a screen lock to protect Pocket Plan',
          biometricOnly: false,
        );
        if (didAuth && mounted) widget.onUnlocked();
        return;
      }

      final didAuth = await _auth.authenticate(
        localizedReason: 'Unlock Pocket Plan',
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
            content: Text('Unlock failed: ${e.toString()}'),
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
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.lock_rounded,
                  size: 36, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Text(
              'Pocket Plan',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to unlock',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _authenticating ? null : _authenticate,
              icon: const Icon(Icons.fingerprint_rounded, size: 22),
              label: const Text('Unlock'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(CardTokens.radius)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
