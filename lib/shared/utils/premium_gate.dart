import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/premium_provider.dart';

/// Show upgrade screen if the feature is premium and user doesn't have premium.
/// Returns true if the user has access (premium or feature is free).
bool checkPremiumAccess(BuildContext context, WidgetRef ref, String feature) {
  if (!isFeaturePremium(feature)) return true;
  if (ref.read(hasPremiumProvider)) return true;
  context.push('/upgrade', extra: feature);
  return false;
}
