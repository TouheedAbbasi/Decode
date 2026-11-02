import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'editor_buffer.dart';
import 'suggester.dart';
import 'syntax_highlighter.dart';

/// Multi-line code field: line numbers, horizontal scrolling and a
/// VS Code style suggestion popup that opens right under the word you type.
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
      color: theme.colorScheme.onSurfaceVariant,
    );
    final strut = StrutStyle(
      fontFamily: 'monospace',
      fontSize: widget.fontSize,
      height: _lineHeightFactor,
      forceStrutHeight: true,
    );
    final charWidth = _charWidth(textStyle);
    final lineHeight = widget.fontSize * _lineHeightFactor;

    return ListenableBuilder(
      listenable: buffer.controller,
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
        final numbers =
            [for (var i = 1; i <= lineCount; i++) '$i'].join('\n');

        return LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = math.max(
              constraints.maxWidth - gutterWidth,
              longest * charWidth + 64,
            );
            return Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => buffer.focus.requestFocus(),
                  child: SingleChildScrollView(
                    controller: _vertical,
                    padding:
                        const EdgeInsets.symmetric(vertical: _verticalPadding),
                    child: Row(
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
                    viewport: Size(constraints.maxWidth, constraints.maxHeight),
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

        final width = math.min(300.0, widget.viewport.width - 16);
        final height = result.items.length * _rowHeight + 2;

        final x = widget.gutterWidth + column * widget.charWidth - hOffset;
        final lineTop = widget.verticalPadding + line * widget.lineHeight - vOffset;

        final left = math.max(8.0, math.min(x, widget.viewport.width - width - 8));
        var top = lineTop + widget.lineHeight + 2;
        if (top + height > widget.viewport.height) {
          top = math.max(0.0, lineTop - height - 2);
        }

        // Hide it when the word has been scrolled out of view.
        if (lineTop < -widget.lineHeight ||
            lineTop > widget.viewport.height) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: width,
              child: Material(
                elevation: 6,
                color: scheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: scheme.outline),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final item in result.items)
                      InkWell(
                        canRequestFocus: false,
                        onTap: () => widget.onApply(result, item),
                        child: SizedBox(
                          height: _rowHeight,
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
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
