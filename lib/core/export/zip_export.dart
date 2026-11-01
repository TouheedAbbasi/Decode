import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../../features/projects/project.dart';
import '../../features/projects/project_repository.dart';

/// "My Cool App!" -> "My_Cool_App"
String safeArchiveName(String name) {
  final cleaned = name
      .replaceAll(RegExp(r'[^\w\- ]+'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');
  return cleaned.isEmpty ? 'project' : cleaned;
}

/// Zips the user's files of [project] (never the internal metadata) into
/// [outDir] and returns the ZIP file.
Future<File> buildProjectZip(Project project, Directory outDir) async {
  final root = Directory(project.path);
  final archive = Archive();

  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final relative = p.relative(entity.path, from: root.path);
    final base = p.basename(relative);
    if (base == ProjectRepository.metaFileName || base.endsWith('.tmp')) {
      continue;
    }
    final bytes = await entity.readAsBytes();
    archive.addFile(
      ArchiveFile(relative.replaceAll('\\', '/'), bytes.length, bytes),
    );
  }

  if (archive.files.isEmpty) {
    throw StateError('This project has no files to export.');
  }
  final data = ZipEncoder().encode(archive);
  if (data == null) throw StateError('Could not create the ZIP file.');

  await outDir.create(recursive: true);
  final file = File(p.join(outDir.path, '${safeArchiveName(project.name)}.zip'));
  await file.writeAsBytes(data, flush: true);
  return file;
}
