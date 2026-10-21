import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database_provider.dart';
import 'household_provider.dart';

/// Progress through the envelope-budgeting basics, read from real data:
/// income recorded → envelopes exist → an envelope was funded → an expense
/// was logged. Drives the getting-started checklist on Home.
class GettingStarted {
  final bool income;
  final bool envelopes;
  final bool funded;
  final bool expense;

  const GettingStarted({
    required this.income,
    required this.envelopes,
    required this.funded,
    required this.expense,
  });

  int get doneCount =>
      [income, envelopes, funded, expense].where((d) => d).length;
  bool get allDone => doneCount == 4;
}

final gettingStartedProvider = StreamProvider<GettingStarted>((ref) {
  final db = ref.watch(databaseProvider);
  final hid = ref.watch(currentHouseholdIdProvider);
  if (hid == null) return const Stream.empty();
  return db
      .customSelect(
        '''
SELECT
  EXISTS(SELECT 1 FROM transactions WHERE household_id = ?1 AND deleted = 0
         AND status IS NULL AND type = 'income') AS income,
  EXISTS(SELECT 1 FROM allocations WHERE household_id = ?1 AND deleted = 0
         AND archived = 0) AS envelopes,
  EXISTS(SELECT 1 FROM allocation_ledger l
         JOIN allocations a ON a.id = l.allocation_id
         WHERE a.household_id = ?1 AND l.entry_type = 'funding') AS funded,
  EXISTS(SELECT 1 FROM transactions WHERE household_id = ?1 AND deleted = 0
         AND status IS NULL AND type = 'expense') AS expense
''',
        variables: [Variable.withString(hid)],
        readsFrom: {db.transactions, db.allocations, db.allocationLedger},
      )
      .watchSingle()
      .map((r) => GettingStarted(
            income: r.read<bool>('income'),
            envelopes: r.read<bool>('envelopes'),
            funded: r.read<bool>('funded'),
            expense: r.read<bool>('expense'),
          ));
});

/// Whether the checklist is hidden for good: the user closed it, or every
/// step was done once (it doesn't come back if data is deleted later).
class GettingStartedHiddenNotifier extends Notifier<bool> {
  static const _key = 'getting_started_hidden';

  @override
  bool build() {
    // Hidden until the pref is read, so a closed checklist never flashes.
    SharedPreferences.getInstance().then((p) {
      state = p.getBool(_key) ?? false;
    });
    return true;
  }

  Future<void> hide() async {
    state = true;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, true);
  }
}

final gettingStartedHiddenProvider =
    NotifierProvider<GettingStartedHiddenNotifier, bool>(
        GettingStartedHiddenNotifier.new);
