import 'package:decode/core/preview/preview_bundler.dart';
import 'package:decode/core/preview/preview_source.dart';
import 'package:decode/features/editor/code_language.dart';
import 'package:decode/features/editor/css_color.dart';
import 'package:decode/features/editor/lorem.dart';
import 'package:decode/features/editor/suggester.dart';
import 'package:decode/features/editor/syntax_highlighter.dart';
import 'package:decode/features/explore/palette_data.dart';
import 'package:decode/features/explore/palette_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('css highlighting', () {
    test('selectors, properties, values, units and colours', () {
      const css =
          '.card:hover { margin: 0 auto; color: #ff0000; width: calc(100% - 20px); }';
      final by = <TokenKind, List<String>>{};
      for (final t in tokenize(css, CodeLanguage.css)) {
        by.putIfAbsent(t.kind, () => []).add(css.substring(t.start, t.end));
      }
      expect(by[TokenKind.selectorClass], ['.card']);
      expect(by[TokenKind.pseudo], [':hover']);
      expect(by[TokenKind.property], containsAll(['margin', 'color', 'width']));
      expect(by[TokenKind.value], contains('auto'));
      expect(by[TokenKind.number], containsAll(['0', '#ff0000', '100', '20']));
      expect(by[TokenKind.unit], containsAll(['%', 'px']));
      expect(by[TokenKind.function], ['calc']);
    });

    test('js: functions, members, types and builtins', () {
      const js = 'class Box extends Base { run() { console.log(this.x); } }';
      final by = <TokenKind, List<String>>{};
      for (final t in tokenize(js, CodeLanguage.js)) {
        by.putIfAbsent(t.kind, () => []).add(js.substring(t.start, t.end));
      }
      expect(by[TokenKind.storage], containsAll(['class', 'extends']));
      expect(by[TokenKind.type], containsAll(['Box', 'Base']));
      expect(by[TokenKind.builtin], ['console']);
      expect(by[TokenKind.function], containsAll(['run', 'log']));
      expect(by[TokenKind.constant], ['this']);
    });

    test('spans still rebuild the text exactly for all languages', () {
      const samples = {
        CodeLanguage.css: '@media (max-width: 600px) { a:hover { color: red !important; } }\n/* c */',
        CodeLanguage.js: "const a = `x\${1}`; // c\nif (a) { /* b */ }",
        CodeLanguage.html: '<p class="a">&amp; hi</p><br/><!-- c --><style>a{}</style>',
      };
      samples.forEach((lang, text) {
        final spans = buildSpans(text, lang, SyntaxPalette.dark);
        expect(spans.map((s) => s.text).join(), text, reason: '$lang');
      });
    });
  });

  group('colours', () {
    test('parse and format', () {
      expect(parseCssColor('#f00'), const Color(0xFFFF0000));
      expect(parseCssColor('rgb(0, 128, 255)'), const Color(0xFF0080FF));
      expect(parseCssColor('hsl(0, 100%, 50%)')?.toARGB32(), 0xFFFF0000);
      expect(parseCssColor('red')?.toARGB32(), 0xFFFF0000);
      expect(parseCssColor('nonsense'), isNull);
      expect(colorToHex(const Color(0xFF4F46E5)), '#4f46e5');
      expect(colorToHsl(const Color(0xFFFF0000)), 'hsl(0, 100%, 50%)');
      expect(colorToRgb(const Color(0x80FF0000)), startsWith('rgba(255, 0, 0, 0.5'));
    });

    test('finds colours in a line', () {
      expect(findColors('color: #fff; background: rgb(1,2,3);').length, 2);
      expect(findColors('color: red;').length, 0);
      expect(findColors('color: red;', names: true).length, 1);
    });
  });

  group('suggestions v2', () {
    List<String> labels(SuggestionResult? r) =>
        r == null ? [] : r.items.map((s) => s.label).toList();

    test('h at the start of a line offers h1 to h6', () {
      const text = '<body>\n  h';
      final r = Suggester.suggest(text, text.length, CodeLanguage.html);
      expect(labels(r), containsAll(['h1', 'h2', 'h3']));
    });

    test('no tag popup in the middle of a sentence', () {
      const text = '<p>hello world h';
      expect(Suggester.suggest(text, text.length, CodeLanguage.html), isNull);
    });

    test('font-family suggests fonts, with quotes when needed', () {
      const text = 'p { font-family: seg';
      final r = Suggester.suggest(text, text.length, CodeLanguage.css)!;
      final font = r.items.firstWhere((s) => s.label == 'Segoe UI');
      expect(font.template, "'Segoe UI', sans-serif");

      const quoted = "p { font-family: 'seg";
      final q = Suggester.suggest(quoted, quoted.length, CodeLanguage.css)!;
      expect(q.replaceStart, quoted.indexOf("'"));
    });

    test('values depend on the property', () {
      const text = 'p { text-align: ce';
      expect(
        labels(Suggester.suggest(text, text.length, CodeLanguage.css)),
        contains('center'),
      );
      const color = 'p { background-color: te';
      expect(
        labels(Suggester.suggest(color, color.length, CodeLanguage.css)),
        contains('teal'),
      );
    });

    test('lorem snippets work', () {
      const text = '<p>one</p>\nlor';
      final r = Suggester.suggest(text, text.length, CodeLanguage.html);
      expect(labels(r), contains('lorem'));
      expect(r!.items.firstWhere((s) => s.label == 'lorem').template, startsWith('Lorem ipsum'));
    });
  });

  group('lorem', () {
    test('word counts', () {
      expect(loremWords(5), 'Lorem ipsum dolor sit amet.');
      expect(loremWords(30).split(RegExp(r'\s+')).length, 30);
      expect(loremParagraphs(3).split('\n\n').length, 3);
      expect(loremWords(0), '');
    });
  });

  group('palettes', () {
    test('300 palettes with four colours, unique names, known moods', () {
      final all = parsePalettes(paletteSource);
      expect(all.length, 300);
      expect(all.every((p) => p.colors.length == 4), isTrue);
      expect(all.map((p) => p.name).toSet().length, 300);
      expect(all.every((p) => paletteMoods.contains(p.mood)), isTrue);
    });

    test('roles pick light background and dark text', () {
      final p = parsePalettes(paletteSource).first;
      final r = p.roles;
      expect(
        HSLColor.fromColor(r.background).lightness >=
            HSLColor.fromColor(r.text).lightness,
        isTrue,
      );
      expect(p.cssVariables, contains('--color-4'));
      expect(p.cssGradient, startsWith('background: linear-gradient'));
    });
  });

  group('preview bundler', () {
    test('inlines local css, js and images; leaves remote ones alone', () async {
      final bundle = await PreviewBundler(
        MemorySource({
          'index.html': '<link rel="stylesheet" href="css/style.css">'
              '<link rel="stylesheet" href="https://x.com/a.css">'
              '<script src="js/app.js"></script>'
              '<img src="img/a.png" alt="a">'
              '<link rel="stylesheet" href="../secret.css">',
          'css/style.css': 'body{background:url(../img/a.png)}',
          'js/app.js': 'var x = 1;',
          'img/a.png': 'PNG',
        }),
      ).bundle('index.html');

      expect(bundle, isNotNull);
      expect(bundle, contains('<style>'));
      expect(bundle, contains('url("data:image/png;base64,'));
      expect(bundle, contains('<script>\nvar x = 1;\n</script>'));
      expect(bundle, contains('<img src="data:image/png;base64,'));
      expect(bundle, contains('href="https://x.com/a.css"'));
      expect(bundle, contains('href="../secret.css"'));
      expect(bundle, isNot(contains('href="css/style.css"')));
    });

    test('missing entry gives null', () async {
      expect(await PreviewBundler(MemorySource({})).bundle('index.html'), isNull);
    });
  });
}
