import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/utils/receipt_helper.dart';
import '../sync/cloud_provider.dart';
import '../sync/file_picker_provider.dart';
import '../sync/google_drive_provider.dart';
import '../sync/sync_engine.dart';
import 'database_provider.dart';
import 'household_provider.dart';
import 'receipt_sync_provider.dart';

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
  }) =>
      SyncState(
        activeProvider: clearProvider ? null : (activeProvider ?? this.activeProvider),
        status: status ?? this.status,
        lastSyncTime: lastSyncTime ?? this.lastSyncTime,
        lastError: lastError ?? this.lastError,
        lastChanges: lastChanges ?? this.lastChanges,
      );
}

class SyncNotifier extends Notifier<SyncState> {
  late final SyncEngine _engine;

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
              subtitle: 'Sign in with your Google account',
              iconKey: 'google_drive',
              provider: googleDrive,
            ),
            (
              label: 'OneDrive',
              subtitle: 'Requires the OneDrive app installed',
              iconKey: 'onedrive',
              provider: filePicker,
            ),
            (
              label: 'Dropbox',
              subtitle: 'Requires the Dropbox app installed',
              iconKey: 'dropbox',
              provider: filePicker,
            ),
            (
              label: 'Local File',
              subtitle: 'Pick any file on your device',
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
  Future<void> sync() async {
    final provider = state.activeProvider;
    if (provider == null) return;

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
        lastError: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        lastError: e.toString(),
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
  Future<void> restoreFromProvider(CloudProvider provider) async {
    state = state.copyWith(status: SyncStatus.syncing);
    try {
      final json = await provider.download();
      if (json == null) {
        state = state.copyWith(
          status: SyncStatus.error,
          lastError: 'No sync file found',
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
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        lastError: e.toString(),
      );
    }
  }

  /// Export and upload without downloading first (initial sync).
  Future<void> initialUpload() async {
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
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        lastError: e.toString(),
      );
    }
  }
}

final syncProvider =
    NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);
