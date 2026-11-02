import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/preview/preview_server.dart';
import '../../core/preview/preview_source.dart';

/// A small live preview that can sit inside a normal screen.
class InlinePreview extends StatefulWidget {
  const InlinePreview({
    super.key,
    required this.source,
    this.entry = 'index.html',
  });

  final PreviewSource source;
  final String entry;

  @override
  State<InlinePreview> createState() => _InlinePreviewState();
}

class _InlinePreviewState extends State<InlinePreview> {
  PreviewServer? _server;
  WebViewController? _controller;
  bool _loading = true;
  String? _error;

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
            onNavigationRequest: (request) {
              final uri = Uri.tryParse(request.url);
              final inside = !request.isMainFrame ||
                  (uri != null &&
                      (uri.host == '127.0.0.1' ||
                          uri.scheme == 'about' ||
                          uri.scheme == 'data'));
              return inside
                  ? NavigationDecision.navigate
                  : NavigationDecision.prevent;
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
            onWebResourceError: (error) {
              if (!mounted || error.isForMainFrame == false) return;
              setState(() {
                _loading = false;
                _error = error.description;
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
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not start the preview.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        WebViewWidget(controller: controller),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
      ],
    );
  }
}
