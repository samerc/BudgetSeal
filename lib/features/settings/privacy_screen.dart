import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Terms')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _section(context, 'Privacy Policy',
              'Last updated: May 2026'),
          const SizedBox(height: 16),
          _body(context,
              'PocketPlan is designed with your privacy as a core principle. '
              'Your financial data belongs to you — we never collect, store, '
              'or transmit it to any server.'),
          const SizedBox(height: 24),

          _heading(context, '1. Data Storage'),
          _body(context,
              'All your financial data (transactions, accounts, envelopes, '
              'categories, goals, and settings) is stored locally on your '
              'device in an SQLite database. No data leaves your device '
              'unless you explicitly enable Cloud Sync.'),
          const SizedBox(height: 16),

          _heading(context, '2. Cloud Sync (Optional)'),
          _body(context,
              'If you choose to enable Cloud Sync, your data is uploaded to '
              'your personal Google Drive account or a file storage provider '
              'you select. PocketPlan does not have access to your Google '
              'account credentials — authentication is handled by Google\'s '
              'OAuth system.\n\n'
              'You may optionally encrypt your sync file with AES-256 '
              'encryption using a password you set. The password is stored '
              'only on your device in secure storage (Android Keystore / '
              'iOS Keychain).'),
          const SizedBox(height: 16),

          _heading(context, '3. Web Companion'),
          _body(context,
              'The Web Companion feature runs a local HTTP server on your '
              'phone. It is only accessible from devices on the same WiFi '
              'network (private IP addresses). No data is sent to the '
              'internet. The connection is protected by a PIN, session '
              'tokens, and rate limiting. The server stops automatically '
              'after 6 hours.'),
          const SizedBox(height: 16),

          _heading(context, '4. Analytics & Tracking'),
          _body(context,
              'PocketPlan does not include any analytics SDKs, crash '
              'reporting tools, advertising libraries, or tracking pixels. '
              'No usage data, device identifiers, or behavioral metrics '
              'are collected.'),
          const SizedBox(height: 16),

          _heading(context, '5. Permissions'),
          _body(context,
              '• Camera — used only for receipt scanning (offline OCR)\n'
              '• Notifications — daily reminders and bill alerts\n'
              '• Biometrics — optional app lock\n'
              '• Network — only for Cloud Sync and exchange rate fetching\n'
              '• Local Network — Web Companion server\n\n'
              'All permissions are optional and can be denied without '
              'affecting core functionality.'),
          const SizedBox(height: 16),

          _heading(context, '6. Receipt Images'),
          _body(context,
              'Receipt photos are stored in the app\'s private directory '
              'on your device. They are not uploaded anywhere unless you '
              'enable receipt sync via Google Drive. OCR processing is '
              'performed entirely offline using on-device ML.'),
          const SizedBox(height: 16),

          _heading(context, '7. Backups'),
          _body(context,
              'Automatic backups are stored locally in the app\'s documents '
              'directory. You control backup frequency and retention. '
              'Exported backup files are shared via the system share sheet '
              'and deleted from temporary storage afterward.'),

          const SizedBox(height: 32),
          Divider(color: AppColors.bd(context)),
          const SizedBox(height: 32),

          _section(context, 'Terms of Use',
              'Last updated: May 2026'),
          const SizedBox(height: 16),

          _heading(context, '1. Acceptance'),
          _body(context,
              'By using PocketPlan, you agree to these terms. If you do not '
              'agree, please uninstall the app.'),
          const SizedBox(height: 16),

          _heading(context, '2. Intended Use'),
          _body(context,
              'PocketPlan is a personal finance management tool for '
              'individual and household budgeting. It is not intended for '
              'commercial accounting, tax preparation, or financial advice. '
              'The app provides tools to organize your finances — it does '
              'not provide financial recommendations.'),
          const SizedBox(height: 16),

          _heading(context, '3. Data Accuracy'),
          _body(context,
              'You are responsible for the accuracy of the data you enter. '
              'PocketPlan calculates balances, budgets, and reports based '
              'on your input. Exchange rates fetched from external sources '
              'are approximate and may not reflect real-time market rates.'),
          const SizedBox(height: 16),

          _heading(context, '4. No Warranty'),
          _body(context,
              'PocketPlan is provided "as is" without warranty of any kind. '
              'While we strive for reliability, we cannot guarantee that '
              'the app will be error-free or uninterrupted. Regular backups '
              'are strongly recommended.'),
          const SizedBox(height: 16),

          _heading(context, '5. Limitation of Liability'),
          _body(context,
              'The developer shall not be liable for any direct, indirect, '
              'incidental, or consequential damages arising from the use '
              'of PocketPlan, including but not limited to data loss, '
              'financial miscalculations, or sync failures.'),
          const SizedBox(height: 16),

          _heading(context, '6. Intellectual Property'),
          _body(context,
              'PocketPlan and its original content are protected by '
              'copyright. The app uses open-source libraries listed in '
              'the Licenses section of the About screen.'),
          const SizedBox(height: 16),

          _heading(context, '7. Changes'),
          _body(context,
              'These terms may be updated with new app versions. Continued '
              'use after an update constitutes acceptance of the revised '
              'terms.'),
          const SizedBox(height: 16),

          _heading(context, '8. Contact'),
          _body(context,
              'For questions or concerns about this privacy policy or '
              'terms of use, contact: samer@pocketplan.app'),

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
