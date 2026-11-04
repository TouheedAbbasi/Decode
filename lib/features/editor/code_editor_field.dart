import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'code_language.dart';
import 'color_picker.dart';
import 'css_color.dart';
import 'editor_buffer.dart';
import 'suggester.dart';
import 'syntax_highlighter.dart';

/// Multi-line code field: line numbers, current-line highlight, colour
/// swatches and a VS Code style suggestion popup that opens right under the
/// word you type.
class CodeEditorField extends StatefulWidget {
  const CodeEditorField({
    super.key,
    required this.buffer,
    required this.fontSize,
    this.showLineNumbers = true,
    this.smartTyping = true,
  });

  final EditorBuffer buffer;
  final double fontSize;
  final bool showLineNumbers;
  final bool smartTyping;

  @override
  State<CodeEditorField> createState() => _CodeEditorFieldState();
}

class _CodeEditorFieldState extends State<CodeEditorField> {
  static const _verticalPadding = 12.0;
  static const _lineHeightFactor = 1.5;

  final _vertical = ScrollController();
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  static double _charWidth(TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: 'MMMMMMMMMM', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final width = painter.width / 10;
    painter.dispose();
    return width;
  }

  void _apply(SuggestionResult result, Suggestion suggestion) {
    final controller = widget.buffer.controller;
    final text = controller.text;
    final cursor = controller.selection.start;
    if (cursor < result.replaceStart) return;

    // Keep the indentation of the current line for multi-line snippets.
    final lineStart =
        text.substring(0, result.replaceStart).lastIndexOf('\n') + 1;
    final indent =
        RegExp(r'^[ \t]*').firstMatch(text.substring(lineStart))!.group(0)!;
    final template = suggestion.template.replaceAll('\n', '\n$indent');
    final marker = template.indexOf(caretMarker);
    final body = template.replaceFirst(caretMarker, '');

    controller.value = TextEditingValue(
      text: text.replaceRange(result.replaceStart, cursor, body),
      selection: TextSelection.collapsed(
        offset: result.replaceStart + (marker < 0 ? body.length : marker),
      ),
    );
    widget.buffer.focus.requestFocus();
  }

