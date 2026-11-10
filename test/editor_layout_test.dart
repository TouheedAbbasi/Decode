import 'package:decode/features/editor/editor_layout.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const style = TextStyle(fontFamily: 'Ahem', fontSize: 10, height: 1.5);
  const strut = StrutStyle(fontFamily: 'Ahem', fontSize: 10, height: 1.5, forceStrutHeight: true);
  // In the test font every character is exactly 10 pixels wide.
  EditorLayout build(String text, {bool wrap = true, double width = 103}) =>
      EditorLayout.compute(
        text: text,
        wrap: wrap,
        textWidth: width, // minus the 3px caret margin = 100px = 10 characters
        charWidth: 10,
        lineHeight: 15,
        style: style,
        strut: strut,
        cache: {},
      );

  test('short lines stay on one row', () {
    final layout = build('abc\n\nhello');
    expect(layout.rows, [1, 1, 1]);
    expect(layout.rowStart, [0, 1, 2]);
    expect(layout.totalRows, 3);
    expect(layout.gutterText(), '1\n2\n3');
  });

  test('a long line wraps and later lines move down', () {
    final layout = build('short\n${'a' * 25}\nend');
    expect(layout.rows, [1, 3, 1]);
    expect(layout.rowStart, [0, 1, 4]);
    expect(layout.totalRows, 5);
    // line number sits on the first row only; wrapped rows stay empty
    expect(layout.gutterText(), '1\n2\n\n\n3');
  });

  test('without wrap every line is one row', () {
    final layout = build('${'a' * 25}\nb', wrap: false);
    expect(layout.rows, [1, 1]);
    expect(layout.totalRows, 2);
  });

  test('lineOf and locate follow the wrapped rows', () {
    final text = 'short\n${'a' * 25}\nend';
    final layout = build(text);
    expect(layout.lineOf(0), 0);
    expect(layout.lineOf(6), 1);
    expect(layout.lineOf(text.length), 2);

    final start = layout.locate(6);
    expect(start.row, 1);
    expect(start.x, 0);
    final third = layout.locate(6 + 22); // 22nd character -> third row
    expect(third.row, 3);
    final endLine = layout.locate(text.length);
    expect(endLine.row, 4);
    expect(endLine.x, 30);
  });

  test('row counts are cached by line text', () {
    final cache = <String, int>{};
    EditorLayout.compute(
      text: 'a' * 25,
      wrap: true,
      textWidth: 103,
      charWidth: 10,
      lineHeight: 15,
      style: style,
      strut: strut,
      cache: cache,
    );
    expect(cache['a' * 25], 3);
  });
}
