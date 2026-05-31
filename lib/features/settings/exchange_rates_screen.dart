import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';

/// Displays cached exchange rates and allows manual refresh.
class ExchangeRatesScreen extends ConsumerStatefulWidget {
  const ExchangeRatesScreen({super.key});

  @override
  ConsumerState<ExchangeRatesScreen> createState() =>
      _ExchangeRatesScreenState();
}

class _ExchangeRatesScreenState extends ConsumerState<ExchangeRatesScreen> {
  /// Common currencies to show rates for.
  static const _currencies = [
    'USD', 'EUR', 'GBP', 'LBP', 'AED', 'CAD', 'AUD', 'JPY',
    'CHF', 'TRY', 'SAR', 'EGP', 'INR', 'BRL',
  ];

  final Map<String, double> _rates = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRates();
  }

  Future<void> _fetchRates() async {
    final baseCurrency =
        ref.read(householdProvider).value?.baseCurrency ?? 'USD';
    setState(() {
      _loading = true;
      _error = null;
    });

    final fxService = ref.read(fxServiceProvider);
    final fetched = <String, double>{};
    try {
      for (final currency in _currencies) {
        if (currency == baseCurrency) continue;
        try {
          final rate =
              await fxService.getRateWithCache(baseCurrency, currency);
          fetched[currency] = rate;
        } catch (e) {
          debugPrint('Failed to fetch rate for $currency: $e');
        }
      }
      if (mounted) {
        setState(() {
          _rates
            ..clear()
            ..addAll(fetched);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  String _formatRate(double rate) {
    if (rate >= 1000) return formatNumber(rate, decimals: 0);
    if (rate >= 100) return formatNumber(rate, decimals: 1);
    if (rate >= 1) return formatNumber(rate, decimals: 2);
    return formatNumber(rate, decimals: 6);
  }

  @override
  Widget build(BuildContext context) {
    final baseCurrency =
        ref.watch(householdProvider).value?.baseCurrency ?? 'USD';

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).fxTitle),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: S.of(context).fxRefreshTooltip,
            onPressed: _loading ? null : _fetchRates,
          ),
        ],
      ),
      body: _loading && _rates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : !_loading && _rates.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off_rounded,
                            size: 48, color: AppColors.ts(context)),
                        const SizedBox(height: 12),
                        Text(
                          _error != null
                              ? S.of(context).fxCouldNotFetch
                              : S.of(context).fxNoRates,
                          style: TextStyle(
                              color: AppColors.tp(context),
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          S.of(context).fxCheckInternet,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.ts(context), fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _fetchRates,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: Text(S.of(context).commonRetry),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(CardTokens.radius),
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.currency_exchange_rounded,
                              size: 20, color: AppColors.accent),
                          const SizedBox(width: 12),
                          Text(
                            'Base: $baseCurrency',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                          const Spacer(),
                          if (_loading)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.accent),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      S.of(context).fxCacheInfo,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.ts(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Rate list
                    ..._rates.entries.map((e) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: AppColors.sf(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                e.key,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            '1 $baseCurrency = ${_formatRate(e.value)} ${e.key}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}
