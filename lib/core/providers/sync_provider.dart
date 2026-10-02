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
import '../sync/cloud_provider.dart';
import '../sync/file_picker_provider.dart';
import '../sync/google_drive_provider.dart';
import '../sync/sync_encryption.dart';
import '../sync/sync_engine.dart';
import 'database_provider.dart';
import 'household_provider.dart';
import 'receipt_sync_provider.dart';
import '../../l10n/s_lookup.dart';

const _prefActiveProvider = 'sync_active_provider';
const _prefLastSync = 'sync_last_sync';

enum SyncStatus { idle, syncing, success, error }

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

  /// All provider options shown in the UI. OneDrive, Dropbox, and Local File
  /// all use the same [FilePickerProvider] under the hood — the system file
  /// picker navigates to those apps when they are installed.
  List<({String label, String subtitle, String iconKey, CloudProvider provider})>
      get providerOptions => [
            (
              label: 'Google Drive',
              subtitle: currentS().syncGoogleSub,
              iconKey: 'google_drive',
              provider: googleDrive,
            ),
            (
              label: 'OneDrive',
              subtitle: currentS().syncOneDriveSub,
              iconKey: 'onedrive',
              provider: filePicker,
            ),
            (
              label: 'Dropbox',
              subtitle: currentS().syncDropboxSub,
              iconKey: 'dropbox',
              provider: filePicker,
            ),
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
    }

    state = state.copyWith(
      activeProvider: provider,
      lastSyncTime: lastSync,
    );
  }

  /// Connect to a cloud provider and set it as active.
  Future<bool> connectProvider(CloudProvider provider) async {
    final ok = await provider.connect();
    if (!ok) return false;

    final key = provider is GoogleDriveProvider ? 'google_drive' : 'file';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefActiveProvider, key);

    state = state.copyWith(activeProvider: provider);
    return true;
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

  /// Full sync: download remote → merge → upload local → sync receipts.
  /// A call while one is running waits for that one instead.
  Future<void> sync() => _exclusive(_sync);

  Future<void> _sync() async {
    final provider = state.activeProvider;
    if (provider == null) return;
    // The open DB is about to be replaced by a restored backup.
    if (AutoBackupService.restorePending) return;

    state = state.copyWith(status: SyncStatus.syncing);

    try {
      int totalChanges = 0;

      // 1. Download and merge remote changes
      final remoteJson = await provider.download();
      if (remoteJson != null) {
        totalChanges += await _engine.mergeFromJson(remoteJson);
      }

      // 2. Export local state and upload
      final localJson = await _engine.exportToJson();
      await provider.upload(localJson);

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

  /// Full restore from the sync file (replaces all local data).
  Future<void> restoreFromProvider(CloudProvider provider) =>
      _exclusive(() => _restore(provider));

  Future<void> _restore(CloudProvider provider) async {
    state = state.copyWith(status: SyncStatus.syncing);
    try {
      final json = await provider.download();
      if (json == null) {
        state = state.copyWith(
          status: SyncStatus.error,
          lastError: currentS().syncNoSyncFile,
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
      await _engine.restoreFromJson(json);

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

      final key = provider is GoogleDriveProvider ? 'google_drive' : 'file';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefActiveProvider, key);
      await prefs.setString(_prefLastSync, DateTime.now().toIso8601String());

      state = state.copyWith(
        activeProvider: provider,
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

  /// Export and upload without downloading first (initial sync).
  Future<void> initialUpload() => _exclusive(_initialUpload);

  Future<void> _initialUpload() async {
    final provider = state.activeProvider;
    if (provider == null) return;

    state = state.copyWith(status: SyncStatus.syncing);
    try {
      final json = await _engine.exportToJson();
      await provider.upload(json);

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
    FormatException() => s.syncErrCorrupt,
    CloudAuthException() || GoogleSignInException() => s.syncErrSignedOut,
    drive.DetailedApiRequestError(status: 401 || 403) => s.syncErrSignedOut,
    SocketException() || HttpException() || TimeoutException() ||
    http.ClientException() =>
      s.syncErrNetwork,
    _ => s.syncErrGeneric,
  };
}

final syncProvider =
    NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);
