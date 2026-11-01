import 'package:decode/features/components/component_item.dart';
import 'package:decode/features/components/component_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('component ids are unique and content is not empty', () {
    final ids = componentLibrary.map((c) => c.id).toSet();
    expect(ids.length, componentLibrary.length);
    for (final c in componentLibrary) {
      expect(c.html.trim(), isNotEmpty, reason: c.id);
      expect(componentCategories, contains(c.category), reason: c.id);
    }
  });

  test('every component builds linked project files', () {
    for (final c in componentLibrary) {
      final files = c.toFiles();
      final html = files['index.html']!;
      expect(html, contains('href="style.css"'), reason: c.id);
      expect(files.containsKey('style.css'), isTrue, reason: c.id);
      if (c.js.isNotEmpty) {
        expect(html, contains('src="script.js"'), reason: c.id);
        expect(files.containsKey('script.js'), isTrue, reason: c.id);
      } else {
        expect(html, isNot(contains('script.js')), reason: c.id);
      }
    }
  });

  test('bodyOf strips wrapper and script tag', () {
    const doc = '<html><body>\n<p>Hi</p>\n<script src="script.js"></script>\n'
        '</body></html>';
    expect(bodyOf(doc), '<p>Hi</p>');
  });

  test('template components include full pages', () {
    final portfolio = componentLibrary.firstWhere((c) => c.id == 'portfolio');
    expect(portfolio.html, isNot(contains('<!DOCTYPE')));
    expect(portfolio.html, contains('class="header"'));
  });

  test('every design style has card, buttons and login', () {
    const styles = [
      'Neumorphism',
      'Glassmorphism',
      'Minimal',
      'Gradient',
      'Dark UI',
      'Brutalism',
    ];
    for (final style in styles) {
      final items = componentLibrary.where((c) => c.category == style);
      expect(items.length, 3, reason: style);
      expect(componentCategories, contains(style));
    }
  });

  test('user components survive a JSON round trip', () {
    const item = ComponentItem(
      id: 'u_1',
      name: 'Mine',
      description: 'desc',
      category: 'UI',
      icon: Icons.extension_outlined,
      html: '<p>hi</p>',
      css: 'p { color: red; }',
      isUser: true,
    );
    final back = ComponentItem.fromJson(item.toJson());
    expect(back.name, 'Mine');
    expect(back.html, '<p>hi</p>');
    expect(back.css, contains('red'));
    expect(back.isUser, isTrue);
  });
}
