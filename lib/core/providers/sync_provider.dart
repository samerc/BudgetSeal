import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auto_backup_service.dart';
import '../../shared/utils/receipt_helper.dart';
import '../sync/household_key.dart';
import '../sync/relay_provider.dart';
import '../sync/cloud_provider.dart';
import '../sync/file_picker_provider.dart';
import '../sync/google_drive_provider.dart';
import '../sync/sync_encryption.dart';
import '../sync/log_sync.dart';
import '../sync/sync_engine.dart';
import 'age_of_money_provider.dart';
import 'daily_spending_provider.dart';
import 'database_provider.dart';
import 'household_provider.dart';
import 'objectives_provider.dart';
import 'period_reset_provider.dart';
import 'receipt_sync_provider.dart';
import '../../l10n/s_lookup.dart';
import '../services/household_members.dart';
import 'transactions_provider.dart';

const _prefActiveProvider = 'sync_active_provider';
const _prefLastSync = 'sync_last_sync';
const _prefLastSnapshot = 'sync_last_snapshot';

enum SyncStatus { idle, syncing, success, error }

/// What a newly connected provider already holds.
enum RemoteMatch {
  /// No sync file yet — upload this device's data.
  none,

  /// A file of this device's budget — sync (merge) as usual.
  same,

  /// A file of a different budget — ask before replacing this one.
  other,
}

class SyncState {
  final CloudProvider? activeProvider;
  final SyncStatus status;
  final DateTime? lastSyncTime;
  final String? lastError;
  final int? lastChanges;

  const SyncState({
    this.activeProvider,
    this.status = SyncStatus.idle,
    this.lastSyncTime,
    this.lastError,
    this.lastChanges,
  });

  SyncState copyWith({
    CloudProvider? activeProvider,
    SyncStatus? status,
    DateTime? lastSyncTime,
    String? lastError,
    int? lastChanges,
    bool clearProvider = false,
    bool clearError = false,
  }) =>
      SyncState(
        activeProvider: clearProvider ? null : (activeProvider ?? this.activeProvider),
        status: status ?? this.status,
        lastSyncTime: lastSyncTime ?? this.lastSyncTime,
        lastError: clearError ? null : (lastError ?? this.lastError),
        lastChanges: lastChanges ?? this.lastChanges,
      );
}

class SyncNotifier extends Notifier<SyncState> {
  late final SyncEngine _engine;

  /// The sync, restore or upload in progress. Only one runs at a time:
  /// Sync now, resume and pause can all start one, and two merges +
  /// uploads overlapping would upload a file missing the other's changes.
  Future<void>? _running;

  Future<void> _exclusive(Future<void> Function() job) {
    final running = _running;
    if (running != null) return running;
    final f = job().whenComplete(() => _running = null);
    _running = f;
    return f;
  }

  // Available providers
  final googleDrive = GoogleDriveProvider();
  final filePicker = FilePickerProvider();
  final relay = RelayProvider();

  /// The pref value naming [provider] (`sync_active_provider`).
  static String _keyOf(CloudProvider provider) => switch (provider) {
        GoogleDriveProvider() => 'google_drive',
        RelayProvider() => 'household',
        _ => 'file',
      };

  /// All provider options shown in the UI. Local file uses the system file
  /// picker, which also reaches OneDrive/Dropbox when their apps are installed.
  List<({String label, String subtitle, String iconKey, CloudProvider provider})>
      get providerOptions => [
            (
              label: 'Google Drive',
              subtitle: currentS().syncGoogleSub,
              iconKey: 'google_drive',
              provider: googleDrive,
            ),
            // OneDrive and Dropbox rows ('onedrive' / 'dropbox', subtitles
            // syncOneDriveSub / syncDropboxSub) are hidden until they get
            // their own providers; Local file reaches them through the picker.
            (
              label: currentS().syncLocalFile,
              subtitle: currentS().syncLocalFileSub,
              iconKey: 'local',
              provider: filePicker,
            ),
          ];

  List<CloudProvider> get availableProviders => [googleDrive, filePicker];

  @override
  SyncState build() {
    _engine = SyncEngine(ref.read(databaseProvider));
    _loadSavedProvider();
    return const SyncState();
  }

