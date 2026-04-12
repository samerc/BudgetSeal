import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// ── Receipt path encoding helpers ──────────────────────────────────────────

/// Parse the receiptPath column value into a list of filenames.
/// Handles both legacy single-path strings and JSON-encoded arrays.
List<String> parseReceiptPaths(String? receiptPath) {
  if (receiptPath == null || receiptPath.isEmpty) return [];
  if (receiptPath.startsWith('[')) {
    return (jsonDecode(receiptPath) as List).cast<String>();
  }
  return [receiptPath]; // legacy single path
}

/// Encode a list of receipt filenames into a JSON string for storage.
String encodeReceiptPaths(List<String> paths) {
  return jsonEncode(paths);
}

/// Resolve a receipt filename to its full path on disk.
Future<String> receiptFullPath(String filename) async {
  final appDir = await getApplicationDocumentsDirectory();
  return p.join(appDir.path, 'receipts', filename);
}

/// Resolve a list of receipt filenames to full paths, filtering out missing files.
Future<List<String>> resolveReceiptPaths(List<String> filenames) async {
  final appDir = await getApplicationDocumentsDirectory();
  final receiptsDir = p.join(appDir.path, 'receipts');
  final result = <String>[];
  for (final name in filenames) {
    final fullPath = p.join(receiptsDir, name);
    if (File(fullPath).existsSync()) {
      result.add(fullPath);
    }
  }
  return result;
}

/// Get the receipts directory, creating it if needed.
Future<Directory> getReceiptsDirectory() async {
  final appDir = await getApplicationDocumentsDirectory();
  final receiptsDir = Directory(p.join(appDir.path, 'receipts'));
  if (!receiptsDir.existsSync()) {
    receiptsDir.createSync(recursive: true);
  }
  return receiptsDir;
}

// ── Picking helpers ────────────────────────────────────────────────────────

/// Pick a single receipt photo from camera or gallery and save to app storage.
/// Returns the saved FILENAME only (not full path), or null if cancelled.
Future<String?> pickAndSaveReceipt(BuildContext context) async {
  final result = await _showPickerSheet(context);
  if (result == null) return null;

  if (result == _PickerChoice.camera) {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 55,
    );
    if (picked == null) return null;
    return _savePickedFile(picked);
  } else {
    // Gallery single
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 55,
    );
    if (picked == null) return null;
    return _savePickedFile(picked);
  }
}

/// Pick multiple receipt photos (multi-select from gallery, or one from camera).
/// Returns a list of saved FILENAMES (not full paths). Empty if cancelled.
Future<List<String>> pickAndSaveReceipts(BuildContext context) async {
  final result = await _showPickerSheet(context);
  if (result == null) return [];

  if (result == _PickerChoice.camera) {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 55,
    );
    if (picked == null) return [];
    final filename = await _savePickedFile(picked);
    return filename != null ? [filename] : [];
  } else {
    // Gallery multi-select
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 55,
    );
    final filenames = <String>[];
    for (final picked in pickedFiles) {
      final filename = await _savePickedFile(picked);
      if (filename != null) filenames.add(filename);
    }
    return filenames;
  }
}

// ── Internals ──────────────────────────────────────────────────────────────

enum _PickerChoice { camera, gallery }

Future<_PickerChoice?> _showPickerSheet(BuildContext context) async {
  return showModalBottomSheet<_PickerChoice>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded),
            title: const Text('Take Photo'),
            onTap: () => Navigator.pop(ctx, _PickerChoice.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Choose from Gallery'),
            subtitle: const Text('Select multiple photos'),
            onTap: () => Navigator.pop(ctx, _PickerChoice.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.close_rounded),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(ctx),
          ),
        ],
      ),
    ),
  );
}

/// Save a picked XFile to the receipts directory. Returns the FILENAME only.
Future<String?> _savePickedFile(XFile picked) async {
  // Validate file extension.
  final allowedExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.heic'};
  final pickedExt = p.extension(picked.path).toLowerCase();
  if (!allowedExtensions.contains(pickedExt)) return null;

  final receiptsDir = await getReceiptsDirectory();

  final ext = p.extension(picked.path);
  final fileName =
      'receipt_${DateTime.now().millisecondsSinceEpoch}$ext';
  final savedPath = p.join(receiptsDir.path, fileName);
  await File(picked.path).copy(savedPath);

  return fileName; // Return filename only, not the full path
}
