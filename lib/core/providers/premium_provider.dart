import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

/// Feature identifiers for premium gating.
abstract class PremiumFeature {
  static const sync = 'sync';
  static const webCompanion = 'web_companion';
  static const travelExchange = 'travel_exchange';
  static const billSplitter = 'bill_splitter';
  static const plannedPayments = 'planned_payments';
}

/// Free-tier limits.
abstract class FreeLimits {
  static const maxAccounts = 3;
  static const maxEnvelopes = 5;
  static const maxRecurring = 5;
}

/// Which features require premium. Easy to change — move a feature out of
/// this set to make it free. In the future, this can be swapped to a
/// remote config fetch.
const _premiumFeatures = <String>{
  PremiumFeature.sync,
  PremiumFeature.webCompanion,
  PremiumFeature.travelExchange,
  PremiumFeature.billSplitter,
  PremiumFeature.plannedPayments,
};

const _redeemCodeKey = 'premium_redeem_code';
const _purchaseKey = 'premium_purchased';
const _storage = FlutterSecureStorage();

/// Whether the user has premium access (purchased or redeemed).
final hasPremiumProvider =
    NotifierProvider<PremiumNotifier, bool>(PremiumNotifier.new);

class PremiumNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    try {
      final purchased = await _storage.read(key: _purchaseKey);
      if (purchased == 'true') {
        state = true;
        return;
      }
      final code = await _storage.read(key: _redeemCodeKey);
      if (code != null && code.isNotEmpty) {
        state = true;
        return;
      }
    } catch (_) {}
  }

  /// Called when Google Play purchase is confirmed.
  Future<void> setPurchased() async {
    state = true;
    await _storage.write(key: _purchaseKey, value: 'true');
  }

  /// Called when a valid redeem code is entered.
  Future<void> redeemCode(String code) async {
    state = true;
    await _storage.write(key: _redeemCodeKey, value: code);
  }

  /// Restore purchases (called on app start or from settings).
  Future<void> restorePurchases() async {
    // Phase 1: check secure storage only.
    // Phase 2: will also query Google Play Billing API.
    await _load();
  }
}

/// Check if a specific feature requires premium.
bool isFeaturePremium(String feature) => _premiumFeatures.contains(feature);

/// Check if the user has hit a free-tier limit.
bool isAtFreeLimit(int currentCount, int limit) => currentCount >= limit;

/// Valid redeem codes. In production, these could be fetched from a server
/// or use a more sophisticated validation (HMAC, expiry, etc.).
/// For now, a simple hardcoded set that you control.
const _validCodes = <String>{
  'BETA2026',
  'EARLYBIRD',
  'BUDGETSEAL-VIP',
};

/// Validate a redeem code.
bool isValidRedeemCode(String code) =>
    _validCodes.contains(code.trim().toUpperCase());

/// Gate a premium feature. Returns `true` if the user has access (premium or
/// feature is free). Returns `false` after navigating to the upgrade screen.
bool checkPremiumAccess(BuildContext context, WidgetRef ref, String feature) {
  if (ref.read(hasPremiumProvider)) return true;
  if (!isFeaturePremium(feature)) return true;
  context.push('/upgrade', extra: feature);
  return false;
}

/// Gate a free-tier count limit. Returns `true` if under the limit or premium.
/// Navigates to upgrade screen and returns `false` otherwise.
bool checkFreeLimit(
    BuildContext context, WidgetRef ref, int currentCount, int limit, String label) {
  if (ref.read(hasPremiumProvider)) return true;
  if (currentCount < limit) return true;
  context.push('/upgrade', extra: label);
  return false;
}
