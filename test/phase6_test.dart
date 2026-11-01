import 'dart:io';

import 'package:archive/archive.dart';
import 'package:decode/core/export/zip_export.dart';
import 'package:decode/features/components/component_backup.dart';
import 'package:decode/features/components/component_item.dart';
import 'package:decode/features/projects/project_repository.dart';
import 'package:decode/features/projects/templates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _categories = ['UI', 'Forms', 'Minimal'];

ComponentItem _item(String name, {String category = 'Forms'}) => ComponentItem(
      id: 'x',
      name: name,
      description: 'desc',
      category: category,
      icon: Icons.extension_outlined,
      html: '<p>$name</p>',
      css: 'p { color: red; }',
      js: 'console.log(1);',
      isUser: true,
    );

void main() {
  group('backup', () {
    test('round trip keeps content and assigns new ids', () {
      final text = encodeBackup([_item('A'), _item('B', category: 'Minimal')]);
      final back = decodeBackup(text, idPrefix: 'u_9', categories: _categories);
      expect(back.map((c) => c.name), ['A', 'B']);
      expect(back.map((c) => c.id), ['u_9_0', 'u_9_1']);
      expect(back[1].category, 'Minimal');
      expect(back[0].css, contains('red'));
      expect(back.every((c) => c.isUser), isTrue);
    });

    test('unknown category falls back to UI and bad entries are skipped', () {
      const text = '{"components":['
          '{"name":"Ok","html":"<b>x</b>","category":"Nope"},'
          '{"name":"","html":"<b>y</b>"},'
          '{"name":"NoHtml","html":"  "},'
          '42]}';
      final back = decodeBackup(text, idPrefix: 'p', categories: _categories);
      expect(back.length, 1);
      expect(back.single.category, 'UI');
    });

    test('invalid text gives a readable error', () {
      expect(
        () => decodeBackup('hello', idPrefix: 'p', categories: _categories),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => decodeBackup('{"a":1}', idPrefix: 'p', categories: _categories),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => decodeBackup('[]', idPrefix: 'p', categories: _categories),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('zip export', () {
    test('safeArchiveName cleans the project name', () {
      expect(safeArchiveName('My Cool App!'), 'My_Cool_App');
      expect(safeArchiveName('???'), 'project');
    });

    test('zip contains user files only', () async {
      final tmp = await Directory.systemTemp.createTemp('decode_zip_');
      addTearDown(() => tmp.delete(recursive: true));
      final repo = ProjectRepository(Directory('${tmp.path}/projects'));
      final project = await repo.create(
        name: 'Site',
        template: Templates.htmlCssJs,
      );

      final zip = await buildProjectZip(project, Directory('${tmp.path}/out'));
      expect(zip.path, endsWith('Site.zip'));

      final archive = ZipDecoder().decodeBytes(await zip.readAsBytes());
      final names = archive.files.map((f) => f.name).toList()..sort();
      expect(names, ['index.html', 'script.js', 'style.css']);
    });
  });
}
