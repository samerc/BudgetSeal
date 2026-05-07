import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/tx_list_settings_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';

class TxListSettingsScreen extends ConsumerWidget {
  const TxListSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(txListSettingsProvider);
    final notifier = ref.read(txListSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction List')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── Live Preview ──────────────────────────────────────────
          Text('Select Layout',
              style: TextStyle(
                fontSize: TypographyTokens.screenTitleSize,
                fontWeight: TypographyTokens.screenTitleWeight,
                color: AppColors.tp(context),
              )),
          const SizedBox(height: 16),
          _LayoutPreview(settings: s),
          const SizedBox(height: 28),

          // ── Date Banner Total ─────────────────────────────────────
          _SettingRow(
            icon: Icons.calendar_today_rounded,
            title: 'Date Banner Total',
            trailing: _DropdownChip(
              value: s.dateBannerTotal == 'dayTotal' ? 'Day Total' : 'None',
              onTap: () {
                final next =
                    s.dateBannerTotal == 'dayTotal' ? 'none' : 'dayTotal';
                notifier.update((s) => s.copyWith(dateBannerTotal: next));
              },
            ),
          ),
          const Divider(height: 1),

          // ── Account Label ─────────────────────────────────────────
          _ToggleRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Account Label',
            subtitle: 'Show account name on each transaction',
            value: s.showAccount,
            onChanged: (v) =>
                notifier.update((s) => s.copyWith(showAccount: v)),
          ),
          const Divider(height: 1),

          // ── Category Icon ─────────────────────────────────────────
          _ToggleRow(
            icon: Icons.category_outlined,
            title: 'Category Icon',
            subtitle: 'Show category icon circle',
            value: s.showCategoryIcon,
            onChanged: (v) =>
                notifier.update((s) => s.copyWith(showCategoryIcon: v)),
          ),
          const Divider(height: 1),

          // ── Time ──────────────────────────────────────────────────
          _ToggleRow(
            icon: Icons.schedule_rounded,
            title: 'Time',
            subtitle: 'Show time of the transaction',
            value: s.showTime,
            onChanged: (v) =>
                notifier.update((s) => s.copyWith(showTime: v)),
          ),
        ],
      ),
    );
  }
}

// ── Live preview widget ─────────────────────────────────────────────────────

class _LayoutPreview extends StatelessWidget {
  final TxListSettings settings;
  const _LayoutPreview({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Compact option
        _PreviewCard(
          selected: settings.compact,
          onTap: () => _toggle(context, true),
          child: _CompactPreviewRow(settings: settings),
        ),
        const SizedBox(height: 10),
        // Expanded option
        _PreviewCard(
          selected: !settings.compact,
          onTap: () => _toggle(context, false),
          child: _ExpandedPreviewRow(settings: settings),
        ),
      ],
    );
  }

  void _toggle(BuildContext context, bool compact) {
    // Use ProviderScope.containerOf to avoid needing ref
    // Since parent is a ConsumerWidget, the provider is already in scope
    final container = ProviderScope.containerOf(context);
    container
        .read(txListSettingsProvider.notifier)
        .update((s) => s.copyWith(compact: compact));
  }
}

class _PreviewCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  const _PreviewCard(
      {required this.selected, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.sfv(context),
          borderRadius: BorderRadius.circular(CardTokens.radius),
          border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.6)
                : AppColors.bd(context),
            width: selected ? 2 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _CompactPreviewRow extends StatelessWidget {
  final TxListSettings settings;
  const _CompactPreviewRow({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (settings.showCategoryIcon) ...[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.restaurant, size: 16, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Row(
            children: [
              Text('Transaction Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tp(context),
                  ),
                  overflow: TextOverflow.ellipsis),
              if (settings.showAccount) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.sfv(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Bank',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.ts(context))),
                ),
              ],
            ],
          ),
        ),
        Text('▼ \$100',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.overspent)),
      ],
    );
  }
}

class _ExpandedPreviewRow extends StatelessWidget {
  final TxListSettings settings;
  const _ExpandedPreviewRow({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (settings.showCategoryIcon) ...[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.restaurant, size: 18, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Transaction Name',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tp(context),
                        )),
                  ),
                  Text('▼ \$100',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.overspent)),
                ],
              ),
              const SizedBox(height: 3),
              Text('This is a note that is part of the transaction.',
                  style: TextStyle(fontSize: 12, color: AppColors.ts(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (settings.showAccount) ...[
                const SizedBox(height: 3),
                Text('Bank · USD',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.th(context))),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Setting row widgets ─────────────────────────────────────────────────────

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  const _SettingRow(
      {required this.icon, required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.ts(context)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.tp(context),
                )),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.ts(context)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tp(context),
                    )),
                if (subtitle != null)
                  Text(subtitle!,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.ts(context))),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _DropdownChip extends StatelessWidget {
  final String value;
  final VoidCallback onTap;
  const _DropdownChip({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.sfv(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.tp(context))),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: AppColors.ts(context)),
          ],
        ),
      ),
    );
  }
}
