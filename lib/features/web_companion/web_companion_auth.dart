import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

const _storage = FlutterSecureStorage();
const _pinKey = 'web_companion_pin_hash';

class WebCompanionAuth {
  static const _uuid = Uuid();

  // In-memory only — intentionally reset on server restart
  final Map<String, _Session> _sessions = {};
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  static const _maxAttempts = 5;
  static const _lockoutDuration = Duration(minutes: 30);
  static const _sessionTimeout = Duration(hours: 4);
  static const _absoluteSessionTimeout = Duration(hours: 8);
  static const _maxSessions = 10;

  // ── PIN management ──────────────────────────────────────────────────────────

  static Future<bool> hasPin() async {
    final h = await _storage.read(key: _pinKey);
    return h != null && h.isNotEmpty;
  }

  static Future<void> setPin(String pin) async {
    assert(pin.length == 4 && RegExp(r'^\d{4}$').hasMatch(pin));
    final hash = sha256.convert(utf8.encode(pin)).toString();
    await _storage.write(key: _pinKey, value: hash);
  }

  static Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
  }

  // ── Auth flow ────────────────────────────────────────────────────────────────

  /// Validates the PIN and returns a session token on success.
  /// Throws [AuthException] on wrong PIN or lockout.
  Future<String> submitPin(String pin) async {
    _checkLockout();

    final storedHash = await _storage.read(key: _pinKey);
    if (storedHash == null) throw const AuthException('No PIN configured');

    final hash = sha256.convert(utf8.encode(pin)).toString();
    if (hash != storedHash) {
      _failedAttempts++;
      if (_failedAttempts >= _maxAttempts) {
        _lockoutUntil = DateTime.now().add(_lockoutDuration);
        _failedAttempts = 0;
        throw const AuthException(
          'Too many failed attempts. Please try again later.',
          isLockout: true,
        );
      }
      throw const AuthException('Incorrect PIN. Please try again.');
    }

    _failedAttempts = 0;
    final token = _uuid.v4();
    _sessions[token] = _Session(token: token);

    // Evict oldest session when over the cap to bound memory usage
    if (_sessions.length > _maxSessions) {
      final oldest = _sessions.values
          .reduce((a, b) => a.lastActivity.isBefore(b.lastActivity) ? a : b);
      _sessions.remove(oldest.token);
    }

    return token;
  }

  /// Returns true if the token is valid and not expired.
  /// Touches the session (resets inactivity timer) on success.
  bool validateToken(String? token) {
    if (token == null) return false;
    final session = _sessions[token];
    if (session == null) return false;
    final now = DateTime.now();
    // Absolute timeout — session can't live forever even with activity
    if (now.difference(session.createdAt) > _absoluteSessionTimeout) {
      _sessions.remove(token);
      return false;
    }
    // Inactivity timeout
    if (now.difference(session.lastActivity) > _sessionTimeout) {
      _sessions.remove(token);
      return false;
    }
    session.touch();
    return true;
  }

  void revokeToken(String token) => _sessions.remove(token);

  void revokeAllSessions() => _sessions.clear();

  int get activeSessionCount => _sessions.length;

  LockoutStatus get lockoutStatus {
    if (_lockoutUntil == null) return const LockoutStatus.unlocked();
    final remaining = _lockoutUntil!.difference(DateTime.now());
    if (remaining.isNegative) {
      _lockoutUntil = null;
      return const LockoutStatus.unlocked();
    }
    return LockoutStatus.locked(remaining);
  }

  /// Prune sessions that have been inactive for longer than the session timeout.
  void pruneExpiredSessions() {
    final now = DateTime.now();
    _sessions.removeWhere((_, s) =>
        now.difference(s.lastActivity) > _sessionTimeout);
  }

  void _checkLockout() {
    final status = lockoutStatus;
    if (status.isLocked) {
      throw const AuthException(
        'Too many failed attempts. Please try again later.',
        isLockout: true,
      );
    }
  }
}

// ── Supporting types ─────────────────────────────────────────────────────────

class _Session {
  final String token;
  final DateTime createdAt;
  DateTime lastActivity;

  _Session({required this.token})
      : createdAt = DateTime.now(),
        lastActivity = DateTime.now();

  void touch() => lastActivity = DateTime.now();
}

class AuthException implements Exception {
  final String message;
  final bool isLockout;
  const AuthException(this.message, {this.isLockout = false});

  @override
  String toString() => message;
}

class LockoutStatus {
  final bool isLocked;
  final Duration? remaining;

  const LockoutStatus.unlocked()
      : isLocked = false,
        remaining = null;

  const LockoutStatus.locked(Duration this.remaining) : isLocked = true;

  int get remainingMinutes =>
      remaining == null ? 0 : remaining!.inMinutes + 1;
}
