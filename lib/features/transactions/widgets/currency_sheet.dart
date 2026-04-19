import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

// ---------------------------------------------------------------------------
// Common currencies
// ---------------------------------------------------------------------------

const kCurrencies = [
  ('USD', 'US Dollar'),
  ('EUR', 'Euro'),
  ('GBP', 'British Pound'),
  ('JPY', 'Japanese Yen'),
  ('CHF', 'Swiss Franc'),
  ('CAD', 'Canadian Dollar'),
  ('AUD', 'Australian Dollar'),
  ('CNY', 'Chinese Yuan'),
  ('INR', 'Indian Rupee'),
  ('BRL', 'Brazilian Real'),
  ('MXN', 'Mexican Peso'),
  ('SGD', 'Singapore Dollar'),
  ('HKD', 'Hong Kong Dollar'),
  ('NOK', 'Norwegian Krone'),
  ('SEK', 'Swedish Krona'),
  ('NZD', 'New Zealand Dollar'),
  ('ZAR', 'South African Rand'),
  ('AED', 'UAE Dirham'),
  ('LBP', 'Lebanese Pound'),
  ('SAR', 'Saudi Riyal'),
  ('KWD', 'Kuwaiti Dinar'),
  ('TRY', 'Turkish Lira'),
];

/// Currency code to flag emoji mapping.
const kCurrencyFlags = <String, String>{
  'USD': '\u{1F1FA}\u{1F1F8}',
  'EUR': '\u{1F1EA}\u{1F1FA}',
  'GBP': '\u{1F1EC}\u{1F1E7}',
  'JPY': '\u{1F1EF}\u{1F1F5}',
  'CHF': '\u{1F1E8}\u{1F1ED}',
  'CAD': '\u{1F1E8}\u{1F1E6}',
  'AUD': '\u{1F1E6}\u{1F1FA}',
  'CNY': '\u{1F1E8}\u{1F1F3}',
  'INR': '\u{1F1EE}\u{1F1F3}',
  'BRL': '\u{1F1E7}\u{1F1F7}',
  'MXN': '\u{1F1F2}\u{1F1FD}',
  'SGD': '\u{1F1F8}\u{1F1EC}',
  'HKD': '\u{1F1ED}\u{1F1F0}',
  'NOK': '\u{1F1F3}\u{1F1F4}',
  'SEK': '\u{1F1F8}\u{1F1EA}',
  'NZD': '\u{1F1F3}\u{1F1FF}',
  'ZAR': '\u{1F1FF}\u{1F1E6}',
  'AED': '\u{1F1E6}\u{1F1EA}',
  'LBP': '\u{1F1F1}\u{1F1E7}',
  'SAR': '\u{1F1F8}\u{1F1E6}',
  'KWD': '\u{1F1F0}\u{1F1FC}',
  'TRY': '\u{1F1F9}\u{1F1F7}',
  'EGP': '\u{1F1EA}\u{1F1EC}',
};

/// Currency code to symbol mapping.
const kCurrencySymbols = <String, String>{
  'USD': '\$',
  'EUR': '\u20AC',
  'GBP': '\u00A3',
  'JPY': '\u00A5',
  'CHF': 'CHF',
  'CAD': 'CA\$',
  'AUD': 'A\$',
  'CNY': '\u00A5',
  'INR': '\u20B9',
  'BRL': 'R\$',
  'MXN': 'MX\$',
  'SGD': 'S\$',
  'HKD': 'HK\$',
  'NOK': 'kr',
  'SEK': 'kr',
  'NZD': 'NZ\$',
  'ZAR': 'R',
  'AED': '\u062F.\u0625',
  'LBP': '\u0644.\u0644',
  'SAR': '\uFDFC',
  'KWD': 'KD',
  'TRY': '\u20BA',
};

class CurrencySheet extends StatefulWidget {
  final String current;

  /// Optional list of currency codes to show in a "Recently Used" section.
  final List<String> recentCurrencies;

  const CurrencySheet({
    super.key,
    required this.current,
    this.recentCurrencies = const [],
  });

  @override
  State<CurrencySheet> createState() => _CurrencySheetState();
}

class _CurrencySheetState extends State<CurrencySheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = kCurrencies
        .where((c) =>
            c.$1.contains(_query.toUpperCase()) ||
            c.$2.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    // Build the recently-used list (only when not searching, max 3).
    final recentCodes = _query.isEmpty
        ? widget.recentCurrencies
            .where((c) => kCurrencies.any((k) => k.$1 == c))
            .take(3)
            .toList()
        : <String>[];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.sfv(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Currency',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Search\u2026',
                  prefixIcon:
                      const Icon(Icons.search_rounded, size: 18),
                  filled: true,
                  fillColor: AppColors.sfv(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: AppColors.bd(context)),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Recently used section
                  if (recentCodes.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: Text(
                        'RECENTLY USED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.ts(context),
                        ),
                      ),
                    ),
                    for (final code in recentCodes)
                      _buildCurrencyTile(
                        code,
                        kCurrencies
                            .firstWhere((c) => c.$1 == code,
                                orElse: () => (code, code))
                            .$2,
                      ),
                    Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: AppColors.bd(context),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: Text(
                        'ALL CURRENCIES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.ts(context),
                        ),
                      ),
                    ),
                  ],
                  // Full filtered list
                  for (final (code, name) in filtered)
                    _buildCurrencyTile(code, name),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyTile(String code, String name) {
    final isSelected = code == widget.current;
    final flag = kCurrencyFlags[code];
    final symbol = kCurrencySymbols[code];

    return ListTile(
      leading: SizedBox(
        width: 72,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (flag != null) ...[
              Text(flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                code,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.tp(context),
                ),
              ),
            ),
          ],
        ),
      ),
      title: Text(
        symbol != null ? '$name ($symbol)' : name,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          color: isSelected
              ? AppColors.accent
              : AppColors.tp(context),
          fontWeight:
              isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.accent, size: 16),
            )
          : null,
      selected: isSelected,
      selectedTileColor: AppColors.accent.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () => Navigator.pop(context, code),
    );
  }
}
