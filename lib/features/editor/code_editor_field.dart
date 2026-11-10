import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'code_language.dart';
import 'color_picker.dart';
import 'css_color.dart';
import 'editor_buffer.dart';
import 'editor_layout.dart';
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
    this.wrap = true,
  });

  final EditorBuffer buffer;
  final double fontSize;
  final bool showLineNumbers;
  final bool smartTyping;

  /// Wrap long lines instead of scrolling sideways.
  final bool wrap;

  @override
  State<CodeEditorField> createState() => _CodeEditorFieldState();
}

class _CodeEditorFieldState extends State<CodeEditorField> {
  static const _verticalPadding = 12.0;
  static const _lineHeightFactor = 1.5;

  final _vertical = ScrollController();
  final _horizontal = ScrollController();

  /// Row counts of long lines, so only edited lines are measured again.
  final Map<String, int> _rowCache = {};
  double? _cacheWidth;
  double? _cacheFont;

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

        final digits = math.max(2, lineCount.toString().length);
        final gutterWidth =
            widget.showLineNumbers ? digits * charWidth + 22 : 0.0;

        return LayoutBuilder(
          builder: (context, constraints) {
            final textWidth = math.max(60.0, constraints.maxWidth - gutterWidth);
            if (_cacheWidth != textWidth || _cacheFont != widget.fontSize) {
              _rowCache.clear();
              _cacheWidth = textWidth;
              _cacheFont = widget.fontSize;
            }
            final layout = EditorLayout.compute(
              text: text,
              wrap: widget.wrap,
              textWidth: textWidth,
              charWidth: charWidth,
              lineHeight: lineHeight,
              style: textStyle,
              strut: strut,
              cache: _rowCache,
            );
            final contentWidth = widget.wrap
                ? textWidth
                : math.max(textWidth, longest * charWidth + 64);

            int? caretLine;
            final selection = buffer.controller.selection;
            if (buffer.focus.hasFocus && selection.isValid) {
              caretLine = layout.lineOf(selection.start);
            }
            final viewport = Size(constraints.maxWidth, constraints.maxHeight);

            final field = TextField(
              controller: buffer.controller,
              focusNode: buffer.focus,
              undoController: buffer.undo,
              inputFormatters: widget.smartTyping ? buffer.formatters : const [],
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
              decoration: const InputDecoration.collapsed(hintText: null),
              scrollPadding: const EdgeInsets.all(48),
            );

            // The editor ignores the system font scale: row heights and
            // wrapping are calculated for the exact font size set here.
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.noScaling,
              ),
              child: Stack(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => buffer.focus.requestFocus(),
                    child: SingleChildScrollView(
                      controller: _vertical,
                      padding: const EdgeInsets.symmetric(
                        vertical: _verticalPadding,
                      ),
                      child: Stack(
                        children: [
                          if (caretLine != null)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: layout.rowStart[caretLine] * lineHeight,
                              height: layout.rows[caretLine] * lineHeight,
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
                                      layout.gutterText(),
                                      textAlign: TextAlign.right,
                                      style: gutterStyle,
                                      strutStyle: strut,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: widget.wrap
                                    ? field
                                    : SingleChildScrollView(
                                        controller: _horizontal,
                                        scrollDirection: Axis.horizontal,
                                        child: SizedBox(
                                          width: contentWidth,
                                          child: field,
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
                      layout: layout,
                      vertical: _vertical,
                      horizontal: _horizontal,
                      gutterWidth: gutterWidth,
                      verticalPadding: _verticalPadding,
                      viewport: viewport,
                      onPick: _pickColor,
                    ),
                  ),
                  Positioned.fill(
                    child: _SuggestionPopup(
                      buffer: buffer,
                      layout: layout,
                      vertical: _vertical,
                      horizontal: _horizontal,
                      gutterWidth: gutterWidth,
                      verticalPadding: _verticalPadding,
                      viewport: viewport,
                      onApply: _apply,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Small colour boxes drawn just BEFORE every colour in view (over the space
/// in front of it). If there is no space in front (for example after `(` or
/// `,`), the box goes right after the colour so no code is covered.
/// Tap a box to change the colour with HSL sliders.
class _ColorSwatches extends StatelessWidget {
  const _ColorSwatches({
    required this.buffer,
    required this.layout,
    required this.vertical,
    required this.horizontal,
    required this.gutterWidth,
    required this.verticalPadding,
    required this.viewport,
    required this.onPick,
  });

  final EditorBuffer buffer;
  final EditorLayout layout;
  final ScrollController vertical;
  final ScrollController horizontal;
  final double gutterWidth;
  final double verticalPadding;
  final Size viewport;
  final void Function(int start, int end, Color color) onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final language = buffer.language;
    if (language == CodeLanguage.text) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: Listenable.merge([vertical, horizontal]),
      builder: (context, _) {
        final text = layout.text;
        final vOffset = vertical.hasClients ? vertical.offset : 0.0;
        final hOffset = horizontal.hasClients ? horizontal.offset : 0.0;
        final lineHeight = layout.lineHeight;
        final box = math.max(9.0, layout.charWidth * 1.15);

        final firstRow = math.max(0, ((vOffset - verticalPadding) / lineHeight).floor() - 1);
        final lastRow = ((vOffset + viewport.height) / lineHeight).ceil();

        final children = <Widget>[];
        for (var line = 0; line < layout.starts.length; line++) {
          final rowStart = layout.rowStart[line];
          if (rowStart + layout.rows[line] < firstRow) continue;
          if (rowStart > lastRow) break;

          final start = layout.starts[line];
          final end = line + 1 < layout.starts.length
              ? layout.starts[line + 1] - 1
              : text.length;
          if (end <= start || end - start > 600) continue;
          final lineText = text.substring(start, end);
          final matches =
              findColors(lineText, names: language == CodeLanguage.css);

          var after = 0;
          for (final m in matches) {
            final here = layout.locate(start + m.start);
            final spaceBefore = m.start > 0 && lineText[m.start - 1] == ' ';

            double x;
            int row;
            if (spaceBefore && here.x >= box) {
              x = here.x - box + 0.5;
              row = here.row;
            } else {
              final tail = layout.locate(start + m.end);
              x = tail.x + 4 + after * (box + 4);
              row = tail.row;
              after++;
            }

            final left = math.max(
              gutterWidth,
              math.min(gutterWidth + x - hOffset, viewport.width - box - 8),
            );
            final top = verticalPadding + row * lineHeight - vOffset +
                (lineHeight - box) / 2;
            if (top < -lineHeight || top > viewport.height) continue;

            children.add(
              Positioned(
                left: left - 3,
                top: top - 3,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onPick(start + m.start, start + m.end, m.color),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      width: box,
                      height: box,
                      decoration: BoxDecoration(
                        color: m.color,
                        borderRadius: BorderRadius.circular(3),
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
    required this.layout,
    required this.vertical,
    required this.horizontal,
    required this.gutterWidth,
    required this.verticalPadding,
    required this.viewport,
    required this.onApply,
  });

  final EditorBuffer buffer;
  final EditorLayout layout;
  final ScrollController vertical;
  final ScrollController horizontal;
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
        final start =
            result.replaceStart.clamp(0, widget.layout.text.length).toInt();
        final here = widget.layout.locate(start);
        final lineHeight = widget.layout.lineHeight;

        final vOffset = widget.vertical.hasClients ? widget.vertical.offset : 0.0;
        final hOffset =
            widget.horizontal.hasClients ? widget.horizontal.offset : 0.0;

        final width = math.min(320.0, widget.viewport.width - 16);
        final rows = math.min(result.items.length, _visibleRows);
        final height = rows * _rowHeight + 2;

        final x = widget.gutterWidth + here.x - hOffset;
        final lineTop = widget.verticalPadding + here.row * lineHeight - vOffset;

        final left = math.max(8.0, math.min(x, widget.viewport.width - width - 8));
        var top = lineTop + lineHeight + 2;
        if (top + height > widget.viewport.height) {
          top = math.max(0.0, lineTop - height - 2);
        }

        // Hide it when the word has been scrolled out of view.
        if (lineTop < -lineHeight || lineTop > widget.viewport.height) {
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
