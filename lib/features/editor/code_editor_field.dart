import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'code_editing.dart';
import 'editor_buffer.dart';
import 'syntax_highlighter.dart';

/// Multi-line code field with line numbers and horizontal scrolling.
class CodeEditorField extends StatelessWidget {
  const CodeEditorField({
    super.key,
    required this.buffer,
    required this.fontSize,
  });

  final EditorBuffer buffer;
  final double fontSize;

  static double _charWidth(TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: 'MMMMMMMMMM', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final width = painter.width / 10;
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    buffer.controller.palette = dark ? SyntaxPalette.dark : SyntaxPalette.light;

    final textStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: fontSize,
      height: 1.5,
      color: theme.colorScheme.onSurface,
    );
    final gutterStyle = textStyle.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final strut = StrutStyle(
      fontFamily: 'monospace',
      fontSize: fontSize,
      height: 1.5,
      forceStrutHeight: true,
    );
    final charWidth = _charWidth(textStyle);

    return ListenableBuilder(
      listenable: buffer.controller,
      builder: (context, _) {
        final lines = buffer.controller.text.split('\n');
        var longest = 0;
        for (final line in lines) {
          if (line.length > longest) longest = line.length;
        }
        final digits = math.max(2, lines.length.toString().length);
        final gutterWidth = digits * charWidth + 22;
        final numbers = [for (var i = 1; i <= lines.length; i++) '$i'].join('\n');

        return LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = math.max(
              constraints.maxWidth - gutterWidth,
              longest * charWidth + 64,
            );
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => buffer.focus.requestFocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: contentWidth,
                          child: TextField(
                            controller: buffer.controller,
                            focusNode: buffer.focus,
                            undoController: buffer.undo,
                            inputFormatters: [CodeInputFormatter(buffer.language)],
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
                            decoration:
                                const InputDecoration.collapsed(hintText: null),
                            scrollPadding: const EdgeInsets.all(48),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
