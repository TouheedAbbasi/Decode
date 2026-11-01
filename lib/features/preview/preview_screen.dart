import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/preview/browser.dart';
import '../../core/preview/preview_server.dart';
import '../../core/preview/preview_source.dart';

/// Renders a [PreviewSource] in an in-app WebView served from a loopback
/// server, with a button to open the same page in Chrome.
class PreviewScreen extends StatefulWidget {
  const PreviewScreen({
    super.key,
    required this.source,
    this.entry = 'index.html',
  });

  final PreviewSource source;
  final String entry;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  PreviewServer? _server;
  WebViewController? _controller;
  String? _startError;
  String? _pageError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    final server = _server;
    if (server != null) unawaited(server.stop());
    super.dispose();
  }

  Future<void> _start() async {
    try {
      final server = await PreviewServer.start(widget.source);
      if (!mounted) {
        await server.stop();
        return;
      }
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: _onNavigationRequest,
            onPageStarted: (_) {
              if (!mounted) return;
              setState(() {
                _loading = true;
                _pageError = null;
              });
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
            onWebResourceError: (error) {
              if (!mounted || error.isForMainFrame == false) return;
              setState(() {
                _loading = false;
                _pageError = error.description;
              });
            },
          ),
        )
        ..loadRequest(Uri.parse(server.urlFor(widget.entry)));
      setState(() {
        _server = server;
        _controller = controller;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _startError = 'Could not start the preview.';
      });
    }
  }

  /// Pages may only navigate inside the preview. Links to other websites
  /// open in the system browser instead.
  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    if (!request.isMainFrame) return NavigationDecision.navigate;
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;
    if (uri.host == '127.0.0.1' ||
        uri.scheme == 'about' ||
        uri.scheme == 'data' ||
        uri.scheme == 'blob') {
      return NavigationDecision.navigate;
    }
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
    }
    return NavigationDecision.prevent;
  }

  Future<void> _refresh() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.clearCache();
    await controller.reload();
  }

  Future<void> _openInChrome() async {
    final server = _server;
    if (server == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await openInChrome(server.urlFor(widget.entry));
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open a browser.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = _server?.urlFor(widget.entry);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Preview'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _controller == null ? null : _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Container(
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border.all(color: scheme.outline),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.language_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      url ?? 'Starting...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: url == null ? null : _openInChrome,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Open in Chrome'),
                  ),
                ],
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_startError != null) {
      return Center(child: Text(_startError!));
    }
    final controller = _controller;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        WebViewWidget(controller: controller),
        if (_pageError != null)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'The page could not be loaded.\n$_pageError',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
