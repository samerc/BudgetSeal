import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'cloud_provider.dart';
import '../../l10n/s_lookup.dart';

const _syncFileName = 'BudgetSeal_Sync.json';
const _folderName = 'BudgetSeal';

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
  bool _sharedFolder = false;
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
          _AuthClient(http.Client(), auth.accessToken, _refreshToken));
      return true;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('sign_in') || msg.contains('not configured') ||
          msg.contains('apiexception')) {
        lastConnectError = currentS().syncErrGoogleNotConfigured;
      } else if (msg.contains('network')) {
        lastConnectError = currentS().syncErrNetwork;
      } else {
        debugPrint('Google Drive connect failed: $e');
        lastConnectError = currentS().syncErrConnectFailed;
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
    _sharedFolder = false;
  }

  @override
  Future<void> upload(String jsonContent) async {
    final bytes = utf8.encode(jsonContent);
    await _retryIfGone((api) async {
      final folderId = await _getOrCreateFolder(api);
      final fileId = await _findSyncFile(api, folderId);
      final media = drive.Media(Stream.value(bytes), bytes.length,
          contentType: 'application/json');

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
    });
  }

  @override
  Future<String?> download() => _retryIfGone((api) async {
        final folderId = await _getOrCreateFolder(api);
        final fileId = await _findSyncFile(api, folderId);
        if (fileId == null) return null;
        return utf8.decode(await _fetch(api, fileId));
      });

  @override
  Future<bool> syncFileExists() => _retryIfGone((api) async {
        final folderId = await _getOrCreateFolder(api);
        return await _findSyncFile(api, folderId) != null;
      });

  // ── Receipt sync ──────────────────────────────────────────────

  /// Upload receipt files to BudgetSeal/receipts/ folder on Drive.
  Future<void> uploadReceipts(List<String> filePaths) async {
    final api = await _getDriveApi();
    final parentFolderId = await _getOrCreateFolder(api);
    final receiptsFolderId =
        await _getOrCreateSubfolder(api, parentFolderId, 'receipts');
    // One listing instead of a query per receipt.
    final onDrive = (await _receiptFiles(api, receiptsFolderId)).keys.toSet();

    for (final filePath in filePaths) {
      final file = io.File(filePath);
      if (!file.existsSync()) continue;

      final fileName = filePath.split('/').last.split('\\').last;
      if (onDrive.contains(fileName)) continue;

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

    final onDrive = await _receiptFiles(api, receiptsFolderId);
    final wanted = filenames.toSet();

    for (final MapEntry(key: name, value: id) in onDrive.entries) {
      if (!wanted.contains(name)) continue;

      // Sanitize filename to prevent path traversal
      final safeName = name.replaceAll(RegExp(r'[/\\]'), '_').replaceAll('..', '_');
      final localPath = '$localReceiptsDir/$safeName';
      if (io.File(localPath).existsSync()) continue;

      final bytes = await _fetch(api, id);

      final dir = io.Directory(localReceiptsDir);
      if (!dir.existsSync()) dir.createSync(recursive: true);
      await io.File(localPath).writeAsBytes(bytes);
    }
  }

  /// Every receipt in the folder, name → id, following pages (a list
  /// call returns at most 100 by default).
  Future<Map<String, String>> _receiptFiles(
      drive.DriveApi api, String folderId) async {
    final files = <String, String>{};
    String? page;
    do {
      final list = await api.files.list(
        q: "'${_escGdql(folderId)}' in parents and trashed = false",
        spaces: 'drive',
        pageSize: 1000,
        pageToken: page,
        $fields: 'nextPageToken, files(id, name)',
      );
      for (final f in list.files ?? const <drive.File>[]) {
        if (f.name != null && f.id != null) files[f.name!] = f.id!;
      }
      page = list.nextPageToken;
    } while (page != null);
    return files;
  }

  Future<Uint8List> _fetch(drive.DriveApi api, String fileId) async {
    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in media.stream) {
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  /// Runs [job]; when Drive says a remembered file or folder is gone (404 —
  /// deleted in the Drive app, or this session's ids are stale) it forgets
  /// them and tries once more, which finds or recreates them.
  Future<T> _retryIfGone<T>(Future<T> Function(drive.DriveApi api) job) async {
    final api = await _getDriveApi();
    try {
      return await job(api);
    } on drive.DetailedApiRequestError catch (e) {
      if (e.status != 404) rethrow;
      _syncFileId = null;
      // A joined (shared) folder that's gone stays an error.
      if (!_sharedFolder) _folderId = null;
      return job(api);
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

  /// Share the BudgetSeal folder with another user's email.
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
          _AuthClient(http.Client(), auth.accessToken, _refreshToken));
      _folderId = folderId;
      _sharedFolder = true;

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
          _AuthClient(http.Client(), auth.accessToken, _refreshToken));
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

  /// A new access token without UI (Google tokens last ~1 hour).
  Future<String> _refreshToken() async {
    final account = _account;
    if (account == null) throw const CloudAuthException();
    final auth = await account.authorizationClient
            .authorizationForScopes([drive.DriveApi.driveFileScope]) ??
        await account.authorizationClient
            .authorizeScopes([drive.DriveApi.driveFileScope]);
    return auth.accessToken;
  }

  Future<drive.DriveApi> _getDriveApi() async {
    if (_driveApi != null) return _driveApi!;
    // If no account cached, we're not connected — don't prompt.
    if (_account == null) throw const CloudAuthException();

    final authClient = _account!.authorizationClient;
    final auth = await authClient.authorizeScopes(
      [drive.DriveApi.driveFileScope],
    );
    _driveApi = drive.DriveApi(
        _AuthClient(http.Client(), auth.accessToken, _refreshToken));
    return _driveApi!;
  }

  Future<String> _getOrCreateFolder(drive.DriveApi api) async {
    if (_folderId != null) return _folderId!;
    final query =
        "name = '${_escGdql(_folderName)}' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
    // Oldest first: two folders (made by two devices at once) always
    // resolve to the same one.
    final list =
        await api.files.list(q: query, spaces: 'drive', orderBy: 'createdTime');
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
    // Several sync files (two first uploads at once): the newest one.
    final list = await api.files
        .list(q: query, spaces: 'drive', orderBy: 'modifiedTime desc');
    if (list.files != null && list.files!.isNotEmpty) {
      _syncFileId = list.files!.first.id;
      return _syncFileId;
    }
    return null;
  }
}

/// Adds the bearer token to every request and swaps in a fresh token before
/// the old one expires — a cached DriveApi otherwise fails with 401 after an
/// hour and every later sync keeps failing.
class _AuthClient extends http.BaseClient {
  final http.Client _inner;
  final Future<String> Function() _refresh;
  String _accessToken;
  DateTime _issuedAt = DateTime.now();
  Future<String>? _pending;

  static const _maxAge = Duration(minutes: 45);

  _AuthClient(this._inner, this._accessToken, this._refresh);

  Future<String> _token() async {
    if (DateTime.now().difference(_issuedAt) < _maxAge) return _accessToken;
    // One refresh at a time, shared by concurrent requests.
    final pending = _pending ??= _refresh();
    try {
      _accessToken = await pending;
      _issuedAt = DateTime.now();
    } catch (e) {
      debugPrint('Drive token refresh failed: $e');
    } finally {
      _pending = null;
    }
    return _accessToken;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['Authorization'] = 'Bearer ${await _token()}';
    return _inner.send(request);
  }
}
