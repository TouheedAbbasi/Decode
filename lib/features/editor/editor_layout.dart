import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Where every logical line of the text lands on screen, including lines
/// that wrap onto several rows. Used to align line numbers, the current-line
/// highlight, colour boxes and the suggestion popup with the text.
///
/// Rows have one fixed height ([lineHeight]), so a row index is enough to
/// know the vertical position.
class EditorLayout {
  EditorLayout._({
    required this.text,
    required this.starts,
    required this.rows,
    required this.rowStart,
    required this.totalRows,
    required this.wrap,
    required this.availableWidth,
    required this.charWidth,
    required this.lineHeight,
    required this.style,
    required this.strut,
  });

  final String text;

  /// Offset in [text] where each logical line begins.
  final List<int> starts;

  /// Number of visual rows each logical line needs.
  final List<int> rows;

  /// Index of the first visual row of each logical line.
  final List<int> rowStart;
  final int totalRows;

  final bool wrap;
  final double availableWidth;
  final double charWidth;
  final double lineHeight;
  final TextStyle style;
  final StrutStyle strut;

  /// The text field wraps at its width minus the caret margin
  /// (1px gap + cursor width).
  static const caretMargin = 3.0;

  static EditorLayout compute({
    required String text,
    required bool wrap,
    required double textWidth,
    required double charWidth,
    required double lineHeight,
    required TextStyle style,
    required StrutStyle strut,
    required Map<String, int> cache,
  }) {
    final available = math.max(charWidth, textWidth - caretMargin);
    final starts = <int>[0];
    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == 10) starts.add(i + 1);
    }
    final rows = List<int>.filled(starts.length, 1);
    final rowStart = List<int>.filled(starts.length, 0);
    var total = 0;
    for (var i = 0; i < starts.length; i++) {
      final end = i + 1 < starts.length ? starts[i + 1] - 1 : text.length;
      var count = 1;
      if (wrap) {
        final length = end - starts[i];
        // Monospace: a line that is clearly narrower than the field is one row.
        if (length * charWidth > available - 1) {
          final line = text.substring(starts[i], end);
          count = cache[line] ??= _measure(line, style, strut, available);
        }
      }
      rows[i] = count;
      rowStart[i] = total;
      total += count;
    }
    return EditorLayout._(
      text: text,
      starts: starts,
      rows: rows,
      rowStart: rowStart,
      totalRows: total,
      wrap: wrap,
      availableWidth: available,
      charWidth: charWidth,
      lineHeight: lineHeight,
      style: style,
      strut: strut,
    );
  }

  static int _measure(
    String line,
    TextStyle style,
    StrutStyle strut,
    double width,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: line, style: style),
      textDirection: TextDirection.ltr,
      strutStyle: strut,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: width);
    final count = painter.computeLineMetrics().length;
    painter.dispose();
    return math.max(1, count);
  }

  /// Index of the logical line that contains [offset].
  int lineOf(int offset) {
    var low = 0;
    var high = starts.length - 1;
    final target = offset.clamp(0, text.length).toInt();
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (starts[mid] <= target) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  int _lineEnd(int line) =>
      line + 1 < starts.length ? starts[line + 1] - 1 : text.length;

  /// Visual row and horizontal position (in pixels from the left edge of the
  /// text area) of the caret at [offset].
  ({int row, double x}) locate(int offset) {
    final safe = offset.clamp(0, text.length).toInt();
    final line = lineOf(safe);
    final column = safe - starts[line];
    if (rows[line] == 1) {
      return (row: rowStart[line], x: column * charWidth);
    }
    final painter = TextPainter(
      text: TextSpan(text: text.substring(starts[line], _lineEnd(line)), style: style),
      textDirection: TextDirection.ltr,
      strutStyle: strut,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: availableWidth);
    final caret = painter.getOffsetForCaret(
      TextPosition(offset: column),
      Rect.zero,
    );
    painter.dispose();
    final inner = ((caret.dy + lineHeight * 0.25) / lineHeight).floor();
    return (
      row: rowStart[line] + inner.clamp(0, rows[line] - 1).toInt(),
      x: caret.dx,
    );
  }

  /// One entry per visual row: the line number on the first row of a line and
  /// an empty string on wrapped rows, joined with line breaks.
  String gutterText() {
    final out = StringBuffer();
    for (var i = 0; i < starts.length; i++) {
      out.write(i + 1);
      for (var k = 1; k < rows[i]; k++) {
        out.write('\n');
      }
      if (i < starts.length - 1) out.write('\n');
    }
    return out.toString();
  }
}
