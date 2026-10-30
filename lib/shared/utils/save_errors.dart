import '../../core/engine/allocation_engine.dart';
import '../../core/engine/recurring_engine.dart'
    show AccountUnavailableException, RecurringEndedException;
import '../../l10n/generated/app_localizations.dart';

/// User-facing text for a failed transaction save: a missing exchange rate
/// gets its own explanation, anything else the generic [fallback].
String txSaveErrorText(S l, Object error, {String? fallback}) {
  if (error is CurrencyConversionException) {
    return l.txNoRateBetween(error.from, error.to);
  }
  if (error is AccountUnavailableException) return l.txAccountUnavailable;
  if (error is RecurringEndedException) return l.upcomingBillEnded;
  return fallback ?? l.txFormCouldNotSave;
}
