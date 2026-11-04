import 'package:flutter/painting.dart';

import 'code_language.dart';

enum TokenKind {
  comment,
  tag,
  punctuation,
  attribute,
  attrValue,
  string,
  number,
  unit,
  keyword,
  storage,
  function,
  property,
  variable,
  constant,
  selectorClass,
  selectorId,
  pseudo,
  value,
  type,
  builtin,
  entity,
}

class Token {
  const Token(this.start, this.end, this.kind);

  final int start;
  final int end;
  final TokenKind kind;
}

/// Colours modelled on VS Code's "Light+" and "Dark+" themes.
class SyntaxPalette {
  const SyntaxPalette._(this._colors);

  final Map<TokenKind, Color> _colors;

  Color colorOf(TokenKind kind) => _colors[kind] ?? const Color(0xFF808080);

  static const light = SyntaxPalette._({
    TokenKind.comment: Color(0xFF008000),
    TokenKind.tag: Color(0xFF800000),
    TokenKind.punctuation: Color(0xFF800000),
    TokenKind.attribute: Color(0xFFE50000),
    TokenKind.attrValue: Color(0xFF0000FF),
    TokenKind.string: Color(0xFFA31515),
    TokenKind.number: Color(0xFF098658),
    TokenKind.unit: Color(0xFF098658),
    TokenKind.keyword: Color(0xFFAF00DB),
    TokenKind.storage: Color(0xFF0000FF),
    TokenKind.function: Color(0xFF795E26),
    TokenKind.property: Color(0xFFE50000),
    TokenKind.variable: Color(0xFF001080),
    TokenKind.constant: Color(0xFF0000FF),
    TokenKind.selectorClass: Color(0xFF800000),
    TokenKind.selectorId: Color(0xFF800000),
    TokenKind.pseudo: Color(0xFF800000),
    TokenKind.value: Color(0xFF0451A5),
    TokenKind.type: Color(0xFF267F99),
    TokenKind.builtin: Color(0xFF001080),
    TokenKind.entity: Color(0xFF0000FF),
  });

  static const dark = SyntaxPalette._({
    TokenKind.comment: Color(0xFF6A9955),
    TokenKind.tag: Color(0xFF569CD6),
    TokenKind.punctuation: Color(0xFF808080),
    TokenKind.attribute: Color(0xFF9CDCFE),
    TokenKind.attrValue: Color(0xFFCE9178),
    TokenKind.string: Color(0xFFCE9178),
    TokenKind.number: Color(0xFFB5CEA8),
    TokenKind.unit: Color(0xFFB5CEA8),
    TokenKind.keyword: Color(0xFFC586C0),
    TokenKind.storage: Color(0xFF569CD6),
    TokenKind.function: Color(0xFFDCDCAA),
    TokenKind.property: Color(0xFF9CDCFE),
    TokenKind.variable: Color(0xFF9CDCFE),
    TokenKind.constant: Color(0xFF569CD6),
    TokenKind.selectorClass: Color(0xFFD7BA7D),
    TokenKind.selectorId: Color(0xFFD7BA7D),
    TokenKind.pseudo: Color(0xFFD7BA7D),
    TokenKind.value: Color(0xFFCE9178),
    TokenKind.type: Color(0xFF4EC9B0),
    TokenKind.builtin: Color(0xFF4FC1FF),
    TokenKind.entity: Color(0xFF569CD6),
  });
}

/// Splits [text] into coloured tokens. Tokens never overlap and are sorted.
List<Token> tokenize(String text, CodeLanguage language) => switch (language) {
      CodeLanguage.html => _tokenizeHtml(text),
      CodeLanguage.css => _tokenizeCss(text),
      CodeLanguage.js => _tokenizeJs(text),
      CodeLanguage.text => const <Token>[],
    };

/// Builds spans whose text, joined together, equals [text] exactly.
List<TextSpan> buildSpans(
  String text,
  CodeLanguage language,
  SyntaxPalette palette,
) {
  if (text.isEmpty) return const <TextSpan>[];
  final spans = <TextSpan>[];
  var cursor = 0;
  for (final token in tokenize(text, language)) {
    if (token.start < cursor || token.end > text.length) continue;
    if (token.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, token.start)));
    }
    spans.add(
      TextSpan(
        text: text.substring(token.start, token.end),
        style: TextStyle(color: palette.colorOf(token.kind)),
      ),
    );
    cursor = token.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor)));
  }
  return spans;
}

