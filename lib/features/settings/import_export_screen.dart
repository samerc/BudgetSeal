import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/settings_row.dart';

class ImportExportScreen extends StatelessWidget {
  const ImportExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).ieTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _HubTile(
            icon: AppIcons.fileArrowUp,
            iconColor: SettingsRowStyle.hue(174),
            title: S.of(context).ieImportCsv,
            subtitle: S.of(context).ieImportCsvSub,
            onTap: () => context.push('/import'),
          ),
          const SizedBox(height: Spacing.sm),
          _HubTile(
            icon: AppIcons.downloadSimple,
            iconColor: SettingsRowStyle.hue(123),
            title: S.of(context).ieExportCsv,
            subtitle: S.of(context).ieExportCsvSub,
            onTap: () => context.push('/export'),
          ),
          const SizedBox(height: Spacing.sm),
          _HubTile(
            icon: AppIcons.filePdf,
            iconColor: SettingsRowStyle.hue(1),
            title: S.of(context).ieExportReport,
            subtitle: S.of(context).ieExportReportSub,
            onTap: () => context.push('/export-report'),
          ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HubTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: SettingsRow(
        icon: icon,
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
      ),
    );
  }
}
