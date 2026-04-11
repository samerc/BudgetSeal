import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/allocation_engine.dart';
import '../engine/period_engine.dart';
import '../engine/recurring_engine.dart';
import '../fx/fx_service.dart';
import 'database_provider.dart';

final allocationEngineProvider = Provider<AllocationEngine>((ref) {
  return AllocationEngine(ref.watch(databaseProvider));
});

final periodEngineProvider = Provider<PeriodEngine>((ref) {
  return PeriodEngine(ref.watch(databaseProvider));
});

final recurringEngineProvider = Provider<RecurringEngine>((ref) {
  return RecurringEngine(ref.watch(databaseProvider));
});

final fxServiceProvider = Provider<FxService>((ref) {
  return FxService(ref.watch(databaseProvider));
});
