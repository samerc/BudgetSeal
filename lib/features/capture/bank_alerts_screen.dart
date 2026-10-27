import 'package:flutter/material.dart';

import '../../core/capture/bank_alerts.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/theme/design_tokens.dart';

/// Settings › Bank alerts (roadmap #2, Android): what it does and doesn't
/// do (shown first — reading notifications is sensitive), the system switch
/// for notification access, and the apps to read (picked from the ones
/// that have posted a notification; only their names are known otherwise).
class BankAlertsScreen extends StatefulWidget {
  const BankAlertsScreen({super.key});

  @override
  State<BankAlertsScreen> createState() => _BankAlertsScreenState();
}

class _BankAlertsScreenState extends State<BankAlertsScreen>
    with WidgetsBindingObserver {
  bool _enabled = false;
  Map<String, String> _seen = const {};
  Set<String> _apps = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Back from the system settings: access may have changed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    if (!BankAlerts.supported) {
      setState(() => _loaded = true);
      return;
    }
    try {
      final s = await BankAlerts.status();
      if (!mounted) return;
      setState(() {
        _enabled = s.enabled;
        _seen = s.seen;
        _apps = s.apps.toSet();
        _loaded = true;
      });
    } catch (e) {
      debugPrint('[BankAlerts] Status failed: $e');
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _toggle(String app, bool on) async {
    final tr = S.of(context);
    final next = {..._apps};
    on ? next.add(app) : next.remove(app);
    setState(() => _apps = next);
    try {
      await BankAlerts.setApps(next.toList());
    } catch (e) {
      debugPrint('[BankAlerts] Saving apps failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr.commonSomethingWentWrong),
            behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final apps = _seen.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
    return Scaffold(
      appBar: AppBar(title: Text(tr.tileBankAlerts)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: CardTokens.borderRadius,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.lock, size: 20, color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(tr.alertsDisclosure,
                      style: TextStyle(
                          fontSize: 13.5, color: AppColors.tp(context))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!BankAlerts.supported)
            Text(tr.alertsNotAndroid,
                style: TextStyle(color: AppColors.ts(context)))
          else if (_loaded) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppColors.card(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Icon(_enabled ? AppIcons.checkCircle : AppIcons.warning,
                        size: 20,
                        color: _enabled ? AppColors.healthy : AppColors.caution),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          _enabled ? tr.alertsAccessOn : tr.alertsAccessOff,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _enabled
                      ? OutlinedButton(
                          onPressed: BankAlerts.openSettings,
                          child: Text(tr.alertsChange))
                      : FilledButton(
                          onPressed: BankAlerts.openSettings,
                          child: Text(tr.alertsAllow)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
              child: Text(tr.alertsApps,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            if (apps.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(tr.alertsAppsEmpty,
                    style: TextStyle(
                        fontSize: 13.5, color: AppColors.ts(context))),
              )
            else
              Container(
                decoration: AppColors.card(context),
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  for (final e in apps)
                    SwitchListTile(
                      value: _apps.contains(e.key),
                      onChanged: (v) => _toggle(e.key, v),
                      title: Text(e.value),
                      subtitle: e.value == e.key
                          ? null
                          : Text(e.key,
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.th(context))),
                    ),
                ]),
              ),
          ],
        ],
      ),
    );
  }
}
