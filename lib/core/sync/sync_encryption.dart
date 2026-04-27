import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/pointycastle.dart' as pc;

const _secureStorage = FlutterSecureStorage();
const _passwordKey = 'sync_encryption_password';
const _saltKey = 'sync_encryption_salt';

/// AES-256-CBC encryption for the sync file.
///
/// Uses PBKDF2 to derive a 256-bit key from the user's password + a random salt.
/// The salt is stored in secure storage (device-local) and also embedded in the
/// encrypted file header so the same password works on any device.
class SyncEncryption {
  /// Check if a sync password has been set.
  static Future<bool> hasPassword() async {
    final pw = await _secureStorage.read(key: _passwordKey);
    return pw != null && pw.isNotEmpty;
  }

  /// Store the sync password in secure storage.
  static Future<void> setPassword(String password) async {
    await _secureStorage.write(key: _passwordKey, value: password);
    // Generate a random salt if not already set
    if (await _secureStorage.read(key: _saltKey) == null) {
      final salt = SecureRandom(16).bytes;
      await _secureStorage.write(
          key: _saltKey, value: base64Encode(salt));
    }
  }

  /// Read the stored password (null if not set).
  static Future<String?> getPassword() async {
    return _secureStorage.read(key: _passwordKey);
  }

  /// Clear the stored password.
  static Future<void> clearPassword() async {
    await _secureStorage.delete(key: _passwordKey);
    await _secureStorage.delete(key: _saltKey);
  }

  /// Encrypt a plaintext JSON string with the stored password.
  ///
  /// Format: `ENC:1:<base64 salt>:<base64 IV>:<base64 ciphertext>`
  /// Version 1 = AES-256-CBC with PBKDF2 key derivation.
  static Future<String> encrypt(String plaintext) async {
    final password = await getPassword();
    if (password == null || password.isEmpty) {
      // No password set — return plaintext (backward compatible)
      return plaintext;
    }

    final salt = await _getOrCreateSalt();
    final key = _deriveKey(password, salt);
    final iv = IV.fromSecureRandom(16);

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    return 'ENC:1:${base64Encode(salt)}:${iv.base64}:${encrypted.base64}';
  }

  /// Decrypt an encrypted string with the given password.
  ///
  /// If the string doesn't start with `ENC:`, it's treated as plaintext
  /// (backward compatible with unencrypted sync files).
  static Future<String> decrypt(String data, {String? password}) async {
    if (!data.startsWith('ENC:')) {
      // Not encrypted — return as-is (backward compatible)
      return data;
    }

    password ??= await getPassword();
    if (password == null || password.isEmpty) {
      throw StateError('Sync file is encrypted but no password is set. '
          'Enter your sync password to decrypt.');
    }

    final parts = data.split(':');
    if (parts.length != 5 || parts[1] != '1') {
      throw FormatException('Invalid encrypted sync file format');
    }

    final salt = base64Decode(parts[2]);
    final iv = IV.fromBase64(parts[3]);
    final ciphertext = Encrypted.fromBase64(parts[4]);

    final key = _deriveKey(password, salt);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    try {
      return encrypter.decrypt(ciphertext, iv: iv);
    } catch (e) {
      throw StateError('Wrong sync password. Could not decrypt the sync file.');
    }
  }

  /// Check if a sync file string is encrypted.
  static bool isEncrypted(String data) => data.startsWith('ENC:');

  // ─── Internal ──────────────────────────────────────────────────────────────

  static Future<Uint8List> _getOrCreateSalt() async {
    final stored = await _secureStorage.read(key: _saltKey);
    if (stored != null) return base64Decode(stored);
    final salt = SecureRandom(16).bytes;
    await _secureStorage.write(key: _saltKey, value: base64Encode(salt));
    return salt;
  }

  /// Derive a 256-bit AES key from password + salt using PBKDF2.
  static Key _deriveKey(String password, Uint8List salt) {
    final pbkdf2 = pc.KeyDerivator('SHA-256/HMAC/PBKDF2')
      ..init(pc.Pbkdf2Parameters(salt, 100000, 32));
    final keyBytes = pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
    return Key(keyBytes);
  }
}
