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

class CurrencySheet extends StatefulWidget {
  final String current;
  const CurrencySheet({super.key, required this.current});

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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  hintText: 'Search…',
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
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final (code, name) = filtered[i];
                  final isSelected = code == widget.current;
                  return ListTile(
                    leading: SizedBox(
                      width: 44,
                      child: Text(
                        code,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.accent, size: 18)
                        : null,
                    onTap: () => Navigator.pop(context, code),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
