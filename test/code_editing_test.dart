import 'package:decode/features/editor/code_editing.dart';
import 'package:decode/features/editor/code_language.dart';
import 'package:decode/features/editor/suggester.dart';
import 'package:decode/features/editor/syntax_highlighter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simulates typing [typed] at the cursor of [before] (cursor marked by |).
TextEditingValue? type(String before, String typed, CodeLanguage lang) {
  final cursor = before.indexOf('|');
  final text = before.replaceFirst('|', '');
  final oldValue = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: cursor),
  );
  final newValue = TextEditingValue(
    text: text.replaceRange(cursor, cursor, typed),
    selection: TextSelection.collapsed(offset: cursor + typed.length),
  );
  return CodeEditing.autoEdit(oldValue, newValue, lang);
}

void main() {
  group('auto edit', () {
    test('closes brackets', () {
      final v = type('foo|', '(', CodeLanguage.js)!;
      expect(v.text, 'foo()');
      expect(v.selection.start, 4);
    });

    test('skips over an existing closer', () {
      final v = type('foo(|)', ')', CodeLanguage.js)!;
      expect(v.text, 'foo()');
      expect(v.selection.start, 5);
    });

    test('does not close a bracket before a word', () {
      expect(type('|abc', '(', CodeLanguage.js), isNull);
    });

    test('pairs quotes but not apostrophes inside words', () {
      expect(type('x = |', '"', CodeLanguage.js)!.text, 'x = ""');
      expect(type("don|", "'", CodeLanguage.js), isNull);
    });

    test('closes html tags and ignores void tags', () {
      final v = type('<div class="a"|', '>', CodeLanguage.html)!;
      expect(v.text, '<div class="a"></div>');
      expect(v.selection.start, '<div class="a">'.length);
      expect(type('<br|', '>', CodeLanguage.html), isNull);
      expect(type('<img src="a"|', '>', CodeLanguage.html), isNull);
    });

    test('keeps indentation on Enter and expands braces', () {
      final v = type('  if (x) {|}', '\n', CodeLanguage.js)!;
      expect(v.text, '  if (x) {\n    \n  }');
      expect(v.selection.start, '  if (x) {\n    '.length);
    });

    test('Enter between html tags opens an indented line', () {
      final v = type('<ul>|</ul>', '\n', CodeLanguage.html)!;
      expect(v.text, '<ul>\n  \n</ul>');
    });

    test('plain characters are left alone', () {
      expect(type('ab|', 'c', CodeLanguage.js), isNull);
    });
  });

  group('highlighter', () {
    const samples = {
      CodeLanguage.html:
          '<!DOCTYPE html>\n<div class="a" id=\'b\'>Hi</div>\n<!-- note -->\n<p',
      CodeLanguage.css:
          '/* c */\n.btn:hover { color: #fff; margin: 0 -2px; content: "x"; }',
      CodeLanguage.js:
          "const a = 'x'; // note\nfunction go(n) { return `t\${n}` + 1.5; }",
    };

    test('spans always rebuild the exact text', () {
      samples.forEach((language, text) {
        final spans = buildSpans(text, language, SyntaxPalette.light);
        expect(spans.map((s) => s.text).join(), text, reason: '$language');
      });
    });

    test('empty and unterminated input do not throw', () {
      for (final language in CodeLanguage.values) {
        for (final text in ['', '"open', '/* open', '<div class="x', '`tpl']) {
          final spans = buildSpans(text, language, SyntaxPalette.dark);
          expect(spans.map((s) => s.text).join(), text);
        }
      }
    });

    test('colours html tags and js keywords', () {
      final html = tokenize('<div>', CodeLanguage.html);
      expect(html.first.kind, TokenKind.tag);
      final js = tokenize('const x = 1;', CodeLanguage.js);
      expect(js.first.kind, TokenKind.keyword);
    });
  });

  group('suggester', () {
    test('suggests html tags after <', () {
      final r = Suggester.suggest('<di', 3, CodeLanguage.html)!;
      expect(r.items.map((s) => s.label), contains('div'));
      expect(r.replaceStart, 1);
    });

    test('suggests css properties and values', () {
      final props = Suggester.suggest('a { col', 7, CodeLanguage.css)!;
      expect(props.items.map((s) => s.label), contains('color'));
      final values = Suggester.suggest('a { display: fl', 15, CodeLanguage.css)!;
      expect(values.items.map((s) => s.label), contains('flex'));
    });

    test('suggests js members after a dot', () {
      final r = Suggester.suggest('document.getEl', 14, CodeLanguage.js)!;
      expect(r.items.map((s) => s.label), contains('getElementById'));
    });

    test('returns null when nothing matches', () {
      expect(Suggester.suggest('zzzz', 4, CodeLanguage.js), isNull);
    });
  });
}
