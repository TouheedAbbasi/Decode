import 'code_language.dart';
import 'lorem.dart';

/// Marks where the caret lands after a snippet is inserted.
const caretMarker = '\u0001';

const _c = caretMarker;

class Suggestion {
  const Suggestion(this.label, this.template);

  /// What the user types to find it, for example `article`.
  final String label;

  /// What gets inserted. May contain [caretMarker] and line breaks.
  final String template;

  /// One-line preview of the insertion.
  String get preview {
    final clean = template.replaceAll(caretMarker, '');
    final lines = clean.split('\n');
    return lines.length > 1 ? '${lines.first.trim()} ...' : clean;
  }
}

class SuggestionResult {
  const SuggestionResult(this.items, this.replaceStart);

  final List<Suggestion> items;

  /// Index where the typed text starts (includes a leading `<`).
  final int replaceStart;
}

class _Group {
  const _Group(this.items, this.minLength, this.allowExact);

  final List<Suggestion> items;
  final int minLength;
  final bool allowExact;
}

/// VS Code style suggestions and snippets for HTML, CSS and JavaScript.
class Suggester {
  Suggester._();

  static final _wordChar = RegExp(r'[\w-]');
  static const maxItems = 12;

  static SuggestionResult? suggest(
    String text,
    int cursor,
    CodeLanguage language,
  ) {
    if (cursor <= 0 || cursor > text.length) return null;
    final lang = effectiveLanguage(text, cursor, language);

    var start = cursor;
    while (start > 0 && _wordChar.hasMatch(text[start - 1])) {
      start--;
    }
    final prefix = text.substring(start, cursor);
    if (prefix.isEmpty) return null;
    final prev = start > 0 ? text[start - 1] : '';
    final before = text.substring(0, start);

    var replaceStart = start;
    final groups = <_Group>[];

    switch (lang) {
      case CodeLanguage.html:
        final insideTag = before.lastIndexOf('<') > before.lastIndexOf('>');
        if (prev == '<') {
          replaceStart = start - 1;
          groups.add(_Group(_htmlSnippets, 1, true));
        } else if (insideTag) {
          if (prev.trim().isNotEmpty) return null;
          groups.add(_Group(_htmlAttributes, 1, false));
        } else {
          // Tag snippets only where a tag could begin: at the start of a
          // line, or right after another tag. Not in the middle of a sentence.
          final line = before.substring(before.lastIndexOf('\n') + 1);
          if (line.trim().isEmpty) {
            groups.add(_Group(_htmlSnippets, 1, true));
          } else if (line.endsWith('>')) {
            groups.add(_Group(_htmlSnippets, 2, true));
          }
          groups.add(_Group(_loremSnippets, 3, true));
        }
      case CodeLanguage.css:
        if (before.lastIndexOf('{') <= before.lastIndexOf('}')) return null;
        final boundary = [
          before.lastIndexOf('{'),
          before.lastIndexOf(';'),
          before.lastIndexOf('}'),
        ].reduce((a, b) => a > b ? a : b);
        final segment = before.substring(boundary + 1);
        final colon = segment.indexOf(':');
        if (colon < 0) {
          groups.add(_Group(_cssProperties, 2, false));
        } else {
          final property = segment.substring(0, colon).trim().toLowerCase();
          final isFont = property == 'font-family' || property == 'font';
          if (isFont && (prev == "'" || prev == '"')) replaceStart = start - 1;
          groups.add(_Group(_cssValuesFor(property), isFont ? 1 : 2, false));
        }
      case CodeLanguage.js:
        groups.add(_Group(prev == '.' ? _jsMembers : _jsWords, 2, false));
        groups.add(_Group(_loremSnippets, 3, true));
      case CodeLanguage.text:
        groups.add(_Group(_loremSnippets, 3, true));
    }

    final lower = prefix.toLowerCase();
    final matches = <Suggestion>[];
    for (final group in groups) {
      if (prefix.length < group.minLength) continue;
      for (final s in group.items) {
        if (!s.label.toLowerCase().startsWith(lower)) continue;
        if (!group.allowExact && s.label == prefix) continue;
        if (!matches.any((m) => m.label == s.label)) matches.add(s);
      }
    }
    if (matches.isEmpty) return null;
    matches.sort((a, b) {
      final byLength = a.label.length.compareTo(b.label.length);
      return byLength != 0 ? byLength : a.label.compareTo(b.label);
    });
    return SuggestionResult(matches.take(maxItems).toList(), replaceStart);
  }
}

