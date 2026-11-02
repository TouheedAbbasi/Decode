import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/storage/atomic_file.dart';

import 'project.dart';
import 'templates.dart';

/// Stores every project as a folder under [root]:
///
///   root/<id>/.decode.json   (metadata)
///   root/<id>/index.html ... (user files)
///
/// No database is needed yet; SQLite can be added later if search/indexing
/// requires it.
class ProjectRepository {
  ProjectRepository(this.root);

  final Directory root;

  static const metaFileName = '.decode.json';

  Future<List<Project>> list() async {
    final result = <Project>[];
    if (!await root.exists()) return result;
    await for (final entity in root.list()) {
      if (entity is! Directory) continue;
      final meta = File(p.join(entity.path, metaFileName));
      if (!await meta.exists()) continue;
      try {
        final json =
            jsonDecode(await meta.readAsString()) as Map<String, dynamic>;
        result.add(Project.fromJson(json, entity.path));
      } catch (_) {
        // Skip corrupt metadata instead of crashing the whole list.
        continue;
      }
    }
    result.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return result;
  }

  Future<Project> create({
    required String name,
    required ProjectTemplate template,
  }) async {
    await root.create(recursive: true);
    final id = await _newId();
    final dir = Directory(p.join(root.path, id));
    await dir.create(recursive: true);
    try {
      for (final entry in template.files.entries) {
        await _writeAtomic(File(p.join(dir.path, entry.key)), entry.value);
      }
      final now = DateTime.now();
      final project = Project(
        id: id,
        name: name.trim(),
        createdAt: now,
        modifiedAt: now,
        template: template.id,
        path: dir.path,
      );
      await _writeMeta(project);
      return project;
    } catch (_) {
      if (await dir.exists()) await dir.delete(recursive: true);
      rethrow;
    }
  }

  Future<Project> rename(Project project, String newName) async {
    final updated = project.copyWith(
      name: newName.trim(),
      modifiedAt: DateTime.now(),
    );
    await _writeMeta(updated);
    return updated;
  }

  Future<Project> duplicate(Project project) async {
    final id = await _newId();
    final target = Directory(p.join(root.path, id));
    await target.create(recursive: true);
    try {
      final source = Directory(project.path);
      await for (final entity in source.list(recursive: true)) {
        if (entity is! File) continue;
        final relative = p.relative(entity.path, from: source.path);
        if (relative == metaFileName || relative.endsWith('.tmp')) continue;
        final dest = File(p.join(target.path, relative));
        await dest.parent.create(recursive: true);
        await entity.copy(dest.path);
      }
      final now = DateTime.now();
      final copy = Project(
        id: id,
        name: '${project.name} copy',
        createdAt: now,
        modifiedAt: now,
        template: project.template,
        path: target.path,
      );
      await _writeMeta(copy);
      return copy;
    } catch (_) {
      if (await target.exists()) await target.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> delete(Project project) async {
    final dir = Directory(project.path);
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// Visible files of a project (name, size in bytes), sorted by name.
  Future<List<(String, int)>> listFiles(Project project) async {
    final files = <(String, int)>[];
    final dir = Directory(project.path);
    if (!await dir.exists()) return files;
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (name == metaFileName || name.endsWith('.tmp')) continue;
      files.add((name, await entity.length()));
    }
    files.sort((a, b) => a.$1.compareTo(b.$1));
    return files;
  }

  /// Marks a project as just modified (used after the editor saves a file).
  Future<void> touch(Project project) =>
      _writeMeta(project.copyWith(modifiedAt: DateTime.now()));

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
  };

  Future<String> readFile(Project project, String fileName) =>
      File(p.join(project.path, _safeFileName(fileName))).readAsString();

  /// Saves one file and bumps the project's modified time.
  Future<void> writeFile(
    Project project,
    String fileName,
    String content,
  ) async {
    final name = _safeFileName(fileName);
    await _writeAtomic(File(p.join(project.path, name)), content);
    await _writeMeta(project.copyWith(modifiedAt: DateTime.now()));
  }

  /// Only plain file names are accepted: no folders, no hidden files.
  String _safeFileName(String name) {
    if (name.isEmpty ||
        name != p.basename(name) ||
        name.startsWith('.') ||
        name.contains(r'\')) {
      throw ArgumentError.value(name, 'fileName', 'Invalid file name');
    }
    return name;
  }

  Future<String> _newId() async {
    var id = DateTime.now().microsecondsSinceEpoch.toString();
    var n = 0;
    while (await Directory(p.join(root.path, id)).exists()) {
      n++;
      id = '${DateTime.now().microsecondsSinceEpoch}_$n';
    }
    return id;
  }

  Future<void> _writeMeta(Project project) => _writeAtomic(
        File(p.join(project.path, metaFileName)),
        jsonEncode(project.toJson()),
      );

  Future<void> _writeAtomic(File file, String content) =>
      writeFileAtomic(file, content);
}
