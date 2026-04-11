import 'package:flutter/services.dart';

/// Light haptic for taps and selections.
void hapticLight() => HapticFeedback.lightImpact();

/// Medium haptic for confirmations.
void hapticMedium() => HapticFeedback.mediumImpact();

/// Heavy haptic for destructive actions.
void hapticHeavy() => HapticFeedback.heavyImpact();

/// Selection haptic for toggles.
void hapticSelection() => HapticFeedback.selectionClick();
