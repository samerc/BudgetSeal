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
    // Theme vars from the app, so the guide follows the chosen accent pair
    // and light/dark/black mode. Appended at the end of the first <style>
    // block so they win over the page's own :root and media-query rules.
    String hex(Color c) =>
        '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    final surface = AppColors.sf(context);
    final vars = ':root{'
        '--accent:${hex(AppColors.accent)};'
        '--accent-light:${hex(AppColors.accentLight)};'
        '--bg:${hex(AppColors.bg(context))};'
        '--surface:${hex(surface)};'
        '--text:${hex(AppColors.tp(context))};'
        '--text-secondary:${hex(AppColors.ts(context))};'
        '--border:${hex(Color.alphaBlend(AppColors.bd(context), surface))};'
        '}';
    try {
      final html = await rootBundle.loadString('assets/web/help.html');
      if (!mounted) return;
      final themed = html.replaceFirst('</style>', '$vars</style>');
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
