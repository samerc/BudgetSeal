import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Pick a receipt photo from camera or gallery and save to app storage.
/// Returns the saved file path, or null if cancelled.
Future<String?> pickAndSaveReceipt(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded),
            title: const Text('Take Photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );

  if (source == null) return null;

  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: source,
    maxWidth: 1200,
    maxHeight: 1200,
    imageQuality: 80,
  );

  if (picked == null) return null;

  // Validate file extension.
  final allowedExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.heic'};
  final pickedExt = p.extension(picked.path).toLowerCase();
  if (!allowedExtensions.contains(pickedExt)) return null;

  // Copy to app documents directory for persistence.
  final appDir = await getApplicationDocumentsDirectory();
  final receiptsDir = Directory(p.join(appDir.path, 'receipts'));
  if (!receiptsDir.existsSync()) {
    receiptsDir.createSync(recursive: true);
  }

  final ext = p.extension(picked.path);
  final fileName =
      'receipt_${DateTime.now().millisecondsSinceEpoch}$ext';
  final savedPath = p.join(receiptsDir.path, fileName);
  await File(picked.path).copy(savedPath);

  return savedPath;
}
