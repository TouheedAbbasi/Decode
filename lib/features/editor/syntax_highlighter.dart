import 'package:flutter/painting.dart';

import 'code_language.dart';

enum TokenKind {
  comment,
  tag,
  attribute,
  string,
  number,
  keyword,
  function,
  property,
}

class Token {
  const Token(this.start, this.end, this.kind);

  final int start;
  final int end;
  final TokenKind kind;
}

class SyntaxPalette {
  const SyntaxPalette({
    required this.comment,
    required this.tag,
    required this.attribute,
    required this.string,
    required this.number,
    required this.keyword,
    required this.function,
    required this.property,
  });

  final Color comment;
  final Color tag;
  final Color attribute;
  final Color string;
  final Color number;
  final Color keyword;
  final Color function;
  final Color property;

  static const light = SyntaxPalette(
    comment: Color(0xFF8A8F98),
    tag: Color(0xFFBE185D),
    attribute: Color(0xFFB45309),
    string: Color(0xFF047857),
    number: Color(0xFF1D4ED8),
    keyword: Color(0xFF6D28D9),
    function: Color(0xFF0369A1),
    property: Color(0xFF0369A1),
  );

  static const dark = SyntaxPalette(
    comment: Color(0xFF6B7280),
    tag: Color(0xFFF472B6),
    attribute: Color(0xFFFBBF24),
    string: Color(0xFF34D399),
    number: Color(0xFF60A5FA),
    keyword: Color(0xFFA78BFA),
    function: Color(0xFF38BDF8),
    property: Color(0xFF38BDF8),
  );

  Color colorOf(TokenKind kind) => switch (kind) {
        TokenKind.comment => comment,
        TokenKind.tag => tag,
        TokenKind.attribute => attribute,
        TokenKind.string => string,
        TokenKind.number => number,
        TokenKind.keyword => keyword,
        TokenKind.function => function,
        TokenKind.property => property,
      };
}

/// Splits [text] into coloured tokens. Tokens never overlap and are sorted.
List<Token> tokenize(String text, CodeLanguage language) => switch (language) {
      CodeLanguage.html => _tokenizeHtml(text),
      CodeLanguage.css => _scan(text, _css, _cssKind),
      CodeLanguage.js => _scan(text, _js, _jsKind),
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
    if (token.start < cursor) continue;
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

List<Token> _scan(
  String text,
  RegExp pattern,
  TokenKind? Function(RegExpMatch) kindOf,
) {
  final tokens = <Token>[];
  for (final match in pattern.allMatches(text)) {
    if (match.end == match.start) continue;
    final kind = kindOf(match);
    if (kind != null) tokens.add(Token(match.start, match.end, kind));
  }
  return tokens;
}

// ------------------------------------------------------------------- HTML

final _htmlOuter = RegExp(r'<!--[\s\S]*?(?:-->|$)|</?[a-zA-Z!][^<>]*>?');
final _htmlName = RegExp(r'^</?[a-zA-Z!][\w:-]*');
final _htmlPart = RegExp("([\\w:@.-]+)(?=\\s*=)|\"[^\"]*\"?|'[^']*'?");

List<Token> _tokenizeHtml(String text) {
  final tokens = <Token>[];
  for (final match in _htmlOuter.allMatches(text)) {
    final chunk = match[0]!;
    if (chunk.startsWith('<!--')) {
      tokens.add(Token(match.start, match.end, TokenKind.comment));
      continue;
    }
    final name = _htmlName.firstMatch(chunk);
    if (name == null) continue;
    tokens.add(Token(match.start, match.start + name.end, TokenKind.tag));
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
        tokens.add(Token(base + part.start, base + part.end, TokenKind.string));
      }
    }
  }
  return tokens;
}

// -------------------------------------------------------------------- CSS

final _css = RegExp(
  [
    r'(?<comment>/\*[\s\S]*?(?:\*/|$))',
    r'(?<dq>"(?:\\.|[^"\\\n])*"?)',
    r"(?<sq>'(?:\\.|[^'\\\n])*'?)",
    r'(?<at>@[\w-]+)',
    r'(?<hex>#[0-9a-fA-F]{3,8}\b)',
    r'(?<id>#[a-zA-Z_][\w-]*)',
    r'(?<prop>[a-zA-Z-][\w-]*(?=\s*:))',
    r'(?<cls>\.[a-zA-Z_][\w-]*)',
    r'(?<imp>!important)',
    r'(?<num>(?<![\w#.-])-?\d*\.?\d+(?:%|[a-zA-Z]+)?)',
  ].join('|'),
);

TokenKind? _cssKind(RegExpMatch m) {
  if (m.namedGroup('comment') != null) return TokenKind.comment;
  if (m.namedGroup('dq') != null || m.namedGroup('sq') != null) {
    return TokenKind.string;
  }
  if (m.namedGroup('at') != null || m.namedGroup('imp') != null) {
    return TokenKind.keyword;
  }
  if (m.namedGroup('hex') != null || m.namedGroup('num') != null) {
    return TokenKind.number;
  }
  if (m.namedGroup('prop') != null) return TokenKind.property;
  return TokenKind.tag;
}

// ------------------------------------------------------------- JavaScript

final _js = RegExp(
  [
    r'(?<comment>//[^\n]*|/\*[\s\S]*?(?:\*/|$))',
    r'(?<tpl>`(?:\\[\s\S]|[^`\\])*`?)',
    r'(?<dq>"(?:\\.|[^"\\\n])*"?)',
    r"(?<sq>'(?:\\.|[^'\\\n])*'?)",
    r'(?<kw>\b(?:const|let|var|function|return|if|else|for|while|do|switch|'
        r'case|break|continue|new|class|extends|import|export|from|default|'
        r'async|await|try|catch|finally|throw|typeof|instanceof|in|of|this|'
        r'true|false|null|undefined|void|delete|yield)\b)',
    r'(?<num>(?<![\w$])\d+(?:\.\d+)?\b)',
    r'(?<fn>[a-zA-Z_$][\w$]*(?=\s*\())',
  ].join('|'),
);

TokenKind? _jsKind(RegExpMatch m) {
  if (m.namedGroup('comment') != null) return TokenKind.comment;
  if (m.namedGroup('tpl') != null ||
      m.namedGroup('dq') != null ||
      m.namedGroup('sq') != null) {
    return TokenKind.string;
  }
  if (m.namedGroup('kw') != null) return TokenKind.keyword;
  if (m.namedGroup('num') != null) return TokenKind.number;
  return TokenKind.function;
}
