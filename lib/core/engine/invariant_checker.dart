import '../database/app_database.dart';
import 'balance_calculator.dart';

/// Exposes invariant checking as a callable utility.
/// Used in debug builds after any engine mutation.
class InvariantChecker {
  final BalanceCalculator _calculator;

  InvariantChecker(AppDatabase db) : _calculator = BalanceCalculator(db);

  Future<Map<String, double>> getUnallocated(String householdId) =>
      _calculator.unallocatedByCurrency(householdId);

  Future<bool> check(String householdId) =>
      _calculator.checkInvariant(householdId);
}
