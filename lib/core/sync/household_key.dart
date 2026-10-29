import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

/// The household relay's default address (`relay/`); a code can name another.
const defaultRelayUrl = String.fromEnvironment('RELAY_URL',
    defaultValue: 'https://budgetseal-relay.budgetseal-relay.workers.dev');

const _codePrefix = 'BS1-';
const _magic = [0x42, 0x53, 0x52, 0x31]; // "BSR1"

/// One household's secret: 32 random bytes, handed from phone to phone as
/// the invite code / QR (`BS1-<base64url>`, `.<base64url relay url>` when
/// not the default relay). Everything else is derived from it, so the relay
/// gets an id and a password but never the key that reads the files.
class HouseholdKey {
  HouseholdKey(this.secret, {this.relayUrl = defaultRelayUrl})
      : assert(secret.length == 32);

  factory HouseholdKey.generate({String relayUrl = defaultRelayUrl}) {
    final r = Random.secure();
    return HouseholdKey(
        Uint8List.fromList(List.generate(32, (_) => r.nextInt(256))),
        relayUrl: relayUrl);
  }

  final Uint8List secret;
  final String relayUrl;

  /// The code from an invite, or null when it isn't one (a `PP-` code is a
  /// Google Drive invite from before the relay: [isOldInvite]).
  static HouseholdKey? fromCode(String code) {
    final c = code.trim();
    if (!c.startsWith(_codePrefix)) return null;
    final parts = c.substring(_codePrefix.length).split('.');
    try {
      final secret = base64Url.decode(base64Url.normalize(parts[0]));
      if (secret.length != 32) return null;
      final url = parts.length > 1
          ? utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
          : defaultRelayUrl;
      if (!url.startsWith('https://')) return null;
      return HouseholdKey(Uint8List.fromList(secret), relayUrl: url);
    } catch (_) {
      return null;
    }
  }

  static bool isOldInvite(String code) => code.trim().startsWith('PP-');

  String get code {
    final s = base64Url.encode(secret).replaceAll('=', '');
    if (relayUrl == defaultRelayUrl) return '$_codePrefix$s';
    final u = base64Url.encode(utf8.encode(relayUrl)).replaceAll('=', '');
    return '$_codePrefix$s.$u';
  }

  List<int> _derive(String label) =>
      Hmac(sha256, secret).convert(utf8.encode('budgetseal/relay/$label')).bytes;

  /// The household's name on the relay (32 hex characters).
  String get householdId => _derive('id')
      .take(16)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();

  /// The relay password (the relay keeps only its hash).
  String get auth => base64Url.encode(_derive('auth')).replaceAll('=', '');

  Uint8List get _fileKey => Uint8List.fromList(_derive('files'));

  /// gzip, then AES-256-GCM: "BSR1" + 12-byte nonce + ciphertext and tag.
  Future<Uint8List> seal(String text) {
    final key = _fileKey;
    final r = Random.secure();
    final nonce = Uint8List.fromList(List.generate(12, (_) => r.nextInt(256)));
    return Isolate.run(() => sealWith(key, nonce, text));
  }

  /// [seal] undone. Throws [FormatException] for anything not sealed with
  /// this household's key (or changed on the way).
  Future<String> open(Uint8List data) {
    final key = _fileKey;
    return Isolate.run(() => openWith(key, data));
  }
}

Uint8List sealWith(Uint8List key, Uint8List nonce, String text) {
  final cipher = GCMBlockCipher(AESEngine())
    ..init(true, AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)));
  final body = cipher.process(Uint8List.fromList(gzip.encode(utf8.encode(text))));
  return Uint8List.fromList([..._magic, ...nonce, ...body]);
}

String openWith(Uint8List key, Uint8List data) {
  if (data.length < 4 + 12 + 16 ||
      !List.generate(4, (i) => data[i] == _magic[i]).every((x) => x)) {
    throw const FormatException('Not a household file');
  }
  final cipher = GCMBlockCipher(AESEngine())
    ..init(false,
        AEADParameters(KeyParameter(key), 128, data.sublist(4, 16), Uint8List(0)));
  final Uint8List plain;
  try {
    plain = cipher.process(data.sublist(16));
  } on InvalidCipherTextException {
    throw const FormatException('Household file failed its check');
  }
  return utf8.decode(gzip.decode(plain));
}
