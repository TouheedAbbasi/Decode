import 'code_language.dart';

class Suggestion {
  const Suggestion(this.label, this.insert, {this.caretBack = 0});

  final String label;
  final String insert;

  /// How many characters to move the caret back after inserting.
  final int caretBack;
}

class SuggestionResult {
  const SuggestionResult(this.items, this.replaceStart);

  final List<Suggestion> items;

  /// Index where the typed prefix starts.
  final int replaceStart;
}

/// Lightweight, context-aware autocomplete for HTML, CSS and JavaScript.
class Suggester {
  Suggester._();

  static final _wordChar = RegExp(r'[\w-]');

  static SuggestionResult? suggest(
    String text,
    int cursor,
    CodeLanguage language,
  ) {
    if (cursor <= 0 || cursor > text.length) return null;

    var start = cursor;
    while (start > 0 && _wordChar.hasMatch(text[start - 1])) {
      start--;
    }
    final prefix = text.substring(start, cursor);
    if (prefix.isEmpty) return null;
    final prev = start > 0 ? text[start - 1] : '';
    final before = text.substring(0, start);

    List<Suggestion> candidates;
    switch (language) {
      case CodeLanguage.html:
        if (prev == '<') {
          candidates = [for (final t in _htmlTags) Suggestion(t, t)];
        } else if (before.lastIndexOf('<') > before.lastIndexOf('>') &&
            prev.trim().isEmpty) {
          candidates = [
            for (final a in _htmlAttributes)
              Suggestion(a, '$a=""', caretBack: 1),
          ];
        } else {
          return null;
        }
      case CodeLanguage.css:
        if (prefix.length < 2) return null;
        final boundary = [
          before.lastIndexOf('{'),
          before.lastIndexOf(';'),
          before.lastIndexOf('}'),
        ].reduce((a, b) => a > b ? a : b);
        final segment = before.substring(boundary + 1);
        if (segment.contains(':')) {
          candidates = [for (final v in _cssValues) Suggestion(v, v)];
        } else {
          candidates = [for (final p in _cssProperties) Suggestion(p, '$p: ')];
        }
      case CodeLanguage.js:
        if (prefix.length < 2) return null;
        final words = prev == '.' ? _jsMembers : _jsWords;
        candidates = [for (final w in words) Suggestion(w, w)];
      case CodeLanguage.text:
        return null;
    }

    final lower = prefix.toLowerCase();
    final items = candidates
        .where((s) => s.label.startsWith(lower) && s.label != prefix)
        .take(8)
        .toList();
    if (items.isEmpty) return null;
    return SuggestionResult(items, start);
  }
}

const _htmlTags = [
  'a', 'article', 'aside', 'body', 'br', 'button', 'canvas', 'div', 'footer',
  'form', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'head', 'header', 'hr', 'html',
  'img', 'input', 'label', 'li', 'link', 'main', 'meta', 'nav', 'ol', 'option',
  'p', 'script', 'section', 'select', 'span', 'style', 'table', 'td', 'textarea',
  'th', 'title', 'tr', 'ul', 'video', //
];

const _htmlAttributes = [
  'alt', 'autocomplete', 'charset', 'class', 'content', 'disabled', 'for',
  'height', 'href', 'id', 'lang', 'name', 'onclick', 'placeholder', 'rel',
  'required', 'src', 'style', 'target', 'title', 'type', 'value', 'width', //
];

const _cssProperties = [
  'align-items', 'animation', 'background', 'background-color', 'border',
  'border-radius', 'bottom', 'box-shadow', 'box-sizing', 'color', 'cursor',
  'display', 'flex', 'flex-direction', 'flex-wrap', 'font-family', 'font-size',
  'font-weight', 'gap', 'grid-template-columns', 'height', 'justify-content',
  'left', 'letter-spacing', 'line-height', 'margin', 'margin-bottom',
  'margin-top', 'max-width', 'min-height', 'opacity', 'overflow', 'padding',
  'padding-bottom', 'padding-top', 'position', 'right', 'text-align',
  'text-decoration', 'top', 'transform', 'transition', 'width', 'z-index', //
];

const _cssValues = [
  'absolute', 'auto', 'block', 'bold', 'center', 'column', 'fixed', 'flex',
  'grid', 'hidden', 'inherit', 'inline-block', 'none', 'normal', 'pointer',
  'relative', 'row', 'solid', 'space-between', 'sticky', 'transparent',
  'underline', 'white', 'wrap', //
];

const _jsWords = [
  'addEventListener', 'alert', 'async', 'await', 'break', 'catch', 'class',
  'const', 'console', 'continue', 'document', 'else', 'false', 'finally',
  'for', 'function', 'if', 'import', 'let', 'localStorage', 'null', 'return',
  'setInterval', 'setTimeout', 'switch', 'this', 'throw', 'true', 'try',
  'undefined', 'var', 'while', 'window', //
];

const _jsMembers = [
  'addEventListener', 'appendChild', 'children', 'classList', 'click',
  'createElement', 'getElementById', 'innerHTML', 'innerText', 'length', 'log',
  'map', 'parentElement', 'push', 'querySelector', 'querySelectorAll',
  'remove', 'removeEventListener', 'setAttribute', 'style', 'textContent',
  'toggle', 'value', //
];
