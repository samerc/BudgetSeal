import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';

class ImportExportScreen extends StatelessWidget {
  const ImportExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).ieTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _HubTile(
            icon: Icons.upload_file_rounded,
            iconColor: const Color(0xFF26A69A),
            title: S.of(context).ieImportCsv,
            subtitle: S.of(context).ieImportCsvSub,
            onTap: () => context.push('/import'),
          ),
          const SizedBox(height: 12),
          _HubTile(
            icon: Icons.download_rounded,
            iconColor: const Color(0xFF66BB6A),
            title: S.of(context).ieExportCsv,
            subtitle: S.of(context).ieExportCsvSub,
            onTap: () => context.push('/export'),
          ),
          const SizedBox(height: 12),
          _HubTile(
            icon: Icons.picture_as_pdf_rounded,
            iconColor: const Color(0xFFEF5350),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: BorderRadius.circular(CardTokens.radius),
          border: Border.all(color: AppColors.bd(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tp(context))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.ts(context))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.th(context)),
          ],
        ),
      ),
    );
  }
}
