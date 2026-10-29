import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../l10n/s_lookup.dart';
import 'cloud_provider.dart';
import 'household_key.dart';

const _storage = FlutterSecureStorage();
const _codeKey = 'household_relay_code';
const _timeout = Duration(seconds: 60);

/// Why the household relay said no.
enum RelayError {
  /// No household with this code (deleted, or a mistyped code).
  notFound,

  /// The code no longer opens the household.
  unauthorized,

  /// The household reached the relay's size limit.
  full,

  /// Too many requests for now.
  busy,

  /// Anything else from the relay.
  server,
}

class RelayException implements Exception {
  const RelayException(this.error, [this.status]);
  final RelayError error;
  final int? status;
  @override
  String toString() => 'RelayException($error, $status)';
}

/// Household sync through BudgetSeal's relay (`relay/`): the household's
/// phones share the operation log there, every file sealed with the
/// household key ([HouseholdKey]) — the relay only ever holds ciphertext.
/// The key lives in secure storage as its invite code.
class RelayProvider implements CloudProvider {
  RelayProvider({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  HouseholdKey? _key;

  @override
  bool connectCanceled = false;

  @override
  String get displayName => currentS().relayName;

  @override
  String get iconName => 'household';

  /// This phone's household key, from secure storage once.
  Future<HouseholdKey?> get key async {
    if (_key != null) return _key;
    final code = await _storage.read(key: _codeKey);
    return _key = code == null ? null : HouseholdKey.fromCode(code);
  }

  @override
  Future<bool> get isConnected async => await key != null;

  /// Starts a new household with a fresh key.
  @override
  Future<bool> connect() async {
    connectCanceled = false;
    final k = HouseholdKey.generate();
    final r = await _send(k, 'PUT', '');
    if (r.statusCode != 201) throw _error(r);
    await _save(k);
    return true;
  }

  /// Joins the household [k] opens: it must exist and accept the key.
  Future<void> join(HouseholdKey k) async {
    final r = await _send(k, 'GET', '/files');
    if (r.statusCode != 200) throw _error(r);
    await _save(k);
  }

  Future<void> _save(HouseholdKey k) async {
    await _storage.write(key: _codeKey, value: k.code);
    _key = k;
  }

  /// Leaves the household on this phone (the relay keeps it for the others).
  @override
  Future<void> disconnect() async {
    _key = null;
    await _storage.delete(key: _codeKey);
  }

  // The daily readable copy (BudgetSeal_Sync.json) is for files people can
  // open; on the relay nobody can, so it isn't kept there.
  @override
  Future<void> upload(String jsonContent) async {}

  @override
  Future<String?> download() async => null;

  @override
  Future<bool> syncFileExists() async => false;

  @override
  Future<Map<String, String>> listLogFiles() async {
    final k = await _require();
    final r = await _send(k, 'GET', '/files');
    if (r.statusCode != 200) throw _error(r);
    final files = (jsonDecode(r.body) as Map)['files'] as List;
    return {
      for (final f in files.cast<Map>())
        f['name'] as String: '${f['version']}',
    };
  }

  @override
  Future<String?> readLogFile(String name) async {
    final k = await _require();
    final r = await _send(k, 'GET', '/files/$name');
    if (r.statusCode == 404) return null;
    if (r.statusCode != 200) throw _error(r);
    return k.open(r.bodyBytes);
  }

  @override
  Future<void> writeLogFile(String name, String content) async {
    final k = await _require();
    final r = await _send(k, 'PUT', '/files/$name', body: await k.seal(content));
    if (r.statusCode != 200) throw _error(r);
  }

  Future<HouseholdKey> _require() async {
    final k = await key;
    if (k == null) throw const CloudAuthException();
    return k;
  }

  Future<http.Response> _send(HouseholdKey k, String method, String path,
      {List<int>? body}) async {
    final request = http.Request(
        method, Uri.parse('${k.relayUrl}/v1/h/${k.householdId}$path'))
      ..headers['authorization'] = 'Bearer ${k.auth}';
    if (body != null) request.bodyBytes = body;
    final streamed = await _client.send(request).timeout(_timeout);
    return http.Response.fromStream(streamed).timeout(_timeout);
  }

  RelayException _error(http.Response r) => RelayException(
        switch (r.statusCode) {
          404 => RelayError.notFound,
          401 || 409 => RelayError.unauthorized,
          413 => RelayError.full,
          429 => RelayError.busy,
          _ => RelayError.server,
        },
        r.statusCode,
      );
}
