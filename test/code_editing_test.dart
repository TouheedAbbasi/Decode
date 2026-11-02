import 'package:decode/features/editor/code_actions.dart';
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

    test('html colours embedded style and script blocks', () {
      const doc =
          '<style>a { color: #fff; }</style>\n<script>if (a<b) { go("x"); }</script>';
      final spans = buildSpans(doc, CodeLanguage.html, SyntaxPalette.light);
      expect(spans.map((s) => s.text).join(), doc);
      final kinds = tokenize(doc, CodeLanguage.html).map((t) => t.kind).toSet();
      expect(kinds, containsAll([TokenKind.property, TokenKind.keyword]));
    });

    test('colours html tags and js keywords', () {
      final html = tokenize('<div>', CodeLanguage.html);
      expect(html.first.kind, TokenKind.tag);
      final js = tokenize('const x = 1;', CodeLanguage.js);
      expect(js.first.kind, TokenKind.keyword);
    });
  });

  group('suggester', () {
    List<String> labels(SuggestionResult? r) =>
        r == null ? [] : r.items.map((s) => s.label).toList();

    test('html text: typing a tag name offers the full element', () {
      const text = '<body>\n  art';
      final r = Suggester.suggest(text, text.length, CodeLanguage.html)!;
      expect(labels(r), contains('article'));
      final article = r.items.firstWhere((s) => s.label == 'article');
      expect(
        article.template.replaceAll(caretMarker, ''),
        '<article></article>',
      );
      expect(article.template.indexOf(caretMarker), '<article>'.length);
      expect(r.replaceStart, text.length - 3);
    });

    test('html: after < the whole <tag> is replaced', () {
      final r = Suggester.suggest('<di', 3, CodeLanguage.html)!;
      expect(labels(r), contains('div'));
      expect(r.replaceStart, 0);
    });

    test('html: attributes inside a tag', () {
      const text = '<a hr';
      final r = Suggester.suggest(text, text.length, CodeLanguage.html)!;
      expect(labels(r), contains('href'));
    });

    test('one-letter prose does not trigger html snippets', () {
      expect(Suggester.suggest('<p>a', 4, CodeLanguage.html), isNull);
    });

    test('css properties and values only inside a rule', () {
      final props = Suggester.suggest('a { col', 7, CodeLanguage.css)!;
      expect(labels(props), contains('color'));
      final values = Suggester.suggest('a { display: fl', 15, CodeLanguage.css)!;
      expect(labels(values), contains('flex'));
      expect(Suggester.suggest('col', 3, CodeLanguage.css), isNull);
    });

    test('js members after a dot and snippets', () {
      final r = Suggester.suggest('document.getEl', 14, CodeLanguage.js)!;
      expect(labels(r), contains('getElementById'));
      final log = Suggester.suggest('lo', 2, CodeLanguage.js)!;
      expect(labels(log), contains('log'));
    });

    test('code inside <script> and <style> in html gets js / css help', () {
      const script = '<script>\ncon';
      expect(
        labels(Suggester.suggest(script, script.length, CodeLanguage.html)),
        contains('console'),
      );
      const style = '<style>\n.a { col';
      expect(
        labels(Suggester.suggest(style, style.length, CodeLanguage.html)),
        contains('color'),
      );
    });

    test('returns null when nothing matches', () {
      expect(Suggester.suggest('zzzz', 4, CodeLanguage.js), isNull);
    });
  });

  group('effective language', () {
    test('switches inside style and script blocks only', () {
      const doc = '<style>a{}</style><p>x</p><script>var a;</script>';
      expect(
        effectiveLanguage(doc, doc.indexOf('a{}') + 1, CodeLanguage.html),
        CodeLanguage.css,
      );
      expect(
        effectiveLanguage(doc, doc.indexOf('<p>') + 4, CodeLanguage.html),
        CodeLanguage.html,
      );
      expect(
        effectiveLanguage(doc, doc.indexOf('var') + 2, CodeLanguage.html),
        CodeLanguage.js,
      );
      expect(effectiveLanguage('a', 1, CodeLanguage.css), CodeLanguage.css);
    });
  });

  group('smart delete and block actions', () {
    test('backspace on an auto-closed pair removes both', () {
      const old = TextEditingValue(
        text: 'f()',
        selection: TextSelection.collapsed(offset: 2),
      );
      const typed = TextEditingValue(
        text: 'f)',
        selection: TextSelection.collapsed(offset: 1),
      );
      final v = CodeEditing.smartEdit(old, typed, CodeLanguage.js)!;
      expect(v.text, 'f');
      expect(v.selection.start, 1);
    });

    test('backspace on a normal character is untouched', () {
      const old = TextEditingValue(
        text: 'ab',
        selection: TextSelection.collapsed(offset: 2),
      );
      const typed = TextEditingValue(
        text: 'a',
        selection: TextSelection.collapsed(offset: 1),
      );
      expect(CodeEditing.smartEdit(old, typed, CodeLanguage.js), isNull);
    });

    test('typing > of <script still closes the tag', () {
      final v = type('<script|', '>', CodeLanguage.html);
      // goes through autoEdit directly, as the formatter would
      expect(v?.text, '<script></script>');
    });

    test('indent and outdent a block', () {
      const value = TextEditingValue(
        text: 'a\nb\nc',
        selection: TextSelection(baseOffset: 0, extentOffset: 3),
      );
      final indented = CodeActions.indent(value, outdent: false);
      expect(indented.text, '  a\n  b\nc');
      final back = CodeActions.indent(indented, outdent: true);
      expect(back.text, 'a\nb\nc');
    });

    test('toggle comment per language', () {
      const js = TextEditingValue(
        text: '  run();',
        selection: TextSelection.collapsed(offset: 4),
      );
      final on = CodeActions.toggleComment(js, CodeLanguage.js);
      expect(on.text, '  // run();');
      expect(CodeActions.toggleComment(on, CodeLanguage.js).text, '  run();');

      const css = TextEditingValue(
        text: 'color: red;',
        selection: TextSelection.collapsed(offset: 0),
      );
      final wrapped = CodeActions.toggleComment(css, CodeLanguage.css);
      expect(wrapped.text, '/* color: red; */');
      expect(
        CodeActions.toggleComment(wrapped, CodeLanguage.css).text,
        'color: red;',
      );

      const html = TextEditingValue(
        text: '<p>x</p>',
        selection: TextSelection.collapsed(offset: 0),
      );
      final commented = CodeActions.toggleComment(html, CodeLanguage.html);
      expect(commented.text, '<!-- <p>x</p> -->');
    });
  });
}
