import 'dart:io';

import 'package:decode/features/editor/workspace.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late DirectoryWorkspace workspace;
  var saved = 0;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('decode_ws_');
    File(p.join(tmp.path, 'index.html')).writeAsStringSync('<h1>Hi</h1>');
    Directory(p.join(tmp.path, 'css')).createSync();
    File(p.join(tmp.path, 'css', 'style.css')).writeAsStringSync('a{}');
    File(p.join(tmp.path, 'logo.png')).writeAsBytesSync([1, 2, 3]);
    File(p.join(tmp.path, '.decode.json')).writeAsStringSync('{}');
    Directory(p.join(tmp.path, '.git')).createSync();
    saved = 0;
    workspace = DirectoryWorkspace(
      rootPath: tmp.path,
      title: 'Site',
      hiddenNames: const {'.decode.json'},
      onSaved: () async => saved++,
    );
  });

  tearDown(() => tmp.delete(recursive: true));

  test('lists folders first and hides internal files', () async {
    final root = await workspace.list('');
    expect(root.map((e) => e.path), ['css', 'index.html', 'logo.png']);
    expect(root.first.isDirectory, isTrue);

    final css = await workspace.list('css');
    expect(css.single.path, 'css/style.css');
    expect(css.single.name, 'style.css');
  });

  test('knows which files can be edited', () {
    expect(workspace.isEditable('index.html'), isTrue);
    expect(workspace.isEditable('css/style.css'), isTrue);
    expect(workspace.isEditable('logo.png'), isFalse);
  });

  test('reads and saves in place, including sub folders', () async {
    expect(await workspace.read('css/style.css'), 'a{}');
    await workspace.write('css/style.css', 'body{}');
    expect(File(p.join(tmp.path, 'css', 'style.css')).readAsStringSync(), 'body{}');
    expect(saved, 1);
  });

  test('non-atomic workspaces save directly', () async {
    final direct = DirectoryWorkspace(rootPath: tmp.path, title: 'x', atomic: false);
    await direct.write('index.html', 'new');
    expect(File(p.join(tmp.path, 'index.html')).readAsStringSync(), 'new');
    expect(File(p.join(tmp.path, 'index.html.tmp')).existsSync(), isFalse);
  });

  test('creates files and folders, refuses duplicates', () async {
    await workspace.createFile('js/app.js');
    expect(File(p.join(tmp.path, 'js', 'app.js')).existsSync(), isTrue);
    await workspace.createFolder('img');
    expect(Directory(p.join(tmp.path, 'img')).existsSync(), isTrue);
    expect(() => workspace.createFile('index.html'), throwsA(isA<FileSystemException>()));
  });

  test('never leaves the project folder', () async {
    expect(() => workspace.read('../secret.txt'), throwsArgumentError);
    expect(() => workspace.write('../evil.js', 'x'), throwsArgumentError);
    expect(() => workspace.read('/etc/passwd'), throwsArgumentError);
    expect(() => workspace.list('..'), throwsArgumentError);
  });

  test('refuses files that are too big', () async {
    final big = File(p.join(tmp.path, 'big.txt'))
      ..writeAsStringSync('x' * (DirectoryWorkspace.maxEditableBytes + 10));
    expect(big.existsSync(), isTrue);
    expect(() => workspace.read('big.txt'), throwsA(isA<FileSystemException>()));
  });

  test('imports a file into a folder with a safe, unique name', () async {
    final source = File(p.join(tmp.path, 'My Photo (1).PNG'))
      ..writeAsBytesSync([9, 9, 9]);
    final first = await workspace.importFile(source.path, 'img');
    expect(first, 'img/My-Photo-1-.png');
    expect(File(p.join(tmp.path, first)).readAsBytesSync(), [9, 9, 9]);

    final second = await workspace.importFile(source.path, 'img');
    expect(second, 'img/My-Photo-1--1.png');
    expect(() => workspace.importFile(source.path, '../x'), throwsArgumentError);
  });
}
