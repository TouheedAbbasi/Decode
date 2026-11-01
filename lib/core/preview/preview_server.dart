import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'preview_source.dart';

/// A tiny read-only HTTP server bound to the loopback interface only.
///
/// Both the in-app WebView and "Open in Chrome" load pages from it, so
/// relative links such as `style.css` behave the same in both. It lives only
/// while the preview screen is open.
class PreviewServer {
  PreviewServer._(this._server, this.source);

  final HttpServer _server;
  final PreviewSource source;

  int get port => _server.port;

  String get baseUrl => 'http://127.0.0.1:$port';

  String urlFor(String path) => '$baseUrl/$path';

  static Future<PreviewServer> start(PreviewSource source) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final preview = PreviewServer._(server, source);
    server.listen(preview._handle, onError: (Object _) {});
    return preview;
  }

  Future<void> stop() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    try {
      if (request.method != 'GET' && request.method != 'HEAD') {
        response.statusCode = HttpStatus.methodNotAllowed;
        await response.close();
        return;
      }

      var path = Uri.decodeComponent(request.uri.path);
      if (path.endsWith('/')) path = '${path}index.html';
      final relative = path.startsWith('/') ? path.substring(1) : path;

      final bytes = await source.read(relative);
      if (bytes == null) {
        response.statusCode = HttpStatus.notFound;
        response.headers.contentType = ContentType.html;
        response.write(
          '<!DOCTYPE html><meta name="viewport" '
          'content="width=device-width, initial-scale=1">'
          '<body style="font-family:sans-serif;padding:24px">'
          '<h3>404 - File not found</h3>'
          '<p>${HtmlEscape().convert(relative)} does not exist in this '
          'project.</p></body>',
        );
        await response.close();
        return;
      }

      response.headers.contentType = _contentType(relative);
      response.headers.set('Cache-Control', 'no-store');
      response.headers.set('X-Content-Type-Options', 'nosniff');
      if (request.method != 'HEAD') response.add(bytes);
      await response.close();
    } catch (_) {
      try {
        response.statusCode = HttpStatus.internalServerError;
        await response.close();
      } catch (_) {
        // The client already went away.
      }
    }
  }

  ContentType _contentType(String path) {
    switch (p.extension(path).toLowerCase()) {
      case '.html':
      case '.htm':
        return ContentType('text', 'html', charset: 'utf-8');
      case '.css':
        return ContentType('text', 'css', charset: 'utf-8');
      case '.js':
      case '.mjs':
        return ContentType('text', 'javascript', charset: 'utf-8');
      case '.json':
        return ContentType('application', 'json', charset: 'utf-8');
      case '.svg':
        return ContentType('image', 'svg+xml');
      case '.png':
        return ContentType('image', 'png');
      case '.jpg':
      case '.jpeg':
        return ContentType('image', 'jpeg');
      case '.gif':
        return ContentType('image', 'gif');
      case '.webp':
        return ContentType('image', 'webp');
      case '.ico':
        return ContentType('image', 'x-icon');
      case '.woff2':
        return ContentType('font', 'woff2');
      case '.txt':
      case '.md':
        return ContentType('text', 'plain', charset: 'utf-8');
      default:
        return ContentType('application', 'octet-stream');
    }
  }
}
