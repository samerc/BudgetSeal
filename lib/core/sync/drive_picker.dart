import 'package:flutter/services.dart';

/// Google's Drive picker (Android, `DrivePicker.kt`). With the drive.file
/// scope the app may only open files it made for this account — or ones the
/// user picks here, such as a household folder another account shared.
class DrivePicker {
  static const _channel = MethodChannel('budgetseal/drive_picker');

  /// Shows the picker for [email] with [fileIds] already selected. Returns
  /// the picked ids, or null when the user backed out.
  static Future<List<String>?> pick({
    String? email,
    List<String> fileIds = const [],
    bool folders = true,
  }) async {
    final r = await _channel.invokeMethod<Map>('pick', {
      'email': email,
      'fileIds': fileIds,
      'folders': folders,
      'picker': true,
    });
    if (r == null) return null;
    return (r['picked'] as List?)?.cast<String>() ?? const [];
  }
}
