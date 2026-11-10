import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'copy_helper.dart';

/// Shows a small web page bundled with the app (icons, fonts). The page can
/// copy text through the `DecodeCopy` channel.
class WebToolScreen extends StatefulWidget {
  const WebToolScreen({super.key, required this.title, required this.asset});

  final String title;
  final String asset;

  @override
  State<WebToolScreen> createState() => _WebToolScreenState();
}

class _WebToolScreenState extends State<WebToolScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'DecodeCopy',
        onMessageReceived: (message) {
          if (mounted) copyText(context, message.message, message: 'Copied');
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (!request.isMainFrame) return NavigationDecision.navigate;
            final uri = Uri.tryParse(request.url);
            if (uri != null && uri.host == 'decode.local') {
              return NavigationDecision.navigate;
            }
            if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
              unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
            }
            return NavigationDecision.prevent;
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
            _applyTheme();
          },
        ),
      );
    _load();
  }

  Future<void> _load() async {
    try {
      final html = await rootBundle.loadString(widget.asset);
      await _controller.loadHtmlString(html, baseUrl: 'https://decode.local/');
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not open this page.';
        });
      }
    }
  }

  void _applyTheme() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    _controller.runJavaScript(
      "window.setTheme && setTheme('${dark ? 'dark' : 'light'}')",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _loading = true);
              _load();
            },
          ),
        ],
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading) const LinearProgressIndicator(minHeight: 2),
              ],
            ),
    );
  }
}
