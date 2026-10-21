import '../../l10n/generated/app_localizations.dart';

/// User-facing text for a failed biometric/device-credential prompt. The
/// local_auth error codes we can explain get their own message; anything
/// else gets [fallback] — never the raw exception.
String biometricErrorText(S l, Object error, {required String fallback}) {
  final code = error.toString();
  if (code.contains('NotAvailable') || code.contains('NotEnrolled')) {
    return l.biometricNotEnrolled;
  }
  if (code.contains('LockedOut')) return l.biometricLockedOut;
  if (code.contains('PasscodeNotSet')) return l.biometricPasscodeNotSet;
  return fallback;
}
