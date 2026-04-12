import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'cloud_provider.dart';

const _syncFileName = 'PocketPlan_Sync.json';
const _folderName = 'PocketPlan';

/// Your Web OAuth 2.0 client ID from Google Cloud Console.
/// To set this up:
/// 1. Go to console.cloud.google.com → APIs & Services → Credentials
/// 2. Enable the Google Drive API
/// 3. Create an OAuth 2.0 "Web application" client ID
/// 4. Create an OAuth 2.0 "Android" client ID with your SHA-1 + package name
/// 5. Paste the Web client ID below
const _serverClientId = '87876782358-4a7gnh8dfgtl2q3vfk9l20c1r5ragakc.apps.googleusercontent.com';

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
    } catch (_) {
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
    } catch (_) {}
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

  // ── Internals ─────────────────────────────────────────────────

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: _serverClientId.isNotEmpty ? _serverClientId : null,
      );
      _initialized = true;
    } catch (_) {
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
        "name = '$_folderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
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
        "name = '$_syncFileName' and '$folderId' in parents and trashed = false";
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
