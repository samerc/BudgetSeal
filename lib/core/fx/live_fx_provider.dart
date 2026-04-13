import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'fx_provider.dart';

/// Live exchange rate provider using the fawazahmed0/currency-api.
/// Free, no API key, 200+ currencies including LBP.
class LiveFxProvider implements FxProvider {
  static const _cdnBase =
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies';
  static const _fallbackBase =
      'https://latest.currency-api.pages.dev/v1/currencies';

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  @override
  bool get isLive => true;

  @override
  Future<double> getRate(String from, String to) async {
    if (from == to) return 1.0;

    final fromLower = from.toLowerCase();
    final toLower = to.toLowerCase();

    // Try primary CDN first, then fallback.
    for (final base in [_cdnBase, _fallbackBase]) {
      try {
        final url = '$base/$fromLower.min.json';
        final response = await _dio.get(url);

        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          final rates = data[fromLower] as Map<String, dynamic>?;
          if (rates != null && rates.containsKey(toLower)) {
            return (rates[toLower] as num).toDouble();
          }
        }
      } catch (e) {
        debugPrint('FX provider $base failed for $from->$to: $e');
        // Try fallback on next iteration.
      }
    }

    throw Exception('Failed to fetch rate $from → $to from all providers');
  }
}
