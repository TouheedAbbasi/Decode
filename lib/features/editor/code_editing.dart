import 'package:flutter/services.dart';

import 'code_language.dart';

/// Smart typing helpers: auto-closing brackets, quotes and HTML tags,
/// skipping over closers, and auto-indent on Enter.
class CodeEditing {
  CodeEditing._();

  static const _voidTags = {
    'area',
    'base',
    'br',
    'col',
    'embed',
    'hr',
    'img',
    'input',
    'link',
    'meta',
    'source',
    'track',
    'wbr',
  };

  static const _pairs = {'(': ')', '[': ']', '{': '}'};
  static const _quotes = {'"', "'", '`'};
  static const _closers = {')', ']', '}', '"', "'", '`'};

  static final _wordChar = RegExp(r'\w');
  static final _openTag = RegExp(r'^([a-zA-Z][\w:-]*)(?:\s[^<>]*)?$');
  static final _lineOpenTag = RegExp(r'^\s*<([a-zA-Z][\w:-]*)[^<>]*>$');
  static final _leadingSpace = RegExp(r'^[ \t]*');

  /// Returns the edited value, or null when no special handling applies.
  /// [oldValue] -> [newValue] must be exactly one character typed at the
  /// cursor.
  static TextEditingValue? autoEdit(
    TextEditingValue oldValue,
    TextEditingValue newValue,
    CodeLanguage language,
  ) {
    if (!oldValue.selection.isValid || !oldValue.selection.isCollapsed) {
      return null;
    }
    if (!newValue.selection.isValid || !newValue.selection.isCollapsed) {
      return null;
    }
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) {
      return null;
    }

    final oldText = oldValue.text;
    final newText = newValue.text;
    if (newText.length != oldText.length + 1) return null;

    final i = newValue.selection.start - 1;
    if (i < 0 || i >= newText.length || oldValue.selection.start != i) {
      return null;
    }

    final before = oldText.substring(0, i);
    final after = oldText.substring(i);
    final ch = newText[i];
    if (newText != before + ch + after) return null;

    final next = after.isEmpty ? '' : after[0];
    final prev = before.isEmpty ? '' : before[before.length - 1];

    if (_closers.contains(ch) && next == ch) {
      return TextEditingValue(
        text: oldText,
        selection: TextSelection.collapsed(offset: i + 1),
      );
    }

    final inHtmlText = language == CodeLanguage.html && !_insideTag(before);

    if (_pairs.containsKey(ch)) {
      if (inHtmlText || _isWord(next)) return null;
      return _build(before, ch + _pairs[ch]!, after, i + 1);
    }

    if (_quotes.contains(ch)) {
      if (inHtmlText || _isWord(prev) || _isWord(next)) return null;
      return _build(before, ch + ch, after, i + 1);
    }

    if (ch == '>' && language == CodeLanguage.html) {
      final closing = _closingTagFor(before);
      if (closing != null) return _build(before, '>$closing', after, i + 1);
      return null;
    }

    if (ch == '\n') return _newline(before, after, language);

    return null;
  }

  static bool _isWord(String c) => c.isNotEmpty && _wordChar.hasMatch(c);

  static bool _insideTag(String before) =>
      before.lastIndexOf('<') > before.lastIndexOf('>');

  /// For text typed up to `<div class="a"`, returns `</div>`.
  static String? _closingTagFor(String before) {
    final lt = before.lastIndexOf('<');
    if (lt < 0 || before.lastIndexOf('>') > lt) return null;
    final inner = before.substring(lt + 1);
    if (inner.endsWith('/')) return null;
    final match = _openTag.firstMatch(inner);
    if (match == null) return null;
    final tag = match.group(1)!;
    if (_voidTags.contains(tag.toLowerCase())) return null;
    return '</$tag>';
  }

  static TextEditingValue _build(
    String before,
    String middle,
    String after,
    int caret,
  ) =>
      TextEditingValue(
        text: before + middle + after,
        selection: TextSelection.collapsed(offset: caret),
      );

  static TextEditingValue _newline(
    String before,
    String after,
    CodeLanguage language,
  ) {
    final line = before.substring(before.lastIndexOf('\n') + 1);
    final indent = _leadingSpace.firstMatch(line)!.group(0)!;
    final trimmed = line.trimRight();
    final nextChar = after.isEmpty ? '' : after[0];

    final opensBlock = trimmed.endsWith('{') ||
        trimmed.endsWith('[') ||
        trimmed.endsWith('(');
    final closesBlock =
        nextChar == '}' || nextChar == ']' || nextChar == ')';

    var opensTag = false;
    var betweenTags = false;
    if (language == CodeLanguage.html) {
      final match = _lineOpenTag.firstMatch(line);
      if (match != null &&
          !trimmed.endsWith('/>') &&
          !_voidTags.contains(match.group(1)!.toLowerCase())) {
        opensTag = true;
        betweenTags = after.startsWith('</');
      }
    }

    final extra = (opensBlock || opensTag) ? '  ' : '';
    final expand = (opensBlock && closesBlock) || betweenTags;
    final caretText = '\n$indent$extra';
    final tail = expand ? '\n$indent' : '';

    return TextEditingValue(
      text: before + caretText + tail + after,
      selection: TextSelection.collapsed(
        offset: before.length + caretText.length,
      ),
    );
  }
}

/// Plugs [CodeEditing] into a TextField.
class CodeInputFormatter extends TextInputFormatter {
  CodeInputFormatter(this.language);

  final CodeLanguage language;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      CodeEditing.autoEdit(oldValue, newValue, language) ?? newValue;
}
