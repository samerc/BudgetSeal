import 'dart:convert';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';

import '../../../core/database/app_database.dart';

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

/// Parse request body as a JSON map. Returns null if body is empty or invalid.
Future<Map<String, dynamic>?> parseBody(Request request) async {
  final body = await request.readAsString();
  if (body.isEmpty) return null;
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return null;
  } catch (_) {
    return null;
  }
}

Response ok(Object? data) =>
    Response.ok(jsonEncode(data), headers: _jsonHeaders);

Response created(Object? data) =>
    Response(201, body: jsonEncode(data), headers: _jsonHeaders);

Response badRequest(String message) =>
    Response(400, body: jsonEncode({'error': message}), headers: _jsonHeaders);

Response notFound([String message = 'Not found']) =>
    Response(404, body: jsonEncode({'error': message}), headers: _jsonHeaders);

Response forbidden([String message = 'No active household']) =>
    Response(403, body: jsonEncode({'error': message}), headers: _jsonHeaders);

Response serverError(Object e) {
  debugPrint('[WebCompanion] Server error: $e');
  return Response(
    500,
    body: jsonEncode({'error': 'Internal server error'}),
    headers: _jsonHeaders,
  );
}

/// Extract a required non-empty String field from a JSON body.
String? requireString(Map<String, dynamic> body, String key) {
  final v = body[key];
  if (v is String && v.isNotEmpty) return v;
  return null;
}

/// Extract a required numeric field (accepts int, double, or parseable String).
/// Returns null for non-finite values (NaN, Infinity).
double? requireDouble(Map<String, dynamic> body, String key) {
  final v = body[key];
  double? result;
  if (v is num) result = v.toDouble();
  if (v is String) result = double.tryParse(v);
  return (result != null && result.isFinite) ? result : null;
}

/// Extract an optional numeric field.
/// Returns null for non-finite values (NaN, Infinity).
double? optDouble(Map<String, dynamic> body, String key) {
  final v = body[key];
  double? result;
  if (v is num) result = v.toDouble();
  if (v is String) result = double.tryParse(v);
  return (result != null && result.isFinite) ? result : null;
}

/// Extract an optional non-empty String field.
String? optString(Map<String, dynamic> body, String key) {
  final v = body[key];
  if (v is String && v.isNotEmpty) return v;
  return null;
}

/// Extract an optional bool field.
bool? optBool(Map<String, dynamic> body, String key) {
  final v = body[key];
  if (v is bool) return v;
  return null;
}

/// Extract an optional int field.
int? requireInt(Map<String, dynamic> body, String key) {
  final v = body[key];
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

/// Safely truncate a string to max characters.
String truncate(String s, int max) =>
    s.length <= max ? s : s.substring(0, max);

/// Max characters for name/title fields (mirrors InputLimits.nameMaxLength).
const kMaxNameLength = 100;

/// Max characters for note fields (mirrors InputLimits.noteMaxLength).
const kMaxNoteLength = 500;

/// Max amount for any financial value.
const kMaxAmount = 1e9;

/// Extract a required non-empty String with length limit.
String? requireStringLimited(Map<String, dynamic> body, String key,
    [int maxLen = kMaxNameLength]) {
  final v = body[key];
  if (v is String && v.isNotEmpty) return truncate(v.trim(), maxLen);
  return null;
}

/// Extract a required positive amount within bounds.
/// Returns null if missing, negative, zero, or exceeds kMaxAmount.
double? requireAmount(Map<String, dynamic> body, String key) {
  final v = requireDouble(body, key);
  if (v == null || v <= 0 || v > kMaxAmount) return null;
  return v;
}

/// Allowed table names for FK validation (whitelist prevents SQL injection).
const _allowedTables = {
  'accounts', 'categories', 'allocations', 'transactions',
  'recurring_transactions', 'objectives', 'households',
};

/// Validate that an ID exists in a database table.
/// Returns the ID if found, null if not.
/// Table name must be in the whitelist — rejects unknown tables.
Future<String?> validateIdExists(
    AppDatabase db, String table, String id) async {
  if (!_allowedTables.contains(table)) {
    throw ArgumentError('Invalid table name: $table');
  }
  final rows = await db.customSelect(
    'SELECT 1 FROM $table WHERE id = ? LIMIT 1',
    variables: [Variable.withString(id)],
  ).get();
  return rows.isNotEmpty ? id : null;
}
