import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = S.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.privacyTermsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _section(context, l.privacyPolicyTitle,
              l.privacyLastUpdated),
          const SizedBox(height: 16),
          _body(context, l.privacyIntro),
          const SizedBox(height: 24),

          _heading(context, l.privacyDataStorageTitle),
          _body(context, l.privacyDataStorageBody),
          const SizedBox(height: 16),

          _heading(context, l.privacyCloudSyncTitle),
          _body(context, l.privacyCloudSyncBody),
          const SizedBox(height: 16),

          _heading(context, l.privacyWebCompanionTitle),
          _body(context, l.privacyWebCompanionBody),
          const SizedBox(height: 16),

          _heading(context, l.privacyAnalyticsTitle),
          _body(context, l.privacyAnalyticsBody),
          const SizedBox(height: 16),

          _heading(context, l.privacyPermissionsTitle),
          _body(context, l.privacyPermissionsBody),
          const SizedBox(height: 16),

          _heading(context, l.privacyReceiptsTitle),
          _body(context, l.privacyReceiptsBody),
          const SizedBox(height: 16),

          _heading(context, l.privacyBackupsTitle),
          _body(context, l.privacyBackupsBody),

          const SizedBox(height: 32),
          Divider(color: AppColors.bd(context)),
          const SizedBox(height: 32),

          _section(context, l.termsOfUseTitle,
              l.privacyLastUpdated),
          const SizedBox(height: 16),

          _heading(context, l.termsAcceptanceTitle),
          _body(context, l.termsAcceptanceBody),
          const SizedBox(height: 16),

          _heading(context, l.termsIntendedUseTitle),
          _body(context, l.termsIntendedUseBody),
          const SizedBox(height: 16),

          _heading(context, l.termsDataAccuracyTitle),
          _body(context, l.termsDataAccuracyBody),
          const SizedBox(height: 16),

          _heading(context, l.termsNoWarrantyTitle),
          _body(context, l.termsNoWarrantyBody),
          const SizedBox(height: 16),

          _heading(context, l.termsLiabilityTitle),
          _body(context, l.termsLiabilityBody),
          const SizedBox(height: 16),

          _heading(context, l.termsIPTitle),
          _body(context, l.termsIPBody),
          const SizedBox(height: 16),

          _heading(context, l.termsChangesTitle),
          _body(context, l.termsChangesBody),
          const SizedBox(height: 16),

          _heading(context, l.termsContactTitle),
          _body(context, l.termsContactBody),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.tp(context),
            )),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.th(context),
            )),
      ],
    );
  }

  Widget _heading(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.tp(context),
          )),
    );
  }

  Widget _body(BuildContext context, String text) {
    return Text(text,
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: AppColors.ts(context),
        ));
  }
}
