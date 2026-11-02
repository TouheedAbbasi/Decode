import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/storage/atomic_file.dart';

class WorkspaceEntry {
  const WorkspaceEntry({required this.path, required this.isDirectory});

  /// Relative to the workspace root, always with `/` separators.
  final String path;
  final bool isDirectory;

  String get name =>
      path.contains('/') ? path.substring(path.lastIndexOf('/') + 1) : path;
}

/// A folder of files the editor can browse, open and save.
///
/// It is used both for Decode's own projects and for real folders on the
/// phone's storage.
abstract class Workspace {
  String get title;

  /// Absolute folder on disk (also used by the preview server).
  String get rootPath;

  bool isEditable(String path);

  /// Direct children of [dir] (`''` is the root), folders first.
  Future<List<WorkspaceEntry>> list(String dir);

  Future<String> read(String path);

  Future<void> write(String path, String content);

  Future<void> createFile(String path);

  Future<void> createFolder(String path);
}

class DirectoryWorkspace implements Workspace {
  DirectoryWorkspace({
    required this.rootPath,
    required this.title,
    this.atomic = true,
    this.hiddenNames = const {},
    this.onSaved,
  });

  @override
  final String rootPath;

  @override
  final String title;

  /// Write through a temp file + rename. Turned off for folders on shared
  /// storage so the original file keeps its identity.
  final bool atomic;

  /// Names never shown in the file list (for example internal metadata).
  final Set<String> hiddenNames;

  /// Called after every successful save.
  final Future<void> Function()? onSaved;

  static const editableExtensions = {
    '.html',
    '.htm',
    '.css',
    '.js',
    '.mjs',
    '.json',
    '.txt',
    '.md',
    '.svg',
    '.xml',
  };

  static const maxEditableBytes = 1500000;

  static const _alwaysHidden = {'.git', 'node_modules', '.DS_Store'};

  @override
  bool isEditable(String path) {
    final extension = p.extension(path).toLowerCase();
    return editableExtensions.contains(extension);
  }

  /// Turns a relative path into a file inside the root. Anything that would
  /// escape the root (`../`, absolute paths) is refused.
  String _resolve(String relative) {
    final root = p.normalize(p.absolute(rootPath));
    final target = p.normalize(p.join(root, relative));
    if (target != root && !p.isWithin(root, target)) {
      throw ArgumentError.value(relative, 'path', 'Outside of the project');
    }
    return target;
  }

  @override
  Future<List<WorkspaceEntry>> list(String dir) async {
    final directory = Directory(_resolve(dir));
    final entries = <WorkspaceEntry>[];
    await for (final entity in directory.list(followLinks: false)) {
      final name = p.basename(entity.path);
      if (hiddenNames.contains(name) ||
          _alwaysHidden.contains(name) ||
          name.endsWith('.tmp')) {
        continue;
      }
      entries.add(
        WorkspaceEntry(
          path: dir.isEmpty ? name : '$dir/$name',
          isDirectory: entity is Directory,
        ),
      );
    }
    entries.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return entries;
  }

  @override
  Future<String> read(String path) async {
    final file = File(_resolve(path));
    if (await file.length() > maxEditableBytes) {
      throw const FileSystemException('This file is too large to edit.');
    }
    try {
      return await file.readAsString();
    } on FormatException {
      throw const FileSystemException('This file is not plain text.');
    }
  }

  @override
  Future<void> write(String path, String content) async {
    final file = File(_resolve(path));
    if (atomic) {
      await writeFileAtomic(file, content);
    } else {
      await file.writeAsString(content, flush: true);
    }
    await onSaved?.call();
  }

  @override
  Future<void> createFile(String path) async {
    final file = File(_resolve(path));
    if (await file.exists()) {
      throw const FileSystemException('A file with this name already exists.');
    }
    await file.create(recursive: true);
  }

  @override
  Future<void> createFolder(String path) async {
    await Directory(_resolve(path)).create(recursive: true);
  }
}