// ------------------------------------------------------------------- HTML

final _htmlOuter = RegExp(r'<!--[\s\S]*?(?:-->|$)|</?[a-zA-Z!][^<>]*>?');
final _htmlName = RegExp(r'^(</?)([a-zA-Z!][\w:-]*)');
final _htmlPart = RegExp("([\\w:@.-]+)(?=\\s*=)|\"[^\"]*\"?|'[^']*'?");
final _htmlEntity = RegExp(r'&(?:[a-zA-Z]+|#\d+|#x[0-9a-fA-F]+);');
final _htmlBlock = RegExp(
  r'<(style|script)\b[^>]*>([\s\S]*?)(?:</\1\s*>|$)',
  caseSensitive: false,
);

List<Token> _tokenizeHtml(String text) {
  final tokens = <Token>[];
  final blocks = <(int, int)>[];

  // Code inside <style> and <script> is coloured as CSS / JavaScript.
  for (final block in _htmlBlock.allMatches(text)) {
    final inner = block.group(2)!;
    if (inner.isEmpty) continue;
    final innerStart = text.indexOf('>', block.start) + 1;
    final isStyle = block.group(1)!.toLowerCase() == 'style';
    final sub = isStyle ? _tokenizeCss(inner) : _tokenizeJs(inner);
    for (final token in sub) {
      tokens.add(
        Token(token.start + innerStart, token.end + innerStart, token.kind),
      );
    }
    blocks.add((innerStart, innerStart + inner.length));
  }

  bool inBlock(int index) => blocks.any((b) => index >= b.$1 && index < b.$2);

  for (final match in _htmlOuter.allMatches(text)) {
    if (inBlock(match.start)) continue;
    final chunk = match[0]!;
    if (chunk.startsWith('<!--')) {
      tokens.add(Token(match.start, match.end, TokenKind.comment));
      continue;
    }
    final name = _htmlName.firstMatch(chunk);
    if (name == null) continue;
    final bracket = name.group(1)!;
    final tagName = name.group(2)!;
    tokens.add(
      Token(match.start, match.start + bracket.length, TokenKind.punctuation),
    );
    tokens.add(
      Token(
        match.start + bracket.length,
        match.start + name.end,
        tagName.startsWith('!') ? TokenKind.keyword : TokenKind.tag,
      ),
    );
    final base = match.start + name.end;
    for (final part in _htmlPart.allMatches(chunk.substring(name.end))) {
      final attribute = part.group(1);
      if (attribute != null) {
        tokens.add(
          Token(
            base + part.start,
            base + part.start + attribute.length,
            TokenKind.attribute,
          ),
        );
      } else {
        tokens.add(
          Token(base + part.start, base + part.end, TokenKind.attrValue),
        );
      }
    }
    if (chunk.endsWith('/>') && chunk.length > name.end + 1) {
      tokens.add(Token(match.end - 2, match.end, TokenKind.punctuation));
    } else if (chunk.endsWith('>') && chunk.length > name.end) {
      tokens.add(Token(match.end - 1, match.end, TokenKind.punctuation));
    }
  }

  tokens.sort((a, b) => a.start.compareTo(b.start));

  // &amp; and friends in the text, when they do not touch another token.
  final entities = <Token>[];
  for (final match in _htmlEntity.allMatches(text)) {
    final clash =
        tokens.any((t) => match.start < t.end && match.end > t.start);
    if (!clash) entities.add(Token(match.start, match.end, TokenKind.entity));
  }
  if (entities.isNotEmpty) {
    tokens
      ..addAll(entities)
      ..sort((a, b) => a.start.compareTo(b.start));
  }
  return tokens;
}

// -------------------------------------------------------------------- CSS

final _cssSelector = RegExp(
  [
    r'(?<comment>/\*[\s\S]*?\*/)',
    r'(?<attr>\[[^\]]*\])',
    r'(?<pseudo>::?[\w-]+(?:\([^)]*\))?)',
    r'(?<cls>\.[\w-]+)',
    r'(?<id>#[\w-]+)',
    r'(?<tag>(?<![\w-])[a-zA-Z][\w-]*)',
  ].join('|'),
);