  Future<void> _loadSavedProvider() async {
    final prefs = await SharedPreferences.getInstance();
    final savedProvider = prefs.getString(_prefActiveProvider);
    final lastSyncStr = prefs.getString(_prefLastSync);
    final lastSync =
        lastSyncStr != null ? DateTime.tryParse(lastSyncStr) : null;

    CloudProvider? provider;
    if (savedProvider == 'google_drive') {
      // Try to silently restore the Google session without prompting.
      final restored = await googleDrive.tryReconnectSilently();
      if (restored) provider = googleDrive;
    } else if (savedProvider == 'file' && await filePicker.isConnected) {
      provider = filePicker;
    } else if (savedProvider == 'household' && await relay.isConnected) {
      provider = relay;
    }

    if (!ref.mounted) return;
    state = state.copyWith(
      activeProvider: provider,
      lastSyncTime: lastSync,
    );
  }

  /// Connect to a cloud provider and set it as active.
  Future<bool> connectProvider(CloudProvider provider) async {
    final ok = await provider.connect();
    if (!ok) return false;
    await useConnectedProvider(provider);
    return true;
  }

  /// Make [provider] — already signed in (joining a shared folder) — the
  /// active one, without signing in again.
  Future<void> useConnectedProvider(CloudProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefActiveProvider, _keyOf(provider));

