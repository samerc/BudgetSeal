import 'dart:convert';

import 'package:shelf/shelf.dart';

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

Response serverError(Object e) => Response(
      500,
      body: jsonEncode({'error': 'Internal error: $e'}),
      headers: _jsonHeaders,
    );

/// Extract a required non-empty String field from a JSON body.
String? requireString(Map<String, dynamic> body, String key) {
  final v = body[key];
  if (v is String && v.isNotEmpty) return v;
  return null;
}

/// Extract a required numeric field (accepts int, double, or parseable String).
double? requireDouble(Map<String, dynamic> body, String key) {
  final v = body[key];
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

/// Extract an optional numeric field.
double? optDouble(Map<String, dynamic> body, String key) {
  final v = body[key];
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
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
