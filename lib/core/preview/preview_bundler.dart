import 'dart:convert';

import 'package:path/path.dart' as p;

import 'preview_source.dart';

/// Turns a page plus its local CSS, JS and images into ONE self-contained
/// HTML document. The in-app preview uses it when the WebView is not allowed
/// to open `http://127.0.0.1` (a missing Android network-security setting),
/// so the preview works either way.
class PreviewBundler {
  PreviewBundler(this.source);

  final PreviewSource source;

  static const maxAssetBytes = 2 * 1024 * 1024;

  static final _link = RegExp(r'<link\b[^>]*>', caseSensitive: false);
  static final _script =
      RegExp(r'<script\b([^>]*)>\s*</script\s*>', caseSensitive: false);
  static final _img = RegExp(r'<img\b[^>]*>', caseSensitive: false);
  static final _cssUrl = RegExp(r'''url\(\s*(["']?)([^)"']+)\1\s*\)''');
  static final _stylesheet =
      RegExp(r'''rel\s*=\s*["']?stylesheet''', caseSensitive: false);

  static const _mime = {
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif': 'image/gif',
    '.webp': 'image/webp',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon',
    '.woff2': 'font/woff2',
    '.woff': 'font/woff',
    '.ttf': 'font/ttf',
  };

  /// The bundled document for [entry] (a path relative to the project), or
  /// null when that file does not exist.
  Future<String?> bundle(String entry) async {
    final bytes = await source.read(entry);
    if (bytes == null) return null;
    var html = utf8.decode(bytes, allowMalformed: true);
    final dir = _dirOf(entry);

    html = await _replace(html, _link, (m) async {
      final tag = m[0]!;
      if (!_stylesheet.hasMatch(tag)) return tag;
      final path = _resolve(dir, _attr(tag, 'href'));
      if (path == null) return tag;
      final css = await _text(path);
      if (css == null) return tag;
      return '<style>\n${await _inlineCssUrls(css, _dirOf(path))}\n</style>';
    });

    html = await _replace(html, _script, (m) async {
      final attrs = m[1]!;
      final path = _resolve(dir, _attr(attrs, 'src'));
      if (path == null) return m[0]!;
      final js = await _text(path);
      if (js == null) return m[0]!;
      final rest = attrs
          .replaceAll(RegExp(r'''\bsrc\s*=\s*(?:"[^"]*"|'[^']*'|[^\s>]+)'''), '')
          .trim();
      final safe = js.replaceAll('</script', r'<\/script');
      return '<script${rest.isEmpty ? '' : ' $rest'}>\n$safe\n</script>';
    });

    html = await _replace(html, _img, (m) async {
      final tag = m[0]!;
      final src = _attr(tag, 'src');
      final path = _resolve(dir, src);
      if (path == null) return tag;
      final uri = await _dataUri(path);
      return uri == null ? tag : tag.replaceFirst(src, uri);
    });

    return html;
  }

  Future<String> _inlineCssUrls(String css, String cssDir) {
    return _replace(css, _cssUrl, (m) async {
      final path = _resolve(cssDir, m[2]!);
      if (path == null) return m[0]!;
      final uri = await _dataUri(path);
      return uri == null ? m[0]! : 'url("$uri")';
    });
  }

  Future<String> _replace(
    String input,
    RegExp pattern,
    Future<String> Function(RegExpMatch) replacement,
  ) async {
    final out = StringBuffer();
    var last = 0;
    for (final match in pattern.allMatches(input)) {
      out.write(input.substring(last, match.start));
      out.write(await replacement(match));
      last = match.end;
    }
    out.write(input.substring(last));
    return out.toString();
  }

  Future<String?> _text(String path) async {
    final bytes = await source.read(path);
    return bytes == null ? null : utf8.decode(bytes, allowMalformed: true);
  }

  Future<String?> _dataUri(String path) async {
    final bytes = await source.read(path);
    if (bytes == null || bytes.length > maxAssetBytes) return null;
    final mime = _mime[p.posix.extension(path).toLowerCase()] ??
        'application/octet-stream';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  static String _dirOf(String path) {
    final dir = p.posix.dirname(path);
    return dir == '.' ? '' : dir;
  }

  static String _attr(String tag, String name) {
    final match = RegExp(
      '\\b$name\\s*=\\s*(?:"([^"]*)"|\'([^\']*)\'|([^\\s>]+))',
      caseSensitive: false,
    ).firstMatch(tag);
    return match?.group(1) ?? match?.group(2) ?? match?.group(3) ?? '';
  }

  /// A project-relative path, or null for remote / data / empty references.
  static String? _resolve(String dir, String ref) {
    final value = ref.trim();
    if (value.isEmpty ||
        value.startsWith('#') ||
        value.startsWith('//') ||
        RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(value)) {
      return null;
    }
    final clean = value.split('#').first.split('?').first;
    final joined =
        clean.startsWith('/') ? clean.substring(1) : p.posix.join(dir, clean);
    final normalized = p.posix.normalize(joined);
    if (normalized.startsWith('..') || normalized.isEmpty) return null;
    return normalized;
  }
}
