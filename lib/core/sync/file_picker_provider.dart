import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_provider.dart';

const _syncFileName = 'BudgetSeal_Sync.json';
const _prefKeyPath = 'file_sync_path';

/// File-based sync adapter. User picks a file from the system file picker,
/// which on Android can access Google Drive, Dropbox, OneDrive, or local storage.
/// This is the universal fallback for any cloud storage provider.
class FilePickerProvider implements CloudProvider {
  String? _filePath;

  @override
  String get displayName => 'Cloud File';

  @override
  String get iconName => 'cloud_file';

  @override
  Future<bool> get isConnected async {
    final prefs = await SharedPreferences.getInstance();
    _filePath = prefs.getString(_prefKeyPath);
    return _filePath != null && await File(_filePath!).exists();
  }

  @override
  Future<bool> connect() async {
    // Let user pick or create a file
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      dialogTitle: 'Select BudgetSeal Sync File',
    );

    if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
      _filePath = result.files.single.path!;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyPath, _filePath!);
      return true;
    }

    // If no file selected, create a new one in documents
    return false;
  }

  /// Connect by creating a new sync file in app documents.
  /// Returns the path of the created file.
  Future<String> createNew() async {
    final dir = await getApplicationDocumentsDirectory();
    _filePath = p.join(dir.path, _syncFileName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyPath, _filePath!);
    return _filePath!;
  }

  @override
  Future<void> disconnect() async {
    _filePath = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyPath);
  }

  @override
  Future<void> upload(String jsonContent) async {
    if (_filePath == null) throw StateError('No sync file path set');
    await File(_filePath!).writeAsString(jsonContent);
  }

  @override
  Future<String?> download() async {
    if (_filePath == null) return null;
    final file = File(_filePath!);
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  @override
  Future<bool> syncFileExists() async {
    if (_filePath == null) return false;
    return File(_filePath!).exists();
  }
}
