import '../../core/engine/allocation_engine.dart';
import '../../l10n/generated/app_localizations.dart';

/// User-facing text for a failed transaction save: a missing exchange rate
/// gets its own explanation, anything else the generic [fallback].
String txSaveErrorText(S l, Object error, {String? fallback}) {
  if (error is CurrencyConversionException) {
    return l.txNoRateBetween(error.from, error.to);
  }
  return fallback ?? l.txFormCouldNotSave;
}
