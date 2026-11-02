import 'code_language.dart';

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

/// VS Code style suggestions and snippets for HTML, CSS and JavaScript.
class Suggester {
  Suggester._();

  static final _wordChar = RegExp(r'[\w-]');
  static const maxItems = 6;

  static SuggestionResult? suggest(
    String text,
    int cursor,
    CodeLanguage language,
  ) {
    if (cursor <= 0 || cursor > text.length) return null;
    final lang = effectiveLanguage(text, cursor, language);
    if (lang == CodeLanguage.text) return null;

    var start = cursor;
    while (start > 0 && _wordChar.hasMatch(text[start - 1])) {
      start--;
    }
    final prefix = text.substring(start, cursor);
    if (prefix.isEmpty) return null;
    final prev = start > 0 ? text[start - 1] : '';
    final before = text.substring(0, start);

    var replaceStart = start;
    var minLength = 2;
    var allowExact = false;
    final List<Suggestion> candidates;

    switch (lang) {
      case CodeLanguage.html:
        final insideTag = before.lastIndexOf('<') > before.lastIndexOf('>');
        if (prev == '<') {
          candidates = _htmlSnippets;
          replaceStart = start - 1;
          minLength = 1;
          allowExact = true;
        } else if (insideTag) {
          if (prev.trim().isNotEmpty) return null;
          candidates = _htmlAttributes;
          minLength = 1;
        } else {
          candidates = _htmlSnippets;
          allowExact = true;
        }
      case CodeLanguage.css:
        if (before.lastIndexOf('{') <= before.lastIndexOf('}')) return null;
        final boundary = [
          before.lastIndexOf('{'),
          before.lastIndexOf(';'),
          before.lastIndexOf('}'),
        ].reduce((a, b) => a > b ? a : b);
        candidates = before.substring(boundary + 1).contains(':')
            ? _cssValues
            : _cssProperties;
      case CodeLanguage.js:
        candidates = prev == '.' ? _jsMembers : _jsWords;
      case CodeLanguage.text:
        return null;
    }

    if (prefix.length < minLength) return null;
    final lower = prefix.toLowerCase();
    final matches = candidates
        .where(
          (s) =>
              s.label.toLowerCase().startsWith(lower) &&
              (allowExact || s.label != prefix),
        )
        .toList()
      ..sort((a, b) {
        final byLength = a.label.length.compareTo(b.label.length);
        return byLength != 0 ? byLength : a.label.compareTo(b.label);
      });
    if (matches.isEmpty) return null;
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

// --------------------------------------------------------------------- CSS

const _cssPropertyNames = [
  'align-items', 'animation', 'background', 'background-color', 'border',
  'border-radius', 'bottom', 'box-shadow', 'box-sizing', 'color', 'cursor',
  'display', 'flex', 'flex-direction', 'flex-wrap', 'font-family', 'font-size',
  'font-weight', 'gap', 'grid-template-columns', 'height', 'justify-content',
  'left', 'letter-spacing', 'line-height', 'margin', 'margin-bottom',
  'margin-top', 'max-width', 'min-height', 'opacity', 'overflow', 'padding',
  'padding-bottom', 'padding-top', 'position', 'right', 'text-align',
  'text-decoration', 'top', 'transform', 'transition', 'width', 'z-index', //
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
];

final List<Suggestion> _cssValues = [
  for (final v in const [
    'absolute', 'auto', 'block', 'bold', 'center', 'column', 'fixed', 'flex',
    'grid', 'hidden', 'inherit', 'inline-block', 'none', 'normal', 'pointer',
    'relative', 'row', 'solid', 'space-between', 'sticky', 'transparent',
    'underline', 'white', 'wrap', //
  ])
    Suggestion(v, v),
];

// -------------------------------------------------------------- JavaScript

final List<Suggestion> _jsWords = [
  for (final w in const [
    'addEventListener', 'alert', 'async', 'await', 'break', 'catch', 'class',
    'const', 'console', 'continue', 'document', 'else', 'false', 'finally',
    'function', 'import', 'let', 'localStorage', 'null', 'return',
    'setInterval', 'switch', 'this', 'throw', 'true', 'try', 'undefined',
    'var', 'while', 'window', //
  ])
    Suggestion(w, w),
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
    Suggestion(m, m),
];
