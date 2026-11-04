import 'package:decode/features/components/component_item.dart';
import 'package:decode/features/components/component_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _item = ComponentItem(
  id: 'x',
  name: 'Demo',
  description: 'd',
  category: 'UI',
  icon: Icons.extension_outlined,
  html: '<p>hi</p>',
  css: 'p { color: red; }',
  js: 'console.log(1);',
);

void main() {
  test('component files are linked together', () {
    final files = _item.toFiles();
    final html = files['index.html']!;
    expect(html, contains('href="style.css"'));
    expect(html, contains('src="script.js"'));
    expect(files.keys, containsAll(['index.html', 'style.css', 'script.js']));
  });

  test('no script file when the component has no js', () {
    final files = _item.copyWith(js: '').toFiles();
    expect(files.containsKey('script.js'), isFalse);
    expect(files['index.html'], isNot(contains('script.js')));
  });

  test('bodyOf strips wrapper and script tag', () {
    const doc = '<html><body>\n<p>Hi</p>\n<script src="script.js"></script>\n'
        '</body></html>';
    expect(bodyOf(doc), '<p>Hi</p>');
  });

  test('JSON round trip keeps user components', () {
    final back = ComponentItem.fromJson(_item.toJson());
    expect(back.name, 'Demo');
    expect(back.css, contains('red'));
    expect(back.isUser, isTrue);
  });

  test('categories for filing components', () {
    expect(userCategories, contains('Glassmorphism'));
    expect(userCategories, isNot(contains('All')));
  });
}