// -------------------------------------------------------------------- HTML

const _plainTags = [
  'article', 'aside', 'audio', 'body', 'canvas', 'div', 'em', 'footer',
  'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'head', 'header', 'html', 'i', 'li',
  'main', 'nav', 'option', 'p', 'pre', 'section', 'small', 'span', 'strong',
  'style', 'textarea', 'th', 'td', 'title', 'tr', 'video', //
];

final List<Suggestion> _htmlSnippets = _buildHtmlSnippets();

List<Suggestion> _buildHtmlSnippets() {
  final special = <String, String>{
    'a': '<a href="$_c"></a>',
    'img': '<img src="$_c" alt="">',
    'input': '<input type="$_c">',
    'link': '<link rel="stylesheet" href="$_c">',
    'meta': '<meta name="$_c" content="">',
    'script': '<script src="$_c"></script>',
    'br': '<br>',
    'hr': '<hr>',
    'button': '<button type="button">$_c</button>',
    'label': '<label for="">$_c</label>',
    'ul': '<ul>\n  <li>$_c</li>\n</ul>',
    'ol': '<ol>\n  <li>$_c</li>\n</ol>',
    'select': '<select>\n  <option value="">$_c</option>\n</select>',
    'table': '<table>\n  <tr>\n    <td>$_c</td>\n  </tr>\n</table>',
    'form': '<form action="">\n  $_c\n</form>',
    'html5': '<!DOCTYPE html>\n<html lang="en">\n<head>\n'
        '  <meta charset="UTF-8">\n'
        '  <meta name="viewport" content="width=device-width, initial-scale=1.0">\n'
        '  <title>$_c</title>\n'
        '</head>\n<body>\n  \n</body>\n</html>',
  };
  return [
    for (final tag in _plainTags)
      if (!special.containsKey(tag)) Suggestion(tag, '<$tag>$_c</$tag>'),
    for (final entry in special.entries) Suggestion(entry.key, entry.value),
  ];
}

const _attributeNames = [
  'alt', 'autocomplete', 'charset', 'class', 'content', 'disabled', 'for',
  'height', 'href', 'id', 'lang', 'name', 'onclick', 'placeholder', 'rel',
  'required', 'src', 'style', 'target', 'title', 'type', 'value', 'width', //
];

final List<Suggestion> _htmlAttributes = [
  for (final a in _attributeNames) Suggestion(a, '$a="$_c"'),
];

final List<Suggestion> _loremSnippets = [
  Suggestion('lorem', loremWords(20)),
  for (final n in const [5, 10, 30, 50, 100]) Suggestion('lorem$n', loremWords(n)),
];

// --------------------------------------------------------------------- CSS

const _cssPropertyNames = [
  'align-items', 'align-self', 'animation', 'aspect-ratio', 'background',
  'background-color', 'background-image', 'background-position',
  'background-repeat', 'background-size', 'border', 'border-bottom',
  'border-color', 'border-radius', 'border-top', 'border-width', 'bottom',
  'box-shadow', 'box-sizing', 'color', 'cursor', 'display', 'filter', 'flex',
  'flex-direction', 'flex-wrap', 'font', 'font-family', 'font-size',
  'font-style', 'font-weight', 'gap', 'grid-template-columns',
  'grid-template-rows', 'height', 'justify-content', 'left', 'letter-spacing',
  'line-height', 'list-style', 'margin', 'margin-bottom', 'margin-left',
  'margin-right', 'margin-top', 'max-height', 'max-width', 'min-height',
  'min-width', 'object-fit', 'opacity', 'outline', 'overflow', 'padding',
  'padding-bottom', 'padding-left', 'padding-right', 'padding-top',
  'pointer-events', 'position', 'right', 'text-align', 'text-decoration',
  'text-shadow', 'text-transform', 'top', 'transform', 'transition',
  'user-select', 'vertical-align', 'visibility', 'white-space', 'width',
  'z-index', //
];

final List<Suggestion> _cssProperties = [
  for (final p in _cssPropertyNames) Suggestion(p, '$p: $_c;'),
  const Suggestion(
    'flexcenter',
    'display: flex;\n  align-items: center;\n  justify-content: center;',
  ),
  const Suggestion(
    'gridcols',
    'display: grid;\n  grid-template-columns: repeat(2, 1fr);\n  gap: 16px;',
  ),
  const Suggestion('shadow', 'box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);'),
  const Suggestion(
    'glass',
    'background: rgba(255, 255, 255, 0.15);\n  backdrop-filter: blur(12px);\n'
        '  border: 1px solid rgba(255, 255, 255, 0.3);',
  ),
];