  Future<void> _pickColor(int start, int end, Color color) async {
    final controller = widget.buffer.controller;
    final text = controller.text;
    if (end > text.length) return;
    final picked = await showColorPickerDialog(
      context,
      initial: color,
      initialText: text.substring(start, end),
    );
    if (picked == null || !mounted) return;
    final now = controller.text;
    if (end > now.length) return;
    controller.value = TextEditingValue(
      text: now.replaceRange(start, end, picked),
      selection: TextSelection.collapsed(offset: start + picked.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buffer = widget.buffer;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    buffer.controller.palette = dark ? SyntaxPalette.dark : SyntaxPalette.light;

    final textStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: widget.fontSize,
      height: _lineHeightFactor,
      color: theme.colorScheme.onSurface,
    );
    final gutterStyle = textStyle.copyWith(
      color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
    );
    final strut = StrutStyle(
      fontFamily: 'monospace',
      fontSize: widget.fontSize,
      height: _lineHeightFactor,
      forceStrutHeight: true,
    );
    final charWidth = _charWidth(textStyle);
    final lineHeight = widget.fontSize * _lineHeightFactor;
    final lineHighlight = theme.colorScheme.primary.withAlpha(dark ? 30 : 16);

    return ListenableBuilder(
      listenable: Listenable.merge([buffer.controller, buffer.focus]),
      builder: (context, _) {
        final text = buffer.controller.text;
        var lineCount = 1;
        var longest = 0;
        var current = 0;
        for (var i = 0; i < text.length; i++) {
          if (text.codeUnitAt(i) == 10) {
            lineCount++;
            if (current > longest) longest = current;
            current = 0;
          } else {
            current++;
          }
        }
        if (current > longest) longest = current;

        int? caretLine;
        final selection = buffer.controller.selection;
        if (buffer.focus.hasFocus && selection.isValid) {
          var line = 0;
          final stop = math.min(selection.start, text.length);
          for (var i = 0; i < stop; i++) {
            if (text.codeUnitAt(i) == 10) line++;
          }
          caretLine = line;
        }

        final digits = math.max(2, lineCount.toString().length);
        final gutterWidth =
            widget.showLineNumbers ? digits * charWidth + 22 : 0.0;
        final numbers =
            [for (var i = 1; i <= lineCount; i++) '$i'].join('\n');

        return LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = math.max(
              constraints.maxWidth - gutterWidth,
              longest * charWidth + 64,
            );
            final viewport = Size(constraints.maxWidth, constraints.maxHeight);
            return Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => buffer.focus.requestFocus(),
                  child: SingleChildScrollView(
                    controller: _vertical,
                    padding:
                        const EdgeInsets.symmetric(vertical: _verticalPadding),
                    child: Stack(
                      children: [
                        if (caretLine != null)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: caretLine * lineHeight,
                            height: lineHeight,
                            child: ColoredBox(color: lineHighlight),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.showLineNumbers)
                              SizedBox(
                                width: gutterWidth,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Text(
                                    numbers,
                                    textAlign: TextAlign.right,
                                    style: gutterStyle,
                                    strutStyle: strut,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: _horizontal,
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: contentWidth,
                                  child: TextField(
                                    controller: buffer.controller,
                                    focusNode: buffer.focus,
                                    undoController: buffer.undo,
                                    inputFormatters: widget.smartTyping
                                        ? buffer.formatters
                                        : const [],
                                    maxLines: null,
                                    keyboardType: TextInputType.multiline,
                                    textInputAction: TextInputAction.newline,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    smartDashesType: SmartDashesType.disabled,
                                    smartQuotesType: SmartQuotesType.disabled,
                                    style: textStyle,
                                    strutStyle: strut,
                                    cursorColor: theme.colorScheme.primary,
                                    cursorWidth: 2,
                                    decoration: const InputDecoration.collapsed(
                                      hintText: null,
                                    ),
                                    scrollPadding: const EdgeInsets.all(48),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: _ColorSwatches(
                    buffer: buffer,
                    vertical: _vertical,
                    horizontal: _horizontal,
                    charWidth: charWidth,
                    lineHeight: lineHeight,
                    gutterWidth: gutterWidth,
                    verticalPadding: _verticalPadding,
                    viewport: viewport,
                    onPick: _pickColor,
                  ),
                ),
                Positioned.fill(
                  child: _SuggestionPopup(
                    buffer: buffer,
                    vertical: _vertical,
                    horizontal: _horizontal,
                    charWidth: charWidth,
                    lineHeight: lineHeight,
                    gutterWidth: gutterWidth,
                    verticalPadding: _verticalPadding,
                    viewport: viewport,
                    onApply: _apply,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Small colour boxes shown at the end of every visible line that contains a
/// colour. Tap one to change the colour with HSL sliders.
class _ColorSwatches extends StatefulWidget {
  const _ColorSwatches({
    required this.buffer,
    required this.vertical,
    required this.horizontal,
    required this.charWidth,
    required this.lineHeight,
    required this.gutterWidth,
    required this.verticalPadding,
    required this.viewport,
    required this.onPick,
  });

  final EditorBuffer buffer;
  final ScrollController vertical;
  final ScrollController horizontal;
  final double charWidth;
  final double lineHeight;
  final double gutterWidth;
  final double verticalPadding;
  final Size viewport;
  final void Function(int start, int end, Color color) onPick;

  @override
  State<_ColorSwatches> createState() => _ColorSwatchesState();
}

class _ColorSwatchesState extends State<_ColorSwatches> {
  String? _cachedText;
  List<int> _lineStarts = const [0];

  List<int> _starts(String text) {
    if (!identical(text, _cachedText)) {
      _cachedText = text;
      _lineStarts = [
        0,
        for (var i = 0; i < text.length; i++)
          if (text.codeUnitAt(i) == 10) i + 1,
      ];
    }
    return _lineStarts;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final language = widget.buffer.language;
    if (language == CodeLanguage.text) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.buffer.controller,
        widget.vertical,
        widget.horizontal,
      ]),
      builder: (context, _) {
        final text = widget.buffer.controller.text;
        final starts = _starts(text);
        final vOffset = widget.vertical.hasClients ? widget.vertical.offset : 0.0;
        final hOffset =
            widget.horizontal.hasClients ? widget.horizontal.offset : 0.0;

        final first = math.max(
          0,
          ((vOffset - widget.verticalPadding) / widget.lineHeight).floor(),
        );
        final last = math.min(
          starts.length - 1,
          ((vOffset + widget.viewport.height) / widget.lineHeight).ceil(),
        );

        final children = <Widget>[];
        for (var line = first; line <= last; line++) {
          final start = starts[line];
          final end = line + 1 < starts.length ? starts[line + 1] - 1 : text.length;
          if (end <= start || end - start > 400) continue;
          final lineText = text.substring(start, end);
          final matches =
              findColors(lineText, names: language == CodeLanguage.css);
          for (var k = 0; k < matches.length; k++) {
            final m = matches[k];
            var x = widget.gutterWidth +
                lineText.length * widget.charWidth +
                10 +
                k * 26 -
                hOffset;
            x = math.max(widget.gutterWidth, math.min(x, widget.viewport.width - 28));
            final y = widget.verticalPadding +
                line * widget.lineHeight -
                vOffset +
                (widget.lineHeight - 24) / 2;
            children.add(
              Positioned(
                left: x,
                top: y,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      widget.onPick(start + m.start, start + m.end, m.color),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: m.color,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: scheme.outline),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
        }
        return Stack(children: children);
      },
    );
  }
}

/// The suggestion list. It is placed from the position of the word being
/// typed, so it always sits inside the code area (never over the keyboard).
class _SuggestionPopup extends StatefulWidget {
  const _SuggestionPopup({
    required this.buffer,
    required this.vertical,
    required this.horizontal,
    required this.charWidth,
    required this.lineHeight,
    required this.gutterWidth,
    required this.verticalPadding,
    required this.viewport,
    required this.onApply,
  });

  final EditorBuffer buffer;
  final ScrollController vertical;
  final ScrollController horizontal;
  final double charWidth;
  final double lineHeight;
  final double gutterWidth;
  final double verticalPadding;
  final Size viewport;
  final void Function(SuggestionResult, Suggestion) onApply;

  @override
  State<_SuggestionPopup> createState() => _SuggestionPopupState();
}

class _SuggestionPopupState extends State<_SuggestionPopup> {
  static const _rowHeight = 38.0;
  static const _visibleRows = 6;

  SuggestionResult? _result;

  @override
  void initState() {
    super.initState();
    widget.buffer.controller.addListener(_recompute);
    widget.buffer.focus.addListener(_recompute);
    _result = _compute();
  }

  @override
  void dispose() {
    widget.buffer.controller.removeListener(_recompute);
    widget.buffer.focus.removeListener(_recompute);
    super.dispose();
  }

  SuggestionResult? _compute() {
    final controller = widget.buffer.controller;
    final selection = controller.selection;
    if (!widget.buffer.focus.hasFocus ||
        !selection.isValid ||
        !selection.isCollapsed) {
      return null;
    }
    return Suggester.suggest(
      controller.text,
      selection.start,
      widget.buffer.language,
    );
  }

  void _recompute() {
    final next = _compute();
    if (next == null && _result == null) return;
    if (mounted) setState(() => _result = next);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: Listenable.merge([widget.vertical, widget.horizontal]),
      builder: (context, _) {
        final text = widget.buffer.controller.text;
        final start = result.replaceStart.clamp(0, text.length);
        final before = text.substring(0, start);
        var line = 0;
        for (var i = 0; i < before.length; i++) {
          if (before.codeUnitAt(i) == 10) line++;
        }
        final column = start - (before.lastIndexOf('\n') + 1);

        final vOffset = widget.vertical.hasClients ? widget.vertical.offset : 0.0;
        final hOffset =
            widget.horizontal.hasClients ? widget.horizontal.offset : 0.0;

        final width = math.min(320.0, widget.viewport.width - 16);
        final rows = math.min(result.items.length, _visibleRows);
        final height = rows * _rowHeight + 2;

        final x = widget.gutterWidth + column * widget.charWidth - hOffset;
        final lineTop = widget.verticalPadding + line * widget.lineHeight - vOffset;

        final left = math.max(8.0, math.min(x, widget.viewport.width - width - 8));
        var top = lineTop + widget.lineHeight + 2;
        if (top + height > widget.viewport.height) {
          top = math.max(0.0, lineTop - height - 2);
        }

        // Hide it when the word has been scrolled out of view.
        if (lineTop < -widget.lineHeight || lineTop > widget.viewport.height) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: Material(
                elevation: 6,
                color: scheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: scheme.outline),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: result.items.length,
                  itemExtent: _rowHeight,
                  itemBuilder: (_, i) {
                    final item = result.items[i];
                    return InkWell(
                      canRequestFocus: false,
                      onTap: () => widget.onApply(result, item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Text(
                              item.label,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.preview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
