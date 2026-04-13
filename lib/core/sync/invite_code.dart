import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Encode a Drive folder ID into a short invite code.
/// Format: `PP-` followed by the base64url encoded folder ID.
String generateInviteCode(String folderId) {
  final encoded = base64Url.encode(utf8.encode(folderId));
  return 'PP-$encoded';
}

/// Decode an invite code back to a Drive folder ID.
/// Returns null if the code is invalid.
String? decodeInviteCode(String code) {
  if (!code.startsWith('PP-')) return null;
  try {
    final encoded = code.substring(3);
    return utf8.decode(base64Url.decode(encoded));
  } catch (e) {
    debugPrint('Failed to decode invite code: $e');
    return null;
  }
}
