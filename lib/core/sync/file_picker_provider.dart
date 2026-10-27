import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/s_lookup.dart';
import 'cloud_provider.dart';

const _syncFileName = 'BudgetSeal_Sync.json';
const _prefKeyFolder = 'file_sync_folder';

/// Before log sync this provider used one picked file (`file_sync_path`);
/// a phone that still has it is asked once to pick a folder instead.
const legacyFileSyncPathKey = 'file_sync_path';

/// Folder-based sync adapter: the user picks a folder with the system
/// picker (on the phone, or one a Dropbox/OneDrive app keeps in sync), and
/// each phone writes its own log files there, next to the daily
/// `BudgetSeal_Sync.json` snapshot.
class FilePickerProvider implements CloudProvider {
  String? _folder;

  @override
  String get displayName => 'Cloud File';

  @override
  String get iconName => 'cloud_file';

  @override
  Future<bool> get isConnected async {
    final prefs = await SharedPreferences.getInstance();
    _folder = prefs.getString(_prefKeyFolder);
    return _folder != null && await Directory(_folder!).exists();
  }

  @override
  Future<bool> connect() async {
    final folder = await FilePicker.getDirectoryPath(
        dialogTitle: currentS().filePickerTitle);
    if (folder == null) return false;
    _folder = folder;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyFolder, folder);
    await prefs.remove(legacyFileSyncPathKey);
    return true;
  }

  @override
  Future<void> disconnect() async {
    _folder = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyFolder);
  }

  File _file(String name) {
    if (_folder == null) throw StateError('No sync folder set');
    return File(p.join(_folder!, name));
  }

  @override
  Future<void> upload(String jsonContent) =>
      _file(_syncFileName).writeAsString(jsonContent, flush: true);

  @override
  Future<String?> download() async {
    if (_folder == null) return null;
    final file = _file(_syncFileName);
    return await file.exists() ? file.readAsString() : null;
  }

  @override
  Future<bool> syncFileExists() async =>
      _folder != null && await _file(_syncFileName).exists();

  @override
  Future<Map<String, String>> listLogFiles() async {
    if (_folder == null) throw StateError('No sync folder set');
    final out = <String, String>{};
    await for (final e in Directory(_folder!).list()) {
      final name = p.basename(e.path);
      if (e is! File || !name.startsWith('log-')) continue;
      final stat = await e.stat();
      out[name] = '${stat.size}:${stat.modified.millisecondsSinceEpoch}';
    }
    return out;
  }

  @override
  Future<String?> readLogFile(String name) async {
    final file = _file(name);
    return await file.exists() ? file.readAsString() : null;
  }

  @override
  Future<void> writeLogFile(String name, String content) async {
    // Write beside it, then rename: another phone's sync app never sees a
    // half-written file.
    final tmp = _file('.$name.tmp');
    await tmp.writeAsString(content, flush: true);
    await tmp.rename(_file(name).path);
  }
}