Suggestion _plain(String v) => Suggestion(v, v);

const _enumValues = <String, List<String>>{
  'display': [
    'block', 'inline', 'inline-block', 'flex', 'inline-flex', 'grid', 'none',
    'contents', //
  ],
  'position': ['static', 'relative', 'absolute', 'fixed', 'sticky'],
  'text-align': ['left', 'center', 'right', 'justify'],
  'flex-direction': ['row', 'row-reverse', 'column', 'column-reverse'],
  'flex-wrap': ['nowrap', 'wrap', 'wrap-reverse'],
  'justify-content': [
    'flex-start', 'center', 'flex-end', 'space-between', 'space-around',
    'space-evenly', //
  ],
  'align-items': ['stretch', 'flex-start', 'center', 'flex-end', 'baseline'],
  'align-self': ['auto', 'flex-start', 'center', 'flex-end', 'stretch'],
  'cursor': ['pointer', 'default', 'text', 'move', 'not-allowed', 'grab'],
  'overflow': ['visible', 'hidden', 'scroll', 'auto'],
  'overflow-x': ['visible', 'hidden', 'scroll', 'auto'],
  'overflow-y': ['visible', 'hidden', 'scroll', 'auto'],
  'font-weight': [
    'normal', 'bold', 'lighter', 'bolder', '100', '200', '300', '400', '500',
    '600', '700', '800', '900', //
  ],
  'font-style': ['normal', 'italic', 'oblique'],
  'text-decoration': ['none', 'underline', 'line-through', 'overline'],
  'text-transform': ['none', 'uppercase', 'lowercase', 'capitalize'],
  'visibility': ['visible', 'hidden'],
  'white-space': ['normal', 'nowrap', 'pre', 'pre-wrap'],
  'object-fit': ['fill', 'contain', 'cover', 'none', 'scale-down'],
  'box-sizing': ['border-box', 'content-box'],
  'background-repeat': ['no-repeat', 'repeat', 'repeat-x', 'repeat-y'],
  'background-size': ['cover', 'contain', 'auto', '100%'],
  'background-position': ['center', 'top', 'bottom', 'left', 'right'],
  'list-style': ['none', 'disc', 'circle', 'square', 'decimal'],
  'pointer-events': ['auto', 'none'],
  'user-select': ['auto', 'none', 'text', 'all'],
  'vertical-align': ['baseline', 'top', 'middle', 'bottom'],
  'transition': ['all 0.3s ease', 'opacity 0.3s ease', 'transform 0.3s ease'],
};

const _fonts = <(String, String)>[
  ('Arial', 'sans-serif'), ('Helvetica', 'sans-serif'),
  ('Verdana', 'sans-serif'), ('Tahoma', 'sans-serif'),
  ('Trebuchet MS', 'sans-serif'), ('Segoe UI', 'sans-serif'),
  ('Roboto', 'sans-serif'), ('Open Sans', 'sans-serif'),
  ('Inter', 'sans-serif'), ('Poppins', 'sans-serif'),
  ('Montserrat', 'sans-serif'), ('Lato', 'sans-serif'),
  ('Nunito', 'sans-serif'), ('Impact', 'sans-serif'),
  ('Georgia', 'serif'), ('Times New Roman', 'serif'), ('Garamond', 'serif'),
  ('Playfair Display', 'serif'), ('Merriweather', 'serif'),
  ('Courier New', 'monospace'), ('Consolas', 'monospace'),
  ('Fira Code', 'monospace'), ('JetBrains Mono', 'monospace'),
  ('Comic Sans MS', 'cursive'), ('Brush Script MT', 'cursive'),
];

final List<Suggestion> _fontSuggestions = [
  for (final (name, fallback) in _fonts)
    Suggestion(
      name,
      name.contains(' ') ? "'$name', $fallback" : '$name, $fallback',
    ),
  const Suggestion(
    'system-ui',
    "system-ui, -apple-system, 'Segoe UI', sans-serif",
  ),
  _plain('sans-serif'),
  _plain('serif'),
  _plain('monospace'),
  _plain('cursive'),
];

