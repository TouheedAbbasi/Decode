import 'dart:math' as math;

import 'package:flutter/services.dart';

import 'code_language.dart';

/// Block edits used by the editor toolbar: indent, outdent, comment.
class CodeActions {
  CodeActions._();

  static TextEditingValue indent(
    TextEditingValue value, {
    required bool outdent,
  }) {
    final selection = value.selection;
    if (!selection.isValid) return value;
    final range = _lineRange(value.text, selection);
    final lines = value.text.substring(range.$1, range.$2).split('\n');
    final changed = [
      for (final line in lines)
        outdent ? _outdentLine(line) : (line.isEmpty ? line : '  $line'),
    ];
    return _replace(
      value,
      range,
      changed.join('\n'),
      firstLineDelta: changed.first.length - lines.first.length,
    );
  }

  static TextEditingValue toggleComment(
    TextEditingValue value,
    CodeLanguage language,
  ) {
    final selection = value.selection;
    if (!selection.isValid) return value;
    final lang = effectiveLanguage(value.text, selection.start, language);
    final range = _lineRange(value.text, selection);
    final block = value.text.substring(range.$1, range.$2);
    final lines = block.split('\n');

    if (lang == CodeLanguage.js) {
      final filled = lines.where((l) => l.trim().isNotEmpty).toList();
      final allCommented =
          filled.isNotEmpty && filled.every((l) => l.trimLeft().startsWith('//'));
      final changed = [
        for (final line in lines)
          line.trim().isEmpty
              ? line
              : (allCommented ? _uncommentLine(line) : _commentLine(line)),
      ];
      return _replace(
        value,
        range,
        changed.join('\n'),
        firstLineDelta: changed.first.length - lines.first.length,
      );
    }

    final isCss = lang == CodeLanguage.css;
    final open = isCss ? '/*' : '<!--';
    final close = isCss ? '*/' : '-->';
    final trimmed = block.trim();
    final wrapped = trimmed.startsWith(open) && trimmed.endsWith(close);

    String changed;
    if (wrapped) {
      var text = block;
      final oi = text.indexOf(open);
      final afterOpen = oi + open.length;
      text = text.replaceRange(
        oi,
        afterOpen + (text.startsWith(' ', afterOpen) ? 1 : 0),
        '',
      );
      final ci = text.lastIndexOf(close);
      final start = (ci > 0 && text[ci - 1] == ' ') ? ci - 1 : ci;
      changed = text.replaceRange(start, ci + close.length, '');
    } else {
      final indent = RegExp(r'^[ \t]*').firstMatch(block)!.group(0)!;
      changed = '$indent$open ${block.substring(indent.length)} $close';
    }
    return _replace(
      value,
      range,
      changed,
      firstLineDelta: wrapped ? -(open.length + 1) : open.length + 1,
    );
  }

  // ----------------------------------------------------------------- helpers

  /// Start and end offsets of the whole lines touched by [selection].
  static (int, int) _lineRange(String text, TextSelection selection) {
    final start = selection.start;
    var end = selection.end;
    final lineStart = text.substring(0, start).lastIndexOf('\n') + 1;
    if (end > start && end > 0 && text[end - 1] == '\n') end -= 1;
    final newline = text.indexOf('\n', end);
    return (lineStart, newline < 0 ? text.length : newline);
  }

  static TextEditingValue _replace(
    TextEditingValue value,
    (int, int) range,
    String newBlock, {
    required int firstLineDelta,
  }) {
    final text = value.text.replaceRange(range.$1, range.$2, newBlock);
    final selection = value.selection;
    if (selection.isCollapsed) {
      final caret = math.min(
        math.max(selection.start + firstLineDelta, range.$1),
        range.$1 + newBlock.length,
      );
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: caret),
      );
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection(
        baseOffset: range.$1,
        extentOffset: range.$1 + newBlock.length,
      ),
    );
  }

  static String _outdentLine(String line) {
    if (line.startsWith('  ')) return line.substring(2);
    if (line.startsWith(' ') || line.startsWith('\t')) return line.substring(1);
    return line;
  }

  static String _commentLine(String line) {
    final indent = RegExp(r'^[ \t]*').firstMatch(line)!.group(0)!;
    return '$indent// ${line.substring(indent.length)}';
  }

  static String _uncommentLine(String line) {
    final indent = RegExp(r'^[ \t]*').firstMatch(line)!.group(0)!;
    final rest = line.substring(indent.length);
    if (rest.startsWith('// ')) return '$indent${rest.substring(3)}';
    if (rest.startsWith('//')) return '$indent${rest.substring(2)}';
    return line;
  }
}
