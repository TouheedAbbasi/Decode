import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Where preview files come from. The preview server asks for a relative
/// path like `index.html` or `img/logo.png` and gets bytes or null.
abstract class PreviewSource {
  Future<List<int>?> read(String path);
}

/// Files held in memory (used for the component quick preview).
class MemorySource implements PreviewSource {
  MemorySource(this.files);

  final Map<String, String> files;

  @override
  Future<List<int>?> read(String path) async {
    final content = files[path];
    return content == null ? null : utf8.encode(content);
  }
}

/// Files from a project folder. Anything outside [root] is refused.
class DirectorySource implements PreviewSource {
  DirectorySource(this.root);

  final Directory root;

  @override
  Future<List<int>?> read(String path) async {
    final rootPath = p.normalize(p.absolute(root.path));
    final target = p.normalize(p.join(rootPath, path));
    if (!p.isWithin(rootPath, target)) return null;

    final name = p.basename(target);
    if (name.startsWith('.') || name.endsWith('.tmp')) return null;

    final file = File(target);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }
}

/// Unsaved editor text wins; everything else falls back to [base].
class OverlaySource implements PreviewSource {
  OverlaySource({required this.overrides, this.base});

  final Map<String, String> Function() overrides;
  final PreviewSource? base;

  @override
  Future<List<int>?> read(String path) async {
    final override = overrides()[path];
    if (override != null) return utf8.encode(override);
    return base?.read(path);
  }
}