const _colorNames = [
  'black', 'white', 'red', 'blue', 'green', 'yellow', 'orange', 'purple',
  'pink', 'gray', 'brown', 'teal', 'navy', 'gold', 'coral', 'crimson',
  'indigo', 'violet', 'lavender', 'turquoise', 'skyblue', 'steelblue',
  'tomato', 'salmon', 'tan', 'beige', 'ivory', 'transparent', 'currentColor',
  'rebeccapurple', //
];

final List<Suggestion> _colorValues = [
  for (final n in _colorNames) _plain(n),
  const Suggestion('rgb', 'rgb($_c)'),
  const Suggestion('rgba', 'rgba($_c, 1)'),
  const Suggestion('hsl', 'hsl($_c, 70%, 50%)'),
  const Suggestion('hsla', 'hsla($_c, 70%, 50%, 1)'),
  const Suggestion('var', 'var(--$_c)'),
  const Suggestion('linear-gradient', 'linear-gradient(135deg, $_c)'),
  const Suggestion('radial-gradient', 'radial-gradient(circle, $_c)'),
];

final List<Suggestion> _genericValues = [
  for (final v in const [
    'auto', 'none', 'inherit', 'initial', 'unset', '0', '100%', '50%',
    '100vh', '100vw', 'fit-content', 'max-content', 'min-content', //
  ])
    _plain(v),
  const Suggestion('calc', 'calc($_c)'),
  const Suggestion('var', 'var(--$_c)'),
  const Suggestion('clamp', 'clamp($_c, 5vw, 2rem)'),
  const Suggestion('url', "url('$_c')"),
  const Suggestion('translate', 'translate($_c)'),
  const Suggestion('rotate', 'rotate($_c)'),
  const Suggestion('scale', 'scale($_c)'),
  const Suggestion('repeat', 'repeat($_c, 1fr)'),
  const Suggestion('minmax', 'minmax($_c, 1fr)'),
];

bool _isColorProperty(String p) =>
    p.contains('color') ||
    p == 'background' ||
    p.startsWith('border') ||
    p == 'outline' ||
    p.endsWith('shadow') ||
    p == 'fill' ||
    p == 'stroke';

List<Suggestion> _cssValuesFor(String property) {
  if (property == 'font-family' || property == 'font') return _fontSuggestions;
  final fixed = _enumValues[property];
  if (fixed != null) {
    return [
      for (final v in fixed) _plain(v),
      _plain('inherit'),
      _plain('initial'),
    ];
  }
  if (_isColorProperty(property)) return _colorValues;
  return _genericValues;
}

// -------------------------------------------------------------- JavaScript

final List<Suggestion> _jsWords = [
  for (final w in const [
    'addEventListener', 'alert', 'async', 'await', 'break', 'catch', 'class',
    'const', 'console', 'continue', 'document', 'else', 'false', 'finally',
    'function', 'import', 'let', 'localStorage', 'null', 'return',
    'setInterval', 'switch', 'this', 'throw', 'true', 'try', 'undefined',
    'var', 'while', 'window', //
  ])
    _plain(w),
  const Suggestion('log', 'console.log($_c);'),
  const Suggestion('for', 'for (let i = 0; i < $_c; i++) {\n  \n}'),
  const Suggestion('foreach', '$_c.forEach((item) => {\n  \n});'),
  const Suggestion('fn', 'function $_c() {\n  \n}'),
  const Suggestion('arrow', 'const $_c = () => {\n  \n};'),
  const Suggestion('if', 'if ($_c) {\n  \n}'),
  const Suggestion('ifelse', 'if ($_c) {\n  \n} else {\n  \n}'),
  const Suggestion('qs', "document.querySelector('$_c')"),
  const Suggestion('qsa', "document.querySelectorAll('$_c')"),
  const Suggestion('gid', "document.getElementById('$_c')"),
  const Suggestion('ael', "$_c.addEventListener('click', () => {\n  \n});"),
  const Suggestion('timeout', 'setTimeout(() => {\n  $_c\n}, 1000);'),
  const Suggestion(
    'fetch',
    "fetch('$_c')\n  .then((res) => res.json())\n  .then((data) => {\n    console.log(data);\n  });",
  ),
];

final List<Suggestion> _jsMembers = [
  for (final m in const [
    'addEventListener', 'appendChild', 'children', 'classList', 'click',
    'createElement', 'getElementById', 'innerHTML', 'innerText', 'length',
    'log', 'map', 'parentElement', 'push', 'querySelector',
    'querySelectorAll', 'remove', 'removeEventListener', 'setAttribute',
    'style', 'textContent', 'toggle', 'value', //
  ])
    _plain(m),
];
