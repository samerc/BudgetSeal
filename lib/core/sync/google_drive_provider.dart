import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'cloud_provider.dart';

const _syncFileName = 'PocketPlan_Sync.json';
const _folderName = 'PocketPlan';

/// Escape single quotes for Google Drive query language to prevent injection.
String _escGdql(String s) => s.replaceAll("'", "\\'");

/// Web OAuth 2.0 client ID from Google Cloud Console.
/// Loaded from .env file via --dart-define-from-file at build time.
/// To set up: create .env in project root with:
///   GOOGLE_SERVER_CLIENT_ID=your-client-id.apps.googleusercontent.com
const _serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

/// Google Drive adapter using google_sign_in v7 + googleapis.
class GoogleDriveProvider implements CloudProvider {
  GoogleSignInAccount? _account;
  drive.DriveApi? _driveApi;
  String? _syncFileId;
  String? _folderId;
  String? lastConnectError;
  bool _initialized = false;

  @override
  String get displayName => 'Google Drive';

  @override
  String get iconName => 'google_drive';

  @override
  Future<bool> get isConnected async {
    try {
      // Only check silently — never prompt the user.
      return _account != null;
    } catch (e) {
      debugPrint('isConnected check failed: $e');
      return false;
    }
  }

  @override
  Future<bool> connect() async {
    try {
      lastConnectError = null;
      await _ensureInitialized();

      _account = await GoogleSignIn.instance.authenticate();

      final authClient = _account!.authorizationClient;
      final auth = await authClient.authorizeScopes(
        [drive.DriveApi.driveFileScope],
      );

      _driveApi = drive.DriveApi(
          _AuthClient(http.Client(), auth.accessToken));
      return true;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('sign_in') || msg.contains('not configured') ||
          msg.contains('apiexception')) {
        lastConnectError =
            'Google Sign-In is not configured for this app. '
            'A Google Cloud project with OAuth credentials is required.';
      } else if (msg.contains('network')) {
        lastConnectError = 'Network error. Check your internet connection.';
      } else {
        lastConnectError = 'Connection failed: ${e.toString()}';
      }
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out failed: $e');
    }
    _account = null;
    _driveApi = null;
    _syncFileId = null;
    _folderId = null;
  }

  @override
  Future<void> upload(String jsonContent) async {
    final api = await _getDriveApi();
    final folderId = await _getOrCreateFolder(api);
    final fileId = await _findSyncFile(api, folderId);

    final media = drive.Media(
      Stream.value(utf8.encode(jsonContent)),
      utf8.encode(jsonContent).length,
      contentType: 'application/json',
    );

    if (fileId != null) {
      await api.files.update(drive.File(), fileId, uploadMedia: media);
    } else {
      final driveFile = drive.File()
        ..name = _syncFileName
        ..parents = [folderId]
        ..mimeType = 'application/json';
      final created =
          await api.files.create(driveFile, uploadMedia: media);
      _syncFileId = created.id;
    }
  }

  @override
  Future<String?> download() async {
    final api = await _getDriveApi();
    final folderId = await _getOrCreateFolder(api);
    final fileId = await _findSyncFile(api, folderId);
    if (fileId == null) return null;

    final response = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final bytes = <int>[];
    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
    }
    return utf8.decode(bytes);
  }

  @override
  Future<bool> syncFileExists() async {
    final api = await _getDriveApi();
    final folderId = await _getOrCreateFolder(api);
    return await _findSyncFile(api, folderId) != null;
  }

  // ── Receipt sync ──────────────────────────────────────────────

  /// Upload receipt files to PocketPlan/receipts/ folder on Drive.
  Future<void> uploadReceipts(List<String> filePaths) async {
    final api = await _getDriveApi();
    final parentFolderId = await _getOrCreateFolder(api);
    final receiptsFolderId =
        await _getOrCreateSubfolder(api, parentFolderId, 'receipts');

    for (final filePath in filePaths) {
      final file = io.File(filePath);
      if (!file.existsSync()) continue;

      final fileName = filePath.split('/').last.split('\\').last;

      // Check if file already exists on Drive
      final query =
          "name = '${_escGdql(fileName)}' and '${_escGdql(receiptsFolderId)}' in parents and trashed = false";
      final existing = await api.files.list(q: query, spaces: 'drive');
      if (existing.files != null && existing.files!.isNotEmpty) continue;

      final bytes = await file.readAsBytes();
      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: 'image/jpeg',
      );

      final driveFile = drive.File()
        ..name = fileName
        ..parents = [receiptsFolderId];
      await api.files.create(driveFile, uploadMedia: media);
    }
  }

  /// Download any receipts that exist on Drive but not locally.
  Future<void> downloadMissingReceipts(
      List<String> filenames, String localReceiptsDir) async {
    final api = await _getDriveApi();
    final parentFolderId = await _getOrCreateFolder(api);
    final receiptsFolderId =
        await _getOrCreateSubfolder(api, parentFolderId, 'receipts');

    // List all receipt files on Drive
    final query =
        "'$receiptsFolderId' in parents and trashed = false";
    final driveFiles = await api.files.list(q: query, spaces: 'drive');

    if (driveFiles.files == null) return;

    for (final driveFile in driveFiles.files!) {
      final name = driveFile.name;
      if (name == null || driveFile.id == null) continue;
      if (!filenames.contains(name)) continue;

      final localPath = '$localReceiptsDir/$name';
      if (io.File(localPath).existsSync()) continue;

      // Download the file
      final response = await api.files.get(
        driveFile.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }

      final dir = io.Directory(localReceiptsDir);
      if (!dir.existsSync()) dir.createSync(recursive: true);
      await io.File(localPath).writeAsBytes(bytes);
    }
  }

  Future<String> _getOrCreateSubfolder(
      drive.DriveApi api, String parentId, String name) async {
    final query =
        "name = '${_escGdql(name)}' and '${_escGdql(parentId)}' in parents and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
    final list = await api.files.list(q: query, spaces: 'drive');
    if (list.files != null && list.files!.isNotEmpty) {
      return list.files!.first.id!;
    }
    final folder = drive.File()
      ..name = name
      ..parents = [parentId]
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await api.files.create(folder);
    return created.id!;
  }

  // ── Household sharing ──────────────────────────────────────────

  /// Share the PocketPlan folder with another user's email.
  /// Adds them as a writer so they can sync to the same file.
  Future<void> shareFolder(String email) async {
    final api = await _getDriveApi();
    final folderId = await _getOrCreateFolder(api);
    final permission = drive.Permission()
      ..type = 'user'
      ..role = 'writer'
      ..emailAddress = email;
    await api.permissions.create(permission, folderId,
        sendNotificationEmail: false);
  }

  /// Get the current folder ID for encoding into an invite code.
  Future<String> getFolderId() async {
    final api = await _getDriveApi();
    return _getOrCreateFolder(api);
  }

  /// Connect to a specific shared folder by ID (used when joining via invite code).
  Future<bool> connectToSharedFolder(String folderId) async {
    try {
      await _ensureInitialized();
      _account = await GoogleSignIn.instance.authenticate();
      if (_account == null) return false;

      final authClient = _account!.authorizationClient;
      final auth = await authClient.authorizeScopes(
        [drive.DriveApi.driveFileScope],
      );
      _driveApi = drive.DriveApi(
          _AuthClient(http.Client(), auth.accessToken));
      _folderId = folderId;

      // Verify we can access the folder
      await _driveApi!.files.get(folderId);
      return true;
    } catch (e) {
      debugPrint('connectToSharedFolder failed: $e');
      return false;
    }
  }

  /// Attempt to restore a previous Google Sign-In session silently (no prompt).
  /// Returns true if the session was restored and Drive API is ready.
  Future<bool> tryReconnectSilently() async {
    try {
      await _ensureInitialized();

      // In google_sign_in v7, attemptLightweightAuthentication restores
      // a cached session without showing any sign-in UI.
      _account =
          await GoogleSignIn.instance.attemptLightweightAuthentication();
      if (_account == null) return false;

      final authClient = _account!.authorizationClient;
      final auth = await authClient.authorizeScopes(
        [drive.DriveApi.driveFileScope],
      );
      _driveApi = drive.DriveApi(
          _AuthClient(http.Client(), auth.accessToken));
      return true;
    } catch (e) {
      debugPrint('tryReconnectSilently failed: $e');
      return false;
    }
  }

  // ── Internals ─────────────────────────────────────────────────

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: _serverClientId.isNotEmpty ? _serverClientId : null,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('GoogleSignIn.initialize failed (may already be initialized): $e');
      _initialized = true; // Already initialized
    }
  }

  Future<drive.DriveApi> _getDriveApi() async {
    if (_driveApi != null) return _driveApi!;
    // If no account cached, we're not connected — don't prompt.
    if (_account == null) throw StateError('Not connected to Google Drive');

    final authClient = _account!.authorizationClient;
    final auth = await authClient.authorizeScopes(
      [drive.DriveApi.driveFileScope],
    );
    _driveApi = drive.DriveApi(
        _AuthClient(http.Client(), auth.accessToken));
    return _driveApi!;
  }

  Future<String> _getOrCreateFolder(drive.DriveApi api) async {
    if (_folderId != null) return _folderId!;
    final query =
        "name = '${_escGdql(_folderName)}' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
    final list = await api.files.list(q: query, spaces: 'drive');
    if (list.files != null && list.files!.isNotEmpty) {
      _folderId = list.files!.first.id!;
      return _folderId!;
    }
    final folder = drive.File()
      ..name = _folderName
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await api.files.create(folder);
    _folderId = created.id!;
    return _folderId!;
  }

  Future<String?> _findSyncFile(
      drive.DriveApi api, String folderId) async {
    if (_syncFileId != null) return _syncFileId;
    final query =
        "name = '${_escGdql(_syncFileName)}' and '${_escGdql(folderId)}' in parents and trashed = false";
    final list = await api.files.list(q: query, spaces: 'drive');
    if (list.files != null && list.files!.isNotEmpty) {
      _syncFileId = list.files!.first.id;
      return _syncFileId;
    }
    return null;
  }
}

class _AuthClient extends http.BaseClient {
  final http.Client _inner;
  final String _accessToken;
  _AuthClient(this._inner, this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _inner.send(request);
  }
}
