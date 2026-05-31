import 'package:intl/intl.dart';

import 'generated/app_localizations.dart';
import 'generated/app_localizations_ar.dart';
import 'generated/app_localizations_en.dart';
import 'generated/app_localizations_fr.dart';

/// Get the [S] instance for the current [Intl.defaultLocale].
/// Use this in pure Dart services/engines that have no BuildContext.
S currentS() {
  return switch (Intl.defaultLocale) {
    'ar' => SAr(),
    'fr' => SFr(),
    _ => SEn(),
  };
}