    state = state.copyWith(activeProvider: provider);
  }

  /// Starts a household on the relay with this phone's budget: leaves
  /// Drive or a folder (one sync at a time), uploads everything sealed.
  /// The household key replaces the sync password, which every phone
  /// would otherwise need too.
  /// The household is made first: offline (or refused), this throws with
  /// Drive / the folder and the password still in place.
  Future<void> startHousehold() async {
    await relay.connect();
    await _leaveOtherProvider();
    await SyncEncryption.clearPassword();
    await useConnectedProvider(relay);
    await initialUpload();
  }

  /// Joins the household [key] opens, replacing this phone's budget (after
  /// a backup). Throws [RelayException] when the relay refuses the key.
  ///
  /// Nothing is kept until the household's budget is in: the key is
  /// checked and the budget downloaded with the key held in memory only.
  /// When that fails (the state shows why), this phone keeps its budget,
  /// its sync (Drive, folder, or the household it was in) and password.
  Future<void> joinHousehold(HouseholdKey key) async {
    await relay.check(key);
    // A sync in progress finishes first (it would otherwise be what
    // _exclusive hands back, and the join would never run).
    final running = _running;
    if (running != null) {
      try {
        await running;
      } catch (_) {}
    }
    await _exclusive(() => _restore(relay.withKey(key), commit: () async {
          await _leaveOtherProvider();
          await SyncEncryption.clearPassword();
          await relay.adopt(key);
        }, activeAs: relay));
  }

  Future<void> _leaveOtherProvider() async {
    final current = state.activeProvider;
    if (current == null || current is RelayProvider) return;
    await disconnectProvider();
  }

  /// Disconnect the current provider.
  Future<void> disconnectProvider() async {
    final provider = state.activeProvider;
    if (provider != null) {
      await provider.disconnect();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefActiveProvider);
    await prefs.remove(_prefLastSync);

    state = state.copyWith(clearProvider: true, status: SyncStatus.idle);
  }

  /// Full sync: apply the other phones' log entries, write this phone's
  /// (`LogSync`), refresh the daily snapshot, sync receipts. A call while
  /// one is running waits for that one instead.
  Future<void> sync() => _exclusive(_sync);

  Future<void> _sync() async {
    final provider = state.activeProvider;
    if (provider == null) return;
    // The open DB is about to be replaced by a restored backup.
    if (AutoBackupService.restorePending) return;

    state = state.copyWith(status: SyncStatus.syncing);

    try {
      int totalChanges = 0;

      // 1. The other phones' changes in, ours out.
      totalChanges += await _logSync.sync(ProviderLogStore(provider));
      if (totalChanges > 0) _refreshAfterMerge();

      // 2. The readable copy (docs/file-format.md), at most once a day.
      await _snapshotIfDue(provider);

      // 3. Sync receipts if enabled and provider supports it
      if (provider is GoogleDriveProvider) {
        final receiptSyncEnabled = ref.read(receiptSyncProvider);
        if (receiptSyncEnabled) {
          await _syncReceipts(provider);
        }
      }

      // 4. Update last sync time
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLastSync, now.toIso8601String());

      state = state.copyWith(
        status: SyncStatus.success,
        lastSyncTime: now,
        lastChanges: totalChanges,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        lastError: syncErrorText(e),
      );
    }
  }

  LogSync get _logSync => LogSync(ref.read(databaseProvider));

  /// Writes `BudgetSeal_Sync.json` (the whole budget, readable without the
  /// app) when the last one is a day old. Sync itself uses the logs.
  Future<void> _snapshotIfDue(CloudProvider provider, {bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final last = DateTime.tryParse(prefs.getString(_prefLastSnapshot) ?? '');
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < const Duration(days: 1)) {
      return;
    }
    await provider.upload(await _engine.exportToJson());
    await prefs.setString(_prefLastSnapshot, DateTime.now().toIso8601String());
  }

  /// A phone that synced to one picked file before log sync: it has to
  /// pick a folder (Settings › Cloud sync shows the prompt).
  Future<bool> needsFolderPick() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefActiveProvider) == 'file' &&
        prefs.getString(legacyFileSyncPathKey) != null &&
        !await filePicker.isConnected;
  }

  /// Most screens read Drift streams and redraw by themselves after a
  /// merge; these providers load once and need a nudge.
  void _refreshAfterMerge() {
    // Its lines cache can't see lines changed without their row.
    ref.invalidate(transactionEntriesProvider);
    ref.invalidate(objectivesProvider);
    ref.invalidate(dailySpendingProvider);
    ref.invalidate(ageOfMoneyProvider);
    ref.invalidate(pendingResetProvider);
  }

  /// Shows [e] as the sync error (see [syncErrorText]).
  void reportError(Object e) => state = state.copyWith(
        status: SyncStatus.error,
        lastError: syncErrorText(e),
      );

  /// After connecting: is there a sync file, and is it this budget's?
  /// Throws (e.g. [SyncPasswordException]) when the file can't be read.
  Future<RemoteMatch> checkRemote() async {
    final provider = state.activeProvider;
    if (provider == null) return RemoteMatch.none;
    var ids = await _logSync.householdIdsIn(ProviderLogStore(provider));
    if (ids.isEmpty) {
      // A folder from before log sync: only the old whole-budget file.
      final raw = await provider.download();
      if (raw == null) return RemoteMatch.none;
      ids = await _engine.householdIdsIn(raw);
    }
    final local = ref.read(currentHouseholdIdProvider);
    if (ids.isEmpty) return RemoteMatch.none;
    return local != null && ids.contains(local)
        ? RemoteMatch.same
        : RemoteMatch.other;
  }

  /// Sync receipt files with Google Drive.
  Future<void> _syncReceipts(GoogleDriveProvider provider) async {
    final db = ref.read(databaseProvider);
    final householdId = ref.read(currentHouseholdIdProvider);
    final query = db.select(db.transactions)
      ..where((t) => t.deleted.equals(false));
    if (householdId != null) {
      query.where((t) => t.householdId.equals(householdId));
    }
    final transactions = await query.get();

    // Collect all receipt filenames from the database
    final allFilenames = <String>{};
    for (final tx in transactions) {
      final filenames = parseReceiptPaths(tx.receiptPath);
      allFilenames.addAll(filenames);
    }
    if (allFilenames.isEmpty) return;

    final appDir = await getApplicationDocumentsDirectory();
    final receiptsDir = p.join(appDir.path, 'receipts');

    // Upload local receipts not yet on Drive
    final localPaths = <String>[];
    for (final filename in allFilenames) {
      final fullPath = p.join(receiptsDir, filename);
      if (await File(fullPath).exists()) {
        localPaths.add(fullPath);
      }
    }
    if (localPaths.isNotEmpty) {
      await provider.uploadReceipts(localPaths);
    }

    // Download any Drive receipts not yet local
    await provider.downloadMissingReceipts(
        allFilenames.toList(), receiptsDir);
  }

  /// Replaces all local data with the budget in the provider's folder
  /// (its phones' logs; a folder from before log sync: the old file).
  Future<void> restoreFromProvider(CloudProvider provider) =>
      _exclusive(() => _restore(provider));

  /// [commit] runs once the data is replaced, before [activeAs] (default
  /// [provider]) becomes the active provider.
  Future<void> _restore(CloudProvider provider,
      {Future<void> Function()? commit, CloudProvider? activeAs}) async {
    state = state.copyWith(status: SyncStatus.syncing);
    try {
      final store = ProviderLogStore(provider);
      final hasLogs = (await store.list()).isNotEmpty;
      final json = hasLogs ? null : await provider.download();
      if (!hasLogs && json == null) {
        state = state.copyWith(
          status: SyncStatus.error,
          // A household has no folder: its creator hasn't synced yet.
          lastError: provider is RelayProvider
              ? currentS().relayEmptyHousehold
              : currentS().syncNoSyncFile,
        );
        return;
      }

      // Restoring wipes every table first: keep a copy of what's here
      // (Backup & Restore lists it). No copy, no restore.
      try {
        await AutoBackupService.backupNow();
      } catch (e) {
        debugPrint('[Sync] Backup before restore failed: $e');
        state = state.copyWith(
          status: SyncStatus.error,
          lastError: currentS().syncErrBackupFailed,
        );
        return;
      }
      if (hasLogs) {
        await _logSync.replaceFrom(store);
      } else {
        // Its rows are logged as this phone's: the next sync shares them.
        await _engine.restoreFromJson(json!);
        await _logSync.push(store);
      }
      if (commit != null) await commit();
      final active = activeAs ?? provider;

      // The restored household has its own UUID. Point the app at it —
      // restoreFromJson only writes DB rows, it does not set the active
      // household, so without this the app opens with no household and the
      // restored data is invisible (every screen bails on null householdId).
      final db = ref.read(databaseProvider);
      final households = await db.select(db.households).get();
      if (households.isNotEmpty) {
        await ref
            .read(householdServiceProvider)
            .setCurrentHousehold(households.first.id);
      }

      // A budget taken from the cloud is most likely shared: ask this
      // device's name (HouseholdMembers.shouldAsk).
      await HouseholdMembers.markJoined();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefActiveProvider, _keyOf(active));
      await prefs.setString(_prefLastSync, DateTime.now().toIso8601String());

      state = state.copyWith(
        activeProvider: active,
        status: SyncStatus.success,
        lastSyncTime: DateTime.now(),
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        lastError: syncErrorText(e),
      );
    }
  }

  /// Write this phone's log without reading first (first connection to an
  /// empty folder).
  Future<void> initialUpload() => _exclusive(_initialUpload);

  Future<void> _initialUpload() async {
    final provider = state.activeProvider;
    if (provider == null) return;

    state = state.copyWith(status: SyncStatus.syncing);
    try {
      await _logSync.push(ProviderLogStore(provider));
      await _snapshotIfDue(provider, force: true);

      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLastSync, now.toIso8601String());

      state = state.copyWith(
        status: SyncStatus.success,
        lastSyncTime: now,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        lastError: syncErrorText(e),
      );
    }
  }
}

/// What the user reads when a sync fails: never the raw exception (it can
/// hold file paths, SQL or tokens). The details go to the debug log.
String syncErrorText(Object e) {
  debugPrint('[Sync] failed: $e');
  final s = currentS();
  return switch (e) {
    SyncPasswordException(missing: true) => s.syncErrNeedsPassword,
    SyncPasswordException() => s.syncErrWrongPassword,
    SyncFileTooNewException() => s.syncErrTooNew,
    FormatException() => s.syncErrCorrupt,
    CloudAuthException() || GoogleSignInException() => s.syncErrSignedOut,
    drive.DetailedApiRequestError(status: 401 || 403) => s.syncErrSignedOut,
    RelayException(error: RelayError.notFound) => s.relayErrNotFound,
    RelayException(error: RelayError.unauthorized) => s.relayErrKey,
    RelayException(error: RelayError.full) => s.relayErrFull,
    RelayException(error: RelayError.busy) => s.relayErrBusy,
    RelayException() => s.relayErrServer,
    SocketException() || HttpException() || TimeoutException() ||
    http.ClientException() =>
      s.syncErrNetwork,
    _ => s.syncErrGeneric,
  };
}

final syncProvider =
    NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);
