import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';

/// Remembers the last account and transfer pair used in the add forms, so a
/// new transaction starts on them (both entry modes).
class LastUsedService {
  static const _accountKey = 'last_used_account';
  static const _fromKey = 'last_transfer_from';
  static const _toKey = 'last_transfer_to';

  static Future<void> rememberAccount(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountKey, accountId);
  }

  static Future<void> rememberTransfer(String from, String to) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fromKey, from);
    await prefs.setString(_toKey, to);
  }

  /// The last used account if it's still active, else the first account.
  static Future<String?> defaultAccount(List<Account> accounts) async {
    if (accounts.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_accountKey);
    return accounts.any((a) => a.id == id) ? id : accounts.first.id;
  }

  /// The last transfer pair, each side only if still active.
  static Future<({String? from, String? to})> transferPair(
      List<Account> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    String? valid(String? id) =>
        accounts.any((a) => a.id == id) ? id : null;
    return (
      from: valid(prefs.getString(_fromKey)),
      to: valid(prefs.getString(_toKey)),
    );
  }
}
