import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'preview_bundler.dart';
import 'preview_server.dart';
import 'preview_source.dart';

/// Runs one preview: a WebView that first tries the local server and, if
/// Android refuses that (cleartext policy, no socket), falls back to a
/// self-contained bundled page. Either way something shows up.
class PreviewSession extends ChangeNotifier {
  PreviewSession({required this.source, this.entry = 'index.html'});

  final PreviewSource source;
  final String entry;

  static const _bundleHost = 'decode.local';

  WebViewController? controller;
  PreviewServer? _server;
  bool loading = true;
  bool bundled = false;
  String? error;

  String _current = '';
  bool _triedBundle = false;
  bool _disposed = false;

  String get currentEntry => _current.isEmpty ? entry : _current;

  /// Address of the page on the local server, when it is running.
  String? get serverUrl => _server?.urlFor(currentEntry);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> start() async {
    _current = entry;
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigate,
          onPageStarted: (_) {
            loading = true;
            _notify();
          },
          onPageFinished: (_) {
            loading = false;
            _notify();
          },
          onWebResourceError: _onError,
        ),
      );
    _notify();

    try {
      final server = await PreviewServer.start(source);
      if (_disposed) {
        await server.stop();
        return;
      }
      _server = server;
      await controller!.loadRequest(Uri.parse(server.urlFor(entry)));
    } catch (_) {
      await _loadBundle(entry);
    }
  }

  NavigationDecision _onNavigate(NavigationRequest request) {
    if (!request.isMainFrame) return NavigationDecision.navigate;
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;

    if (uri.host == _bundleHost) {
      final path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
      if (path == _current && uri.hasFragment) return NavigationDecision.navigate;
      unawaited(_loadBundle(path.isEmpty ? entry : Uri.decodeComponent(path)));
      return NavigationDecision.prevent;
    }
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

  void _onError(WebResourceError e) {
    if (e.isForMainFrame == false || _disposed) return;
    if (!bundled && !_triedBundle) {
      _triedBundle = true;
      unawaited(_loadBundle(currentEntry));
      return;
    }
    loading = false;
    error = e.description;
    _notify();
  }

  Future<void> _loadBundle(String path) async {
    bundled = true;
    _current = path;
    error = null;
    loading = true;
    _notify();
    final html = await PreviewBundler(source).bundle(path);
    if (_disposed) return;
    final page = html ??
        '<!DOCTYPE html><meta name="viewport" content="width=device-width, '
            'initial-scale=1"><body style="font-family:sans-serif;padding:24px">'
            '<h3>File not found</h3><p>${const HtmlEscapeLite().convert(path)} '
            'does not exist in this project.</p></body>';
    await controller!.loadHtmlString(page, baseUrl: 'https://$_bundleHost/$path');
  }

  Future<void> reload() async {
    final c = controller;
    if (c == null) return;
    if (bundled) {
      await _loadBundle(currentEntry);
    } else {
      await c.clearCache();
      await c.reload();
    }
  }

  /// Starts the local server if needed and returns the page address, for
  /// "Open in Chrome". Null when the phone does not allow a local server.
  Future<String?> ensureServerUrl() async {
    if (_server == null) {
      try {
        _server = await PreviewServer.start(source);
      } catch (_) {
        return null;
      }
    }
    return _server!.urlFor(currentEntry);
  }

  @override
  void dispose() {
    _disposed = true;
    final server = _server;
    if (server != null) unawaited(server.stop());
    super.dispose();
  }
}

/// Tiny HTML escaper for the not-found page.
class HtmlEscapeLite {
  const HtmlEscapeLite();

  String convert(String input) => input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
