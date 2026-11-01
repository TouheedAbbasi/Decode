import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'project.dart';
import 'project_repository.dart';
import 'templates.dart';

final projectRepositoryProvider = FutureProvider<ProjectRepository>((ref) async {
  final docs = await getApplicationDocumentsDirectory();
  final root = Directory(p.join(docs.path, 'projects'));
  await root.create(recursive: true);
  return ProjectRepository(root);
});

class ProjectsNotifier extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() async {
    final repo = await ref.watch(projectRepositoryProvider.future);
    return repo.list();
  }

  Future<ProjectRepository> get _repo =>
      ref.read(projectRepositoryProvider.future);

  Future<void> _reload() async {
    final repo = await _repo;
    state = AsyncData(await repo.list());
  }

  Future<Project> create({
    required String name,
    required ProjectTemplate template,
  }) async {
    final repo = await _repo;
    final project = await repo.create(name: name, template: template);
    await _reload();
    return project;
  }

  Future<void> rename(Project project, String name) async {
    final repo = await _repo;
    await repo.rename(project, name);
    await _reload();
  }

  Future<void> duplicate(Project project) async {
    final repo = await _repo;
    await repo.duplicate(project);
    await _reload();
  }

  Future<void> delete(Project project) async {
    final repo = await _repo;
    await repo.delete(project);
    await _reload();
  }

  Future<void> saveFile(Project project, String fileName, String text) async {
    final repo = await _repo;
    await repo.writeFile(project, fileName, text);
    await _reload();
  }
}

final projectsProvider =
    AsyncNotifierProvider<ProjectsNotifier, List<Project>>(
  ProjectsNotifier.new,
);