final _cssValue = RegExp(
  [
    r'(?<comment>/\*[\s\S]*?\*/)',
    r'(?<dq>"(?:\\.|[^"\\\n])*"?)',
    r"(?<sq>'(?:\\.|[^'\\\n])*'?)",
    r'(?<imp>!\s*important)',
    r'(?<hex>#[0-9a-fA-F]{3,8}\b)',
    r'(?<num>[+-]?(?:\d+\.?\d*|\.\d+)(?<unit>%|[a-zA-Z]{1,4})?)',
    r'(?<var>--[\w-]+)',
    r'(?<fn>[a-zA-Z_-][\w-]*(?=\())',
    r'(?<word>[a-zA-Z_-][\w-]*)',
  ].join('|'),
);

List<Token> _tokenizeCss(String text) {
  final tokens = <Token>[];
  final n = text.length;
  var i = 0;

  while (i < n) {
    final unit = text.codeUnitAt(i);
    if (unit == 32 || unit == 9 || unit == 10 || unit == 13) {
      i++;
      continue;
    }
    if (text.startsWith('/*', i)) {
      final close = text.indexOf('*/', i + 2);
      final end = close < 0 ? n : close + 2;
      tokens.add(Token(i, end, TokenKind.comment));
      i = end;
      continue;
    }
    final c = text[i];
    if (c == '{' || c == '}' || c == ';') {
      i++;
      continue;
    }

    final end = _cssStatementEnd(text, i);
    final terminator = end < n ? text[end] : ';';
    final segment = text.substring(i, end);

    if (c == '@') {
      final name = RegExp(r'^@[\w-]+').firstMatch(segment);
      if (name != null) {
        tokens.add(Token(i, i + name.end, TokenKind.keyword));
        _cssValues(segment.substring(name.end), i + name.end, tokens);
      }
    } else if (terminator == '{') {
      _cssSelectors(segment, i, tokens);
    } else {
      _cssDeclaration(segment, i, tokens);
    }
    i = end;
  }
  return tokens;
}

