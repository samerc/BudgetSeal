import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';

class HelpScreen extends StatefulWidget {
  final String? section;
  const HelpScreen({super.key, this.section});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
          // Scroll to section if specified
          if (widget.section != null) {
            _controller.runJavaScript(
              'document.getElementById("${widget.section}")?.scrollIntoView({behavior:"smooth"});',
            );
          }
        },
        // Block external links — open in system browser instead
        onNavigationRequest: (request) {
          if (request.url.startsWith('http')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ));
    // Defer load to after first frame so Theme.of(context) is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHtml());
  }

  Future<void> _loadHtml() async {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    try {
      final html = await rootBundle.loadString('assets/web/help.html');
      if (!mounted) return;
      // Inject theme CSS override based on current app theme
      final themed = isDark
          ? html.replaceFirst(
              '<style>',
              '<style>:root{--bg:#0F1219;--surface:#1A1D27;--text:#E8EBF0;--text-secondary:#94A3B8;--border:#2A2D3A;--accent-light:#1E3A5F;}',
            )
          : html;
      await _controller.loadHtmlString(themed);
    } catch (e) {
      debugPrint('[HelpScreen] Error loading help: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).helpGuideTitle)),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            Center(
              child: CircularProgressIndicator(
                color: AppColors.accent,
              ),
            ),
        ],
      ),
    );
  }
}
