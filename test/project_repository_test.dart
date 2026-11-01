import 'dart:io';

import 'package:decode/features/projects/project_repository.dart';
import 'package:decode/features/projects/templates.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late ProjectRepository repo;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('decode_test_');
    repo = ProjectRepository(tmp);
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('create writes linked index.html, style.css and script.js', () async {
    final project = await repo.create(
      name: 'Site',
      template: Templates.htmlCssJs,
    );
    final html = await File(p.join(project.path, 'index.html')).readAsString();
    expect(html, contains('href="style.css"'));
    expect(html, contains('src="script.js"'));
    expect(File(p.join(project.path, 'style.css')).existsSync(), isTrue);
    expect(File(p.join(project.path, 'script.js')).existsSync(), isTrue);
  });

  test('projects persist and list newest first', () async {
    await repo.create(name: 'A', template: Templates.blank);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.create(name: 'B', template: Templates.blank);

    final fresh = ProjectRepository(tmp); // simulates an app restart
    final list = await fresh.list();
    expect(list.map((e) => e.name), ['B', 'A']);
  });

  test('rename updates the name on disk', () async {
    final project = await repo.create(name: 'Old', template: Templates.blank);
    await repo.rename(project, '  New  ');
    expect((await repo.list()).single.name, 'New');
  });

  test('duplicate copies files under a new id', () async {
    final project = await repo.create(
      name: 'Todo',
      template: Templates.todo,
    );
    final copy = await repo.duplicate(project);
    expect(copy.id, isNot(project.id));
    expect(copy.name, 'Todo copy');
    final files = await repo.listFiles(copy);
    expect(files.map((f) => f.$1), ['index.html', 'script.js', 'style.css']);
    expect((await repo.list()).length, 2);
  });

  test('delete removes the project folder', () async {
    final project = await repo.create(name: 'X', template: Templates.blank);
    await repo.delete(project);
    expect(await repo.list(), isEmpty);
    expect(Directory(project.path).existsSync(), isFalse);
  });

  test('listFiles hides metadata and temp files', () async {
    final project = await repo.create(name: 'X', template: Templates.blank);
    final files = await repo.listFiles(project);
    expect(files.map((f) => f.$1), ['index.html']);
  });

  test('writeFile saves content and rejects unsafe names', () async {
    final project = await repo.create(name: 'X', template: Templates.htmlCssJs);
    await repo.writeFile(project, 'script.js', 'console.log(1);');
    expect(await repo.readFile(project, 'script.js'), 'console.log(1);');

    expect(
      () => repo.writeFile(project, '../evil.js', 'x'),
      throwsArgumentError,
    );
    expect(
      () => repo.writeFile(project, '.decode.json', 'x'),
      throwsArgumentError,
    );
  });
}