/// Index of the `{`, `;` or `}` that ends the statement starting at [from]
/// (ignoring strings, comments and parentheses), or the end of the text.
int _cssStatementEnd(String text, int from) {
  var paren = 0;
  var j = from;
  while (j < text.length) {
    final c = text[j];
    if (c == '"' || c == "'") {
      j++;
      while (j < text.length && text[j] != c && text[j] != '\n') {
        if (text[j] == r'\') j++;
        j++;
      }
    } else if (c == '/' && j + 1 < text.length && text[j + 1] == '*') {
      final close = text.indexOf('*/', j + 2);
      j = close < 0 ? text.length : close + 1;
    } else if (c == '(') {
      paren++;
    } else if (c == ')') {
      if (paren > 0) paren--;
    } else if (paren == 0 && (c == '{' || c == ';' || c == '}')) {
      return j;
    }
    j++;
  }
  return text.length;
}

void _cssSelectors(String segment, int offset, List<Token> tokens) {
  for (final m in _cssSelector.allMatches(segment)) {
    final kind = m.namedGroup('comment') != null
        ? TokenKind.comment
        : m.namedGroup('attr') != null
            ? TokenKind.attribute
            : m.namedGroup('pseudo') != null
                ? TokenKind.pseudo
                : m.namedGroup('cls') != null
                    ? TokenKind.selectorClass
                    : m.namedGroup('id') != null
                        ? TokenKind.selectorId
                        : TokenKind.tag;
    tokens.add(Token(offset + m.start, offset + m.end, kind));
  }
}

void _cssDeclaration(String segment, int offset, List<Token> tokens) {
  final colon = segment.indexOf(':');
  if (colon < 0) return;
  final name = segment.substring(0, colon);
  final lead = name.length - name.trimLeft().length;
  final trimmed = name.trim();
  if (trimmed.isEmpty) return;
  tokens.add(
    Token(
      offset + lead,
      offset + lead + trimmed.length,
      trimmed.startsWith('--') ? TokenKind.variable : TokenKind.property,
    ),
  );
  _cssValues(segment.substring(colon + 1), offset + colon + 1, tokens);
}

void _cssValues(String text, int offset, List<Token> tokens) {
  for (final m in _cssValue.allMatches(text)) {
    final start = offset + m.start;
    final end = offset + m.end;
    if (m.namedGroup('comment') != null) {
      tokens.add(Token(start, end, TokenKind.comment));
    } else if (m.namedGroup('dq') != null || m.namedGroup('sq') != null) {
      tokens.add(Token(start, end, TokenKind.string));
    } else if (m.namedGroup('imp') != null) {
      tokens.add(Token(start, end, TokenKind.keyword));
    } else if (m.namedGroup('hex') != null) {
      tokens.add(Token(start, end, TokenKind.number));
    } else if (m.namedGroup('num') != null) {
      final unit = m.namedGroup('unit') ?? '';
      final split = end - unit.length;
      tokens.add(Token(start, split, TokenKind.number));
      if (unit.isNotEmpty) tokens.add(Token(split, end, TokenKind.unit));
    } else if (m.namedGroup('var') != null) {
      tokens.add(Token(start, end, TokenKind.variable));
    } else if (m.namedGroup('fn') != null) {
      tokens.add(Token(start, end, TokenKind.function));
    } else if (m.namedGroup('word') != null) {
      if (m[0] != '-') tokens.add(Token(start, end, TokenKind.value));
    }
  }
}

// ------------------------------------------------------------- JavaScript

final _js = RegExp(
  [
    r'(?<comment>//[^\n]*|/\*[\s\S]*?(?:\*/|$))',
    r'(?<tpl>`(?:\\[\s\S]|[^`\\])*`?)',
    r'(?<dq>"(?:\\.|[^"\\\n])*"?)',
    r"(?<sq>'(?:\\.|[^'\\\n])*'?)",
    r'(?<num>(?<![\w$])(?:0[xX][0-9a-fA-F]+|\d+(?:\.\d+)?)\b)',
    r'(?<word>[A-Za-z_$][\w$]*)',
  ].join('|'),
);

const _jsControl = {
  'if', 'else', 'for', 'while', 'do', 'switch', 'case', 'break', 'continue',
  'return', 'throw', 'try', 'catch', 'finally', 'new', 'delete', 'typeof',
  'instanceof', 'in', 'of', 'await', 'yield', 'import', 'export', 'from',
  'default', 'as', 'void', //
};
const _jsStorage = {
  'const', 'let', 'var', 'function', 'class', 'extends', 'async', 'static',
  'get', 'set', //
};
const _jsConstants = {
  'true', 'false', 'null', 'undefined', 'NaN', 'Infinity', 'this', 'super', //
};
const _jsBuiltins = {
  'console', 'document', 'window', 'Math', 'JSON', 'Object', 'Array',
  'String', 'Number', 'Boolean', 'Date', 'Promise', 'localStorage',
  'sessionStorage', 'navigator', 'location', 'history', //
};

List<Token> _tokenizeJs(String text) {
  final tokens = <Token>[];
  var lastWord = '';
  for (final m in _js.allMatches(text)) {
    if (m.end == m.start) continue;
    if (m.namedGroup('comment') != null) {
      tokens.add(Token(m.start, m.end, TokenKind.comment));
    } else if (m.namedGroup('tpl') != null ||
        m.namedGroup('dq') != null ||
        m.namedGroup('sq') != null) {
      tokens.add(Token(m.start, m.end, TokenKind.string));
    } else if (m.namedGroup('num') != null) {
      tokens.add(Token(m.start, m.end, TokenKind.number));
    } else {
      final word = m[0]!;
      final kind = _jsWordKind(text, m.start, m.end, word, lastWord);
      tokens.add(Token(m.start, m.end, kind));
      lastWord = word;
    }
  }
  return tokens;
}

TokenKind _jsWordKind(String text, int start, int end, String word, String last) {
  if (_jsControl.contains(word)) return TokenKind.keyword;
  if (_jsStorage.contains(word)) return TokenKind.storage;
  if (_jsConstants.contains(word)) return TokenKind.constant;
  final member = start > 0 && text[start - 1] == '.';
  var next = end;
  while (next < text.length && (text[next] == ' ' || text[next] == '\t')) {
    next++;
  }
  final called = next < text.length && text[next] == '(';
  if (!member && _jsBuiltins.contains(word)) return TokenKind.builtin;
  if (last == 'function' || called) return TokenKind.function;
  if (last == 'class' || last == 'extends' || last == 'new') {
    return TokenKind.type;
  }
  final first = word.codeUnitAt(0);
  if (first >= 65 && first <= 90 && word.length > 1) return TokenKind.type;
  return TokenKind.variable;
}
